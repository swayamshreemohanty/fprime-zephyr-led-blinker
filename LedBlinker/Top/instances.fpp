module LedBlinker {

  # ----------------------------------------------------------------------
  # Command Splitter Offset for RPi Integration
  # ----------------------------------------------------------------------
  # This offset MUST match RPi's CMD_SPLITTER_OFFSET (0x10000)
  # RPi CommandSplitter routes commands >= 0x10000 to STM32
  # All STM32 component base IDs use this offset
  constant RPi_CMD_OFFSET = 0x10000

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 3
    constant STACK_SIZE = 64 * 1024
  }

  # ----------------------------------------------------------------------
  # Active component instances
  # ----------------------------------------------------------------------

  instance cmdDisp: Svc.CommandDispatcher base id RPi_CMD_OFFSET + 0x0100 \
    queue size Default.QUEUE_SIZE\
    stack size Default.STACK_SIZE \
    priority 101

  instance eventLogger: Svc.ActiveLogger base id RPi_CMD_OFFSET + 0x0200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  instance tlmSend: Svc.TlmChan base id RPi_CMD_OFFSET + 0x0300 \
    queue size 15 \
    stack size Default.STACK_SIZE \
    priority 97

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance rateGroup1: Svc.PassiveRateGroup base id RPi_CMD_OFFSET + 0x1000

  instance rateDriver: Zephyr.ZephyrRateDriver base id RPi_CMD_OFFSET + 0x1100

  instance commDriver: Zephyr.ZephyrUartDriver base id RPi_CMD_OFFSET + 0x4000

  instance framer: Svc.Framer base id RPi_CMD_OFFSET + 0x4100

  instance fatalAdapter: Svc.AssertFatalAdapter base id RPi_CMD_OFFSET + 0x4200

  instance fatalHandler: Svc.FatalHandler base id RPi_CMD_OFFSET + 0x4300

  instance timeHandler: Zephyr.ZephyrTime base id RPi_CMD_OFFSET + 0x4400 \

  instance rateGroupDriver: Svc.RateGroupDriver base id RPi_CMD_OFFSET + 0x4500

  instance staticMemory: Svc.StaticMemory base id RPi_CMD_OFFSET + 0x4600

  instance textLogger: Svc.PassiveTextLogger base id RPi_CMD_OFFSET + 0x4700

  instance deframer: Svc.Deframer base id RPi_CMD_OFFSET + 0x4800

  instance systemResources: Svc.SystemResources base id RPi_CMD_OFFSET + 0x4900

  instance gpioDriver: Zephyr.ZephyrGpioDriver base id RPi_CMD_OFFSET + 0x4C00

  instance led: Components.Led base id RPi_CMD_OFFSET + 0x10000

  instance gpioDriver1: Zephyr.ZephyrGpioDriver base id RPi_CMD_OFFSET + 0x4D00

  instance gpioDriver2: Zephyr.ZephyrGpioDriver base id RPi_CMD_OFFSET + 0x4E00

  instance led1: Components.Led base id RPi_CMD_OFFSET + 0x10100

  instance led2: Components.Led base id RPi_CMD_OFFSET + 0x10200


}
