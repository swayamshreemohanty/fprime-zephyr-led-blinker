####
# Project-level configuration overrides for Zephyr handle sizes
####

register_fprime_config(
    CONFIGURATION_OVERRIDES
        "${CMAKE_CURRENT_LIST_DIR}/PlatformCfg.fpp"
    INTERFACE # No buildable files - config only
)
