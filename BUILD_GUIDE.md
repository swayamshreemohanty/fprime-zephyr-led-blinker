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

The fprime-zephyr integration requires F' v3.4.3 (not the latest devel branch):

```bash
cd fprime
git checkout v3.4.3
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

Due to Python 3.13 compatibility issues, install specific package versions:

```bash
# Install compatible wheel versions for Python 3.13
pip install lxml==6.0.2 pyzmq==27.1.0

# Install F' requirements
pip install -r fprime/requirements.txt

# Install additional dependencies
pip install jsonschema==4.25.1
pip install pyelftools==0.32
```

---

## Zephyr RTOS Setup

### 1. Create Zephyr Workspace

```bash
mkdir -p ~/zephyrproject
cd ~/zephyrproject
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install West (Zephyr Meta-Tool)

```bash
pip install west==1.5.0
```

### 3. Initialize Zephyr

```bash
west init -m https://github.com/zephyrproject-rtos/zephyr --mr main
```

### 4. Download STM32 HAL Module

Instead of running full `west update` (which downloads many modules), download only the required STM32 HAL:

```bash
mkdir -p modules/hal
cd modules/hal
git clone https://github.com/zephyrproject-rtos/hal_stm32 stm32
cd ~/zephyrproject
```

### 5. Install Zephyr SDK

Download and install the Zephyr SDK for ARM64:

```bash
cd ~
# Transfer zephyr-sdk-0.16.1_linux-aarch64.tar.xz to Raspberry Pi
tar xf zephyr-sdk-0.16.1_linux-aarch64.tar.xz
cd zephyr-sdk-0.16.1
./setup.sh -t arm-zephyr-eabi
```

### 6. Set Environment Variables

Add to your `~/.bashrc` or export in each terminal session:

```bash
export ZEPHYR_BASE=~/zephyrproject/zephyr
export ZEPHYR_SDK_INSTALL_DIR=~/zephyr-sdk-0.16.1
```

---

## Code Fixes Required

### Fix 1: Update POSIX Time Header

**File**: `fprime-zephyr/Zephyr/ZephyrTime/ZephyrTime.hpp`

**Issue**: Zephyr v4.3.99 uses different header path than older versions.

**Change**:
```cpp
// OLD (line 11)
#include <zephyr/posix/time.h>

// NEW
#include <zephyr/posix/posix_time.h>
```

### Fix 2: Update UART Device Node

**File**: `LedBlinker/Main.cpp`

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
export ZEPHYR_BASE=~/zephyrproject/zephyr
```

### 2. Generate Build Configuration

```bash
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

This generates the CMake build files and Zephyr configuration for the target board.

### 3. Build the Firmware

```bash
fprime-util build -j4
```

Build parameters:
- `-j4`: Use 4 parallel jobs (adjust based on your CPU cores)
- Build time: ~5-10 minutes on Raspberry Pi 5

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
st-flash --version
```

Check if the board is detected:

```bash
lsusb | grep -i stm
```

### 3. Flash the Firmware

```bash
st-flash write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000
```

Expected output:
```
st-flash 1.8.0
STM32H7Ax_H7Bx: 128 KiB SRAM, 2048 KiB flash
Attempting to write 206056 bytes to address: 0x8000000
Flash written and verified! jolly good!
```

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

#### Issue: CMake can't find Zephyr
**Solution**: Ensure `ZEPHYR_BASE` is set:
```bash
export ZEPHYR_BASE=~/zephyrproject/zephyr
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
3. **Created memory overlay** to allocate full 1MB RAM for the application
4. **Rolled back F' version** to v3.4.3 for compatibility with fprime-zephyr
5. **Installed compatible packages** for Python 3.13 (lxml 6.0.2, pyzmq 27.1.0)

---

## Version Information

| Component | Version |
|-----------|---------|
| F' Framework | v3.4.3 |
| Zephyr RTOS | v4.3.99 (development) |
| Zephyr SDK | 0.16.1 |
| West | 1.5.0 |
| Python | 3.13.5 |
| CMake | 3.26.0 |
| st-flash | 1.8.0 |

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
