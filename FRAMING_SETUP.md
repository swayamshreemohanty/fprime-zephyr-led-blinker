# GenericHub UART Fragmentation - Correct Solution

## Summary

**Problem:** RPI GenericHub was receiving fragmented packets (15-16 byte chunks) from STM32  
**Root Cause:** LinuxUartDriver `read()` returns whatever bytes are available, not complete packets  
**Solution:** Increase UART buffer allocation size on RPI to >= GenericHub maximum packet size

---

## Why FprimeFramer/Deframer Don't Apply Here

`FprimeFramer` and `FprimeDeframer` are designed for **ground station communication (GDS)**, not for **inter-deployment hub patterns**:

- They use `ComData` ports, not `BufferSend` ports
- They're part of the `ComFprime` subtopology for spacecraft ↔ ground communication
- GenericHub already handles its own serialization with [Type][Port][Size][Payload]

For hub-to-hub communication over UART, **no additional framing is needed** - just ensure buffers are large enough.

---

## Correct Solution: Configure Buffer Sizes

### STM32 Side (Already Correct)

The ZephyrUartDriver is working fine - it transmits complete 31-byte packets.

### RPI Side (Needs Configuration)

When opening LinuxUartDriver, specify a buffer size >= maximum GenericHub packet:

```cpp
void configureTopology() {
    // Configure UART with LARGE buffer allocation
    bool uartOk = uartDriver.open(
        "/dev/ttyUSB0",                     // UART device
        Drv::LinuxUartDriver::BAUD_115K,    // Match STM32 baud
        Drv::LinuxUartDriver::NO_FLOW,
        Drv::LinuxUartDriver::PARITY_NONE,
        512                                  // Buffer size - MUST be >= max packet size
    );
    FW_ASSERT(uartOk);
}
```

**Key parameter:** `allocationSize = 512` bytes

This ensures each `read()` call can hold a complete GenericHub packet. GenericHub telemetry packets are typically:
- Header: 10 bytes (Type + Port + Size)
- Payload: ~20-100 bytes (telemetry data)
- **Total: ~30-110 bytes per packet**

A 512-byte buffer provides plenty of headroom.

---

## Understanding the Fragmentation

**What happened:**
1. STM32 sends complete 31-byte packet via UART
2. Linux kernel buffers incoming bytes asynchronously  
3. LinuxUartDriver calls `read()` which returns **whatever is available** (not complete packets)
4. First read: 16 bytes → GenericHub tries to parse → incomplete header → crash
5. Second read: 15 bytes → treated as new packet → garbage data

**What the documentation says:**
> LinuxUartDriver "allocates buffers for each receive operation" 

The buffer size you specify in `open()` becomes the allocation size. If packets are larger than this, they get split across multiple reads.

---

## Alternative: Keep Simple Approach

If you can't easily modify the RPI deployment code, the **reassembly buffer in GenericHub** (which we implemented earlier) is also a valid solution. It's just not in the F´ library because:

1. Most projects use TCP/IP or reliable links where fragmentation isn't an issue
2. When using UART for GDS, they use FprimeFramer/FrameAccumulator
3. Hub pattern over UART is uncommon enough that fragmentation handling is left to users

Your reassembly buffer implementation was **architecturally sound** - it just modified library code which isn't ideal for maintenance.

---

## Recommended Next Steps

1. ✅ Topology reverted to simple GenericHub ↔ ByteStreamBufferAdapter ↔ UART
2. ❌ No FprimeFramer/Deframer needed
3. ⏳ Configure RPI LinuxUartDriver with 512+ byte buffer allocation
4. ⏳ Test communication

---

## For Reference: GenericHub Packet Format

```
[Type: U32 (4 bytes)]
[Port: U32 (4 bytes)]  
[PayloadSize: U16 (2 bytes)]
[Payload: variable]
```

**Total overhead:** 10 bytes  
**Typical packet:** 30-110 bytes  
**Buffer recommendation:** 512 bytes (safe margin)
