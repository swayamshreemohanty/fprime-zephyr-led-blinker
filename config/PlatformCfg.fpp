####
# PlatformCfg.fpp:
#
# Platform-specific configuration overrides for Zephyr.
# These override the default values in F-Prime/default/config/PlatformCfg.fpp
####

@ Zephyr console handle size
constant FW_CONSOLE_HANDLE_MAX_SIZE = 24

@ Zephyr task handle requires 264 bytes minimum (ZephyrTask structure size)
@ Setting to 300 for safety margin
constant FW_TASK_HANDLE_MAX_SIZE = 300

@ Zephyr file handle size (Posix file descriptor)
constant FW_FILE_HANDLE_MAX_SIZE = 16

@ Zephyr mutex handle size
constant FW_MUTEX_HANDLE_MAX_SIZE = 72

@ Zephyr queue handle size (uses k_msgq)
constant FW_QUEUE_HANDLE_MAX_SIZE = 368

@ Zephyr directory handle size
constant FW_DIRECTORY_HANDLE_MAX_SIZE = 16

@ Zephyr filesystem handle size
constant FW_FILESYSTEM_HANDLE_MAX_SIZE = 16

@ Zephyr raw time handle size
constant FW_RAW_TIME_HANDLE_MAX_SIZE = 56

@ Maximum allowed serialization size for Os::RawTime objects
constant FW_RAW_TIME_SERIALIZATION_MAX_SIZE = 8

@ Zephyr condition variable handle size
constant FW_CONDITION_VARIABLE_HANDLE_MAX_SIZE = 56

@ Zephyr CPU handle size (stub)
constant FW_CPU_HANDLE_MAX_SIZE = 16

@ Zephyr memory handle size (stub)
constant FW_MEMORY_HANDLE_MAX_SIZE = 16

@ Handle alignment for Zephyr
constant FW_HANDLE_ALIGNMENT = 8

@ Zephyr semaphore handle size  
constant FW_SEMAPHORE_HANDLE_MAX_SIZE = 48

@ Chunk size for working with files in the OSAL layer
constant FW_FILE_CHUNK_SIZE = 512
