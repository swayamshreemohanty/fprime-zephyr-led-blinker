####
# This sets up the build system for the 'fprime-zephyr-led-blinker' project, including
# components and deployments from project.cmake. In addition, it imports the core F Prime components.
####

cmake_minimum_required(VERSION 3.13)
cmake_policy(SET CMP0048 NEW)

# Allow Kconfig warnings in Zephyr 4.3.0
set(KCONFIG_STRICT FALSE CACHE BOOL "Treat Kconfig warnings as errors" FORCE)
# Do not fail the configure step on Kconfig warnings (some upstream modules emit benign warnings)
set(KCONFIG_WARNINGS_AS_ERRORS OFF CACHE BOOL "Stop treating Kconfig warnings as fatal" FORCE)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
set(CMAKE_SYSTEM_NAME "Zephyr")

project(fprime-zephyr-led-blinker C CXX)

# Workaround: Add CMSIS includes for Zephyr's internal headers
# These paths are needed because Zephyr 4.3.0 doesn't automatically add them
# when building outside a west workspace
zephyr_include_directories_ifdef(CONFIG_CPU_CORTEX_M "$ENV{ZEPHYR_BASE}/modules/cmsis_6")
zephyr_include_directories_ifdef(CONFIG_CPU_CORTEX_M "$ENV{ZEPHYR_BASE}/../modules/cmsis/CMSIS/Core/Include")

###
# F' Core Setup
# This includes all of the F prime core components, and imports the make-system.
###
# set(FPRIME_SKIP_TOOLS_VERSION_CHECK ON)
# set(FPRIME_FRAMEWORK_PATH "${CMAKE_CURRENT_LIST_DIR}/fprime" CACHE PATH "Location of F prime framework" FORCE)
# set(FPRIME_PROJECT_ROOT "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "Root path of F prime project" FORCE)

# Force use of Zephyr OS implementations instead of stubs
set(FPRIME_USE_BAREMETAL_SCHEDULER OFF CACHE BOOL "Use baremetal scheduler" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/fprime/cmake/FPrime.cmake")
# NOTE: register custom targets between these two lines
include("${FPRIME_FRAMEWORK_PATH}/cmake/FPrime-Code.cmake")


# This includes project-wide objects
include("${CMAKE_CURRENT_LIST_DIR}/project.cmake")
