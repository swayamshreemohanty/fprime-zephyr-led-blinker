####
# Stm32LedBlinker/config/CMakeLists.txt:
#
# Configuration overrides for the deployment
# NOTE: ComCcsdsConfig removed - using hub pattern instead of ComCcsds subtopology
####
register_fprime_config(
    CONFIGURATION_OVERRIDES
        "${CMAKE_CURRENT_LIST_DIR}/CdhCoreConfig.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/PlatformCfg.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/GenericHubCfg.fpp"
    INTERFACE
)
