module Stm32LedBlinker {
  @ Null text logger that accepts but ignores text events
  @ Used when no real text logger is available
  passive component NullTextLogger {
    @ Text event input port - accepts and discards text events
    sync input port TextLogger: Fw.LogText
  }
}
