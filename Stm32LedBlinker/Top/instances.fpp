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
  # All events/telemetry route THROUGH the hub to RPi
  
  @ Number of typed serial input ports for hub (receiving from local components)
  constant GenericHubInputPorts = 2
  
  @ Number of typed serial output ports for hub (sending to local cmdDisp)
  constant GenericHubOutputPorts = 2
  
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

  # LED components with base ID >= 0x10000 (remote commands from RPi)
  instance led: Components.Stm32Led base id 0x10000

  instance led1: Components.Stm32Led base id 0x10100

  instance led2: Components.Stm32Led base id 0x10200

  # ----------------------------------------------------------------------
  # Hub Pattern Components - Spoke Node (STM32)
  # ----------------------------------------------------------------------
  # STM32 receives commands from RPi master hub and sends telemetry/events back
  # Uses simplified architecture: GenericHub <-> ByteStreamBufferAdapter <-> UartDriver
  # No proxy components needed - GenericHub.serialOut connects directly to cmdDisp
  
  @ GenericHub - Receives serialized commands from RPi, sends telemetry/events to RPi
  instance rpiHub: Svc.GenericHub base id 0x5000

  @ ByteStreamBufferAdapter - Bridges byte stream (UART) to F-Prime buffers
  instance uartBufferAdapter: Drv.ByteStreamBufferAdapter base id 0x5100

  @ Buffer manager for hub communication buffers
  instance hubBufferManager: Svc.BufferManager base id 0x5400

}