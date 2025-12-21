# F' Zephyr LED Blinker - Build Guide for STM32 Nucleo H7A3ZI-Q

Complete step-by-step guide for building and deploying the F' (F Prime) LED Blinker application with GDS communication on the STM32 Nucleo H7A3ZI-Q board using Zephyr RTOS.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Python Environment](#python-environment)
4. [Zephyr RTOS Setup](#zephyr-rtos-setup)
5. [Building the Firmware](#building-the-firmware)
6. [Flashing to Board](#flashing-to-board)
7. [Running F' GDS](#running-f-gds)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware
- **Board**: STM32 Nucleo H7A3ZI-Q
- **Connection**: USB cable (ST-Link programming + serial communication)

### Software
- **OS**: Linux (tested on Ubuntu/Debian)
- **Python**: 3.11 or newer
- **Tools**: CMake 3.26+, Git, st-flash (stlink-tools)

---

## Project Setup

### 1. Clone the Repository

```bash
git clone --recurse-submodules https://github.com/fprime-community/fprime-zephyr-led-blinker.git
cd fprime-zephyr-led-blinker
```

### 2. Initialize Submodules

```bash
git submodule update --init --recursive
```

### 3. Checkout F' v4.1.1

```bash
cd fprime
git checkout v4.1.1
cd ..
```

---

## Python Environment

### 1. Create Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install Dependencies

```bash
# Python 3.13+ compatibility packages
pip install legacy-cgi lxml==5.3.0 pyzmq==26.2.0

# F' requirements (skip already installed packages)
grep -v "^lxml" fprime/requirements.txt | grep -v "^pyzmq" | pip install -r /dev/stdin

# Zephyr dependencies
pip install west jsonschema pyelftools

# System tools (if not installed)
sudo apt-get update
sudo apt-get install -y gperf stlink-tools
```

---

## Zephyr RTOS Setup

### ⚠️ Critical: Unset ZEPHYR_BASE

If you have previously installed Zephyr externally, **unset** the environment variable:

```bash
unset ZEPHYR_BASE

# Remove from shell config if present
sed -i '/ZEPHYR_BASE/d' ~/.bashrc
source ~/.bashrc
```

### Initialize West Workspace

```bash
# Initialize west using local manifest
west init -l .

# Download Zephyr v4.3.0 and dependencies (~2GB, takes 10-20 min)
west update
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

### 3. Build Firmware

```bash
fprime-util build -j4
```

Build time: ~5-10 minutes depending on your system.

### 4. Verify Build

```bash
ls -lh build-fprime-automatic-zephyr/zephyr/zephyr.bin
```

You should see a binary file around 280-300KB.

### 5. Generate Topology Dictionary

The topology dictionary is required by GDS to communicate with the board. Generate it using Ninja:

```bash
source .venv/bin/activate
ninja -C build-fprime-automatic-zephyr dictionary

or 

cd /home/swayamshreemohanty/Documents/work/serendipityspace/fprime-zephyr-led-blinker && source .venv/bin/activate && ninja -C build-fprime-automatic-zephyr dictionary
```

This runs F' autocoding tools: **FPP files → fpp-to-xml → fpp-to-dict → JSON dictionary**

Verify the dictionary was created:

```bash
ls -lh build-fprime-automatic-zephyr/Stm32LedBlinker/Top/Stm32LedBlinkerTopologyDictionary.json
```

This JSON file (~97KB) contains:
- Component definitions and interfaces
- Command specifications
- Event definitions
- Telemetry channel metadata
- Port connection information

**Without this dictionary, GDS cannot interpret commands or telemetry from the board.**

---

## Flashing to Board

### 1. Connect Board

Connect the STM32 Nucleo board via USB.

### 2. Flash Firmware

```bash
sudo st-flash --connect-under-reset write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000
```

Expected output:
```
st-flash 1.8.0
STM32H7Ax_H7Bx: 128 KiB SRAM, 2048 KiB flash
Flash written and verified! jolly good!
```

The board will reset automatically and LEDs should start blinking.

---

## Running F' GDS

### 1. Identify Serial Port

```bash
ls -l /dev/ttyACM*
```

Usually `/dev/ttyACM0`.

### 2. Set Port Permissions

```bash
sudo chmod 0777 /dev/ttyACM0
```

Or add user to dialout group permanently:
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

### 4. Access Web Interface

Open browser to: **http://127.0.0.1:5000/**

You should see:
- ✅ **Green connection dot** (top right)
- Events panel showing system initialization
- Telemetry channels updating

### 5. Send Commands

From the **Commanding** tab, try:
- `led.BLINKING_ON_OFF` - Toggle LED blinking
- Check events panel for confirmation

---

## Troubleshooting

### Build Issues

#### "ZEPHYR_BASE is set" Errors

**Symptom**: CMake error "include could not find requested file: zephyr_default"

**Solution**:
```bash
unset ZEPHYR_BASE
sed -i '/ZEPHYR_BASE/d' ~/.bashrc
rm -rf build-fprime-automatic-zephyr
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

#### Python 3.13 Compatibility

**lxml build errors**: `pip install lxml==5.3.0`  
**Missing cgi module**: `pip install legacy-cgi`  
**Missing gperf**: `sudo apt-get install gperf`

#### Build Hangs or Errors

Clean and rebuild:
```bash
fprime-util purge
fprime-util generate -DBOARD=nucleo_h7a3zi_q
fprime-util build -j4
```

### Flashing Issues

#### st-flash not found

```bash
sudo apt-get install stlink-tools
```

#### Permission denied

```bash
sudo st-flash --connect-under-reset write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000
```

### GDS Connection Issues

#### No Green Connection Dot

**Common causes**:

1. **Wrong UART device** - Verify CommDriver uses `usart3`:
   ```cpp
   // In Stm32LedBlinker/Main.cpp line 11
   const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(usart3));
   ```

2. **Console output corrupting frames** - Ensure in `prj.conf`:
   ```
   CONFIG_CONSOLE=n
   CONFIG_UART_CONSOLE=n
   CONFIG_PRINTK=n
   CONFIG_BOOT_BANNER=n
   CONFIG_EARLY_CONSOLE=n
   ```

3. **Port permissions**:
   ```bash
   sudo chmod 0777 /dev/ttyACM0
   ```

4. **Port busy** - Close other programs:
   ```bash
   fuser -k /dev/ttyACM0
   ```

#### Wrong Framing Selection

Make sure to use `--framing-selection space-packet-space-data-link` in GDS command.

---

## Architecture Overview

This deployment uses F' subtopology pattern:

### CdhCore Subtopology
- **cmdDisp**: Command dispatcher
- **eventLogger**: Event logging
- **tlmSend**: Telemetry packetization
- **fatalHandler**: Fatal error handling
- **rateGroup**: Component scheduling

### ComCcsds Subtopology  
- **comQueue**: Uplink/downlink queue
- **comStub**: Byte stream framing
- **frameAccumulator**: CCSDS frame deframing
- **bufferManager**: Memory pool management

### Communication Flow

```
UART (usart3) <-> commDriver <-> comStub <-> frameAccumulator <-> comQueue
                                                                       |
                                                                  cmdDisp/tlmSend
```

---

## Key Configuration Files

### prj.conf (Zephyr Configuration)

**Critical settings for GDS communication**:
```properties
# Disable console to prevent UART corruption
CONFIG_CONSOLE=n
CONFIG_UART_CONSOLE=n
CONFIG_PRINTK=n
CONFIG_BOOT_BANNER=n
CONFIG_EARLY_CONSOLE=n

# F' and dynamic threading
CONFIG_FPRIME=y
CONFIG_DYNAMIC_OBJECTS=y
CONFIG_DYNAMIC_THREAD=y
CONFIG_HEAP_MEM_POOL_SIZE=200000
```

### settings.ini (F' Build)

```ini
[fprime]
framework_path: ./fprime
default_toolchain: zephyr
library_locations: ./fprime-zephyr
```

### topology.fpp (Component Connections)

Defines how components connect, including:
- Rate group scheduling
- Command/event routing
- UART framing pipeline
- Buffer allocation

---

## Project Structure

```
fprime-zephyr-led-blinker/
├── fprime/                          # F' framework (v4.1.1)
├── fprime-zephyr/                   # Zephyr integration
├── Components/
│   └── Stm32Led/                    # LED component
├── Stm32LedBlinker/
│   ├── Main.cpp                     # Entry point
│   ├── Top/                         # Topology
│   │   ├── topology.fpp            # Connections
│   │   ├── instances.fpp           # Component instances
│   │   └── Stm32LedBlinkerTopology.cpp
│   └── config/
│       ├── CdhCoreConfig.fpp       # CdhCore settings
│       └── ComCcsdsConfig.fpp      # Communication settings
├── boards/
│   └── nucleo_h7a3zi_q.overlay     # Device tree overlay
├── prj.conf                         # Zephyr Kconfig
├── west.yml                         # Zephyr v4.3.0 manifest
└── settings.ini                     # F' settings
```

---

## Version Information

| Component | Version |
|-----------|---------|
| F' Framework | v4.1.1 |
| Zephyr RTOS | v4.3.0 |
| Python | 3.11+ (tested 3.13.5) |
| CMake | 3.26+ |
| West | 1.5.0+ |
| st-flash | 1.8.0+ |

---

## Success Checklist

- ✅ Build completes (~5-10 min)
- ✅ Binary size ~280-300KB
- ✅ Flash succeeds: "jolly good!"
- ✅ LEDs blink on board
- ✅ GDS shows green connection dot
- ✅ Events appear in GDS
- ✅ Commands send successfully

---

## Additional Resources

- [F' Documentation](https://nasa.github.io/fprime/)
- [Zephyr Documentation](https://docs.zephyrproject.org/)
- [fprime-zephyr GitHub](https://github.com/fprime-community/fprime-zephyr)
- [STM32H7A3 Reference](https://www.st.com/en/microcontrollers-microprocessors/stm32h7a3zi.html)

---

**Last Updated**: December 21, 2025  
**Platform**: Linux (ARM64/x86_64)  
**Target**: STM32 Nucleo H7A3ZI-Q

