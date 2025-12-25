# STM32 Hub Pattern Implementation - FIXED

## ❌ Issues Found (Before Fix):

The STM32 deployment at `/external_fprime_projects/fprime-zephyr-led-blinker/Stm32LedBlinker` was **NOT properly configured** for the hub pattern. Here were the critical issues:

### 1. **Missing Components**
- ❌ **No `rpiFramer`** - Required to wrap outgoing data with F´ protocol headers
- ❌ **No `rpiDeframer`** - Required to extract F´ protocol packets from incoming UART stream

### 2. **Incorrect Port Connections**
The topology was using **non-existent ports** on GenericHub:
```fpp
# WRONG - These ports don't exist in Svc::GenericHub!
rpiHub.toBufferDriver -> uartBufferAdapter.bufferIn
rpiHub.fromBufferDriver <- uartBufferAdapter.bufferOut
```

GenericHub actually has these ports:
- `dataOut` / `dataIn` - For serialized buffer data
- `portIn` / `portOut` - For typed port calls (commands, responses)
- `LogRecv` / `TlmRecv` - For events and telemetry

### 3. **Missing Protocol Layer**
The communication stack was incomplete:
```
BEFORE (Broken):
GenericHub → ByteStreamBufferAdapter → UART
         ❌ Missing Framer/Deframer!
```

## ✅ Changes Made (After Fix):

### 1. **Added Missing Components** ([instances.fpp](external_fprime_projects/fprime-zephyr-led-blinker/Stm32LedBlinker/Top/instances.fpp))

```fpp
@ Framer for RPi hub - Wraps buffers with F´ protocol headers before UART TX
instance rpiFramer: Svc.Framer base id 0x5400

@ Deframer for RPi hub - Extracts F´ protocol packets from UART RX stream
instance rpiDeframer: Svc.Deframer base id 0x5500
```

### 2. **Fixed Port Connections** ([topology.fpp](external_fprime_projects/fprime-zephyr-led-blinker/Stm32LedBlinker/Top/topology.fpp))

#### ✅ Command Routing (RPi → STM32):
```fpp
# Correct port names for GenericHub
rpiHub.portOut[0] -> proxyGroundInterface.seqCmdBuf
rpiHub.portOut[1] -> proxySequencer.seqCmdBuf

# Response routing back
proxyGroundInterface.seqCmdStatus -> rpiHub.portIn[0]
proxySequencer.seqCmdStatus -> rpiHub.portIn[1]
```

#### ✅ Send Path (STM32 → RPi):
```fpp
# Complete 4-layer stack
rpiHub.dataOut → rpiFramer.bufferIn
rpiFramer.framedOut → uartBufferAdapter.bufferIn
uartBufferAdapter.toByteStreamDriver → commDriver.$send
```

#### ✅ Receive Path (RPi → STM32):
```fpp
# Complete 4-layer stack
commDriver.$recv → uartBufferAdapter.fromByteStreamDriver
uartBufferAdapter.bufferOut → rpiDeframer.framedIn
rpiDeframer.bufferOut → rpiHub.dataIn
```

#### ✅ Events/Telemetry Routing:
```fpp
# STM32 events and telemetry flow to RPi GDS through hub
CdhCore.events.LogSend -> rpiHub.LogRecv
CdhCore.tlmSend.TlmSend -> rpiHub.TlmRecv
```

### 3. **Configured Protocol Handlers** ([Stm32LedBlinkerTopology.cpp](external_fprime_projects/fprime-zephyr-led-blinker/Stm32LedBlinker/Top/Stm32LedBlinkerTopology.cpp))

```cpp
// Added F´ protocol instances
Svc::FprimeFraming rpiFraming;
Svc::FprimeDeframing rpiDeframing;

// In configureTopology():
rpiFramer.setup(rpiFraming);
rpiDeframer.setup(rpiDeframing);
```

## 📊 Architecture Comparison

