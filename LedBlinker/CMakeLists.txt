#####
# 'LedBlinker' Deployment:
#
# This registers the 'LedBlinker' deployment to the build system. 
# Custom components that have not been added at the project-level should be added to 
# the list below.
#
#####

# Deployment is only compatible with the Zephyr platform
restrict_platforms(Zephyr)

###
# Topology and Components
###
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Top/")

# Add custom components to this specific deployment here
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MyComponent/")

# Trim TlmChan telemetry table size for this small deployment
if (TARGET Svc_TlmChan)
    target_compile_definitions(Svc_TlmChan PUBLIC
        TLMCHAN_HASH_BUCKETS_VALUE=64
        TLMCHAN_NUM_TLM_HASH_SLOTS_VALUE=8
        TLMCHAN_HASH_MOD_VALUE_VALUE=97
    )
endif()

register_fprime_zephyr_deployment(
        ${FPRIME_CURRENT_MODULE}
    SOURCES
        "${CMAKE_CURRENT_LIST_DIR}/Main.cpp"
    DEPENDS
        LedBlinker_Top
)

