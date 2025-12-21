# F' Zephyr LED Blinker - Complete Build Guide for STM32 Nucleo H7A3ZI-Q

This guide documents the complete end-to-end process for building and deploying the F' (F Prime) LED Blinker application on the STM32 Nucleo H7A3ZI-Q board using Zephyr RTOS on a Raspberry Pi (ARM64).

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Dependency Installation](#dependency-installation)
4. [Zephyr RTOS Setup](#zephyr-rtos-setup)
5. [Code Fixes Required](#code-fixes-required)
6. [Board Configuration](#board-configuration)
7. [Building the Firmware](#building-the-firmware)
8. [Flashing to Board](#flashing-to-board)
9. [Running F' GDS](#running-f-gds)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware
- **Target Board**: STM32 Nucleo H7A3ZI-Q
- **Development Platform**: Raspberry Pi 5 (ARM64) or similar ARM64 Linux system
- **Connection**: USB cable for ST-Link programming and serial communication

### Software Requirements
- **OS**: Debian Trixie (or compatible Linux distribution)
- **Python**: 3.13.5 (or 3.11+)
- **CMake**: 3.26.0+
- **Git**: For cloning repositories
- **st-flash**: For programming STM32 boards

---

## Project Setup

### 1. Clone the Repository

```bash
cd ~/work/practice/fprime
git clone --recurse-submodules https://github.com/fprime-community/fprime-zephyr-led-blinker.git
cd fprime-zephyr-led-blinker
```

### 2. Initialize Git Submodules

The project uses two git submodules: `fprime` and `fprime-zephyr`.

```bash
git submodule update --init --recursive
```

### 3. Checkout Correct F' Version

The fprime-zephyr integration requires F' v4.1.1:

```bash
cd fprime
git checkout v4.1.1
cd ..
```

---

## Dependency Installation

### 1. Create Python Virtual Environment

```bash
cd ~/work/practice/fprime/fprime-zephyr-led-blinker
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install F' Python Requirements

Due to Python 3.13 compatibility issues with the pinned versions in `fprime/requirements.txt`, install newer compatible versions first:

```bash
# Install Python 3.13 compatibility packages
pip install legacy-cgi  # Provides cgi module for Cheetah3 on Python 3.13

# Install Python 3.13-compatible versions of lxml and pyzmq
pip install lxml==5.3.0 pyzmq==26.2.0

# Install remaining F' requirements (skip lxml and pyzmq since they're already installed)
grep -v "^lxml" fprime/requirements.txt | grep -v "^pyzmq" | pip install -r /dev/stdin

# Install additional system dependencies
sudo apt-get install -y gperf  # Required by Zephyr for perfect hash function generation
```

**Python 3.13 Compatibility Issues:**

The fprime build encountered several Python 3.13 specific errors that required workarounds:

1. **`lxml==4.9.3` Build Failure**
   - **Error**: `too few arguments to function '_PyLong_AsByteArray'`
   - **Cause**: Python 3.13 changed the C API for `_PyLong_AsByteArray()`, adding a new parameter. The old lxml version (4.9.3) uses the old API signature.
   - **Solution**: Upgrade to `lxml==5.3.0` which supports Python 3.13's new C API.

2. **`Cheetah3` Missing `cgi` Module**
   - **Error**: `ModuleNotFoundError: No module named 'cgi'`
   - **Cause**: Python 3.13 removed the deprecated `cgi` module. F-Prime's Cheetah3 template engine (`v3.2.6.post1`) still depends on it.
   - **Solution**: Install `legacy-cgi` package which provides a backport of the removed `cgi` module.

3. **`typing_extensions` TypeVar Incompatibility**
   - **Error**: `AttributeError: attribute '__default__' of 'typing.TypeVar' objects is not writable`
   - **Cause**: Python 3.13 changed how TypeVar defaults work, breaking older versions of `typing_extensions` used by `jsonschema` dependencies.
   - **Solution**: The `pip install` command automatically upgrades to compatible versions.

4. **Missing `gperf` Tool**
   - **Error**: `GPERF-NOTFOUND`
   - **Cause**: Zephyr RTOS uses `gperf` (GNU Perfect Hash Function Generator) to create perfect hash functions for kernel object lookups. It's not installed by default on Debian.
   - **Solution**: Install with `sudo apt-get install -y gperf`.

**Note**: The `fprime/requirements.txt` specifies `lxml==4.9.3` and `pyzmq==25.1.1`, which cannot be built with Python 3.13 due to C API changes. The newer versions (5.3.0 and 26.2.0) are fully compatible and have pre-built wheels for ARM64.

---

## Zephyr RTOS Setup

### Overview

This project uses a **local west workspace** to manage Zephyr RTOS v4.3.0 and its dependencies. Unlike external Zephyr installations, the west workspace is self-contained within the project directory.

### 1. Install System Dependencies

```bash
sudo apt-get update
sudo apt-get install -y gperf python3-dev
```

**Required packages:**
- `gperf` - GNU Perfect Hash Function Generator (required by Zephyr for kernel object hash generation)
- `python3-dev` - Python development headers (for building native extensions)

### 2. Install West and Python Dependencies

```bash
cd ~/work/practice/fprime/fprime-zephyr-led-blinker
source .venv/bin/activate

# Install west (Zephyr meta-tool)
pip install west

# Install Zephyr Python requirements
pip install jsonschema pyelftools
```

### 3. Initialize West Workspace

The project includes a `west.yml` manifest that specifies Zephyr v4.3.0 and required modules.

```bash
# Initialize west workspace using the local manifest
west init -l .
```

This command tells west to use the current directory as the manifest repository.

### 4. Update Zephyr and Dependencies

```bash
# Download Zephyr and all required modules
west update
```

**What this does:**
- Downloads Zephyr v4.3.0 into `zephyr/` directory
- Downloads required modules (HAL drivers, CMSIS, etc.) into `modules/` directory
- Takes ~10-20 minutes and requires ~2GB of disk space

**Required modules automatically downloaded:**
- `hal_stm32` - STM32 Hardware Abstraction Layer
- `cmsis` - ARM Cortex Microcontroller Software Interface Standard
- Many other modules specified by Zephyr's import manifest

### 5. Install Zephyr SDK 0.17.0 (Optional but Recommended)

The Zephyr SDK provides optimized cross-compilation toolchains, debuggers, and tools. While CMake can use system gcc as fallback, the SDK provides:
- Better optimization and smaller binaries
- Consistent build results across platforms
- GDB debugger with Zephyr awareness
- Additional tools (QEMU, OpenOCD integration)

**For ARM64 platforms (Raspberry Pi):**

```bash
cd ~

# Download Zephyr SDK 0.17.0 for ARM64
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_linux-aarch64.tar.xz

# Verify download (optional)
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/sha256.sum
sha256sum --ignore-missing -c sha256.sum

# Extract SDK
tar xf zephyr-sdk-0.17.0_linux-aarch64.tar.xz

# Run setup script (install only ARM toolchain for this project)
cd zephyr-sdk-0.17.0
./setup.sh -t arm-zephyr-eabi
```

**For x86_64 platforms:**

```bash
cd ~

# Download Zephyr SDK 0.17.0 for x86_64
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_linux-x86_64.tar.xz

# Extract and install
tar xf zephyr-sdk-0.17.0_linux-x86_64.tar.xz
cd zephyr-sdk-0.17.0
./setup.sh -t arm-zephyr-eabi
```

**Setup options:**

```bash
# Install all toolchains (requires more disk space)
./setup.sh -h  # See all options
./setup.sh     # Install all toolchains

# Install specific toolchains
./setup.sh -t arm-zephyr-eabi      # ARM Cortex-M/R/A
./setup.sh -t riscv64-zephyr-elf   # RISC-V
./setup.sh -t xtensa-espressif_esp32_zephyr-elf  # ESP32
```

### 6. Environment Variables

**IMPORTANT**: Do **NOT** set `ZEPHYR_BASE` when using the local west workspace!

The west workspace automatically configures paths. Setting `ZEPHYR_BASE` to an external Zephyr installation will cause conflicts:
- CMake will try to use the external Zephyr instead of the local one
- Module paths will be incorrect
- Build will fail with "cannot find zephyr_default" errors

**If you previously set ZEPHYR_BASE**, unset it:

```bash
# Remove from your shell session
unset ZEPHYR_BASE

# If it's in ~/.bashrc or ~/.profile, remove that line
# and restart your terminal
```

**Optional SDK path** (only if you installed the Zephyr SDK):

If the SDK is not installed in the default location, you can specify it:

```bash
# One-time export (for current terminal session)
export ZEPHYR_SDK_INSTALL_DIR=~/zephyr-sdk-0.17.0

# Or add to ~/.bashrc for permanent setup
echo 'export ZEPHYR_SDK_INSTALL_DIR=~/zephyr-sdk-0.17.0' >> ~/.bashrc
source ~/.bashrc
```

**Default SDK search paths:**
- `~/zephyr-sdk-0.17.0`
- `~/.local/zephyr-sdk-0.17.0`
- `/opt/zephyr-sdk-0.17.0`

If installed in any of these locations, no environment variable is needed.

### 7. Verify West Workspace

```bash
# List all west projects
west list

# Should show:
# manifest     fprime-zephyr-led-blinker  HEAD                           N/A
# zephyr       zephyr                      v4.3.0                         https://github.com/zephyrproject-rtos/zephyr
# ... (and many more modules)
```

```bash
# Check west configuration
west config manifest.path
# Should output: fprime-zephyr-led-blinker (or similar)
```

### Troubleshooting West Setup

#### Issue: "FATAL ERROR: already initialized"

**Cause**: West workspace already exists, possibly from a previous setup or conflicting ZEPHYR_BASE.

**Solution**:
```bash
# Unset ZEPHYR_BASE if set
unset ZEPHYR_BASE

# Remove existing west configuration
rm -rf .west

# Re-initialize
west init -l .
west update
```

#### Issue: "include could not find requested file: zephyr_default"

**Cause**: ZEPHYR_BASE is set and pointing to external Zephyr, causing path conflicts.

**Solution**:
```bash
# Unset ZEPHYR_BASE
unset ZEPHYR_BASE

# Clean build directory
rm -rf build-fprime-automatic-zephyr

# Regenerate
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

#### Issue: "No module named 'jsonschema'"

**Cause**: Missing Python dependencies required by Zephyr scripts.

**Solution**:
```bash
pip install jsonschema pyelftools
```

---

## Code Fixes Required

### Fix 1: Update POSIX Time Header

**File**: `fprime-zephyr/Zephyr/ZephyrTime/ZephyrTime.hpp`

**Issue**: Zephyr v4.3.0+ uses different header path than older versions.

**Change**:
```cpp
// OLD (line 11)
#include <zephyr/posix/time.h>

// NEW
#include <zephyr/posix/posix_time.h>
```

### Fix 2: Add POSIX SEEK Constants for Zephyr

**File**: `fprime-zephyr/cmake/platform/zephyr/Platform/PlatformTypes.h`

**Issue**: Zephyr uses `FS_SEEK_*` constants instead of standard POSIX `SEEK_*` constants. F-Prime's POSIX File implementation expects the standard constants.

**Change**: Add the following lines at the end of the file, before the final `#endif`:

```cpp
// Zephyr uses FS_SEEK_* constants instead of POSIX SEEK_* constants
// Map them for compatibility with fprime's Posix File implementation
#include <zephyr/fs/fs.h>
#ifndef SEEK_SET
#define SEEK_SET FS_SEEK_SET
#endif
#ifndef SEEK_CUR
#define SEEK_CUR FS_SEEK_CUR
#endif
#ifndef SEEK_END
#define SEEK_END FS_SEEK_END
#endif

#endif  // PLATFORM_TYPES_H_
```

**Without this fix**, you'll encounter compilation errors like:
```
error: 'SEEK_END' was not declared in this scope; did you mean 'FS_SEEK_END'?
error: 'SEEK_SET' was not declared in this scope; did you mean 'FS_SEEK_SET'?
error: 'SEEK_CUR' was not declared in this scope; did you mean 'FS_SEEK_CUR'?
```

### Fix 3: Update UART Device Node

**File**: `Stm32LedBlinker/Main.cpp`

**Issue**: The default `cdc_acm_uart0` doesn't exist on Nucleo H7A3ZI-Q. The board uses `usart3` for console.

**Change**:
```cpp
// OLD (line 16)
const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(cdc_acm_uart0));

// NEW
const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(usart3));
```

---

## Board Configuration

### Memory Configuration Overlay

The STM32H7A3ZI-Q has 1MB of RAM, but Zephyr defaults to 256KB which is insufficient for F'. Create a device tree overlay:

**File**: `boards/nucleo_h7a3zi_q.overlay`

```dts
/ {
    chosen {
        zephyr,sram = &sram0;
    };
};

&sram0 {
    reg = <0x24000000 DT_SIZE_K(1024)>;  // Use full 1MB of AXI SRAM
};
```

This allocates the full 1MB of available SRAM to the application.

---

## Building the Firmware

### 1. Return to Project Directory

```bash
cd ~/work/practice/fprime/fprime-zephyr-led-blinker
source .venv/bin/activate
```

**IMPORTANT**: Do **NOT** export `ZEPHYR_BASE`! The local west workspace handles all paths automatically.

### 2. Generate Build Configuration

```bash
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

This generates the CMake build files and Zephyr configuration for the target board.

**Expected output:**
```
[INFO] Generating build directory at: .../build-fprime-automatic-zephyr
[INFO] Using toolchain file .../fprime-zephyr/cmake/toolchain/zephyr.cmake
Loading Zephyr default modules (Freestanding).
-- Zephyr version: 4.3.0 (/path/to/local/zephyr)
-- Found west (found suitable version "1.5.0", minimum required is "0.14.0")
...
-- Configuring done
-- Generating done
```

**Verify it's using the LOCAL Zephyr**: The path should show your project's `zephyr/` subdirectory, NOT an external path like `~/zephyrproject/zephyr`.

### 3. Build the Firmware

**Important**: Due to a race condition between Zephyr syscall header generation and F' compilation, you must first build the syscall headers before the main build.

#### Step 1: Pre-generate Zephyr syscall headers

```bash
cd build-fprime-automatic-zephyr
make syscall_list_h_target -j1
cd ..
```

This ensures all Zephyr syscall headers (like `zephyr/syscalls/device.h`) are generated before F' compilation begins.

#### Step 2: Build the complete firmware

```bash
fprime-util build -j4
```

Build parameters:
- `-j4`: Use 4 parallel jobs (adjust based on your CPU cores)
- Build time: ~5-10 minutes on Raspberry Pi 5

**Note**: If you encounter errors like `fatal error: zephyr/syscalls/device.h: No such file or directory`, the race condition occurred. Simply run the syscall header generation command again and rebuild.

### 4. Verify Build Output

```bash
ls -lh build-fprime-automatic-zephyr/zephyr/zephyr.*
```

Expected files:
- `zephyr.elf` - ELF executable with debug symbols
- `zephyr.bin` - Raw binary for flashing
- `zephyr.hex` - Intel HEX format

---

## Flashing to Board

### 1. Connect the Board

Connect your STM32 Nucleo H7A3ZI-Q board to the Raspberry Pi via USB. The ST-Link programmer is built into the Nucleo board.

### 2. Verify Connection

```bash
# Install the st-flash if not installed
sudo apt-get install stlink-tools

# Check the version
st-flash --version
```

Check if the board is detected:

```bash
lsusb | grep -i stm
```

### 3. Flash the Firmware

For best results, erase the flash memory before writing new firmware:

```bash
# Erase the flash completely
st-flash --connect-under-reset erase

# Flash the firmware
st-flash --connect-under-reset write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000
```

Expected output:
```
st-flash 1.8.0
STM32H7Ax_H7Bx: 128 KiB SRAM, 2048 KiB flash
Mass erase completed successfully.
Attempting to write 206688 bytes to address: 0x8000000
Flash written and verified! jolly good!
```

**Note**: The `--connect-under-reset` option helps with STM32H7 boards that may have timing issues during connection.

The board will automatically reset and start running the application.

---

## Running F' GDS

### 1. Check Serial Port

Identify the serial port (usually `/dev/ttyACM0`):

```bash
ls -l /dev/ttyACM*
```

### 2. Set Port Permissions

```bash
sudo chmod 0777 /dev/ttyACM0
```

Or add your user to the `dialout` group permanently:

```bash
sudo usermod -a -G dialout $USER
# Then logout and login again
```

### 3. Close Any Existing Serial Connections

If you have screen/minicom open on the port:

```bash
# Find process using the port
fuser /dev/ttyACM0

# Kill it (replace PID with actual process ID)
kill <PID>
```

### 4. Start F' Ground Data System

```bash
source .venv/bin/activate
fprime-gds -n \
  --dictionary ./build-artifacts/zephyr/LedBlinker/dict/LedBlinkerTopologyAppDictionary.xml \
  --comm-adapter uart \
  --uart-device /dev/ttyACM0 \
  --uart-baud 115200
```

### 5. Access Web Interface

Open a web browser and navigate to:

```
http://localhost:5000
```

Or from another computer on the same network:

```
http://<raspberry-pi-ip>:5000
```

### 6. GDS Features

The web interface provides:
- **Dashboard**: Real-time telemetry display
- **Commanding**: Send commands to the spacecraft/board
- **Events**: View event logs and messages
- **Channels**: Monitor telemetry channels
- **Charts**: Plot telemetry data over time
- **Sequences**: Upload and execute command sequences

### 7. Test the LED Commands

From the GDS command interface, you can:
- `led.BLINKING_ON_OFF` - Toggle LED blinking
- `led.RUN_TIME_LIMIT` - Set runtime limit
- Monitor LED state changes in the events panel

---

## Troubleshooting

### Build Issues

#### Thread Creation Failure

**Symptom**: System crashes during `startTasks()` or immediately after entering main loop

**Root Cause**: F-Prime on Zephyr 4.3.0 with F-Prime v4.1.1 requires specific Zephyr configuration for dynamic thread creation. The `Os/Task.cpp` implementation uses `k_thread_stack_alloc()` which needs:

1. **CONFIG_DYNAMIC_THREAD** - Enable dynamic thread creation
2. **CONFIG_DYNAMIC_OBJECTS** - Enable dynamic kernel object allocation  
3. **CONFIG_DYNAMIC_THREAD_ALLOC** - Enable dynamic thread stack allocation
4. **CONFIG_FPRIME=y** - F-Prime specific configuration
5. **Large heap size** - At least 200KB for thread stacks (5 tasks × 4KB + overhead)

**Solution**: Add to `prj.conf`:

```properties
CONFIG_FPRIME=y
CONFIG_DYNAMIC_OBJECTS=y
CONFIG_DYNAMIC_THREAD=y
CONFIG_DYNAMIC_THREAD_ALLOC=y
CONFIG_HEAP_MEM_POOL_SIZE=200000
CONFIG_MAIN_STACK_SIZE=10000
CONFIG_MAX_THREAD_BYTES=5
```

**Note**: The STM32H7A3ZI-Q has 640KB RAM. With CONFIG_USERSPACE enabled, memory requirements increase significantly. If you get "region RAM overflowed" errors, disable userspace or reduce heap size.

#### Issue: "include could not find requested file: zephyr_default"

**Full Error**:
```
CMake Error at .../ZephyrConfig.cmake:66 (include):
  include could not find requested file:
    zephyr_default
```

**Cause**: This occurs when `ZEPHYR_BASE` environment variable is set and points to an external Zephyr installation, causing conflicts with the local west workspace.

**Solution**:
```bash
# Unset ZEPHYR_BASE
unset ZEPHYR_BASE

# Also remove it from ~/.bashrc or ~/.profile if present
# Then clean and rebuild
rm -rf build-fprime-automatic-zephyr
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

**Important**: When using the local west workspace (recommended), **never** set `ZEPHYR_BASE`. The west workspace manages all paths automatically.

#### Issue: CMake can't find Zephyr (west workspace not initialized)

**Symptom**: CMake errors about missing Zephyr package during generation.

**Solution**: Initialize the west workspace:
```bash
west init -l .
west update
```

#### Issue: lxml build error - "too few arguments to function '_PyLong_AsByteArray'"
**Cause**: Python 3.13 API incompatibility with lxml 4.9.3
**Solution**:
```bash
pip install lxml==5.3.0
```

#### Issue: "ModuleNotFoundError: No module named 'cgi'"
**Cause**: Python 3.13 removed the `cgi` module that Cheetah3 depends on
**Solution**:
```bash
pip install legacy-cgi
```

#### Issue: "GPERF-NOTFOUND" during Zephyr build
**Cause**: Missing `gperf` tool required by Zephyr for kernel object hash generation
**Solution**:
```bash
sudo apt-get install -y gperf
# Then reconfigure the build
fprime-util purge
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

#### Issue: "AttributeError: attribute '__default__' of 'typing.TypeVar' objects is not writable"
**Cause**: Incompatible `typing_extensions` version with Python 3.13
**Solution**:
```bash
pip install --upgrade typing_extensions
```

#### Issue: Missing pyelftools
**Solution**:
```bash
pip install pyelftools
```

#### Issue: Memory overflow during linking
**Solution**: Ensure the `boards/nucleo_h7a3zi_q.overlay` file is present with the 1MB RAM configuration.

### Flashing Issues

#### Issue: st-flash not found
**Solution**: Install stlink tools:
```bash
sudo apt-get install stlink-tools
```

#### Issue: Permission denied on USB device
**Solution**:
```bash
sudo chmod 666 /dev/bus/usb/xxx/yyy
```

### GDS Connection Issues

#### Issue: Serial port busy
**Solution**: Close all other programs using the port:
```bash
fuser -k /dev/ttyACM0
```

#### Issue: No telemetry received
**Solution**: 
1. Verify baud rate (115200)
2. Check that firmware is running (LED should blink)
3. Reset the board: Press black reset button on Nucleo

#### Issue: Checksum validation failed
**Solution**: This warning is normal if the framing protocol doesn't match. The connection should still work.

---

## Project Structure

```
fprime-zephyr-led-blinker/
├── fprime/                          # F' framework (submodule v3.4.3)
├── fprime-zephyr/                   # Zephyr OS integration (submodule)
│   └── Zephyr/
│       ├── Os/                      # OS abstraction layer
│       ├── Drv/                     # Device drivers (GPIO, UART, Rate)
│       └── ZephyrTime/              # Time component
├── Components/
│   └── Led/                         # LED component implementation
│       ├── Led.fpp                  # Component interface definition
│       ├── Led.hpp/cpp              # Component implementation
│       └── CMakeLists.txt
├── LedBlinker/
│   ├── Main.cpp                     # Application entry point
│   └── Top/                         # Topology definition
│       ├── topology.fpp             # Component connections
│       ├── instances.fpp            # Component instances
│       └── LedBlinkerTopology.cpp   # Topology setup
├── boards/
│   └── nucleo_h7a3zi_q.overlay     # Board-specific DTS overlay
├── CMakeLists.txt                   # Top-level build configuration
├── prj.conf                         # Zephyr Kconfig options
└── settings.ini                     # F' build settings
```

---

## Key Configuration Files

### settings.ini
Specifies the F' deployment platform:
```ini
[fprime]
framework_path: ./fprime
default_toolchain: zephyr
default_ut_toolchain: native
library_locations: ./fprime-zephyr
```

### prj.conf
Zephyr Kconfig options:
```
CONFIG_CPP=y
CONFIG_NEWLIB_LIBC=y
CONFIG_FPRIME=y
CONFIG_FPU=y
CONFIG_KERNEL_MEM_POOL=y
CONFIG_HEAP_MEM_POOL_SIZE=524288
```

### project.cmake
Sets up F' build integration with Zephyr:
```cmake
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
list(APPEND FPRIME_PROJECT_ROOT "${CMAKE_CURRENT_LIST_DIR}")
```

---

## Summary of Changes Made

1. **Fixed POSIX header path** in `ZephyrTime.hpp` for Zephyr v4.3.99 compatibility
2. **Changed UART device** from `cdc_acm_uart0` to `usart3` in `Main.cpp`
3. **Created memory overlay** (`boards/nucleo_h7a3zi_q.overlay`) with:
   - 640KB SRAM allocation (combined from multiple SRAM regions)
   - Added red LED (LD3) definition on pin PB14 with `led2` alias
4. **Fixed telemetry packet configuration** in `LedBlinkerPackets.xml` to include all LED channels
5. **Rolled back F' version** to v3.4.3 for compatibility with fprime-zephyr
6. **Resolved Python 3.13 compatibility issues**:
   - Upgraded `lxml` to 5.3.0 (from 4.9.3) - fixes C API incompatibility
   - Upgraded `pyzmq` to 26.2.0 (from 25.1.1) - has pre-built wheels for Python 3.13
   - Installed `legacy-cgi` package - provides removed `cgi` module for Cheetah3
   - Installed `gperf` tool - required by Zephyr for kernel object hash generation
7. **Documented syscall race condition workaround** for reliable builds

---

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| F' Framework | v4.1.1 | Submodule |
| Zephyr RTOS | v4.3.0 | Managed by west |
| Zephyr SDK | 0.17.0 | Optional but recommended |
| West | 1.5.0+ | Python package |
| Python | 3.11+ | Tested with 3.13.5 |
| CMake | 3.20.0+ | System package |
| Ninja | Latest | Build tool |
| st-flash | 1.8.0+ | For STM32 flashing |

---

## Additional Resources

- [F' Documentation](https://nasa.github.io/fprime/)
- [Zephyr Documentation](https://docs.zephyrproject.org/)
- [STM32H7A3 Reference Manual](https://www.st.com/resource/en/reference_manual/rm0455-stm32h7a37b3-and-stm32h7b0-value-line-advanced-armbased-32bit-mcus-stmicroelectronics.pdf)
- [Nucleo-H7A3ZI-Q User Manual](https://www.st.com/resource/en/user_manual/um2905-stm32h7-nucleo144-boards-mb1534-stmicroelectronics.pdf)
- [fprime-zephyr GitHub](https://github.com/fprime-community/fprime-zephyr)

---

## Success Indicators

✅ Build completes without errors  
✅ Binary size: ~206 KB  
✅ Flash verification: "Flash written and verified! jolly good!"  
✅ LED blinks on the board  
✅ GDS connects successfully on port 5000  
✅ Telemetry received in GDS web interface  
✅ Commands can be sent from GDS  

---

## License

This project follows the F' framework licensing (Apache 2.0).

---

**Build Date**: December 9, 2025  
**Platform**: Raspberry Pi 5 (ARM64) / Debian Trixie  
**Target**: STM32 Nucleo H7A3ZI-Q
