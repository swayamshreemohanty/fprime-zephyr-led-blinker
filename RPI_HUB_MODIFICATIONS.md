# Raspberry Pi Hub Modifications for STM32 Subsystem Communication

## Objective
Modify the Raspberry Pi F´ deployment to act as a master hub that communicates with the STM32 subsystem over UART, enabling command transmission to and telemetry/event reception from the STM32 LED blinker.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Raspberry Pi (Master Hub)                                   │
│                                                              │
│  GDS ←→ cmdDisp/eventLogger/tlmChan                         │
│           ↓                    ↑                             │
│         Uplink              Downlink                         │
│           ↓                    ↑                             │
│      LinuxUartDriver (UART Interface)                       │
│           ↓                    ↑                             │
└───────────┼────────────────────┼──────────────────────────────┘
            │ UART TX/RX         │
            ↓                    ↑
┌───────────┼────────────────────┼──────────────────────────────┐
│           ↓                    ↑                             │
│      ZephyrUartDriver (UART Interface)                      │
│           ↓                    ↑                             │
│         Deframer            Framer                          │
│           ↓                    ↑                             │
│        GenericHub (Serialization Bridge)                    │
│           ↓                    ↑                             │
│  cmdDisp/LED Components   eventLogger/tlmSend              │
│                                                              │
│ STM32 (Remote Subsystem)                                    │
└─────────────────────────────────────────────────────────────┘
```

## Current STM32 Configuration (Reference)

The STM32 subsystem is already configured with:

### Topology Components
- **GenericHub** (rpiHub): Serialization bridge for remote communication
- **Framer/Deframer**: F´ protocol framing/deframing
- **ZephyrUartDriver** (commDriver): UART communication at 115200 baud
- **StaticMemory**: Buffer management with 3 allocation indices

### Key Connections
```fpp
# Commands: UART → Deframer → GenericHub → CommandDispatcher
deframer.comOut -> rpiHub.portIn[0]
rpiHub.portOut[0] -> cmdDisp.seqCmdBuff

# Telemetry: Components → GenericHub → Framer → UART
tlmSend.PktSend -> rpiHub.TlmRecv
rpiHub.buffersOut[0] -> framer.bufferIn

# Events: Components → GenericHub → Framer → UART
eventLogger.PktSend -> rpiHub.LogRecv

# UART Physical Layer
framer.framedOut -> commDriver.$send
commDriver.$recv -> deframer.framedIn
```

## Required RPi Modifications

### 1. Add GenericHub Component Instance

**File**: `RPI/Top/instances.fpp`

Add after existing component instances:

```fpp
instance stm32Hub: Svc.GenericHub base id 0x6000
```

Define hub port array sizes (add to constants section):

```fpp
# ----------------------------------------------------------------------
# STM32 GenericHub port array sizes
# ----------------------------------------------------------------------

@ Number of typed serial input ports for STM32 hub
constant Stm32HubInputPorts = 2

@ Number of typed serial output ports for STM32 hub  
constant Stm32HubOutputPorts = 2

@ Number of buffer input ports for STM32 hub
constant Stm32HubInputBuffers = 1