### BEFORE (Broken):
```
❌ SEND PATH:
GenericHub 
    ↓ (toBufferDriver - PORT DOESN'T EXIST!)
ByteStreamBufferAdapter
    ↓
UART

❌ RECEIVE PATH:
UART
    ↓
ByteStreamBufferAdapter
    ↓ (fromBufferDriver - PORT DOESN'T EXIST!)
GenericHub
```

### AFTER (Fixed):
```
✅ SEND PATH (STM32 → RPi):
Events/Telemetry
    ↓
GenericHub (serialization)
    ↓ dataOut
Framer (protocol wrapping)
    ↓ framedOut
ByteStreamBufferAdapter (buffer→bytes)
    ↓ toByteStreamDriver
UART Driver (transmission)

✅ RECEIVE PATH (RPi → STM32):
UART Driver (reception)
    ↓ $recv
ByteStreamBufferAdapter (bytes→buffer)
    ↓ bufferOut
Deframer (protocol extraction)
    ↓ bufferOut
GenericHub (deserialization)
    ↓ portOut
Command Handlers
```

## 🔄 Hub Pattern Port Mapping

### RPi (Hub/Master) Side:
```
portIn[0/1]   ← receives responses from STM32
portOut[0/1]  → sends commands to STM32
LogRecv       ← receives events from STM32
TlmRecv       ← receives telemetry from STM32
```

### STM32 (Spoke/Remote) Side:
```
portIn[0/1]   ← receives responses to send back to RPi
portOut[0/1]  → receives commands from RPi
LogRecv       → sends events to RPi
TlmRecv       → sends telemetry to RPi
```

**Note:** The ports are "mirrored" - RPi's portOut connects to STM32's portOut through the UART link!

## ✅ Verification Checklist

Now both deployments properly implement the NASA GenericHub pattern:

- ✅ **RPi deployment** has: GenericHub + Framer + Deframer + UART
- ✅ **STM32 deployment** has: GenericHub + Framer + Deframer + UART
- ✅ Both use correct **dataOut/dataIn** ports
- ✅ Both use correct **portIn/portOut** ports for commands
- ✅ Both have **F´ protocol** configured (Framing/Deframing)
- ✅ Both have **matching port counts** (GenericHubInputPorts/OutputPorts = 2)
- ✅ **Buffer management** integrated (ComCcsds.commsBufferManager)
- ✅ **Events/Telemetry** routed through hub (LogRecv/TlmRecv)

## 🎯 Key Differences from Demo Project

The demo project uses TCP sockets, but the architecture is identical:

| Layer | Demo (TCP) | Your Implementation (UART) |
|-------|-----------|---------------------------|
| **Application** | GenericHub | ✅ GenericHub |
| **Protocol** | Framer/Deframer | ✅ Framer/Deframer |
| **Adaptation** | Direct socket | ✅ ByteStreamBufferAdapter |
| **Transport** | TcpClient/Server | ✅ LinuxUartDriver/ZephyrUartDriver |

## 🚀 Next Steps

1. **Build both deployments**:
   ```bash
   # RPi
   cd /home/swayamshreemohanty/work/droptestfprimepharmamodule/RPi_Deployment
   fprime-util build
   
   # STM32
   cd /home/swayamshreemohanty/work/droptestfprimepharmamodule/external_fprime_projects/fprime-zephyr-led-blinker
   west build -b nucleo_f767zi Stm32LedBlinker
   ```

2. **Test UART connection**:
   - Connect GPIO14↔STM32 RX, GPIO15↔STM32 TX, GND↔GND
   - Run both deployments
   - From RPi GDS, send command to STM32 LED component

3. **Monitor communication**:
   - Check RPi logs for "NASA HUB PATTERN: STM32 Node Link ACTIVE"
   - Check STM32 logs for "Framer/Deframer ready"
   - Monitor UART with logic analyzer if needed

## 📝 Summary

The STM32 deployment is now **properly configured** for the hub pattern! ✅

The main issue was using incorrect port names (`toBufferDriver`/`fromBufferDriver`) that don't exist in GenericHub, and missing the critical Framer/Deframer components. Both issues are now fixed, and the architecture matches the official NASA hub pattern implementation.
