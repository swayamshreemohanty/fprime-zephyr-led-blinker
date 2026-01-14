module Components {

  @ Custom ByteStream to Buffer adapter for UART communication with GenericHub
  @ This is a project-specific implementation that matches Drv.ByteStreamBufferAdapter
  @ Used to bridge LinuxUartDriver (ByteStreamDriver) to GenericHub (PassiveBufferDriver)
  passive component UartBufferAdapter {

    # ----------------------------------------------------------------------
    # Ports from PassiveBufferDriver interface
    # ----------------------------------------------------------------------

    @ Port for receiving buffers from GenericHub to send via UART
    sync input port bufferIn: Fw.BufferSend

    @ Port for returning buffers back to GenericHub after sending
    output port bufferInReturn: Fw.BufferSend

    @ Port for sending received data to GenericHub
    output port bufferOut: Fw.BufferSend

    @ Port for returning received buffers back to GenericHub after processing
    sync input port bufferOutReturn: Fw.BufferSend

    # ----------------------------------------------------------------------
    # Ports from PassiveByteStreamDriverClient interface
    # ----------------------------------------------------------------------

    @ Port for sending data to UART driver
    output port toByteStreamDriver: Drv.ByteStreamSend

    @ Port for receiving data from UART driver
    sync input port fromByteStreamDriver: Drv.ByteStreamData

    @ Port for returning buffers to buffer manager after receiving
    output port fromByteStreamDriverReturn: Fw.BufferSend

    @ Port for receiving UART driver ready signal
    sync input port byteStreamDriverReady: Drv.ByteStreamReady

  }

}
