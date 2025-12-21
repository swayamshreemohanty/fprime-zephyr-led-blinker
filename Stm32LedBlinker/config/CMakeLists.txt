####
# Stm32LedBlinker/config/CMakeLists.txt:
#
# Configuration overrides for the deployment
####
register_fprime_config(
    CONFIGURATION_OVERRIDES
        "${CMAKE_CURRENT_LIST_DIR}/CdhCoreConfig.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/ComCcsdsConfig.fpp"
    INTERFACE
)
