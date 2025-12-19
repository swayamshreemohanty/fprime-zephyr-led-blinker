module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Base ID Convention
  # ----------------------------------------------------------------------
  #
  # All Base IDs follow the 8-digit hex format: 0xDSSCCxxx
  #
  # Where:
  #   D   = Deployment digit (2 for STM32 deployment)
  #   SS  = Subtopology digits (00 for main topology)
  #   CC  = Component digits (00, 01, 02, etc.)
  #   xxx = Reserved for internal component items (events, commands, telemetry)
  #

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 3
    constant STACK_SIZE = 4 * 1024
  }

  # ----------------------------------------------------------------------
  # Active component instances
  # ----------------------------------------------------------------------

  instance rateGroup1: Svc.ActiveRateGroup base id 0x20001000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance cmdDisp: Svc.CommandDispatcher base id 0x20002000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 101

  instance eventLogger: Svc.EventManager base id 0x20003000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  instance tlmSend: Svc.TlmChan base id 0x20004000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 97

  instance comQueue: Svc.ComQueue base id 0x20005000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 96

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance led: Components.Stm32Led base id 0x20006000
  
  instance led1: Components.Stm32Led base id 0x20006100
  
  instance led2: Components.Stm32Led base id 0x20006200

  instance timeHandler: Svc.OsTime base id 0x20010000

  instance rateGroupDriver: Svc.RateGroupDriver base id 0x20011000

  instance staticMemory: Svc.StaticMemory base id 0x20012000

  instance textLogger: Svc.PassiveTextLogger base id 0x20013000

  instance commDriver: Zephyr.ZephyrUartDriver base id 0x20014000

  instance comStub: Svc.ComStub base id 0x20015000

  instance fprimeRouter: Svc.FprimeRouter base id 0x20016000

  instance fatalAdapter: Svc.AssertFatalAdapter base id 0x20017000

  instance fatalHandler: Svc.FatalHandler base id 0x20018000

  instance systemResources: Svc.SystemResources base id 0x20019000

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id 0x2001A000
  
  instance gpioDriver1: Zephyr.ZephyrGpioDriver base id 0x2001A100
  
  instance gpioDriver2: Zephyr.ZephyrGpioDriver base id 0x2001A200

  instance rateDriver: Zephyr.ZephyrRateDriver base id 0x2001B000

}
