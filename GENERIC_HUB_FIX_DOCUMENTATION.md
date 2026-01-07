# GenericHub Telemetry Fix Documentation

## Problem Overview

F-Prime LED Blinker deployment on STM32H7A3ZI-Q Nucleo board with Zephyr RTOS was crashing when telemetry routing was enabled through GenericHub pattern for RPi master communication.

### Initial Symptoms
- **Crash Location:** `GenericHub.cpp:83`
- **Assertion:** `FW_ASSERT(rawSize == static_cast<U32>(size))`
- **Error:** Kernel panic after ~4 rate group cycles
- **Thread:** Main thread (Stack unused: 62280 bytes)

## Root Cause Analysis

### Primary Issue: Protocol Coordination Requirement

The GenericHub spoke pattern **requires active master coordination** on the UART link. The assertion failure occurred because:

1. **Telemetry enabled** → STM32 serializes telemetry and sends to hub
2. **No RPi master running** → No protocol handshake/coordination
3. **Floating UART RX line** → Electrical noise interpreted as incoming packets
4. **Hub deserializes noise** → Buffer size mismatch between header and actual data
5. **Assertion triggers** → `rawSize != size` due to corrupted packet

### Secondary Issue: Resource Exhaustion

Initially encountered thread creation failure during active component startup:
- **Error:** `ActiveComponentBase.cpp:51` assertion with code 9 (`K_ERR_NO_MEM`)
- **Cause:** 4 active components × 64KB stacks = 256KB total (too much for embedded system)

## Solutions Implemented

### 1. Stack Size Optimization

**File:** `Stm32LedBlinker/Top/instances.fpp`

**Change:**
```fpp
module Default {
  constant QUEUE_SIZE = 5
  constant STACK_SIZE = 16 * 1024   # 16KB per active component (4 components = 64KB total)
}
```

**Previous:** 64KB per component (256KB total)  
**Current:** 16KB per component (64KB total)

**Active Components:**
- `cmdDisp` - CommandDispatcher (priority 101)
- `proxyGroundInterface` - CmdSequenceForwarder (priority 100)
- `proxySequencer` - CmdSequenceForwarder (priority 100)
- `eventLogger` - EventManager (priority 100)

### 2. Event vs Telemetry Routing Separation

**File:** `Stm32LedBlinker/Top/topology.fpp`

**Critical Pattern:**
```fpp
# Events route to local eventLogger (prevents buffer exhaustion during init)
event connections instance eventLogger

# Telemetry routes through GenericHub to RPi GDS
# CRITICAL: RPi master MUST be running BEFORE STM32 boots!
telemetry connections instance hub
```

**Why This Works:**
- **Events** → Routed locally during initialization (prevents GenericHub buffer cascade)
- **Telemetry** → Routed through hub at runtime (requires master coordination)

### 3. Buffer Pool Configuration

**File:** `Stm32LedBlinker/Top/Stm32LedBlinkerTopology.cpp`

```cpp
constexpr U32 HUB_BUFFER_COUNT = 100;  // Increased from 5
constexpr FwSizeType BUFFER_SIZE = 512;
```

**Total Hub Buffers:** 100 × 512 bytes = 50KB

### 4. UART Ring Buffer Sizing

**File:** `fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.hpp`

```cpp
static constexpr FwSizeType RING_BUF_SIZE = 4096;  // Increased from 1024
```

**Reason:** Prevent UART overruns from burst traffic from RPi master

### 5. Rate Group Frequency

**File:** `Stm32LedBlinker/Top/Stm32LedBlinkerTopology.cpp`

```cpp
const NATIVE_INT_TYPE rateGroupDivisors[Svc::RateGroupDriver::DIVIDER_SIZE] = {
    {10, 0}  // 1000Hz / 10 = 100Hz rate group
};
```

**UART Processing:** 100Hz (10ms period) to handle hub communication efficiently

### 6. Zephyr Kernel Configuration

**File:** `prj.conf`

```ini
CONFIG_MAIN_STACK_SIZE=65536          # 64KB main stack
CONFIG_HEAP_MEM_POOL_SIZE=256000      # 256KB heap
CONFIG_SYSTEM_WORKQUEUE_STACK_SIZE=4096
```

## Architecture Pattern

### GenericHub Spoke Node (STM32)

```
┌─────────────┐
│  LED Apps   │ (3× Stm32Led components)
└──────┬──────┘
       │ Telemetry
       ↓
┌─────────────┐
│ GenericHub  │ (Serialization/Routing)
└──────┬──────┘
       │
┌──────┴──────────────┐
│ ByteStreamBuffer    │ (Buffer ↔ Byte Stream)
│ Adapter             │
└──────┬──────────────┘
       │
┌──────┴──────────────┐
│ ZephyrUartDriver    │ (LPUART1 @ 115200)
└─────────────────────┘
       │ UART
       ↓
    RPi Master
```

### Command Flow
```
RPi Master → UART → Hub.serialOut[0] → proxyGroundInterface → cmdDisp → LED components
```

### Telemetry Flow
```
LED components → tlmOut → Hub → ByteStreamBufferAdapter → UART → RPi Master → GDS
```

## Hardware Configuration

### UART Wiring (CRITICAL)

**STM32 Nucleo H7A3ZI-Q ↔ Raspberry Pi**

