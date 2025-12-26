module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Defaults - Optimized for embedded STM32
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 5
    constant STACK_SIZE = 4 * 1024   # Reduced from 8KB to 4KB for embedded
  }

  # ----------------------------------------------------------------------
  # GenericHub Configuration for Spoke Node
  # ----------------------------------------------------------------------
  # STM32 is the SPOKE node - receives commands from RPi master
  # Events/telemetry route through hub to RPi, commands come from RPi
  #
  # CRITICAL PORT MAPPING (must match RPi's stm32Hub):
  # - InputPorts (STM32 → RPi): Sends command responses back to RPi
  # - OutputPorts (RPi → STM32): Receives commands from RPi
  # 
  # RPi's stm32Hub has:
  #   GenericHubInputPorts = 2 (receives FROM spoke)
  #   GenericHubOutputPorts = 2 (sends TO spoke)
  # So STM32's rpiHub must have MATCHING configuration:
  
  @ Number of typed serial input ports for hub (sending command responses TO RPi)
  constant GenericHubInputPorts = 2      # Port[0]: Ground, Port[1]: Sequencer
  
  @ Number of typed serial output ports for hub (receiving commands FROM RPi)
  constant GenericHubOutputPorts = 2     # Port[0]: Ground, Port[1]: Sequencer
  
  @ Number of buffer input ports for hub
  constant GenericHubInputBuffers = 1
  
  @ Number of buffer output ports for hub  
  constant GenericHubOutputBuffers = 1

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance chronoTime: Svc.ChronoTime base id 0x0F00

  instance rateGroup1: Svc.PassiveRateGroup base id 0x1000

  instance rateDriver: Zephyr.ZephyrRateDriver base id 0x1B00

  instance commDriver: Zephyr.ZephyrUartDriver base id 0x4000

  instance rateGroupDriver: Svc.RateGroupDriver base id 0x4500

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id 0x4C00

  instance gpioDriver1: Zephyr.ZephyrGpioDriver base id 0x4D00

  instance gpioDriver2: Zephyr.ZephyrGpioDriver base id 0x4E00

  # LED components with base ID >= 0x10000 (matches RPi GDS dictionary routing)
  instance led: Components.Stm32Led base id 0x10000

  instance led1: Components.Stm32Led base id 0x10100

  instance led2: Components.Stm32Led base id 0x10200

  # ----------------------------------------------------------------------
  # Active Components - Command Infrastructure (matching OBC B pattern)
  # ----------------------------------------------------------------------

  @ Command Dispatcher - Routes commands to components
  instance cmdDisp: Svc.CommandDispatcher base id 0x3000 \
    queue size 20 \
    stack size Default.STACK_SIZE \
    priority 101

  @ Proxy components for hub command forwarding (same as OBC B)
  instance proxyGroundInterface: Components.CmdSequenceForwarder base id 0x3100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  instance proxySequencer: Components.CmdSequenceForwarder base id 0x3200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  # ----------------------------------------------------------------------
  # Hub Pattern Components - Spoke Node (STM32) - Hub Native Topology
  # ----------------------------------------------------------------------
  # Unlike CdhCore approach, this is hub-native: events/telemetry go DIRECTLY to hub
  # No local event manager or telemetry channel - everything routes through RPi
  
  @ GenericHub - Routes events/telemetry TO RPi, receives commands FROM RPi
  instance rpiHub: Svc.GenericHub base id 0x5000

  @ ByteStreamBufferAdapter - Bridges byte stream (UART) to F-Prime buffers
  instance uartBufferAdapter: Drv.ByteStreamBufferAdapter base id 0x5100

  @ Buffer manager for hub communication buffers
  instance hubBufferManager: Svc.BufferManager base id 0x5400

  @ Text logger for LogText ports (matches RPi deployment pattern)
  instance textLogger: Svc.PassiveTextLogger base id 0x5500

}