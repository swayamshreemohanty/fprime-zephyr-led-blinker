module LedBlinker {

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 3
    constant STACK_SIZE = 64 * 1024
  }

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance chronoTime: Svc.ChronoTime base id 0x4500

  instance rateGroup1: Svc.PassiveRateGroup base id 0x1000

  instance rateDriver: Zephyr.ZephyrRateDriver base id 0x4100

  instance uartDriver: Zephyr.ZephyrUartDriver base id 0x4000

  instance rateGroupDriver: Svc.RateGroupDriver base id 0x4600

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id 0x4C00

  # LED components
  instance led: Components.Stm32Led base id 0x5000

  # ----------------------------------------------------------------------
  # Active Components
  # ----------------------------------------------------------------------

  @ Command Dispatcher - Routes commands to local components
  instance cmdDisp: Svc.CommandDispatcher base id 0x0500 \
    queue size 20 \
    stack size Default.STACK_SIZE \
    priority 101

  # ----------------------------------------------------------------------
  # Communication Stack
  # ----------------------------------------------------------------------

  @ Framer - Frames data into F Prime packets for downlink
  instance framer: Svc.FprimeFramer base id 0x100100

  @ Deframer - Deframes incoming packets for uplink
  instance deframer: Svc.FprimeDeframer base id 0x100200

  @ Accumulates incoming UART bytes into complete frames
  instance frameAccumulator: Svc.FrameAccumulator base id 0x100280

  @ F Prime Router - Routes incoming packets to their destination
  instance fprimeRouter: Svc.FprimeRouter base id 0x100300

  @ Communications adapter between Framer/Deframer and UART driver
  instance comStub: Svc.ComStub base id 0x100380

  @ Telemetry/Event Packet Queue
  instance tlmSend: Svc.ComQueue base id 0x4800 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 96

  @ Buffer manager for communication buffers
  instance commsBufferManager: Svc.BufferManager base id 0x4400

  @ Telemetry database
  instance tlmChan: Svc.TlmChan base id 0x4700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 90

  @ Active event logger
  instance eventLogger: Svc.EventManager base id 0x4900 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 95

  @ Text logger for LogText ports
  instance textLogger: Svc.PassiveTextLogger base id 0x4A00

}