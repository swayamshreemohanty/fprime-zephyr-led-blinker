// ======================================================================
// \title  UartBufferAdapter.cpp
// \author Project-specific implementation
// \brief  cpp file for UartBufferAdapter component implementation class
//
// This component bridges ByteStreamDriver (UART) to PassiveBufferDriver (GenericHub)
// It handles the protocol mismatch between STM32 and RPi deployments
// ======================================================================

#include "Components/UartBufferAdapter/UartBufferAdapter.hpp"
#include <Fw/Types/Assert.hpp>
#include <Fw/Logger/Logger.hpp>

namespace Components {

// ----------------------------------------------------------------------
// Component construction and destruction
// ----------------------------------------------------------------------

UartBufferAdapter::UartBufferAdapter(const char* const compName)
    : UartBufferAdapterComponentBase(compName) {}

UartBufferAdapter::~UartBufferAdapter() {}

// ----------------------------------------------------------------------
// Handler implementations for typed input ports
// ----------------------------------------------------------------------

void UartBufferAdapter::bufferIn_handler(FwIndexType portNum, Fw::Buffer& fwBuffer) {
    // TX path: GenericHub → this → UART
    
    if (m_driverIsReady) {
        // Send buffer to UART driver
        Drv::ByteStreamStatus status = toByteStreamDriver_out(0, fwBuffer);
        
        if (status != Drv::ByteStreamStatus::OP_OK) {
            Fw::Logger::log("[UartBufferAdapter] ERROR: UART TX failed with status %d\n", status);
        }
    } else {
        Fw::Logger::log("[UartBufferAdapter] WARNING: UART not ready, dropping TX data\n");
    }
    
    // Return buffer to GenericHub
    bufferInReturn_out(0, fwBuffer);
}

void UartBufferAdapter::bufferOutReturn_handler(FwIndexType portNum, Fw::Buffer& fwBuffer) {
    // RX path: GenericHub returns buffer after processing
    // Return it to UART driver's buffer pool
    fromByteStreamDriverReturn_out(0, fwBuffer);
}

void UartBufferAdapter::fromByteStreamDriver_handler(FwIndexType portNum,
                                                      Fw::Buffer& buffer,
                                                      const Drv::ByteStreamStatus& status) {
    // RX path: UART → this → GenericHub
    
    if (status == Drv::ByteStreamStatus::OP_OK && buffer.getSize() > 0) {
        // Forward received data to GenericHub for deserialization
        bufferOut_out(0, buffer);
    } else {
        // Error or empty buffer - return immediately
        fromByteStreamDriverReturn_out(0, buffer);
    }
}

void UartBufferAdapter::byteStreamDriverReady_handler(FwIndexType portNum) {
    m_driverIsReady = true;
    Fw::Logger::log("[UartBufferAdapter] UART driver ready\n");
}

}  // namespace Components
