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
  # StaticMemory buffer allocation indices
  # ----------------------------------------------------------------------
  
  @ StaticMemory buffer indices for different clients
  @ Each client needs a unique parallel port index for allocate/deallocate pair
  enum Ports_StaticMemory {
    framerBuffers
    deframerBuffers
    commDriverBuffers
  }

  # ----------------------------------------------------------------------
  # Active component instances
  # ----------------------------------------------------------------------
  # All base IDs use CMD_SPLITTER_OFFSET to ensure routing from RPi master

  instance cmdDisp: Svc.CommandDispatcher base id 0x10100 \
    queue size Default.QUEUE_SIZE\
    stack size Default.STACK_SIZE \
    priority 101

  instance eventLogger: Svc.ActiveLogger base id 0x10200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  instance tlmSend: Svc.TlmChan base id 0x10300 \
    queue size 15 \
    stack size Default.STACK_SIZE \
    priority 97

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------
  # All base IDs use CMD_SPLITTER_OFFSET to ensure routing from RPi master

  instance rateGroup1: Svc.PassiveRateGroup base id 0x11000

  instance rateDriver: Zephyr.ZephyrRateDriver base id 0x11100

  instance commDriver: Zephyr.ZephyrUartDriver base id 0x14000

  instance framer: Svc.Framer base id 0x14100

  instance deframer: Svc.Deframer base id 0x14800

  instance fatalAdapter: Svc.AssertFatalAdapter base id 0x14200

  instance fatalHandler: Svc.FatalHandler base id 0x14300

  instance timeHandler: Zephyr.ZephyrTime base id 0x14400 \

  instance rateGroupDriver: Svc.RateGroupDriver base id 0x14500

  instance staticMemory: Svc.StaticMemory base id 0x14600

  instance textLogger: Svc.PassiveTextLogger base id 0x14700

  instance systemResources: Svc.SystemResources base id 0x14900

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id 0x14C00

  instance gpioDriver1: Zephyr.ZephyrGpioDriver base id 0x14D00

  instance gpioDriver2: Zephyr.ZephyrGpioDriver base id 0x14E00

  instance led: Components.Led base id 0x10000

  instance led1: Components.Led base id 0x10100

  instance led2: Components.Led base id 0x10200

  # ----------------------------------------------------------------------
  # GenericHub for distributed communication with RPi master
  # ----------------------------------------------------------------------
  # NASA hub pattern for remote node communication
  # STM32 acts as remote node, RPi acts as master
  # Hub serializes typed ports over UART connection
  
  @ GenericHub - Bridges local components with remote RPi master
  @ Allows RPi to control STM32 LED and receive STM32 telemetry
  instance rpiHub: Svc.GenericHub base id 0x15000

}
