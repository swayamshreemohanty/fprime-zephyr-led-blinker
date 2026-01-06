module Stm32LedBlinker {

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
    constant QUEUE_SIZE = 5
    constant STACK_SIZE = 64 * 1024   # Reduced from 8KB to 4KB for embedded
  }

  # ----------------------------------------------------------------------
  # GenericHub Configuration for Spoke Node
  # ----------------------------------------------------------------------
  # STM32 is the SPOKE node - receives commands from RPi master
  # Events/telemetry route through hub to RPi, commands come from RPi
  #
  # CRITICAL PORT MAPPING (must match RPi master expectations):
  # - serialIn ports: Receives command responses FROM local proxies TO send to RPi
  # - serialOut ports: Sends commands FROM RPi TO local proxies
  # 
  # Matches GitHub RemoteDeployment pattern but with current F´ API
  
  @ Number of typed serial input ports for hub (sending command responses TO RPi)
  constant GenericHubInputPorts = 2      # Port[0]: Ground, Port[1]: Sequencer
  
  @ Number of typed serial output ports for hub (receiving commands FROM RPi)
  constant GenericHubOutputPorts = 2     # Port[0]: Ground, Port[1]: Sequencer
  
  @ Number of buffer input ports for hub
  constant GenericHubInputBuffers = 1
  
  @ Number of buffer output ports for hub  
  constant GenericHubOutputBuffers = 1

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
  # Active Components - Command Infrastructure (Remote Node Pattern)
  # ----------------------------------------------------------------------

  @ Command Dispatcher - Routes commands from hub to local components
  instance cmdDisp: Svc.CommandDispatcher base id REMOTE_TOPOLOGY_BASE + 0x0500 \
    queue size 20 \
    stack size Default.STACK_SIZE \
    priority 101

  # ----------------------------------------------------------------------
  # Hub Pattern Components - Remote Spoke Node (STM32)
  # ----------------------------------------------------------------------
  # This is a SPOKE NODE using current F´ GenericHub pattern:
  # GenericHub ↔ ByteStreamBufferAdapter ↔ ZephyrUartDriver
  # Matches RPi master hub architecture but as remote node
  
  @ GenericHub - Routes events/telemetry TO RPi master, receives commands FROM RPi
  instance hub: Svc.GenericHub base id REMOTE_TOPOLOGY_BASE + 0x100000

  @ ByteStreamBufferAdapter - Bridges PassiveBufferDriver to ByteStreamDriver (UART)
  instance bufferAdapter: Drv.ByteStreamBufferAdapter base id REMOTE_TOPOLOGY_BASE + 0x100100

  @ Buffer manager for hub communication buffers
  instance bufferManager: Svc.BufferManager base id REMOTE_TOPOLOGY_BASE + 0x4400

  @ Event manager for local event handling
  instance eventLogger: Svc.EventManager base id REMOTE_TOPOLOGY_BASE + 0x4700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  @ Text logger for LogText ports
  instance textLogger: Svc.PassiveTextLogger base id REMOTE_TOPOLOGY_BASE + 0x4800

}