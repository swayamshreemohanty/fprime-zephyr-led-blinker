module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 3
    constant STACK_SIZE = 32 * 1024
  }

  # ----------------------------------------------------------------------
  # Active component instances
  # ----------------------------------------------------------------------

  instance cmdDisp: Svc.CommandDispatcher base id 0x0100 \
    queue size Default.QUEUE_SIZE\
    stack size Default.STACK_SIZE \
    priority 101

  instance eventLogger: Svc.EventManager base id 0x0200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  instance tlmSend: Svc.TlmChan base id 0x0300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 97

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance rateGroup1: Svc.PassiveRateGroup base id 0x1000

  instance rateDriver: Zephyr.ZephyrRateDriver base id 0x1100

  instance commDriver: Zephyr.ZephyrUartDriver base id 0x4000

  instance framer: Svc.FprimeFramer base id 0x4100

  instance fatalAdapter: Svc.AssertFatalAdapter base id 0x4200

  instance fatalHandler: Svc.FatalHandler base id 0x4300

  instance timeHandler: Svc.OsTime base id 0x4400

  instance rateGroupDriver: Svc.RateGroupDriver base id 0x4500

  instance staticMemory: Svc.StaticMemory base id 0x4600

  instance textLogger: Svc.PassiveTextLogger base id 0x4700

  instance deframer: Svc.FprimeDeframer base id 0x4800

  instance systemResources: Svc.SystemResources base id 0x4900

  instance comQueue: Svc.ComQueue base id 0x4A00 \
    queue size Default.QUEUE_SIZE\
    stack size Default.STACK_SIZE \
    priority 100

  instance comStub: Svc.ComStub base id 0x4B00

  instance fprimeRouter: Svc.FprimeRouter base id 0x5000

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id 0x4C00

  instance gpioDriver1: Zephyr.ZephyrGpioDriver base id 0x4D00

  instance gpioDriver2: Zephyr.ZephyrGpioDriver base id 0x4E00

  instance led: Components.Stm32Led base id 0x10000

  instance led1: Components.Stm32Led base id 0x10100

  instance led2: Components.Stm32Led base id 0x10200

}
