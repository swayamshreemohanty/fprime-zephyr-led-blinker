# GenericHub UART Implementation - Changes Documentation

## Overview
This document describes the changes made to implement the F-Prime GenericHub pattern for STM32-to-RPi UART communication, following the official [F-Prime GenericHub documentation](https://fprime.jpl.nasa.gov/latest/Svc/GenericHub/docs/sdd/).

## Architecture

### Final Architecture (Correct Implementation)
```
STM32 Spoke Node:
┌─────────────┐     ┌──────────────────────┐     ┌──────────────┐
│ GenericHub  │────▶│ByteStreamBuffer      │────▶│ ZephyrUart   │────▶ UART TX
│             │     │Adapter               │     │ Driver       │
│ (Fw.Buffer) │◀────│(Bridge Component)    │◀────│ (ByteStream) │◀──── UART RX
└─────────────┘     └──────────────────────┘     └──────────────┘
  Fw.BufferSend        Drv.ByteStreamSend
```

**Key Components:**
- **GenericHub**: Hub pattern multiplexer/demultiplexer (uses `Fw.BufferSend` ports)
- **ByteStreamBufferAdapter**: F-Prime standard bridge component between buffer and byte stream interfaces
- **ZephyrUartDriver**: Zephyr RTOS UART hardware driver (uses `Drv.ByteStreamSend` ports)

---

## What Was Removed

### 1. Custom UartBufferAdapter Component ❌
**Location**: `/Components/UartBufferAdapter/`

**Why Removed:**
- Custom implementation attempted to bridge `Fw.Buffer` to `Drv.ByteStreamSend`
- F-Prime already provides a standard component for this: `Drv::ByteStreamBufferAdapter`
- Custom implementation was incorrect (sent buffer object instead of buffer contents)

**Files Deleted:**
```
Components/UartBufferAdapter/UartBufferAdapter.fpp
Components/UartBufferAdapter/UartBufferAdapter.hpp
Components/UartBufferAdapter/UartBufferAdapter.cpp
Components/UartBufferAdapter/CMakeLists.txt
```

**Removed from Build System:**
```cmake
# Components/CMakeLists.txt - REMOVED
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/UartBufferAdapter")
```

---

### 2. CmdSequenceForwarder Component ❌
**Location**: `/Components/CmdSequenceForwarder/`

**Why Removed:**
- Not needed for spoke node pattern
- Commands route directly through GenericHub from RPi master
- Added unnecessary complexity

**Files Deleted:**
```
Components/CmdSequenceForwarder/CmdSequenceForwarder.fpp
Components/CmdSequenceForwarder/CmdSequenceForwarder.hpp
Components/CmdSequenceForwarder/CmdSequenceForwarder.cpp
Components/CmdSequenceForwarder/CMakeLists.txt
```

**Removed from Build System:**
```cmake
# Components/CMakeLists.txt - REMOVED
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/CmdSequenceForwarder")
```

---

### 3. Proxy Components ❌
**Removed Instances:**
- `proxyGroundInterface`
- `proxySequencer`

**Why Removed:**
- Not part of standard spoke node pattern
- GenericHub handles all routing to/from RPi master
- Simplified topology significantly

**Removed from:**
```fpp
# Stm32LedBlinker/Top/instances.fpp - REMOVED
instance proxyGroundInterface: Svc.GenericHubProxy
instance proxySequencer: Svc.GenericHubProxy
```

---

### 4. Invalid Configuration Constants ❌
**Location**: `Stm32LedBlinker/Top/instances.fpp`

**Removed:**
```fpp
constant GenericHubInputBuffers = 0
constant GenericHubOutputBuffers = 0
```

**Why Removed:**
- These constants don't belong in `instances.fpp`
- GenericHub configuration is defined in `config/GenericHubCfg.fpp`
- Setting to 0 was incorrect for standard hub pattern

---

## What Was Implemented

### 1. F-Prime Standard ByteStreamBufferAdapter ✅
**Component**: `Drv::ByteStreamBufferAdapter`

**Purpose:**
Bridges between two interface types:
- **GenericHub side**: `Fw.BufferSend` (PassiveBufferDriver interface)
- **UART side**: `Drv.ByteStreamSend` (ByteStreamDriver interface)

**Added Instance:**
```fpp
# Stm32LedBlinker/Top/instances.fpp
@ ByteStreamBufferAdapter - Bridges GenericHub (BufferSend) to UART (ByteStreamSend)
instance bufferAdapter: Drv.ByteStreamBufferAdapter base id REMOTE_TOPOLOGY_BASE + 0x100100
```

**Why This Works:**
- Standard F-Prime component designed specifically for this use case
- Automatically handles buffer-to-bytestream conversion
- Includes error handling events (DriverNotReady, DataSendError, DataReceiveError)

---

### 2. Standard GenericHub Configuration ✅
**Location**: `Stm32LedBlinker/config/GenericHubCfg.fpp`

**Updated Configuration:**
```fpp
module Svc {
  module GenericHubCfg {
    @ Hub connections. Connections on all deployments should mirror these settings.
    constant NumSerialInputPorts = 10    # Was: 2
    constant NumSerialOutputPorts = 10   # Was: 2
    constant NumBufferInputPorts = 10    # Was: 1
    constant NumBufferOutputPorts = 10   # Was: 1
  }
}
```

**Why Changed to 10:**
- Matches F-Prime GenericHub documentation standard
- Allows multiple simultaneous port connections
- Must match RPi master side configuration
- Serial ports: for typed port calls (commands, events, telemetry)
- Buffer ports: for Fw::Buffer data (file transfers, data products)

---

### 3. Correct Topology Connections ✅

#### Hub ↔ ByteStreamBufferAdapter Connections
```fpp
connections HubToAdapter {
  # Hub -> ByteStreamBufferAdapter (downlink/TX)
  hub.toBufferDriver -> bufferAdapter.bufferIn
  bufferAdapter.bufferInReturn -> hub.toBufferDriverReturn
  
  # ByteStreamBufferAdapter -> Hub (uplink/RX)
  bufferAdapter.bufferOut -> hub.fromBufferDriver
  hub.fromBufferDriverReturn -> bufferAdapter.bufferOutReturn
}
```

**Port Types:**
- `toBufferDriver` / `bufferIn`: `Fw.BufferSend`
- `fromBufferDriver` / `bufferOut`: `Fw.BufferSend`

---

#### ByteStreamBufferAdapter ↔ UART Connections
```fpp
connections AdapterToUart {
  # ByteStreamBufferAdapter -> UART Driver (TX)
  bufferAdapter.toByteStreamDriver -> uartDriver.$send
  
  # UART Driver -> ByteStreamBufferAdapter (RX)
  uartDriver.$recv -> bufferAdapter.fromByteStreamDriver
  bufferAdapter.fromByteStreamDriverReturn -> uartDriver.recvReturnIn
  
  # UART ready signal to adapter
  uartDriver.ready -> bufferAdapter.byteStreamDriverReady
}
```

**Port Types:**
- `toByteStreamDriver` / `$send`: `Drv.ByteStreamSend`
- `fromByteStreamDriver` / `$recv`: `Drv.ByteStreamData`

---

#### ByteStreamBufferAdapter Event/Time Connections
```fpp
connections BufferAdapterConnections {
  bufferAdapter.Log -> eventLogger.LogRecv
  bufferAdapter.LogText -> textLogger.TextLogger
  bufferAdapter.Time -> chronoTime.timeGetPort
}
```

---

#### Buffer Management Connections
```fpp
connections HubBufferManagement {
  # Hub buffer allocation/deallocation
  hub.allocate -> bufferManager.bufferGetCallee
  hub.deallocate -> bufferManager.bufferSendIn
  
  # UART driver buffer allocation/deallocation
  uartDriver.allocate -> bufferManager.bufferGetCallee
  uartDriver.deallocate -> bufferManager.bufferSendIn
}
```

**Note:** ByteStreamBufferAdapter does NOT have allocate/deallocate ports - it's a passive bridge only.

---

## Port Interface Details

### GenericHub Ports (PassiveBufferDriverClient)
```fpp
# Send Interface (to driver)
output port toBufferDriver: Fw.BufferSend
sync input port toBufferDriverReturn: Fw.BufferSend

# Receive Interface (from driver)
sync input port fromBufferDriver: Fw.BufferSend
output port fromBufferDriverReturn: Fw.BufferSend
```

### ByteStreamBufferAdapter Ports

**PassiveBufferDriver Side (Hub-facing):**
```fpp
sync input port bufferIn: Fw.BufferSend
output port bufferInReturn: Fw.BufferSend
output port bufferOut: Fw.BufferSend
sync input port bufferOutReturn: Fw.BufferSend
```

**PassiveByteStreamDriverClient Side (UART-facing):**
```fpp
output port toByteStreamDriver: Drv.ByteStreamSend
sync input port fromByteStreamDriver: Drv.ByteStreamData
output port fromByteStreamDriverReturn: Fw.BufferSend
sync input port byteStreamDriverReady: Drv.ByteStreamReady
```

### ZephyrUartDriver Ports (ByteStreamDriver)
```fpp
guarded input port $send: Drv.ByteStreamSend
output port $recv: Drv.ByteStreamData
sync input port recvReturnIn: Fw.BufferSend
output port ready: Drv.ByteStreamReady
```

---

## Key Lessons Learned

### 1. Use F-Prime Standard Components
❌ **Wrong:** Creating custom bridge components  
✅ **Right:** Use `Drv::ByteStreamBufferAdapter` for buffer-to-bytestream bridging

### 2. Follow Official Documentation
The GenericHub documentation explicitly states:
> "The driver may be a pair consisting of (1) a ByteStreamDriver component and (2) a **ByteStreamBufferAdapter**."

### 3. Port Type Compatibility
- **Cannot directly connect**: `Fw.BufferSend` ↔ `Drv.ByteStreamSend`
- **Must bridge with**: `ByteStreamBufferAdapter` between them

### 4. Passive Components Don't Allocate Buffers
- ByteStreamBufferAdapter is **passive** - no allocate/deallocate ports
- Only **active** components (Hub, UART driver) need buffer allocation

### 5. Configuration File Hierarchy
- **Framework defaults**: `fprime/default/config/GenericHubCfg.fpp`
- **Deployment overrides**: `Stm32LedBlinker/config/GenericHubCfg.fpp`
- Don't define config constants in `instances.fpp`

---

## RPi Master Side Requirements

The RPi master deployment must also:

1. **Use GenericHub** with matching configuration:
   ```fpp
   constant NumSerialInputPorts = 10
   constant NumSerialOutputPorts = 10
   constant NumBufferInputPorts = 10
   constant NumBufferOutputPorts = 10
   ```

2. **Use ByteStreamBufferAdapter** if connecting to UART:
   ```
   GenericHub ↔ ByteStreamBufferAdapter ↔ LinuxUartDriver/TcpClient
   ```

3. **Mirror port connections** (spoke's outputs = master's inputs, vice versa)

---

## Testing Validation

### Build Validation
```bash
# Clean build
fprime-util build -j4

# Check for compilation errors
# All topology connections should resolve correctly
```

### Runtime Validation
1. **UART Communication**: Verify bidirectional data flow STM32 ↔ RPi
2. **Event Logging**: Check ByteStreamBufferAdapter events for errors
3. **Buffer Management**: Monitor buffer allocation/deallocation
4. **Command Routing**: Commands from RPi master reach STM32 components
5. **Telemetry/Events**: STM32 telemetry/events route through hub to RPi

---

## References

- [F-Prime GenericHub SDD](https://fprime.jpl.nasa.gov/latest/Svc/GenericHub/docs/sdd/)
- [F-Prime Hub Pattern](https://fprime.jpl.nasa.gov/latest/docs/user-manual/design-patterns/hub-pattern/)
- [ByteStreamDriverModel](https://fprime.jpl.nasa.gov/latest/Drv/ByteStreamDriverModel/docs/sdd/)
- F-Prime Source: `fprime/Drv/ByteStreamBufferAdapter/`
- F-Prime Source: `fprime/Svc/GenericHub/`

---

## Summary

| Change | Status | Component/File |
|--------|--------|----------------|
| Remove custom UartBufferAdapter | ✅ Done | `Components/UartBufferAdapter/` |
| Remove CmdSequenceForwarder | ✅ Done | `Components/CmdSequenceForwarder/` |
| Remove proxy components | ✅ Done | `instances.fpp` |
| Add ByteStreamBufferAdapter | ✅ Done | F-Prime standard component |
| Update GenericHub config to 10 ports | ✅ Done | `config/GenericHubCfg.fpp` |
| Fix Hub ↔ Adapter connections | ✅ Done | `topology.fpp` |
| Fix Adapter ↔ UART connections | ✅ Done | `topology.fpp` |
| Add adapter event/time connections | ✅ Done | `topology.fpp` |
| Remove invalid config constants | ✅ Done | `instances.fpp` |

**Result:** Fully compliant with F-Prime GenericHub spoke node pattern. ✅
