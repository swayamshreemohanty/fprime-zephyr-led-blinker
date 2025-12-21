# fprime-zephyr-led-blinker

F´ LED Blinker deployment for embedded systems using Zephyr RTOS. This project demonstrates F´ command and data handling (CdhCore) with CCSDS communication (ComCcsds) over UART for ground station communication.

F´ (F Prime) is a component-driven framework that enables rapid development and deployment of spaceflight and other embedded software applications.
**F´ Website:** https://nasa.github.io/fprime/

## Table of Contents
1. [Version Information](#version-information)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Hardware Support](#hardware-support)
5. [Detailed Setup](#detailed-setup)
6. [Building the Firmware](#building-the-firmware)
7. [Flashing to Board](#flashing-to-board)
8. [Running F' GDS](#running-f-gds)
9. [Configuration Files](#configuration-files)
10. [Project Structure](#project-structure)
11. [Troubleshooting](#troubleshooting)
12. [Additional Resources](#additional-resources)

---

## Version Information

| Component | Version | Repository |
|-----------|---------|------------|
| F´ Framework | v4.1.1 | [nasa/fprime](https://github.com/nasa/fprime) |
| fprime-zephyr | main branch | [fprime-community/fprime-zephyr](https://github.com/fprime-community/fprime-zephyr) |
| Zephyr RTOS | v4.3.0 | [zephyrproject-rtos/zephyr](https://github.com/zephyrproject-rtos/zephyr) |
| West | 1.5.0+ | Zephyr meta-tool |
| Python | 3.11+ | Tested with 3.13.5 |
| CMake | 3.26+ | Build system |
| Zephyr SDK | 0.17.0 | Optional but recommended |
| st-flash | 1.8.0+ | For STM32 programming |

---

## Architecture

This deployment uses F´ **subtopology pattern** for modular system architecture:

### CdhCore Subtopology (Command & Data Handling)
- **cmdDisp** - Command dispatcher
- **eventLogger** - Event logging
- **tlmSend** - Telemetry packetization  
- **fatalHandler** - Fatal error handling
- **rateGroup** - Component scheduling

### ComCcsds Subtopology (CCSDS Communication)
- **comQueue** - Uplink/downlink queue
- **comStub** - Byte stream framing
- **frameAccumulator** - CCSDS frame deframing
- **bufferManager** - Memory pool management

### Communication Flow
```
UART (usart3) ↔ commDriver ↔ comStub ↔ frameAccumulator ↔ comQueue
                                                              ↓
                                                         cmdDisp/tlmSend
```

**Framing Protocol:** CCSDS Space Packet over Space Data Link

---

## Quick Start

**⚠️ CRITICAL - If you have used Zephyr before:**

If you previously installed Zephyr externally and set `ZEPHYR_BASE`, **unset it now!**

```bash
unset ZEPHYR_BASE
sed -i '/ZEPHYR_BASE/d' ~/.bashrc
source ~/.bashrc
```

**Why:** Setting `ZEPHYR_BASE` forces CMake to use external Zephyr instead of the local workspace, causing build failures.

### One-Command Build and Flash (STM32 Nucleo H7A3ZI-Q)

```bash
# 1. Install system dependencies
sudo apt-get update && sudo apt-get install -y gperf stlink-tools python3-dev cmake ninja-build

# 2. Clone and setup
git clone --recurse-submodules https://github.com/fprime-community/fprime-zephyr-led-blinker.git
cd fprime-zephyr-led-blinker
cd fprime && git checkout v4.1.1 && cd ..

# 3. Python environment
python3 -m venv .venv
source .venv/bin/activate

# 4. Install Python dependencies (Python 3.13+ compatible)
pip install legacy-cgi lxml==5.3.0 pyzmq==26.2.0
grep -v "^lxml" fprime/requirements.txt | grep -v "^pyzmq" | pip install -r /dev/stdin
pip install west jsonschema pyelftools

# 5. Initialize Zephyr workspace
west init -l .
west update  # Downloads Zephyr v4.3.0 (~2GB, 10-20 min)

# 6. Build firmware
fprime-util generate -DBOARD=nucleo_h7a3zi_q
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr dictionary

# 7. Flash to board
sudo st-flash --connect-under-reset write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000

# 8. Run Ground Data System
sudo chmod 0777 /dev/ttyACM0
fprime-gds -n \
  --dictionary ./build-fprime-automatic-zephyr/Stm32LedBlinker/Top/Stm32LedBlinkerTopologyDictionary.json \
  --communication-selection uart \
  --uart-device /dev/ttyACM0 \
  --uart-baud 115200 \
  --framing-selection space-packet-space-data-link
```

### Verify GDS Connection

Open browser: **http://127.0.0.1:5000/**

**Success indicators:**
- ✅ Green connection dot (top right)
- ✅ Events panel showing system initialization
- ✅ Telemetry channels updating
- ✅ LED blinking on board

**Test commands:**
- `led.BLINKING_ON_OFF` - Toggle LED blinking
- Check events panel for confirmation

---

## Hardware Support

| Board | Status | Notes |
|-------|--------|-------|
| **STM32 Nucleo H7A3ZI-Q** | ✅ Fully Tested | Complete GDS communication, all features working |
| **Teensy 4.1** | ✅ Tested | Requires custom board overlay |
| **Teensy 4.0** | ⚠️ Partial | May need additional configuration |

**Other boards:** See [Zephyr Supported Boards](https://docs.zephyrproject.org/latest/boards/index.html). You'll need to create a board overlay in `boards/` directory.

---

## Detailed Setup

### Prerequisites

**Hardware:**
- STM32 Nucleo H7A3ZI-Q (or compatible board)
- USB cable for ST-Link programming and serial communication

**Software:**
- **OS**: Linux (Ubuntu/Debian/Raspberry Pi OS)
- **Python**: 3.11 or newer (tested with 3.13.5)
- **Disk Space**: ~2GB for Zephyr and modules
- **Tools**: CMake 3.26+, Git, ninja-build

### 1. Install System Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
  gperf \
  python3-dev \
  python3-venv \
  cmake \
  ninja-build \
  device-tree-compiler \
  stlink-tools \
  git
```

**Package descriptions:**
- `gperf` - Perfect hash function generator (required by Zephyr)
- `python3-dev` - Python development headers
- `cmake` - Build system (minimum 3.20.0)
- `ninja-build` - Fast build tool
- `device-tree-compiler` - Device tree compiler (dtc)
- `stlink-tools` - STM32 programmer (st-flash)
- `git` - Version control

### 2. Clone Repository

```bash
git clone --recurse-submodules https://github.com/fprime-community/fprime-zephyr-led-blinker.git
cd fprime-zephyr-led-blinker
```

### 3. Checkout F´ v4.1.1

```bash
cd fprime
git checkout v4.1.1
cd ..
```

### 4. Create Python Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

**Always activate before building:**
```bash
source .venv/bin/activate
```

### 5. Install Python Dependencies

```bash
# Upgrade pip
pip install --upgrade pip

# Python 3.13+ compatibility packages
pip install legacy-cgi lxml==5.3.0 pyzmq==26.2.0

# F' requirements (skip already installed)
grep -v "^lxml" fprime/requirements.txt | grep -v "^pyzmq" | pip install -r /dev/stdin

# Zephyr dependencies
pip install west jsonschema pyelftools
```

**Python 3.13 Compatibility Notes:**
- `legacy-cgi` - Provides removed `cgi` module for Cheetah3
- `lxml==5.3.0` - Fixes C API incompatibility  
- `pyzmq==26.2.0` - Pre-built wheels for Python 3.13
- `gperf` - Required by Zephyr for kernel object hash generation

### 6. Initialize West Workspace

**⚠️ CRITICAL:** Ensure `ZEPHYR_BASE` is NOT set!

```bash
# Verify ZEPHYR_BASE is not set
echo $ZEPHYR_BASE  # Should print nothing

# If set, unset it
unset ZEPHYR_BASE
sed -i '/ZEPHYR_BASE/d' ~/.bashrc
source ~/.bashrc

# Initialize west workspace
west init -l .

# Download Zephyr v4.3.0 and modules (~2GB, 10-20 minutes)
west update
```

**What `west update` downloads:**
- Zephyr v4.3.0 into `zephyr/` directory
- HAL modules: `hal_stm32`, `hal_nxp`, etc.
- `cmsis` - ARM Cortex Microcontroller Software Interface
- Other Zephyr dependencies

### 7. (Optional) Install Zephyr SDK 0.17.0

The SDK provides optimized cross-compilation toolchains and better optimization.

**For ARM64 (Raspberry Pi):**
```bash
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_linux-aarch64.tar.xz
tar xf zephyr-sdk-0.17.0_linux-aarch64.tar.xz
cd zephyr-sdk-0.17.0
./setup.sh -t arm-zephyr-eabi
```

**For x86_64:**
```bash
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_linux-x86_64.tar.xz
tar xf zephyr-sdk-0.17.0_linux-x86_64.tar.xz
cd zephyr-sdk-0.17.0
./setup.sh -t arm-zephyr-eabi
```

---

## Building the Firmware

### 1. Activate Environment

```bash
source .venv/bin/activate
```

### 2. Generate Build Configuration

```bash
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

This generates CMake build files and Zephyr configuration for the target board.

**Expected output:**
```
[INFO] Generating build directory at: .../build-fprime-automatic-zephyr
Loading Zephyr default modules (Freestanding).
-- Zephyr version: 4.3.0 (/path/to/local/zephyr)
-- Configuring done
-- Generating done
```

### 3. Build Firmware

```bash
fprime-util build -j4
```

Build time: ~5-10 minutes depending on your system.

### 4. Generate Topology Dictionary

The dictionary is required by GDS to interpret commands and telemetry:

```bash
# From project root
source .venv/bin/activate
ninja -C build-fprime-automatic-zephyr dictionary

# Or with full path
cd /home/swayamshreemohanty/Documents/work/serendipityspace/fprime-zephyr-led-blinker && source .venv/bin/activate && ninja -C build-fprime-automatic-zephyr dictionary
```

This runs F' autocoding: **FPP files → fpp-to-xml → fpp-to-dict → JSON dictionary**

### 5. Verify Build Output

```bash
# Check binary
ls -lh build-fprime-automatic-zephyr/zephyr/zephyr.bin

# Check dictionary
ls -lh build-fprime-automatic-zephyr/Stm32LedBlinker/Top/Stm32LedBlinkerTopologyDictionary.json
```

**Build artifacts:**
```
build-fprime-automatic-zephyr/
├── Stm32LedBlinker/Top/
│   └── Stm32LedBlinkerTopologyDictionary.json  # GDS dictionary (~97KB)
└── zephyr/
    ├── zephyr.bin    # Flashable binary (~280-300KB)
    ├── zephyr.elf    # ELF with debug symbols
    ├── zephyr.hex    # Intel HEX format
    └── zephyr.uf2    # UF2 format (for drag-and-drop boards)
```

**⚠️ Important:**
- ✅ Use: `build-fprime-automatic-zephyr/zephyr/zephyr.bin`
- ❌ Don't use: `build-artifacts/` (stub only, won't work)

### Building for Different Boards

To switch to a different board:

```bash
# Clean build cache
fprime-util purge

# Generate for new board
fprime-util generate -DBOARD=teensy41

# Build
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr dictionary
```

---

## Flashing to Board

### For STM32 Nucleo Boards

**1. Connect Board**

Connect STM32 Nucleo via USB (ST-Link programmer built-in).

**2. Flash Firmware**

```bash
sudo st-flash --connect-under-reset write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000
```

**Expected output:**
```
st-flash 1.8.0
STM32H7Ax_H7Bx: 128 KiB SRAM, 2048 KiB flash
Flash written and verified! jolly good!
```

The board resets automatically and LEDs should start blinking.

### For Teensy Boards

**Using Teensy Loader:**
```bash
# Teensy 4.1
teensy_loader_cli --mcu=TEENSY41 -w build-fprime-automatic-zephyr/zephyr/zephyr.hex

# Teensy 4.0
teensy_loader_cli --mcu=TEENSY40 -w build-fprime-automatic-zephyr/zephyr/zephyr.hex
```

**Or use Teensy Loader GUI** (download from PJRC website).

---

## Running F' GDS

### 1. Identify Serial Port

```bash
ls -l /dev/ttyACM*
```

Usually `/dev/ttyACM0` for STM32 boards.

### 2. Set Port Permissions

```bash
sudo chmod 0777 /dev/ttyACM0
```

**Permanent solution:** Add user to dialout group:
```bash
sudo usermod -a -G dialout $USER
# Logout and login for changes to take effect
```

### 3. Start GDS

```bash
source .venv/bin/activate
fprime-gds -n \
  --dictionary ./build-fprime-automatic-zephyr/Stm32LedBlinker/Top/Stm32LedBlinkerTopologyDictionary.json \
  --communication-selection uart \
  --uart-device /dev/ttyACM0 \
  --uart-baud 115200 \
  --framing-selection space-packet-space-data-link
```

**Critical parameters:**
- `--framing-selection space-packet-space-data-link` - CCSDS framing (required!)
- `--dictionary` - Path to topology dictionary
- `--uart-device` - Serial port (usually /dev/ttyACM0)
- `--uart-baud 115200` - Baud rate

### 4. Access Web Interface

Open browser: **http://127.0.0.1:5000/**

**Success indicators:**
- ✅ Green connection dot (top right)
- ✅ Events panel showing system initialization
- ✅ Telemetry channels updating
- ✅ LED blinking on board

### 5. GDS Features

- **Dashboard** - Real-time telemetry display
- **Commanding** - Send commands to board
- **Events** - View event logs and messages
- **Channels** - Monitor telemetry channels
- **Charts** - Plot telemetry data over time

### 6. Test Commands

From **Commanding** tab:
- `led.BLINKING_ON_OFF` - Toggle LED blinking
- `led.RUN_TIME_LIMIT` - Set runtime limit
- Monitor LED state changes in events panel

---

## Configuration Files

### prj.conf (Zephyr Configuration)

**Critical for GDS communication** - Disables console output to prevent UART corruption:

```properties
# Disable all console output (prevents UART frame corruption)
CONFIG_CONSOLE=n
CONFIG_UART_CONSOLE=n
CONFIG_PRINTK=n
CONFIG_BOOT_BANNER=n
CONFIG_EARLY_CONSOLE=n

# F' and dynamic threading support
CONFIG_FPRIME=y
CONFIG_DYNAMIC_OBJECTS=n
CONFIG_DYNAMIC_THREAD=y
CONFIG_DYNAMIC_THREAD_ALLOC=y
CONFIG_HEAP_MEM_POOL_SIZE=256000
CONFIG_MAIN_STACK_SIZE=8192
```

**Why disable console output?**
- UART is shared between debug console and F´ CCSDS frames
- Console text corrupts binary CCSDS frames
- Prevents GDS from synchronizing with frame headers
- Result: No green connection dot in GDS


### Topology Files

**Stm32LedBlinker/Top/topology.fpp** - Component connections:
- Rate group scheduling
- Command/event routing  
- UART framing pipeline
- Buffer allocation

**Stm32LedBlinker/Top/instances.fpp** - Component instances:
- chronoTime - Time provider
- commDriver - UART driver
- rateGroups - Periodic scheduling
- GPIO/LED components

### settings.ini (F' Build Settings)

```ini
[fprime]
framework_path: ./fprime
default_toolchain: zephyr
library_locations: ./fprime-zephyr
```

### Configuration Override System

This project uses **F´'s configuration override system** to customize framework behavior without modifying F´ core files. All deployment-specific configuration is in `Stm32LedBlinker/config/`:

- `CMakeLists.txt` - Registers configuration overrides with `register_fprime_config()`
- `PlatformCfg.fpp` - Overrides platform constants (e.g., task handle sizes)
- `CdhCoreConfig.fpp` - CdhCore subtopology configuration
- `ComCcsdsConfig.fpp` - ComCcsds subtopology configuration

**Benefits:**
- ✅ Keeps F´ framework pristine (no git conflicts on updates)
- ✅ Deployment-specific settings isolated in one location
- ✅ Easy to maintain and version control
- ✅ Follows F´ best practices

**Note:** The F´ framework files in `fprime/default/config/` remain unmodified and use default values. Project overrides in `Stm32LedBlinker/config/` take precedence during build.



```ini
[fprime]
framework_path: ./fprime
default_toolchain: zephyr
library_locations: ./fprime-zephyr
```

---

## Project Structure

```
fprime-zephyr-led-blinker/
├── fprime/                                    # F' framework (v4.1.1) - unmodified
│   └── default/config/                        # Framework defaults (not modified)
├── fprime-zephyr/                             # Zephyr integration with F'
├── zephyr/                                    # Zephyr RTOS v4.3.0 (from west update)
├── Components/
│   └── Stm32Led/                              # LED component implementation
├── Stm32LedBlinker/
│   ├── Main.cpp                               # Application entry point
│   ├── Stub.cpp                               # Platform stubs
│   ├── Top/                                   # Topology definition
│   │   ├── topology.fpp                      # Component connections
│   │   ├── instances.fpp                     # Component instances
│   │   ├── Stm32LedBlinkerTopology.cpp       # Topology implementation
│   │   ├── Stm32LedBlinkerTopology.hpp       # Topology header
│   │   ├── Stm32LedBlinkerTopologyDefs.hpp   # Type definitions & state
│   │   └── Stm32LedBlinkerPackets.xml        # Telemetry packet definitions
│   └── config/                                # Project-level configuration overrides
│       ├── CMakeLists.txt                     # Registers config overrides
│       ├── PlatformCfg.fpp                    # Platform constants (overrides fprime defaults)
│       ├── CdhCoreConfig.fpp                  # CdhCore subtopology settings
│       └── ComCcsdsConfig.fpp                 # ComCcsds subtopology settings
├── boards/
│   ├── nucleo_h7a3zi_q.overlay                # STM32 Nucleo H7A3ZI-Q overlay
│   ├── teensy40.overlay                       # Teensy 4.0 overlay
│   └── teensy41.overlay                       # Teensy 4.1 overlay
├── build-fprime-automatic-zephyr/             # Build directory (generated)
│   ├── Stm32LedBlinker/Top/
│   │   └── Stm32LedBlinkerTopologyDictionary.json  # GDS dictionary
│   └── zephyr/
│       ├── zephyr.bin                         # Flashable binary
│       ├── zephyr.elf                         # ELF with debug symbols
│       └── zephyr.hex                         # Intel HEX format
├── prj.conf                                   # Zephyr Kconfig options
├── west.yml                                   # West manifest (Zephyr v4.3.0)
├── settings.ini                               # F' build settings
├── project.cmake                              # CMake Zephyr integration
└── CMakeLists.txt                             # Top-level build configuration
```

---

---

## Troubleshooting

### Build Issues

#### "ZEPHYR_BASE is set" Error

**Symptom:** CMake error "include could not find requested file: zephyr_default"

**Cause:** `ZEPHYR_BASE` environment variable is set, causing conflicts with local west workspace.

**Solution:**
```bash
unset ZEPHYR_BASE
sed -i '/ZEPHYR_BASE/d' ~/.bashrc
source ~/.bashrc
rm -rf build-fprime-automatic-zephyr
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

#### Python 3.13 Compatibility Errors

**lxml build failure:**
```bash
pip install lxml==5.3.0
```

**Missing cgi module:**
```bash
pip install legacy-cgi
```

**Missing gperf tool:**
```bash
sudo apt-get install gperf
```

#### Build Hangs or Fails

Clean and rebuild:
```bash
fprime-util purge
fprime-util generate -DBOARD=nucleo_h7a3zi_q
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr dictionary
```

### Flashing Issues

#### st-flash not found

```bash
sudo apt-get install stlink-tools
```

#### Permission denied

Use sudo:
```bash
sudo st-flash --connect-under-reset write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000
```

### GDS Connection Issues

#### No Green Connection Dot

**Most common cause:** UART corruption from console output.

**Check these in order:**

**1. Verify UART device** in `Stm32LedBlinker/Main.cpp`:
```cpp
// Line 11 - Should be usart3 for STM32 Nucleo
const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(usart3));
```

**2. Console output disabled** in `prj.conf`:
```properties
CONFIG_CONSOLE=n
CONFIG_UART_CONSOLE=n
CONFIG_PRINTK=n
CONFIG_BOOT_BANNER=n
CONFIG_EARLY_CONSOLE=n
```

**3. Correct framing selection:**
```bash
--framing-selection space-packet-space-data-link
```
Wrong framing = no connection!

**4. Port permissions:**
```bash
sudo chmod 0777 /dev/ttyACM0
```

**5. Port not busy:**
```bash
fuser -k /dev/ttyACM0
```

**6. Correct dictionary path:**
```bash
--dictionary ./build-fprime-automatic-zephyr/Stm32LedBlinker/Top/Stm32LedBlinkerTopologyDictionary.json
```

#### Port busy / Permission denied

**Check what's using the port:**
```bash
lsof /dev/ttyACM0
```

**Kill processes:**
```bash
fuser -k /dev/ttyACM0
```

**Add user to dialout group (permanent fix):**
```bash
sudo usermod -a -G dialout $USER
# Logout and login
```

### Dictionary Generation Failed

**Regenerate dictionary:**
```bash
ninja -C build-fprime-automatic-zephyr dictionary
```

**If still fails, clean and rebuild:**
```bash
fprime-util purge
fprime-util generate -DBOARD=nucleo_h7a3zi_q
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr dictionary
```

---

## Success Checklist

Use this to verify your setup is working correctly:

- ✅ Build completes in ~5-10 minutes
- ✅ Binary size ~280-300KB (`zephyr.bin`)
- ✅ Dictionary generated (~97KB JSON file)
- ✅ Flash succeeds with "jolly good!" message
- ✅ LEDs blink on board after reset
- ✅ GDS starts without errors
- ✅ **Green connection dot** appears in GDS (top right)
- ✅ Events appear in GDS events panel
- ✅ Telemetry channels update
- ✅ Commands send successfully (`led.BLINKING_ON_OFF`)

---

## Additional Resources

- **F´ Documentation:** https://nasa.github.io/fprime/
- **Zephyr Documentation:** https://docs.zephyrproject.org/
- **fprime-zephyr GitHub:** https://github.com/fprime-community/fprime-zephyr
- **Zephyr Supported Boards:** https://docs.zephyrproject.org/latest/boards/index.html
- **STM32H7A3 Reference:** https://www.st.com/en/microcontrollers-microprocessors/stm32h7a3zi.html
- **F´ User Guide:** https://nasa.github.io/fprime/UsersGuide/guide.html

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

This project follows the F´ framework licensing (Apache 2.0).

---

**Last Updated:** December 21, 2025  
**Tested Platforms:** Ubuntu 22.04, Debian 12, Raspberry Pi OS  
**Target Boards:** STM32 Nucleo H7A3ZI-Q, Teensy 4.1  
**Maintainers:** fprime-community