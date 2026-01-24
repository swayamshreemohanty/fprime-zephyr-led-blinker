# F´ Zephyr LED Blinker - Production-Ready Embedded Flight Software

F´ LED Blinker deployment for embedded systems using Zephyr RTOS. This project demonstrates production-ready F´ implementation with robust UART communication, enhanced error handling, and comprehensive ground station integration.

**F´ (F Prime)** is NASA's component-driven framework for spaceflight and embedded software applications.  
**Visit:** https://fprime.jpl.nasa.gov

---

## 📋 Table of Contents

1. [Project Setup](#-project-setup)
2. [F´ Library Modifications](#-f-library-modifications)
3. [fprime-zephyr Library Modifications](#-fprime-zephyr-library-modifications)
4. [Architecture](#-architecture)
5. [GDS Dictionary Setup](#-gds-dictionary-setup)
6. [Building the Firmware](#-building-the-firmware)
7. [Flashing to Board](#-flashing-to-board)
8. [Running F' GDS](#-running-f-gds)
9. [Hardware Support](#-hardware-support)
10. [Configuration Files](#-configuration-files)
11. [Project Structure](#-project-structure)
12. [Troubleshooting](#-troubleshooting)
13. [Additional Resources](#-additional-resources)

---

## 🚀 Project Setup

### 1. Clone the Repository

```bash
git clone --recurse-submodules https://github.com/fprime-community/fprime-zephyr-led-blinker.git
cd fprime-zephyr-led-blinker
```

### 2. Download F´ Library

This project uses the official NASA F´ library (v4.1.1) as a Git submodule. **Important:** The library has been modified for robust UART communication (see [F´ Library Modifications](#-f-library-modifications)).

```bash
# If submodules weren't cloned automatically
git submodule init
git submodule update

# Navigate to fprime directory and checkout v4.1.1
cd fprime
git checkout v4.1.1
cd ..
```

**Alternative: Manual Clone**

If submodules aren't working, clone manually:

```bash
git clone https://github.com/nasa/fprime.git
cd fprime
git checkout v4.1.1
cd ..
```

### 3. Download fprime-zephyr Library

The fprime-zephyr library provides Zephyr RTOS integration for F´. **Important:** This library has been modified for enhanced UART performance (see [fprime-zephyr Library Modifications](#-fprime-zephyr-library-modifications)).

```bash
# fprime-zephyr is included as a submodule
# It should already be initialized if you used --recurse-submodules
# If not:
git submodule update --init fprime-zephyr
```

### 4. Install System Dependencies

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

### 5. Install Python Requirements

```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Upgrade pip
pip install --upgrade pip

# Python 3.13+ compatibility packages
pip install legacy-cgi lxml==5.3.0 pyzmq==26.2.0

# F' requirements (skip already installed)
grep -v "^lxml" fprime/requirements.txt | grep -v "^pyzmq" | pip install -r /dev/stdin

# Zephyr dependencies
pip install west jsonschema pyelftools
```

**Requirements breakdown:**
- `fprime-tools`: F´ build utilities (`fprime-util`) and Ground Data System (GDS)
- `west`: Zephyr meta-tool for workspace management
- `legacy-cgi`: Provides removed `cgi` module for Python 3.13+ compatibility
- `lxml==5.3.0`: Fixes C API incompatibility with Python 3.13
- `pyzmq==26.2.0`: Pre-built wheels for Python 3.13

### 6. Initialize Zephyr (Choose One Approach)

**Option A: Use External Zephyr** (if already installed elsewhere):
```bash
export ZEPHYR_BASE=/path/to/your/zephyr/zephyrproject/zephyr
export ZEPHYR_SDK_INSTALL_DIR=/path/to/your/zephyr-sdk-0.17.4
export ZEPHYR_MODULES="/path/to/modules/..."
# Skip west init/update
```

**Option B: Use Local West Workspace** (self-contained):
```bash
unset ZEPHYR_BASE  # Ensure not set
west init -l .
west update  # Downloads Zephyr v4.3.0 (~2GB, 10-20 minutes)
```

### 7. Verify Installation

```bash
# Check fprime-util is available
fprime-util --version

# Check fprime-gds is available  
fprime-gds --version

# Check west is available
west --version
```

---

## 🔧 F´ Library Modifications

This project contains **critical modifications** to the NASA F´ library (`fprime/`) to enable robust UART communication and enhanced error handling for embedded systems. These changes fix packet corruption issues and add debugging capabilities.

### ⚠️ Why These Modifications Are Important

The standard F´ library component (`GenericHub`) was designed for ideal network conditions. In embedded systems with UART links:

1. **Packet Fragmentation**: UART buffers can split or merge packets unpredictably
2. **Data Corruption**: Noise, timing issues, or malformed data can corrupt packet headers
3. **Crash Prevention**: Assertions in original code crash the system on invalid data
4. **Debugging Needs**: Visibility into packet flow is essential for troubleshooting

**Without these modifications**, the system experiences:
- System crashes from assertion failures on corrupted packets
- No diagnostic information for debugging UART issues
- Inability to recover from transient UART errors
- Production-unsafe behavior (crashes on bad data)

### Modified Files

#### `Svc/GenericHub/GenericHub.cpp` - Packet Validation & Error Handling

**Location:** `fprime/Svc/GenericHub/GenericHub.cpp`

**Changes:**
- ✅ **Minimum packet size validation** (prevents crashes on undersized packets)
- ✅ **Packet type validation** (`type < HUB_TYPE_MAX` check before casting)
- ✅ **Payload size mismatch detection** (prevents buffer overruns)
- ✅ **Graceful error recovery** (discards bad packets instead of crashing)
- ✅ **Serialization error handling** (validates all deserialization operations)

**Key Code Changes:**

**1. Minimum Packet Size Validation:**
```cpp
// Before: No size check, crashes on small packets
void GenericHub::fromBufferDriver_handler(const FwIndexType portNum, Fw::Buffer& fwBuffer) {
    // Immediately tries to deserialize without validation
}

// After: Validates minimum header size
constexpr U32 HEADER_SIZE = sizeof(U32) + sizeof(U32) + sizeof(FwBuffSizeType);  // 4+4+2=10
if (fwBuffer.getSize() < HEADER_SIZE) {
    // Log error and return buffer gracefully
    fromBufferDriverReturn_out(0, fwBuffer);
    return;
}
```

**2. Type Validation:**
```cpp
// Before: Assertion crashes on invalid type
FW_ASSERT(type < HUB_TYPE_MAX, type);

// After: Validate and discard gracefully
type = static_cast<HubType>(type_in);
if (type >= HUB_TYPE_MAX) {
    // Log error via F' event system instead of printk
    fromBufferDriverReturn_out(0, fwBuffer);
    return;  // Exit gracefully instead of crashing
}
```

**3. Deserialization Error Handling:**
```cpp
// Before: Assertions crash on deserialization failures
status = incoming.deserializeTo(type_in);
FW_ASSERT(status == Fw::FW_SERIALIZE_OK, static_cast<FwAssertArgType>(status));

// After: Check and handle errors gracefully
status = incoming.deserializeTo(type_in);
if (status != Fw::FW_SERIALIZE_OK) {
    // Log error via F' event system instead of printk
    fromBufferDriverReturn_out(0, fwBuffer);
    return;
}
```

**4. Payload Size Validation:**
```cpp
// Before: Assertion on size mismatch
U8* rawData = fwBuffer.getData() + HEADER_SIZE;
U32 rawSize = static_cast<U32>(fwBuffer.getSize() - HEADER_SIZE);
FW_ASSERT(rawSize == static_cast<U32>(size));

// After: Validate and discard on mismatch
if (rawSize != static_cast<U32>(size)) {
    // Log error via F' event system instead of printk
    fromBufferDriverReturn_out(0, fwBuffer);
    return;
}
```

**Why Important:** 
- UART noise, STM32 bugs, or packet fragmentation can produce corrupted headers
- In-flight crashes are unacceptable - the system must detect and discard bad data
- Graceful error handling allows the system to continue operating despite corrupted packets
- Makes the system production-ready by eliminating crash conditions

### Comparison: Original vs. Modified F´ Library

| Aspect | Original F´ Library | Modified Library (This Project) |
|--------|---------------------|--------------------------------|
| **Packet Validation** | Assertions crash on invalid data | Validates and discards gracefully |
| **Error Handling** | `FW_ASSERT` kills process | Returns buffer, continues operation |
| **Size Checking** | No minimum size validation | Validates header size (10 bytes minimum) |
| **Type Validation** | Crashes on type >= MAX | Checks range before casting |
| **Deserialization** | Crashes on errors | Validates all deserialize operations |
| **Corruption Resistance** | Crashes on size mismatches | Detects and discards malformed packets |
| **Production Readiness** | Not tested for UART errors | Hardened for real-world conditions |

### How to View/Apply Modifications

**Check Current Status:**
```bash
cd fprime
git status
# Should show:
#   modified: Svc/GenericHub/GenericHub.cpp
```

**View Detailed Changes:**
```bash
cd fprime
git diff Svc/GenericHub/GenericHub.cpp
```

**Revert to Original (Not Recommended):**
```bash
cd fprime
git restore Svc/GenericHub/GenericHub.cpp
```

⚠️ **Warning:** Reverting will re-enable crashes on corrupted packets and remove error handling.

**Create Patch File:**
```bash
cd fprime
git diff > ../fprime-uart-hardening.patch
# Apply later with: git apply fprime-uart-hardening.patch
```

---

## 🔧 fprime-zephyr Library Modifications

This project contains **essential modifications** to the fprime-zephyr library to enable robust UART communication with the Ground Data System and improve buffer management.

### ⚠️ Why These Modifications Are Important

The standard fprime-zephyr UART driver was designed for basic communication. In production systems:

1. **Packet Separation**: Without delays, back-to-back packets merge in the receiver's UART buffer
2. **Buffer Overflows**: Small buffers (64 bytes) can't handle F´ packet sizes (up to 512 bytes + framing)
3. **Linux UART Behavior**: With `VMIN=0`, Linux UART reads multiple packets in one call, corrupting packet boundaries
4. **File System Compatibility**: Zephyr uses different constants than POSIX for file operations

**Without these modifications**, the system experiences:
- GDS connection issues (packets merge, GenericHub sees corrupted data)
- Buffer overflows causing data loss
- File system operation failures
- Unreliable UART communication

### Modified Files

#### 1. `fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.cpp` - Inter-Packet Delay

**The Problem:**
When running at full speed without timing delays, the system exhibited strange behavior:
- GDS shows red dot (disconnected) initially
- After GDS restart, green dot appears but **no telemetry in channels**
- Resetting STM32 causes GDS to show red cross again

**Root Cause:** Debug statements were introducing timing delays (~10-20ms) that prevented packets from merging. Without delays:
```
UART Buffer: [Packet1_31bytes][Packet2_31bytes][Packet3_31bytes]...
             ↑ No gap - continuous stream, packets merge
```

LinuxUartDriver reads 62-93 bytes in one `read()` call → GenericHub processes first 31 bytes correctly, but remaining bytes are treated as a new packet with **corrupted header**.

**Changes:**
- ✅ **5ms inter-packet delay** (prevents packet merging in Linux UART buffer)
- ✅ **Zephyr kernel includes** for k_sleep() functionality

**Key Code Changes:**
```cpp
// Before: Continuous transmission without delays
for (U32 i = 0; i < sendBuffer.getSize(); i++) {
    uart_poll_out(this->m_dev, sendBuffer.getData()[i]);
}
return Drv::ByteStreamStatus::OP_OK;

// After: Add inter-packet delay
U32 size = sendBuffer.getSize();

// Transmit byte by byte
for (U32 i = 0; i < size; i++) {
    uart_poll_out(this->m_dev, sendBuffer.getData()[i]);
}

// Inter-packet delay: Prevents back-to-back packets from merging
// in the Linux UART buffer on the RPi side. Without this delay,
// LinuxUartDriver with VMIN=0 will read multiple packets in one
// read() call, causing GenericHub to see corrupted data.
// 5ms is safe for 31-byte packets at 115200 baud (~2.7ms transmission time)
k_sleep(K_MSEC(5));

return Drv::ByteStreamStatus::OP_OK;
```

**Why Important:**
- At 115200 baud: 1 byte = 10 bits (start + 8 data + stop) = ~87 microseconds
- For 31-byte packet: 31 × 87µs = **~2.7ms transmission time**
- Without delay, next packet starts immediately, merging in receiver's buffer
- Linux UART with `VMIN=0` reads both packets in one system call
- GenericHub expects one packet per buffer, sees corrupted data when packets merge
- **5ms delay** = 2.7ms transmission + 2.3ms buffer time for Linux kernel to schedule read()
- Maintains reasonable telemetry rate (200 packets/sec max, typical F´ rate is 1-10 Hz)

**Verification:**
```bash
# Before Fix (Merged Packets)
$ cat /dev/ttyACM0 | od -A x -t x1z -v | head -10
000000 00 00 00 03 00 00 00 00 00 15 10 00 10 01 00 02  >................<
000010 00 00 00 00 65 00 0e d7 9c 00 04 00 00 00 00 00  >....e...........<
000020 00 00 03 00 00 00 00 00 15 10 00 10 02 00 02 00  >................<
       ↑ Packet 1 ends         ↑ Packet 2 starts (no gap - MERGED!)

# After Fix (Separated Packets)
$ cat /dev/ttyACM0 | od -A x -t x1z -v
000000 00 00 00 03 00 00 00 00 00 15 10 00 10 01 00 02  >................<
000010 00 00 00 00 65 00 0e d7 9c 00 04 00 00 00 00     >....e..........<
       ↑ Packet 1 ends, then 5ms delay before Packet 2 (SEPARATED!)
```

**GDS Success Indicators After Fix:**
- ✅ Green dot immediately after STM32 starts
- ✅ Telemetry appearing in Channels tab (e.g., `rateGroup1.CycleCount` incrementing)
- ✅ Green dot persists after STM32 reset

**Alternative Solutions Considered:**
- **RPi-Side Buffer Reassembly**: Could implement packet reassembly in GenericHub to handle merged packets, but this is more complex and requires maintaining modified F´ library code.
- **Verdict**: The 5ms delay solution is simpler, follows embedded best practices, and has no performance impact on typical F´ telemetry rates (1-10 Hz).

**Performance Impact:**
- Without delay: ~1000+ packets/sec (but corrupted)
- With 5ms delay: ~200 packets/sec maximum theoretical
- Actual F´ telemetry rate: 1-10 Hz (far below the limit)
- **Conclusion**: No performance penalty for real-world usage

#### 2. `fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.hpp` - Buffer Size Increase

**Changes:**
- ✅ **Ring buffer size: 1024 → 4096 bytes** (handles burst traffic)
- ✅ **Serial buffer size: 64 → 1024 bytes** (accommodates F´ COM_BUFFER + framing overhead)

**Key Code Changes:**
```cpp
// Before: Small buffers insufficient for F´ packets
#define RING_BUF_SIZE 1024
const FwSizeType SERIAL_BUFFER_SIZE = 64;

// After: Increased buffers for F´ packet sizes
#define RING_BUF_SIZE 4096
const FwSizeType SERIAL_BUFFER_SIZE = 1024;  // FPrime COM_BUFFER (512) + framing overhead
```

**Why Important:**
- F´ CCSDS frames can be up to 512 bytes (COM_BUFFER size)
- CCSDS framing adds overhead (headers, checksums)
- Ring buffer needs headroom for burst traffic and interrupt latency
- Small buffers cause dropped packets and communication failures
- 1024-byte serial buffer ensures no packet is too large to receive

#### 3. `fprime-zephyr/cmake/platform/zephyr/Platform/PlatformTypes.h` - File System Compatibility

**Changes:**
- ✅ **SEEK_* macro definitions** (maps POSIX constants to Zephyr FS_SEEK_*)

**Key Code Changes:**
```cpp
// Before: Missing SEEK_* macros caused compilation errors in F´ file I/O code

// After: Map Zephyr file system constants to POSIX equivalents
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
```

**Why Important:**
- F´'s file I/O components use POSIX `SEEK_SET`, `SEEK_CUR`, `SEEK_END`
- Zephyr RTOS uses different constants: `FS_SEEK_SET`, `FS_SEEK_CUR`, `FS_SEEK_END`
- Without mapping, F´ file operations fail to compile on Zephyr
- Enables F´ file system components to work seamlessly on Zephyr

### Comparison: Original vs. Modified fprime-zephyr Library

| Aspect | Original fprime-zephyr | Modified Library (This Project) |
|--------|------------------------|--------------------------------|
| **Inter-Packet Delay** | None (continuous transmission) | 5ms delay prevents packet merging |
| **Ring Buffer** | 1024 bytes | 4096 bytes (handles burst traffic) |
| **Serial Buffer** | 64 bytes | 1024 bytes (F´ packet size) |
| **File System** | Missing SEEK_* macros | POSIX compatibility layer |
| **Linux UART Compatibility** | Packets merge in receiver buffer | Clean packet separation |
| **Production Readiness** | Basic functionality | Hardened for reliable communication |

### How to View/Apply Modifications

**Check Current Status:**
```bash
cd fprime-zephyr
git status
# Should show:
#   modified: cmake/platform/zephyr/Platform/PlatformTypes.h
#   modified: fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.cpp
#   modified: fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.hpp
```

**View Detailed Changes:**
```bash
cd fprime-zephyr
git diff cmake/platform/zephyr/Platform/PlatformTypes.h
git diff fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.cpp
git diff fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.hpp
```

**Revert to Original (Not Recommended):**
```bash
cd fprime-zephyr
git restore cmake/platform/zephyr/Platform/PlatformTypes.h
git restore fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.cpp
git restore fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.hpp
```

⚠️ **Warning:** Reverting will cause:
- Packet merging issues in Linux UART receivers
- Buffer overflow risks
- File system compilation failures

**Create Patch File:**
```bash
cd fprime-zephyr
git diff > ../fprime-zephyr-enhancements.patch
# Apply later with: git apply fprime-zephyr-enhancements.patch
```

### Data Flow Architecture

**How packets flow through the system:**

```
UART Hardware (STM32)
    ↓
Drv::ZephyrUartDriver (transmits with 5ms inter-packet delay)
    ↓
UART Line (115200 baud)
    ↓
Linux UART (/dev/ttyACM0 with VMIN=0)
    ↓
Receives packets separated by 5ms delay
    ↓
Svc::GenericHub (validates and processes F´ packets)
    ↓
F´ Components (commands, telemetry, events)
```

The combination of ZephyrUartDriver delays (STM32 side) and GenericHub validation (RPi/GDS side) ensures robust, production-ready communication.

---

## 📚 Architecture

## 📚 Architecture

### Version Information

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

### System Overview

This deployment uses F´ **subtopology pattern** for modular system architecture:

#### CdhCore Subtopology (Command & Data Handling)
- **cmdDisp** - Command dispatcher
- **eventLogger** - Event logging
- **tlmSend** - Telemetry packetization  
- **fatalHandler** - Fatal error handling
- **rateGroup** - Component scheduling

#### ComCcsds Subtopology (CCSDS Communication)
- **comQueue** - Uplink/downlink queue
- **comStub** - Byte stream framing
- **frameAccumulator** - CCSDS frame deframing
- **bufferManager** - Memory pool management

#### Communication Flow
```
UART (usart3) ↔ commDriver ↔ comStub ↔ frameAccumulator ↔ comQueue
                                                              ↓
                                                         cmdDisp/tlmSend
```

**Framing Protocol:** CCSDS Space Packet over Space Data Link

---

## ⚡ Quick Start

**One-Command Build and Flash (STM32 Nucleo H7A3ZI-Q)**

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

# 5. Build firmware (Choose Option A or B)

# Option A: Using external Zephyr (if you have it installed)
export ZEPHYR_BASE=/path/to/your/zephyr/zephyrproject/zephyr
export ZEPHYR_SDK_INSTALL_DIR=/path/to/your/zephyr-sdk-0.17.4
export ZEPHYR_MODULES="/path/to/modules/cmsis_6;/path/to/modules/cmsis;/path/to/hal/stm32;/path/to/hal/cmsis"
fprime-util generate -DBOARD=nucleo_h7a3zi_q

# Option B: Using local west workspace (self-contained)
unset ZEPHYR_BASE
west init -l .
west update  # Downloads Zephyr v4.3.0 (~2GB, 10-20 min)
fprime-util generate -DBOARD=nucleo_h7a3zi_q

# 6. Build and generate dictionary
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary

# 7. Flash to board
sudo st-flash --connect-under-reset write build-fprime-automatic-zephyr/zephyr/zephyr.bin 0x08000000

# 8. Run Ground Data System
sudo chmod 0777 /dev/ttyACM0
fprime-gds -n \
  --dictionary ./build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json \
  --communication-selection uart \
  --uart-device /dev/ttyACM0 \
  --uart-baud 115200 \
  --framing-selection space-packet-space-data-link
```

**Verify GDS Connection:**

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

## 🔌 Hardware Support

| Board | Status | Notes |
|-------|--------|-------|
| **STM32 Nucleo H7A3ZI-Q** | ✅ Fully Tested | Complete GDS communication, all features working |
| **Teensy 4.1** | ✅ Tested | Requires custom board overlay |
| **Teensy 4.0** | ⚠️ Partial | May need additional configuration |

**Other boards:** See [Zephyr Supported Boards](https://docs.zephyrproject.org/latest/boards/index.html). You'll need to create a board overlay in `boards/` directory.

**Building for Different Boards:**

To switch to a different board:

```bash
# Clean build cache
fprime-util purge

# Generate for new board
fprime-util generate -DBOARD=teensy41

# Build
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary
```

---

## 📚 GDS Dictionary Setup

### What is a Dictionary?

The F´ dictionary is a JSON file that allows the Ground Data System (GDS) to interpret:
- **Commands**: Available commands and their parameters
- **Events**: Event definitions and severity levels
- **Telemetry**: Channel names, types, and units
- **Component Instances**: Deployed components and their IDs

### Generating the Dictionary

The dictionary must be generated after building the firmware:

```bash
# From project root
source .venv/bin/activate
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary
```

**What this does:**
1. Runs F´ autocoding: **FPP files → fpp-to-xml → fpp-to-dict → JSON dictionary**
2. Processes all component definitions
3. Generates: `build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json`

### Dictionary Location

**Generated dictionary:**
```
build-fprime-automatic-zephyr/
└── LedBlinker/Top/
    └── LedBlinkerTopologyDictionary.json  # ~97KB
```

**⚠️ Important:** Always use the dictionary from `build-fprime-automatic-zephyr/`, not from `build-artifacts/` (which contains only a stub).

### Using the Dictionary with GDS

When starting GDS, specify the dictionary path:

```bash
fprime-gds -n \
  --dictionary ./build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json \
  --communication-selection uart \
  --uart-device /dev/ttyACM0 \
  --uart-baud 115200 \
  --framing-selection space-packet-space-data-link
```

### Regenerating After Code Changes

**When to regenerate:**
- After modifying component FPP files
- After adding/removing commands, events, or telemetry
- After changing component instances or topology
- After clean builds

**How to regenerate:**
```bash
# Quick regeneration (if build is up-to-date)
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary

# Full rebuild + dictionary
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary
```

### Troubleshooting Dictionary Issues

**Problem:** Dictionary generation fails  
**Solution:** Ensure build completed successfully
```bash
# Check build artifacts exist
ls build-fprime-automatic-zephyr/LedBlinker/Top/

# Rebuild if needed
fprime-util build -j4
```

**Problem:** GDS shows "unknown command"  
**Solution:** Dictionary is stale or incorrect
```bash
# Regenerate dictionary
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary

# Restart GDS with correct path
fprime-gds -n --dictionary ./build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json ...
```

---

## 🏗️ Building the Firmware

### Build Approaches

This project supports two build approaches:

#### **Option 1: Using External Zephyr Installation (Recommended)**

If you have Zephyr installed externally, use this approach:

```bash
# Set Zephyr environment variables (adjust paths to your installation)
export ZEPHYR_BASE=/home/swayamshreemohanty/Documents/libraries/zephyr/zephyrproject/zephyr
export ZEPHYR_SDK_INSTALL_DIR=/home/swayamshreemohanty/Documents/libraries/zephyr/zephyr-sdk-0.17.4
export ZEPHYR_MODULES="/home/swayamshreemohanty/Documents/libraries/zephyr/zephyrproject/zephyr/modules/cmsis_6;/home/swayamshreemohanty/Documents/libraries/zephyr/zephyrproject/zephyr/modules/cmsis;/home/swayamshreemohanty/Documents/libraries/zephyr/zephyrproject/modules/hal/stm32;/home/swayamshreemohanty/Documents/libraries/zephyr/zephyrproject/modules/hal/cmsis"

# Navigate to project and build
cd /home/swayamshreemohanty/Documents/work/serendipityspace/fprime-zephyr-led-blinker
source .venv/bin/activate
fprime-util generate -DBOARD=nucleo_h7a3zi_q
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary
```

**Advantages:** Uses shared Zephyr installation, saves disk space, faster if already downloaded.

#### **Option 2: Using Local West Workspace**

If you prefer a self-contained project:

```bash
# Ensure ZEPHYR_BASE is NOT set
unset ZEPHYR_BASE
unset ZEPHYR_SDK_INSTALL_DIR
unset ZEPHYR_MODULES

# Initialize local west workspace
west init -l .
west update  # Downloads Zephyr v4.3.0 (~2GB)

# Build
source .venv/bin/activate
fprime-util generate -DBOARD=nucleo_h7a3zi_q
fprime-util build -j4
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary
```

**Advantages:** Self-contained, easier for beginners, project-specific Zephyr version.

---

### Detailed Build Steps

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

```bash
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary
```

This runs F' autocoding: **FPP files → fpp-to-xml → fpp-to-dict → JSON dictionary**

### 5. Verify Build Output

```bash
# Check binary
ls -lh build-fprime-automatic-zephyr/zephyr/zephyr.bin

# Check dictionary
ls -lh build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json
```

**Build artifacts:**
```
build-fprime-automatic-zephyr/
├── LedBlinker/Top/
│   └── LedBlinkerTopologyDictionary.json  # GDS dictionary (~97KB)
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
ninja -C build-fprime-automatic-zephyr LedBlinker_Top_dictionary
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

## 🚀 Running F' GDS

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
  --dictionary ./build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json \
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

## ⚙️ Configuration Files

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

**LedBlinker/Top/topology.fpp** - Component connections:
- Rate group scheduling
- Command/event routing  
- UART framing pipeline
- Buffer allocation

**LedBlinker/Top/instances.fpp** - Component instances:
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

This project uses **F´'s configuration override system** to customize framework behavior without modifying F´ core files. All deployment-specific configuration is in `LedBlinker/config/`:

- `CMakeLists.txt` - Registers configuration overrides with `register_fprime_config()`
- `PlatformCfg.fpp` - Overrides platform constants (e.g., task handle sizes)
- `CdhCoreConfig.fpp` - CdhCore subtopology configuration
- `ComCcsdsConfig.fpp` - ComCcsds subtopology configuration

**Benefits:**
- ✅ Keeps F´ framework pristine (no git conflicts on updates)
- ✅ Deployment-specific settings isolated in one location
- ✅ Easy to maintain and version control
- ✅ Follows F´ best practices

**Note:** The F´ framework files in `fprime/default/config/` remain unmodified and use default values. Project overrides in `LedBlinker/config/` take precedence during build.

---

## 📂 Project Structure
default_toolchain: zephyr
library_locations: ./fprime-zephyr
```

### Configuration Override System

This project uses **F´'s configuration override system** to customize framework behavior without modifying F´ core files. All deployment-specific configuration is in `LedBlinker/config/`:

- `CMakeLists.txt` - Registers configuration overrides with `register_fprime_config()`
- `PlatformCfg.fpp` - Overrides platform constants (e.g., task handle sizes)
- `CdhCoreConfig.fpp` - CdhCore subtopology configuration
- `ComCcsdsConfig.fpp` - ComCcsds subtopology configuration

**Benefits:**
- ✅ Keeps F´ framework pristine (no git conflicts on updates)
- ✅ Deployment-specific settings isolated in one location
- ✅ Easy to maintain and version control
- ✅ Follows F´ best practices

**Note:** The F´ framework files in `fprime/default/config/` remain unmodified and use default values. Project overrides in `LedBlinker/config/` take precedence during build.

---

## 📂 Project Structure

```
fprime-zephyr-led-blinker/
├── fprime/                                    # F' framework (v4.1.1)
│   ├── Svc/GenericHub/GenericHub.cpp          # MODIFIED: Enhanced packet validation
│   └── default/config/                        # Framework defaults (unmodified)
├── fprime-zephyr/                             # Zephyr integration with F'
│   ├── cmake/platform/zephyr/
│   │   └── Platform/PlatformTypes.h           # MODIFIED: POSIX SEEK_* compatibility
│   └── fprime-zephyr/Drv/ZephyrUartDriver/
│       ├── ZephyrUartDriver.cpp               # MODIFIED: Inter-packet delay
│       └── ZephyrUartDriver.hpp               # MODIFIED: Increased buffer sizes
├── zephyr/                                    # Zephyr RTOS v4.3.0 (from west update)
├── Components/
│   └── Stm32Led/                              # LED component implementation
├── LedBlinker/
│   ├── Main.cpp                               # Application entry point
│   ├── Stub.cpp                               # Platform stubs
│   ├── Top/                                   # Topology definition
│   │   ├── topology.fpp                      # Component connections
│   │   ├── instances.fpp                     # Component instances
│   │   ├── LedBlinkerTopology.cpp       # Topology implementation
│   │   ├── LedBlinkerTopology.hpp       # Topology header
│   │   ├── LedBlinkerTopologyDefs.hpp   # Type definitions & state
│   │   └── LedBlinkerPackets.xml        # Telemetry packet definitions
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
│   ├── LedBlinker/Top/
│   │   └── LedBlinkerTopologyDictionary.json  # GDS dictionary
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

**Key Modified Files:**
1. **fprime/Svc/GenericHub/GenericHub.cpp** - Packet validation, error handling
2. **fprime-zephyr/fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.cpp** - 5ms inter-packet delay
3. **fprime-zephyr/fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.hpp** - Buffer size increases
4. **fprime-zephyr/cmake/platform/zephyr/Platform/PlatformTypes.h** - POSIX file system compatibility

---

## 🔧 Troubleshooting

### Build Issues

#### Build Configuration Issues

**Choose your build approach first:**

**If using external Zephyr:** Set environment variables before building:
```bash
export ZEPHYR_BASE=/path/to/your/zephyr/zephyrproject/zephyr
export ZEPHYR_SDK_INSTALL_DIR=/path/to/your/zephyr-sdk-0.17.4
export ZEPHYR_MODULES="/path/to/modules/..."
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```

**If using local west workspace:** Unset all Zephyr variables:
```bash
unset ZEPHYR_BASE
unset ZEPHYR_SDK_INSTALL_DIR
unset ZEPHYR_MODULES
west init -l .
west update
fprime-util generate -DBOARD=nucleo_h7a3zi_q
```
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

**0. Correct command syntax:**
```bash
# ❌ WRONG (Windows port names won't work on Linux)
fprime-gds -n --dictionary ./build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json --comm-adapter uart --uart-device COM3 --uart-baud 115200

# ✅ CORRECT (Linux/Raspberry Pi)
fprime-gds -n \
  --dictionary ./build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json \
  --communication-selection uart \
  --uart-device /dev/ttyACM0 \
  --uart-baud 115200 \
  --framing-selection space-packet-space-data-link
```
**Common mistakes:**
- Using `COM3` (Windows) instead of `/dev/ttyACM0` (Linux)
- Using `--comm-adapter` instead of `--communication-selection`
- Missing `--framing-selection space-packet-space-data-link`

**1. Verify UART device** in `LedBlinker/Main.cpp`:
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
--dictionary ./build-fprime-automatic-zephyr/LedBlinker/Top/LedBlinkerTopologyDictionary.json
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

## ✅ Success Checklist

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

## 📚 Additional Resources

### F´ Framework
- **F´ Documentation:** https://nasa.github.io/fprime/
- **F´ User Guide:** https://nasa.github.io/fprime/UsersGuide/guide.html
- **F´ GitHub:** https://github.com/nasa/fprime
- **F´ Tutorial:** https://nasa.github.io/fprime/Tutorials/

### Zephyr RTOS
- **Zephyr Documentation:** https://docs.zephyrproject.org/
- **Zephyr Supported Boards:** https://docs.zephyrproject.org/latest/boards/index.html
- **Zephyr GitHub:** https://github.com/zephyrproject-rtos/zephyr
- **West Tool Guide:** https://docs.zephyrproject.org/latest/develop/west/index.html

### fprime-zephyr Integration
- **fprime-zephyr GitHub:** https://github.com/fprime-community/fprime-zephyr
- **fprime-zephyr Documentation:** https://github.com/fprime-community/fprime-zephyr/blob/main/README.md

### Hardware References
- **STM32H7A3ZI Reference:** https://www.st.com/en/microcontrollers-microprocessors/stm32h7a3zi.html
- **Nucleo H7A3ZI-Q Board:** https://www.st.com/en/evaluation-tools/nucleo-h7a3zi-q.html
- **Teensy 4.1:** https://www.pjrc.com/store/teensy41.html

### Development Tools
- **ST-Link Tools:** https://github.com/stlink-org/stlink
- **Teensy Loader:** https://www.pjrc.com/teensy/loader.html

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the [Success Checklist](#-success-checklist)
5. Submit a pull request

**Areas for contribution:**
- Additional board support (new overlays)
- Documentation improvements
- Bug fixes and enhancements
- Component examples
- Performance optimizations

---

## 📄 License

This project follows the F´ framework licensing (Apache 2.0).

---

## 📝 Summary of Changes

This project enhances the standard F´ and fprime-zephyr libraries with production-ready modifications:

### F´ Library Changes (fprime/)
- **GenericHub.cpp**: Packet validation, graceful error handling
- Prevents crashes on corrupted UART data
- Enables production deployment with robust error recovery

### fprime-zephyr Library Changes (fprime-zephyr/)
- **ZephyrUartDriver.cpp**: 5ms inter-packet delay for Linux UART compatibility
- **ZephyrUartDriver.hpp**: Increased buffers (1024/4096 bytes) for F´ packet sizes
- **PlatformTypes.h**: POSIX file system compatibility (SEEK_* macros)
- Ensures reliable UART communication with Ground Data System

**Why These Changes Matter:**
- Standard libraries crash or fail on real-world UART conditions
- These modifications enable reliable, production-ready embedded flight software
- Proven in testing with STM32 Nucleo and GDS communication
- Essential for mission-critical applications where crashes are unacceptable

---

**Last Updated:** January 22, 2026  
**Tested Platforms:** Ubuntu 22.04, Debian 12, Raspberry Pi OS  
**Target Boards:** STM32 Nucleo H7A3ZI-Q, Teensy 4.1, Teensy 4.0  
**Maintainers:** fprime-community  
**Maintainers:** fprime-community