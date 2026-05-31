module LedBlinker {

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 10
    constant STACK_SIZE = 4 * 1024
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

}