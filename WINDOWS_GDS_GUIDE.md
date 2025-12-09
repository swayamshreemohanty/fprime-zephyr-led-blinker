# Running F' GDS on Windows for STM32 Nucleo H7A3ZI-Q

## Issue: No Green Dot in GDS (No Connection)

When the green connection indicator doesn't appear in F' GDS, it means the Ground Data System is not receiving data from the board.

---

## Prerequisites on Windows

1. **Python 3.11+** installed (Python 3.13 recommended)
2. **F' GDS installed**: `pip install fprime-gds`
3. **STM32 Nucleo H7A3ZI-Q** connected via USB
4. **Build artifacts** folder copied from Raspberry Pi
5. **ST-Link drivers** installed (usually automatic on Windows 10/11)

---

## Step-by-Step Setup

### 1. Identify the COM Port

Open **Device Manager** → **Ports (COM & LPT)**

You should see:
```
STMicroelectronics STLink Virtual COM Port (COM3)
```

Note the COM port number (e.g., `COM3`, `COM4`, etc.)

### 2. Install F' GDS on Windows

```cmd
pip install fprime-gds
```

### 3. Copy Build Artifacts

Copy the entire `build-artifacts` folder from your Raspberry Pi to Windows:

**On Raspberry Pi:**
```bash
cd ~/work/practice/fprime/fprime-zephyr-led-blinker
tar czf build-artifacts.tar.gz build-artifacts/
```

**Transfer to Windows** (via SCP, USB drive, or network share)

**On Windows, extract:**
```cmd
tar xzf build-artifacts.tar.gz
```

### 4. Run F' GDS on Windows

Open Command Prompt or PowerShell in the project directory:

```cmd
fprime-gds -n ^
  --dictionary build-artifacts\zephyr\LedBlinker\dict\LedBlinkerTopologyAppDictionary.xml ^
  --comm-adapter uart ^
  --uart-device COM3 ^
  --uart-baud 115200
```

**Replace `COM3` with your actual COM port number!**

---

## Common Issues and Solutions

### Issue 1: No Green Dot / Not Receiving Data

**Symptoms:**
- GDS opens successfully
- Web interface at http://localhost:5000 works
- But green connection indicator never appears
- No telemetry/events received

**Causes & Solutions:**

#### A. Wrong Baud Rate
The firmware uses 115200 baud. Verify:
```cmd
--uart-baud 115200
```

#### B. Wrong COM Port
Double-check Device Manager. The port might be `COM4`, `COM5`, etc.

Try listing available ports:
```python
python -m serial.tools.list_ports
```

#### C. Board Not Running Firmware
**Check:**
1. Is the LED blinking on the board?
2. Press the **BLACK RESET BUTTON** on the Nucleo board
3. Check ST-Link LED: Should be solid green (not blinking red)

If LED not blinking, re-flash:
```cmd
st-flash write zephyr.bin 0x08000000
```

#### D. Serial Port Already in Use
Close any programs that might be using the COM port:
- STM32CubeIDE
- Arduino IDE  
- PuTTY
- Tera Term
- Any serial monitor

#### E. Driver Issues
Reinstall ST-Link drivers:
1. Download from: https://www.st.com/en/development-tools/stsw-link009.html
2. Uninstall old driver
3. Install new driver
4. Reconnect board

#### F. Framing Protocol Mismatch

The firmware might be using a different framing protocol. Try:

```cmd
fprime-gds -n ^
  --dictionary build-artifacts\zephyr\LedBlinker\dict\LedBlinkerTopologyAppDictionary.xml ^
  --comm-adapter uart ^
  --uart-device COM3 ^
  --uart-baud 115200 ^
  --comm-checksum-type crc32
```

Or try without framing:
```cmd
fprime-gds -n ^
  --dictionary build-artifacts\zephyr\LedBlinker\dict\LedBlinkerTopologyAppDictionary.xml ^
  --comm-adapter uart ^
  --uart-device COM3 ^
  --uart-baud 115200 ^
  --comm-checksum-type none
```

---

## Debugging Steps

### 1. Test Serial Communication Directly

Use PuTTY or another serial terminal to verify the board is sending data:

**PuTTY Settings:**
- Connection type: Serial
- Serial line: COM3 (your port)
- Speed: 115200
- Data bits: 8
- Stop bits: 1
- Parity: None
- Flow control: None

