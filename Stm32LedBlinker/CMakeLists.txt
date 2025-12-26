#####
# 'Stm32LedBlinker' Deployment:
#
# This registers the 'Stm32LedBlinker' deployment to the build system. 
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
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/NullTextLogger/")


set(SOURCE_FILES 
    "${CMAKE_CURRENT_LIST_DIR}/Stub.cpp"
)
set(MOD_DEPS ${FPRIME_CURRENT_MODULE}/Top app)

# Trim TlmChan telemetry table size for this small deployment
if (TARGET Svc_TlmChan)
    target_compile_definitions(Svc_TlmChan PUBLIC
        TLMCHAN_HASH_BUCKETS_VALUE=64
        TLMCHAN_NUM_TLM_HASH_SLOTS_VALUE=8
        TLMCHAN_HASH_MOD_VALUE_VALUE=97
    )
endif()

register_fprime_zephyr_deployment()

FILE(GLOB app_sources Main.cpp)
target_sources(app PRIVATE 
    ${app_sources}
)
target_link_libraries(app PRIVATE 
    Stm32LedBlinker_Top
    Os_Task_Zephyr
    Os_Mutex_Zephyr
    Os_RawTime_Zephyr
    Os_Console_Zephyr
    Os_File_Zephyr_Posix
    Os_StringFormat_Zephyr_snprintk
    Os_Queue_Stub_Implementation
    Os_Cpu_Stub_Implementation
    Os_Memory_Stub_Implementation
)
