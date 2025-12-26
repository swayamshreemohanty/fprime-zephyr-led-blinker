####
# F prime CMakeLists.txt:
#
# SOURCE_FILES: combined list of source and autocoding files
# MOD_DEPS: (optional) module dependencies
####

set(SOURCE_FILES
  "${CMAKE_CURRENT_LIST_DIR}/instances.fpp"
  "${CMAKE_CURRENT_LIST_DIR}/Stm32LedBlinkerPackets.xml"
  "${CMAKE_CURRENT_LIST_DIR}/topology.fpp"
  "${CMAKE_CURRENT_LIST_DIR}/Stm32LedBlinkerTopology.cpp"
)
set(MOD_DEPS
  Fw/Logger
  # Hub-native spoke node components
  Drv/ByteStreamBufferAdapter
  Svc/GenericHub
  Svc/BufferManager
)

register_fprime_module()