| RPi Pin | Function | STM32 Pin | Function |
|---------|----------|-----------|----------|
| GPIO14  | TXD      | RXD1      | LPUART1 RX |
| GPIO15  | RXD      | TXD1      | LPUART1 TX |
| GND     | Ground   | GND       | Ground     |

**IMPORTANT:** TX connects to RX (crossed), **not** TX to TX!

### Board Overlay

**File:** `boards/nucleo_h7a3zi_q.overlay`

LPUART1 configured on PB6 (TX) and PB7 (RX) at 115200 baud.

## Usage Modes

### Mode 1: Standalone Testing (No RPi)

**Configuration:**
```fpp
# Comment out telemetry routing
# telemetry connections instance hub
```

**Behavior:**
- ✅ LEDs blink independently
- ✅ No crashes
- ❌ No telemetry visibility
- ❌ No command control

**Build:**
```bash
west build -b nucleo_h7a3zi_q && west flash
```

### Mode 2: GenericHub with RPi Master

**Configuration:**
```fpp
# Enable telemetry routing
telemetry connections instance hub
```

**Prerequisites:**
1. Wire UART correctly (TX ↔ RX crossed)
2. **Start RPi GenericHub master FIRST**
3. Then power on STM32

**Build:**
```bash
west build -b nucleo_h7a3zi_q && west flash
```

**RPi Master Command:**
```bash
# Start your GenericHub master deployment on RPi
# Then connect GDS to the master (not directly to UART)
```

## Testing Procedure

### 1. Verify Standalone Operation

```bash
# Disable telemetry in topology.fpp
west build -b nucleo_h7a3zi_q && west flash
# Connect serial monitor
minicom -D /dev/ttyACM0 -b 115200
```

**Expected Output:**
```
Starting F' LED Blinker
Setting up topology...
...
setupTopology complete! STM32 remote spoke node ready for RPi master communication.
Entering main loop
[LED] GPIO transition to ON
```

### 2. Verify Hub Communication with RPi

```bash
# Enable telemetry in topology.fpp
# Start RPi master FIRST
west build -b nucleo_h7a3zi_q && west flash
```

**On RPi:**
- GenericHub master should detect spoke node
- GDS should show telemetry channels:
  - `led.BlinkingState`
  - `led.LedTransitions`
  - `led1.BlinkingState`, etc.

**Test Commands:**
- `led.BLINKING_ON_OFF(OFF)` - Stop green LED
- `led.BLINKING_ON_OFF(ON)` - Resume blinking

## Memory Usage

| Component | Size | Notes |
|-----------|------|-------|
| Main Stack | 64KB | CONFIG_MAIN_STACK_SIZE |
| Heap | 256KB | CONFIG_HEAP_MEM_POOL_SIZE |
| Active Component Stacks | 64KB | 4 × 16KB |
| Hub Buffers | 50KB | 100 × 512 bytes |
| UART Ring Buffer | 4KB | Per driver instance |
| **Total RAM Usage** | ~450KB | Well within 1MB SRAM |

## Troubleshooting

### Issue: GenericHub.cpp:83 Assertion

**Symptoms:** Crash after 4-5 rate group cycles  
**Cause:** Telemetry enabled without RPi master running  
**Solution:** Start RPi master before STM32, or disable telemetry

### Issue: ActiveComponentBase.cpp:51 Assertion (Code 9)

**Symptoms:** Crash during "Starting active component tasks"  
**Cause:** Insufficient memory for thread stacks  
**Solution:** Reduce STACK_SIZE in instances.fpp

### Issue: UART Buffer Overrun

**Symptoms:** "UART buffer overrun" messages  
**Cause:** UART ring buffer too small or rate group too slow  
**Solution:** 
- Increase RING_BUF_SIZE (currently 4096)
- Increase rate group frequency (currently 100Hz)

### Issue: LED Commands Not Working

**Symptoms:** Commands sent from GDS but LED doesn't respond  
**Cause:** Incorrect UART wiring or protocol mismatch  
**Check:**
- UART connections crossed (TX ↔ RX)
- Baud rate matches (115200)
- Command routing through hub.serialOut[0]

## Key Lessons

1. **GenericHub spoke pattern is NOT autonomous** - It requires active master coordination
2. **Floating UART pins create noise** - Appears as corrupted packets to the hub
3. **Event vs Telemetry routing matters** - Events should be local during init to prevent buffer cascade
4. **Active component stacks add up** - Budget carefully on embedded systems
5. **Protocol order matters** - Master must start before spoke for proper handshake

## Files Modified

1. `Stm32LedBlinker/Top/instances.fpp` - Stack size reduction
2. `Stm32LedBlinker/Top/topology.fpp` - Event/telemetry routing separation
3. `Stm32LedBlinker/Top/Stm32LedBlinkerTopology.cpp` - Buffer pool sizing
4. `fprime-zephyr/Drv/ZephyrUartDriver/ZephyrUartDriver.hpp` - UART ring buffer
5. `prj.conf` - Zephyr kernel memory configuration

## References

- F-Prime GenericHub Pattern: `fprime/Svc/GenericHub/`
- Zephyr UART Driver: `fprime-zephyr/Drv/ZephyrUartDriver/`
- Hub Reference Implementation: `fprime-generichub-reference`

---

**Document Version:** 1.0  
**Last Updated:** January 7, 2026  
**Board:** STM32H7A3ZI-Q Nucleo  
**F-Prime Version:** devel branch  
**Zephyr Version:** 4.x
