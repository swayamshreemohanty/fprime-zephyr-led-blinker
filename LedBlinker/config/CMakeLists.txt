####
# LedBlinker/config/CMakeLists.txt:
#
# Configuration overrides for hub-native spoke node deployment
# No CdhCore subtopology - using GenericHub pattern for direct event/telemetry routing
####
register_fprime_config(
    CONFIGURATION_OVERRIDES
        "${CMAKE_CURRENT_LIST_DIR}/PlatformCfg.fpp"
    INTERFACE
)
