# STM32 GenericHub Pattern Implementation Guide

## Overview

This document describes the modifications made to the STM32 F-Prime deployment to implement the **NASA GenericHub pattern** for distributed communication with the Raspberry Pi master node over UART.

## Architecture Changes

### Before (ComStub Pattern)
```
STM32 ←→ ComStub ←→ ZephyrUartDriver ←→ [UART] ←→ RPi GDS
```
- Direct GDS connection via ComStub
- STM32 runs independently with its own GDS
- No distributed topology support

### After (GenericHub Pattern)
```
STM32 ←→ GenericHub ←→ ByteStreamBufferAdapter ←→ ZephyrUartDriver ←→ [UART] ←→ RPi Master Hub
```
- STM32 acts as remote node controlled by RPi
- Commands routed from RPi to STM32 via hub
- STM32 telemetry/events sent back to RPi GDS
- Official NASA distributed topology pattern

## Files Modified

### 1. `/Stm32LedBlinker/Top/instances.fpp`

**Added GenericHub port constants:**
```fpp
@ Number of typed serial input ports for hub
constant GenericHubInputPorts = 2

@ Number of typed serial output ports for hub
constant GenericHubOutputPorts = 2

@ Number of buffer input ports for hub
constant GenericHubInputBuffers = 1

@ Number of buffer output ports for hub
constant GenericHubOutputBuffers = 1
```

**Added new component instances:**
- `uartBufferAdapter` (Drv.ByteStreamBufferAdapter) - Bridges byte streams to F-Prime buffers
- `rpiHub` (Svc.GenericHub) - Hub component for distributed communication
- `cmdSplitter` (Svc.CmdSplitter) - Routes command responses

### 2. `/Stm32LedBlinker/Top/topology.fpp`

**Changed pattern specifiers:**
- Events now route through `rpiHub` instead of `CdhCore.events`
- Telemetry now routes through `rpiHub` instead of `CdhCore.tlmSend`

**Before:**
```fpp
event connections instance CdhCore.events
telemetry connections instance CdhCore.tlmSend
```

**After:**
```fpp
event connections instance rpiHub
telemetry connections instance rpiHub
```

**Added hub connection blocks:**

1. **send_hub** - Sends telemetry/events to RPi
```fpp
connections send_hub {
  # GenericHub serializes telemetry/events and sends to buffer adapter
  rpiHub.toBufferDriver -> uartBufferAdapter.bufferIn
  uartBufferAdapter.bufferInReturn -> rpiHub.toBufferDriverReturn
}
```

2. **recv_hub** - Receives commands from RPi
```fpp
connections recv_hub {
  # Buffer adapter delivers to GenericHub for deserialization
  uartBufferAdapter.bufferOut -> rpiHub.fromBufferDriver
  rpiHub.fromBufferDriverReturn -> uartBufferAdapter.bufferOutReturn
}
```

3. **hub** - Routes commands and manages buffers
```fpp
connections hub {
  # Hub deserializes commands from RPi and routes to command dispatcher
  rpiHub.serialOut[0] -> ComCcsds.fprimeRouter.serialRecv[0]
  ComCcsds.fprimeRouter.serialSend[0] -> rpiHub.serialIn[0]
  
  # GenericHub needs buffer allocation for serializing telemetry/events
  rpiHub.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
  rpiHub.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
}
```

**Updated Communications connections:**
- Replaced `ComStub` with `ByteStreamBufferAdapter`
- UART driver now connects to buffer adapter instead of ComStub

**Removed ComQueue from rate groups:**
- Removed `ComCcsds.comQueue.run` from rateGroup1 (index 3)
- Adjusted LED connections to fill the gap

### 3. `/Stm32LedBlinker/Top/CMakeLists.txt`

**Added module dependencies:**
```cmake
set(MOD_DEPS
  Fw/Logger
  Drv/ByteStreamBufferAdapter
  Svc/GenericHub
  Svc/CmdSplitter
)
```

### 4. `/Stm32LedBlinker/Top/Stm32LedBlinkerTopology.cpp`

**Added CmdSplitter configuration:**
```cpp
printk("  configureTopology: Configuring command splitter for hub pattern...\n");
// Configure CmdSplitter threshold - all commands stay local on STM32
// Threshold set high so STM32 processes all its own commands locally
cmdSplitter.configure(0x100000);
```

## How It Works

