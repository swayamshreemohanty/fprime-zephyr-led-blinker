// ======================================================================
// \title  UartBufferAdapter.hpp
// \author Auto-generated
// \brief  hpp file for UartBufferAdapter component implementation class
// ======================================================================

#ifndef Components_UartBufferAdapter_HPP
#define Components_UartBufferAdapter_HPP

#include "Components/UartBufferAdapter/UartBufferAdapterComponentAc.hpp"

namespace Components {

  class UartBufferAdapter :
    public UartBufferAdapterComponentBase
  {

    public:

      // ----------------------------------------------------------------------
      // Component construction and destruction
      // ----------------------------------------------------------------------

      //! Construct UartBufferAdapter object
      UartBufferAdapter(
          const char* const compName //!< The component name
      );

      //! Destroy UartBufferAdapter object
      ~UartBufferAdapter();

    private:

      // ----------------------------------------------------------------------
      // Handler implementations for typed input ports
      // ----------------------------------------------------------------------

      //! Handler for bufferIn
      void bufferIn_handler(
          FwIndexType portNum, //!< The port number
          Fw::Buffer& fwBuffer //!< Buffer from GenericHub to send via UART
      );

      //! Handler for bufferOutReturn
      void bufferOutReturn_handler(
          FwIndexType portNum, //!< The port number
          Fw::Buffer& fwBuffer //!< Buffer returned from GenericHub
      );

      //! Handler for fromByteStreamDriver
      void fromByteStreamDriver_handler(
          FwIndexType portNum, //!< The port number
          Fw::Buffer& buffer, //!< Buffer with received data
          const Drv::ByteStreamStatus& status //!< Receive status
      );

      //! Handler for byteStreamDriverReady
      void byteStreamDriverReady_handler(
          FwIndexType portNum //!< The port number
      );

      // ----------------------------------------------------------------------
      // Member variables
      // ----------------------------------------------------------------------

      //! Track if UART driver is ready
      bool m_driverIsReady = false;

  };

}

#endif
