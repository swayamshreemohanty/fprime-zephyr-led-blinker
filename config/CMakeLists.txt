####
# config/CMakeLists.txt:
register_fprime_config(
    CONFIGURATION_OVERRIDES
        "${CMAKE_CURRENT_LIST_DIR}/PlatformCfg.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/CdhCoreConfig.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/ComCcsdsConfig.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/ComFprimeConfig.fpp"
    INTERFACE
)