@ Number of buffer output ports for STM32 hub
constant Stm32HubOutputBuffers = 1
```

### 2. Modify LinuxUartDriver Configuration

**File**: `RPI/Top/instances.fpp`

Update the `uartDrv` instance configuration to use the correct device and baud rate:

**Current** (GPIO UART example):
```fpp
instance uartDrv: Drv.LinuxUartDriver base id 2000 \
{
  phase Fpp.ToCpp.Phases.configComponents """
  {
    const bool status = uartDrv.open("/dev/serial0",
        Drv::LinuxUartDriver::BAUD_19200,
        Drv::LinuxUartDriver::NO_FLOW,
        Drv::LinuxUartDriver::PARITY_NONE,
        1024
    );
    // ... error handling ...
  }
  """
}
```

**Modified** (for STM32 communication):
```fpp
instance uartDrv: Drv.LinuxUartDriver base id 2000 \
{
  phase Fpp.ToCpp.Phases.configComponents """
  {
    const bool status = uartDrv.open("/dev/ttyAMA0",  // or /dev/serial0 depending on RPi model
        Drv::LinuxUartDriver::BAUD_115K,              // Match STM32: 115200 baud
        Drv::LinuxUartDriver::NO_FLOW,
        Drv::LinuxUartDriver::PARITY_NONE,
        1024                                          // Buffer size
    );
    if (!status) {
      Fw::Logger::logMsg("[ERROR] Could not open UART driver for STM32 communication\\n");
      Init::status = false;
    }
  }
  """
}
```

**Note**: Verify UART device path for your Raspberry Pi model:
- `/dev/ttyAMA0` - Primary UART (RPi 3+, RPi 4, RPi 5)
- `/dev/serial0` - Symbolic link to primary UART
- `/dev/ttyS0` - Mini UART (if primary UART is used for Bluetooth)

### 3. Add Topology Connections

**File**: `RPI/Top/topology.fpp`

#### Add STM32 Hub Communication Connection Block

```fpp
connections Stm32HubCommunication {
  # Commands to STM32: CommandDispatcher → GenericHub → Framer → UART
  cmdDisp.compCmdSend -> stm32Hub.portIn[0]
  stm32Hub.portOut[0] -> downlink.comIn
  
  # Command responses from STM32: UART → Deframer → GenericHub → CommandDispatcher
  uplink.comOut -> stm32Hub.portIn[1]
  stm32Hub.portOut[1] -> cmdDisp.compCmdSend
  
  # Telemetry from STM32: UART → Deframer → GenericHub → TlmChan
  stm32Hub.TlmSend -> chanTlm.TlmRecv
  
  # Events from STM32: UART → Deframer → GenericHub → EventLogger
  stm32Hub.LogSend -> eventLogger.LogRecv
  
  # Hub buffer serialization connections
  stm32Hub.buffersIn[0] -> uplink.bufferOut
  stm32Hub.buffersOut[0] -> downlink.bufferIn
}
```

#### Update Existing UART Connection Block

**Current**:
```fpp
connections UART {
  rpiDemo.UartBuffers -> uartBufferManager.bufferSendIn
  rpiDemo.UartWrite -> uartDrv.$send
  uartDrv.$recv -> rpiDemo.UartRead
  uartDrv.allocate -> uartBufferManager.bufferGetCallee
}
```

**Modified** (Replace with STM32 communication):
```fpp
connections UART {
  # UART driver connections for STM32 subsystem communication
  downlink.framedOut -> uartDrv.$send
  uartDrv.$recv -> uplink.framedIn
  
  # Buffer management for UART driver
  uartDrv.allocate -> uartBufferManager.bufferGetCallee
  uartDrv.deallocate -> uartBufferManager.bufferSendIn
}
```

**Note**: If you need to keep the `rpiDemo` UART connections, use a separate UART driver instance (e.g., `uartDrv2`) for the STM32 communication.

#### Add StaticMemory Buffer Indices

**File**: `RPI/Top/instances.fpp` or `topology.fpp`

Add to constants/enums section:

```fpp
enum Ports_StaticMemory_STM32 {
  stm32HubBuffers
}
```

Update StaticMemory connections in topology.fpp:

```fpp
connections StaticMemory {
  # Existing connections...
  comm.allocate -> staticMemory.bufferAllocate[0]
  comm.deallocate -> staticMemory.bufferDeallocate[1]
  downlink.framedAllocate -> staticMemory.bufferAllocate[1]
  uplink.framedDeallocate -> staticMemory.bufferDeallocate[0]
  
  # Add STM32 hub buffer management
  stm32Hub.bufferAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory_STM32.stm32HubBuffers]
  stm32Hub.bufferDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory_STM32.stm32HubBuffers]
}
```

### 4. Hardware UART Connection

**Physical Wiring**:
```
Raspberry Pi          STM32 (NUCLEO/Teensy)
-----------          --------------------
GPIO 14 (TX)    →    UART RX (e.g., PA10)
GPIO 15 (RX)    ←    UART TX (e.g., PA9)
GND             ↔    GND
```

**Important**: 
- Ensure voltage levels are compatible (3.3V for both)
- Do NOT connect 5V power between boards
- Cross TX→RX and RX→TX

### 5. Disable Conflicting Services on RPi

Before running, disable serial console on RPi UART:

```bash
# Disable serial console
sudo raspi-config
# Navigate to: Interface Options → Serial Port
# - "Would you like a login shell over serial?" → No
# - "Would you like the serial port hardware enabled?" → Yes

