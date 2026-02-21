####
# F prime CMakeLists.txt:
#
# SOURCE_FILES: combined list of source and autocoding files
# MOD_DEPS: (optional) module dependencies
####

set(SOURCE_FILES
  "${CMAKE_CURRENT_LIST_DIR}/instances.fpp"
  "${CMAKE_CURRENT_LIST_DIR}/LedBlinkerPackets.xml"
  "${CMAKE_CURRENT_LIST_DIR}/topology.fpp"
  "${CMAKE_CURRENT_LIST_DIR}/LedBlinkerTopology.cpp"
)
set(MOD_DEPS
  Fw/Logger
  Svc/EventManager
  Svc/BufferManager
  Svc/ChronoTime
  Svc/CmdDispatcher
  Svc/ComQueue
  Svc/ComStub
  Svc/FrameAccumulator
  Svc/FprimeDeframer
  Svc/FprimeFramer
  Svc/FprimeRouter
  Svc/PassiveRateGroup
  Svc/PassiveConsoleTextLogger
  Svc/RateGroupDriver
  Svc/TlmChan
  Components/Stm32Led
  fprime-zephyr/Drv/ZephyrGpioDriver
  fprime-zephyr/Drv/ZephyrRateDriver
  fprime-zephyr/Drv/ZephyrUartDriver
)

register_fprime_module()