You should see **binary data** or text output from the firmware.

### 2. Check GDS Logs

GDS creates log files in the `logs/` directory. Check for errors:

```cmd
dir logs
type logs\<latest-timestamp>\*.log
```

Look for errors like:
- "Could not open port"
- "Permission denied"
- "Timeout"

### 3. Verify Dictionary File

Make sure the dictionary path is correct:

```cmd
dir build-artifacts\zephyr\LedBlinker\dict\LedBlinkerTopologyAppDictionary.xml
```

### 4. Enable Debug Output

Run GDS with verbose logging:

```cmd
fprime-gds -n ^
  --dictionary build-artifacts\zephyr\LedBlinker\dict\LedBlinkerTopologyAppDictionary.xml ^
  --comm-adapter uart ^
  --uart-device COM3 ^
  --uart-baud 115200 ^
  --log-level DEBUG
```

---

## Verifying Board is Working

### Method 1: LED Blink Test
The green LED (LD1) on the Nucleo board should be blinking if the firmware is running.

### Method 2: Serial Output Test

Connect with a serial terminal at 115200 baud. You might see:
- F' startup messages
- Event logs
- Telemetry packets (as binary data)

### Method 3: ST-Link Status
The ST-Link LED (near USB connector) should be:
- **Solid RED/GREEN**: Normal operation
- **Blinking RED**: Communication error
- **OFF**: Not powered or driver issue

---

## Alternative: Test with Raw Serial Monitor

If GDS still doesn't work, verify basic serial communication:

**Python test script** (test_serial.py):
```python
import serial
import time

# Change COM3 to your port
ser = serial.Serial('COM3', 115200, timeout=1)

print("Listening on COM3 at 115200 baud...")
print("Press Ctrl+C to exit")

try:
    while True:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            print(f"Received {len(data)} bytes:", data.hex())
        time.sleep(0.1)
except KeyboardInterrupt:
    print("\nExiting...")
finally:
    ser.close()
```

Run:
```cmd
python test_serial.py
```

You should see data being received if the firmware is running.

---

## Working Configuration Example

Once everything is set up correctly, you should see:

```
[INFO] F prime is now running. CTRL-C to shutdown all components.
[INFO] Received uplink data
[INFO] Decoded event: ...
```

And in the web interface:
- **Green indicator** next to "Connection"
- **Events** appearing in the events panel
- **Telemetry channels** showing data
- **Commands** can be sent successfully

---

## Quick Checklist

- [ ] Board connected via USB
- [ ] ST-Link LED solid (not blinking red)
- [ ] LED on board is blinking (firmware running)
- [ ] Correct COM port identified in Device Manager
- [ ] No other program using the COM port
- [ ] Dictionary file path is correct
- [ ] Baud rate is 115200
- [ ] ST-Link drivers installed
- [ ] Python and fprime-gds installed
- [ ] Tried pressing RESET button on board

---

## Still Not Working?

### Option 1: Try Different Framing Options

```cmd
# No checksum
--comm-checksum-type none

# CRC32
--comm-checksum-type crc32
```

### Option 2: Check Firmware Configuration

The issue might be in the firmware framing configuration. Check `LedBlinker/Top/LedBlinkerTopology.cpp` to see what framing protocol is configured.

### Option 3: Rebuild with Debug Output

In `prj.conf`, add:
```
CONFIG_LOG=y
CONFIG_PRINTK=y
CONFIG_EARLY_CONSOLE=y
CONFIG_UART_CONSOLE=y
```

Rebuild and reflash, then check serial output.

---

## Expected GDS Output (Working)

```
[INFO] F prime is now running. CTRL-C to shutdown all components.
[INFO] Received 52 byte uplink data
[INFO] Framing: Found frame of 45 bytes
[INFO] Decoded FpPacket: packet type COM_PACKET
[INFO] Decoded event: Led.BLINK_STATUS (0x01000001)
```

---

## Contact & Support

If issues persist:
1. Check F' Discussions: https://github.com/nasa/fprime/discussions
2. Verify board is working on Raspberry Pi first (where it was tested)
3. Check if there's a firewall blocking localhost:5000

---

**Last Updated**: December 9, 2025  
**Tested Configuration**: Windows 10/11, Python 3.13, F' GDS latest, STM32 Nucleo H7A3ZI-Q