# Or via command line:
sudo systemctl stop serial-getty@ttyAMA0.service
sudo systemctl disable serial-getty@ttyAMA0.service

# Edit /boot/config.txt (RPi 3+ to disable Bluetooth on primary UART)
sudo nano /boot/config.txt
# Add: dtoverlay=disable-bt

# Reboot
sudo reboot
```

### 6. Build and Test

```bash
# Navigate to RPi deployment
cd RPI

# Generate and build
fprime-util generate
fprime-util build

# Run with GDS
fprime-gds -n --dictionary ./build-artifacts/*/dict/RPITopologyAppDictionary.xml
```

### 7. Verify Communication

**From RPi GDS**:
1. Send command to STM32 LED: `led.BLINKING_ON_OFF`
2. View STM32 telemetry: Monitor `led.BlinkingState` channel
3. View STM32 events: Check event log for LED state changes

**Expected Data Flow**:
```
GDS Command → RPi cmdDisp → stm32Hub → downlink → uartDrv → [UART] 
  → STM32 commDriver → deframer → rpiHub → cmdDisp → LED

LED Telemetry → STM32 tlmSend → rpiHub → framer → commDriver → [UART]
  → RPi uartDrv → uplink → stm32Hub → chanTlm → GDS
```

## Troubleshooting

### UART Permission Issues
```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER
# Logout and login again

# Or use sudo
sudo chmod 666 /dev/ttyAMA0
```

### Verify UART Communication
```bash
# Test UART with minicom
sudo apt-get install minicom
minicom -b 115200 -D /dev/ttyAMA0

# Or Python serial test
python3 -c "import serial; s=serial.Serial('/dev/ttyAMA0',115200); print('UART OK')"
```

### Enable Debug Logging
In RPi topology.cpp, enable UART driver debug:
```cpp
// In configureTopology() or before uartDrv.open()
uartDrv.log_DIAGNOSTIC_BytesSent(100);  // Log every 100 bytes
uartDrv.log_DIAGNOSTIC_BytesRecv(100);
```

## Key Differences from Standard RPi Topology

| Component | Standard RPi | Modified for STM32 Hub |
|-----------|--------------|------------------------|
| UART Purpose | GPIO demo/testing | STM32 subsystem communication |
| Baud Rate | Varies (19200) | 115200 (match STM32) |
| Uplink/Downlink | Direct to comm (TCP) | Via GenericHub to STM32 |
| GenericHub | Not used | Bridge to STM32 subsystem |
| Buffer Manager | File uplink only | Includes hub buffers |

## Reference Documentation

- **F´ Hub Pattern**: https://fprime.jpl.nasa.gov/latest/docs/user-manual/design-patterns/hub-pattern/
- **LinuxUartDriver**: https://fprime.jpl.nasa.gov/latest/Drv/LinuxUartDriver/docs/sdd/
- **GenericHub**: https://fprime.jpl.nasa.gov/latest/Svc/GenericHub/docs/sdd/
- **ByteStreamDriverModel**: https://fprime.jpl.nasa.gov/latest/Drv/ByteStreamDriverModel/docs/sdd/

## Testing Checklist

- [ ] RPi UART device path verified (`/dev/ttyAMA0` or `/dev/serial0`)
- [ ] Baud rate matches STM32 (115200)
- [ ] Serial console disabled on RPi UART
- [ ] Physical wiring: TX→RX, RX→TX, GND connected
- [ ] GenericHub instance added with correct port arrays
- [ ] Topology connections updated for hub communication
- [ ] StaticMemory buffer indices configured
- [ ] Build succeeds without errors
- [ ] GDS can send commands to STM32
- [ ] GDS receives telemetry from STM32
- [ ] GDS receives events from STM32