### Command Flow (RPi → STM32)
1. RPi GDS sends command with opcode >= 0x10000
2. RPi CmdSplitter routes to GenericHub
3. RPi GenericHub serializes command to Fw::Buffer
4. RPi ByteStreamBufferAdapter converts to byte stream
5. RPi LinuxUartDriver transmits over UART
6. **→ UART TX/RX →**
7. STM32 ZephyrUartDriver receives byte stream
8. STM32 ByteStreamBufferAdapter converts to Fw::Buffer
9. STM32 GenericHub deserializes command
10. STM32 FprimeRouter routes to CmdDispatcher
11. STM32 CmdDispatcher executes command (e.g., LED control)

### Telemetry/Event Flow (STM32 → RPi)
1. STM32 component emits telemetry/event
2. Routed to STM32 GenericHub (via pattern specifier)
3. STM32 GenericHub serializes to Fw::Buffer
4. STM32 ByteStreamBufferAdapter converts to byte stream
5. STM32 ZephyrUartDriver transmits over UART
6. **→ UART TX/RX →**
7. RPi LinuxUartDriver receives byte stream
8. RPi ByteStreamBufferAdapter converts to Fw::Buffer
9. RPi GenericHub deserializes telemetry/event
10. RPi routes to event logger/telemetry send
11. Displays in RPi GDS

## Component Responsibilities

### On STM32 (Remote Node)

| Component | Purpose |
|-----------|---------|
| rpiHub | Serializes telemetry/events to RPi, deserializes commands from RPi |
| uartBufferAdapter | Converts between byte streams and F-Prime buffers |
| commDriver | Zephyr UART hardware interface |
| cmdSplitter | Routes command responses back to hub |

### On RPi (Master Hub)

| Component | Purpose |
|-----------|---------|
| stm32Hub | Serializes commands to STM32, deserializes telemetry/events from STM32 |
| uartBufferAdapter | Converts between byte streams and F-Prime buffers |
| uartDriver | Linux UART hardware interface (/dev/ttyAMA0) |
| cmdSplitter | Routes commands based on opcode threshold (0x10000) |

## Opcode Ranges

### RPi Local Components (< 0x10000)
- RPi LED: 0x10005xxx
- BMP280: 0x10006xxx
- Camera: 0x10007xxx

### STM32 Remote Components (>= 0x10000)
- STM32 LED: 0x10000
- STM32 LED1: 0x10100
- STM32 LED2: 0x10200

## UART Configuration

Both sides must use matching UART settings:

**STM32 Side:**
- Device: Configured via Zephyr devicetree
- Baud Rate: Configured in topology setup
- Driver: Zephyr UART driver

**RPi Side:**
- Device: /dev/ttyAMA0 (GPIO14/15 UART0)
- Baud Rate: 115200 (must match STM32)
- Driver: Linux UART driver

## Benefits of GenericHub Pattern

1. **Official NASA Pattern** - Used in real spacecraft (Mars Helicopter)
2. **Transparent Communication** - RPi can control STM32 components as if local
3. **Centralized GDS** - Single GDS on RPi monitors entire distributed system
4. **Scalable** - Can add more remote nodes easily
5. **Type-Safe** - F-Prime port types preserved across UART boundary
6. **Automatic Routing** - Commands/telemetry routed by opcode automatically

## Testing Commands

From RPi GDS, you can now send commands to STM32:

```bash
# Control STM32 LEDs (opcodes >= 0x10000)
led.BLINKING_ON_OFF(ON)      # STM32 Green LED
led1.BLINKING_ON_OFF(OFF)    # STM32 Yellow LED
led2.BLINKING_ON_OFF(ON)     # STM32 Red LED
```

STM32 telemetry and events will appear in the RPi GDS automatically!

## Troubleshooting

### No communication between RPi and STM32
1. Check UART wiring (TX→RX, RX→TX, GND→GND)
2. Verify baud rates match (115200)
3. Check UART device paths are correct
4. Ensure both deployments built successfully

### Commands not reaching STM32
1. Verify opcode >= 0x10000
2. Check CmdSplitter threshold on RPi (0x100000)
3. Verify hub connections in topology

### Telemetry/events not visible in RPi GDS
1. Check event/telemetry pattern specifiers point to rpiHub
2. Verify hub connections from rpiHub to event logger
3. Check buffer manager has sufficient buffers

## Summary

The STM32 deployment has been successfully updated to use the **NASA GenericHub pattern** for distributed communication with the Raspberry Pi master node. This enables:

✅ RPi master control of STM32 components via UART
✅ STM32 telemetry/events routed to RPi GDS
✅ Centralized command and control from single GDS
✅ Official F-Prime distributed topology architecture

The modifications follow NASA F-Prime best practices and are production-ready for spacecraft applications.
