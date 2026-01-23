// ======================================================================
// \title  Main.cpp
// \brief main program for the F' application. Intended for CLI-based systems (Linux, macOS)
//
// ======================================================================
// Used to access topology functions
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopologyAc.hpp>
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopology.hpp>
#include <Fw/Logger/Logger.hpp>

// USART2 for RPi communication (PA2=TX, PA3=RX @ 115200 baud, 8N1)
// Matches working uart_rpi_stm_test configuration
const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(usart2));

// Fatal error handler
extern "C" void k_sys_fatal_error_handler(unsigned int reason, const struct arch_esf *esf)
{
    // Fatal error occurred - halt execution
    (void)reason;
    (void)esf;
    
    while(1) {
        k_sleep(K_FOREVER);
    }
}

int main()
{
    // Object for communicating state to the reference topology
    Stm32LedBlinker::TopologyState inputs;
    inputs.dev = serial;
    inputs.uartBaud = 115200;

    // Setup topology
    Stm32LedBlinker::setupTopology(inputs);
    
    while(true)
    {
        Stm32LedBlinker::rateDriver.cycle();
        k_usleep(10);  // 1 millisecond = 1000Hz cycle rate (normal operation)
    }

    return 0;
}
