# This CMake file is intended to register project-wide objects.
# This allows for reuse between deployments, or other projects.

# Register project-level components
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Components")

# Register all deployments in the project
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Stm32LedBlinker/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Stm32LedBlinker/config/")
