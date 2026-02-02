module LedBlinker {

  # ----------------------------------------------------------------------
  # Remote Node Base ID Offset
  # ----------------------------------------------------------------------
  # All STM32 components use this base offset to avoid ID conflicts with RPi master
  # This matches the pattern from fprime-generichub-reference RemoteDeployment
  constant REMOTE_TOPOLOGY_BASE = 0x10000000

  # ----------------------------------------------------------------------
  # Defaults - Optimized for embedded STM32
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 10
    constant STACK_SIZE = 64 * 1024   # 64KB per active component (matches fprime-generichub-reference)
  }

  # ----------------------------------------------------------------------
  # Passive component instances - Remote Node Pattern
  # ----------------------------------------------------------------------
  # Using REMOTE_TOPOLOGY_BASE offset to avoid conflicts with RPi master

  instance chronoTime: Svc.ChronoTime base id REMOTE_TOPOLOGY_BASE + 0x4500

  instance rateGroup1: Svc.PassiveRateGroup base id REMOTE_TOPOLOGY_BASE + 0x1000

  instance rateDriver: Zephyr.ZephyrRateDriver base id REMOTE_TOPOLOGY_BASE + 0x4100

  instance uartDriver: Zephyr.ZephyrUartDriver base id REMOTE_TOPOLOGY_BASE + 0x4000

  instance rateGroupDriver: Svc.RateGroupDriver base id REMOTE_TOPOLOGY_BASE + 0x4600

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id REMOTE_TOPOLOGY_BASE + 0x4C00

  instance gpioDriver1: Zephyr.ZephyrGpioDriver base id REMOTE_TOPOLOGY_BASE + 0x4D00

  instance gpioDriver2: Zephyr.ZephyrGpioDriver base id REMOTE_TOPOLOGY_BASE + 0x4E00

  # LED components - Remote node application components
  instance led: Components.Stm32Led base id REMOTE_TOPOLOGY_BASE + 0x5000

  instance led1: Components.Stm32Led base id REMOTE_TOPOLOGY_BASE + 0x5100

  instance led2: Components.Stm32Led base id REMOTE_TOPOLOGY_BASE + 0x5200

  # ----------------------------------------------------------------------
  # Active Components - Command Infrastructure
  # ----------------------------------------------------------------------

  @ Command Dispatcher - Routes commands to local components
  instance cmdDisp: Svc.CommandDispatcher base id REMOTE_TOPOLOGY_BASE + 0x0500 \
    queue size 20 \
    stack size Default.STACK_SIZE \
    priority 101

  # ----------------------------------------------------------------------
  # Communication Stack - Direct GDS via UART (Framer/Deframer Pattern)
  # ----------------------------------------------------------------------
  
  @ ComQueue - Queues events and telemetry for framing
  instance comQueue: Svc.ComQueue base id REMOTE_TOPOLOGY_BASE + 0x100000 \
    queue size 50 \
    stack size Default.STACK_SIZE \
    priority 100

  @ Framer - Frames data into F Prime packets for downlink
  instance framer: Svc.FprimeFramer base id REMOTE_TOPOLOGY_BASE + 0x100100

  @ Deframer - Deframes incoming packets for uplink
  instance deframer: Svc.FprimeDeframer base id REMOTE_TOPOLOGY_BASE + 0x100200

  @ FrameAccumulator - Accumulates bytes from UART until complete frame
  instance frameAccumulator: Svc.FrameAccumulator base id REMOTE_TOPOLOGY_BASE + 0x100300

  @ FprimeRouter - Routes deframed packets to command dispatcher
  instance fprimeRouter: Svc.FprimeRouter base id REMOTE_TOPOLOGY_BASE + 0x100400

  @ Buffer manager for communication buffers
  instance commsBufferManager: Svc.BufferManager base id REMOTE_TOPOLOGY_BASE + 0x4400

  @ Telemetry database
  instance tlmChan: Svc.TlmChan base id REMOTE_TOPOLOGY_BASE + 0x4700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 90

  @ Active event logger
  instance eventLogger: Svc.ActiveLogger base id REMOTE_TOPOLOGY_BASE + 0x4800 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 95

  @ Text logger for LogText ports
  instance textLogger: Svc.PassiveTextLogger base id REMOTE_TOPOLOGY_BASE + 0x4900

}