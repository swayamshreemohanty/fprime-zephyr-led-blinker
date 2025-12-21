module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 10
    constant STACK_SIZE = 8 * 1024 
  }

  # ----------------------------------------------------------------------
  # GenericHub port array sizes (matches RPi deployment)
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

  instance led: Components.Stm32Led base id 0x10000

  instance led1: Components.Stm32Led base id 0x10100

  instance led2: Components.Stm32Led base id 0x10200

  # ----------------------------------------------------------------------
  # Distributed Communication with RPi Master (NASA Hub Pattern)
  # ----------------------------------------------------------------------
  # STM32 acts as remote node controlled by RPi master via UART
  # Uses GenericHub pattern for distributed F-Prime deployments

  @ ByteStream buffer adapter - bridges ByteStreamDriver to PassiveBufferDriver
  @ Converts byte streams to/from F-Prime buffer objects for UART communication
  instance uartBufferAdapter: Drv.ByteStreamBufferAdapter base id 0x5000

  @ Generic Hub - NASA's official distributed communication pattern
  @ Deserializes commands from RPi and serializes telemetry/events to RPi
  @ Allows RPi master to control STM32 as if components were local
  instance rpiHub: Svc.GenericHub base id 0x5100

  @ Command Splitter - Routes command responses back to RPi
  @ On STM32 side, mainly used for command response routing
  instance cmdSplitter: Svc.CmdSplitter base id 0x5200

}
