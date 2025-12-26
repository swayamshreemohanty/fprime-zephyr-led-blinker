module Drv {
  @ UART driver for Zephyr with work queue support for F´ hub pattern
  @ This version defers ISR processing to task context to avoid mutex issues
  passive component ZephyrUartDriverFixed {

    # ----------------------------------------------------------------------
    # General ports
    # ----------------------------------------------------------------------

    @ Port to send data
    guarded input port $send: Drv.ByteStreamSend

    @ Port to receive data
    output port $recv: Drv.ByteStreamRecv

    @ Port for buffer allocation
    output port allocate: Fw.BufferGet

    @ Port for buffer deallocation  
    output port deallocate: Fw.BufferSend

    @ Port to indicate ready status
    output port ready: Drv.ByteStreamReady

    @ Scheduler port for polling receive data
    async input port schedIn: Svc.Sched

    # ----------------------------------------------------------------------
    # Special ports
    # ----------------------------------------------------------------------

    @ Command receive
    command recv port cmdIn

    @ Command registration
    command reg port cmdRegOut

    @ Command response
    command resp port cmdResponseOut

    @ Event
    event port eventOut

    @ Telemetry
    telemetry port tlmOut

    @ Text event
    text event port textEventOut

    @ Time get
    time get port timeGetOut

    # ----------------------------------------------------------------------
    # Commands
    # ----------------------------------------------------------------------

    @ Open UART device
    async command UART_OPEN(
      device: string size 80 @< Device path
      baud: U32 @< Baud rate
    )

    # ----------------------------------------------------------------------
    # Events
    # ----------------------------------------------------------------------

    event UART_OPEN_SUCCESS(
      device: string size 80 @< Device path
    ) \
      severity activity high \
      format "UART {} opened successfully"

    event UART_OPEN_ERROR(
      device: string size 80 @< Device path
      error: I32 @< Error code
    ) \
      severity warning high \
      format "UART {} open failed with error {}"

    event UART_WRITE_ERROR(
      error: I32 @< Error code
    ) \
      severity warning high \
      format "UART write failed with error {}"

    event UART_READ_ERROR(
      error: I32 @< Error code
    ) \
      severity warning high \
      format "UART read failed with error {}"

    # ----------------------------------------------------------------------
    # Telemetry
    # ----------------------------------------------------------------------

    telemetry BytesSent: U32
    telemetry BytesRecv: U32

  }
}
