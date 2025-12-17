module LedBlinker {

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 3
    constant STACK_SIZE = 64 * 1024
  }
  
  # ----------------------------------------------------------------------
  # Command Splitter Offset for Remote Node
  # ----------------------------------------------------------------------
  # All STM32 component base IDs must be >= 0x10000 to route through RPi CmdSplitter
  # RPi master uses CmdSplitter with threshold 0x10000:
  #   - Commands with opcode < 0x10000 stay local on RPi
  #   - Commands with opcode >= 0x10000 forward to STM32 via GenericHub
  constant CMD_SPLITTER_OFFSET = 0x10000
  
  # ----------------------------------------------------------------------
  # GenericHub port array sizes
  # ----------------------------------------------------------------------
  
  @ Number of typed serial input ports for hub
  constant GenericHubInputPorts = 2
  
  @ Number of typed serial output ports for hub
  constant GenericHubOutputPorts = 2
  
  @ Number of buffer input ports for hub
  constant GenericHubInputBuffers = 1
  
  @ Number of buffer output ports for hub
  constant GenericHubOutputBuffers = 1

  # ----------------------------------------------------------------------
  # Active component instances
  # ----------------------------------------------------------------------

  instance cmdDisp: Svc.CommandDispatcher base id 0x0100 \
    queue size Default.QUEUE_SIZE\
    stack size Default.STACK_SIZE \
    priority 101

  instance eventLogger: Svc.ActiveLogger base id 0x0200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  instance tlmSend: Svc.TlmChan base id 0x0300 \
    queue size 15 \
    stack size Default.STACK_SIZE \
    priority 97

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance rateGroup1: Svc.PassiveRateGroup base id 0x1000

  instance rateDriver: Zephyr.ZephyrRateDriver base id 0x1100

  instance commDriver: Zephyr.ZephyrUartDriver base id 0x4000

  instance framer: Svc.Framer base id 0x4100

  instance deframer: Svc.Deframer base id 0x4800

  instance fatalAdapter: Svc.AssertFatalAdapter base id 0x4200

  instance fatalHandler: Svc.FatalHandler base id 0x4300

  instance timeHandler: Zephyr.ZephyrTime base id 0x4400 \

  instance rateGroupDriver: Svc.RateGroupDriver base id 0x4500

  instance staticMemory: Svc.StaticMemory base id 0x4600

  instance textLogger: Svc.PassiveTextLogger base id 0x4700

  instance systemResources: Svc.SystemResources base id 0x4900

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id 0x4C00

  instance gpioDriver1: Zephyr.ZephyrGpioDriver base id 0x4D00

  instance gpioDriver2: Zephyr.ZephyrGpioDriver base id 0x4E00

  # ----------------------------------------------------------------------
  # GenericHub for distributed communication with RPi master
  # ----------------------------------------------------------------------
  # NASA hub pattern for remote node communication
  # STM32 acts as remote node, RPi acts as master
  # Hub serializes typed ports over UART connection
  
  @ GenericHub - Bridges local components with remote RPi master
  @ Allows RPi to control STM32 LED and receive STM32 telemetry
  instance rpiHub: Svc.GenericHub base id 0x5000

  # ----------------------------------------------------------------------
  # LED Components (must be >= 0x10000 for RPi CmdSplitter routing)
  # ----------------------------------------------------------------------
  # These base IDs are >= 0x10000 so commands route through RPi's CmdSplitter
  
  instance led: Components.Stm32Led base id 0x10000

  instance led1: Components.Stm32Led base id 0x10100

  instance led2: Components.Stm32Led base id 0x10200

}
