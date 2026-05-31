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
  Svc/Subtopologies/CdhCore
  Svc/Subtopologies/ComCcsds
  Svc/ChronoTime
  Svc/PassiveRateGroup
  Svc/PassiveConsoleTextLogger
  Svc/RateGroupDriver
  Components/Led
  fprime-zephyr/Drv/ZephyrGpioDriver
  fprime-zephyr/Drv/ZephyrRateDriver
  fprime-zephyr/Drv/ZephyrUartDriver
)

register_fprime_module()
