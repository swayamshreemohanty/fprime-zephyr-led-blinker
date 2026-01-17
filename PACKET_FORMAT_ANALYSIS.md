# GenericHub Packet Format Analysis

## Summary

✅ **Your STM32 implementation is CORRECT**. GenericHub does NOT use F´ protocol framing (START token, CRC) when connected directly to a ByteStreamDriver.

## GenericHub Packet Format (Official)

According to [GenericHub.cpp](fprime/Svc/GenericHub/GenericHub.cpp):

### Send Path (STM32 → RPI):
```cpp
void GenericHub::send_data(const HubType type, const FwIndexType port, const U8* data, const FwSizeType size) {
    Fw::Buffer outgoing = allocate_out(0, size + sizeof(U32) + sizeof(U32) + sizeof(FwBuffSizeType));
    auto serialize = outgoing.getSerializer();
    
    // Serialize in this order:
    serialize.serializeFrom(static_cast<U32>(type));   // 4 bytes - HubType enum
    serialize.serializeFrom(static_cast<U32>(port));   // 4 bytes - Port number  
    serialize.serializeFrom(data, size);                // Variable - Actual payload
    
    toBufferDriver_out(0, outgoing);
}
```

**Packet Structure:**
```
┌─────────────┬─────────────┬─────────────┬──────────────────┐
│ HubType(U32)│ Port(U32)   │ Size(U32)   │ Payload (bytes)  │
│ 4 bytes     │ 4 bytes     │ 4 bytes     │ Variable         │
└─────────────┴─────────────┴─────────────┴──────────────────┘
```

### Receive Path (RPI → STM32):
```cpp
void GenericHub::fromBufferDriver_handler(const FwIndexType portNum, Fw::Buffer& fwBuffer) {
    auto incoming = fwBuffer.getDeserializer();
    
    // Deserialize in this order:
    incoming.deserializeTo(type_in);  // 4 bytes - HubType
    incoming.deserializeTo(port);     // 4 bytes - Port number
    incoming.deserializeTo(size);     // 4 bytes - Payload size
    
    // Extract payload
    U8* rawData = fwBuffer.getData() + sizeof(U32) + sizeof(U32) + sizeof(FwBuffSizeType);
    U32 rawSize = fwBuffer.getSize() - sizeof(U32) - sizeof(U32) - sizeof(FwBuffSizeType);
}
```

## HubType Enumeration

```cpp
enum HubType {
    HUB_TYPE_PORT,     // 0 - Port type transmission
    HUB_TYPE_BUFFER,   // 1 - Buffer type transmission  
    HUB_TYPE_EVENT,    // 2 - Event transmission
    HUB_TYPE_CHANNEL,  // 3 - Telemetry channel type
    HUB_TYPE_MAX       // 4 - Invalid
};
```

## Current STM32 Architecture (CORRECT)

```
STM32 Spoke Node:
┌─────────────┐     ┌──────────────────────┐     ┌──────────────┐
│ GenericHub  │────▶│ByteStreamBuffer      │────▶│ ZephyrUart   │──┬──▶ UART TX
│             │     │Adapter               │     │ Driver       │  │
│ (Fw.Buffer) │◀────│(Bridge Component)    │◀────│ (ByteStream) │◀─┘◀── UART RX  
└─────────────┘     └──────────────────────┘     └──────────────┘
  Serializes:          Passes buffer              Sends raw
  [Type][Port][Size][Data]  as-is              bytes over UART
```

## What RPI Hub Must Do

**The RPI must ALSO use GenericHub with ByteStreamBufferAdapter!**

### ❌ WRONG RPI Configuration:
```
RPI: FprimeFramer/FprimeDeframer (expects START token, CRC)
STM32: GenericHub (sends Type+Port+Size+Data)
→ PACKET FORMAT MISMATCH!
```

### ✅ CORRECT RPI Configuration:
```
RPI Hub Node:
┌────────────────┐     ┌──────────────────────┐     ┌──────────────┐
│ GenericHub     │────▶│ByteStreamBuffer      │────▶│ LinuxUart    │──┬──▶ UART TX
│                │     │Adapter               │     │ Driver       │  │
│ (Fw.Buffer)    │◀────│(Bridge Component)    │◀────│ (ByteStream) │◀─┘◀── UART RX
└────────────────┘     └──────────────────────┘     └──────────────┘
```

Both sides must use:
1. **GenericHub** (same packet format)
2. **ByteStreamBufferAdapter** (buffer-to-bytestream bridge)
3. **UART Driver** (ByteStreamDriver interface)

## When to Use FprimeFramer/FprimeDeframer

FprimeFramer/FprimeDeframer are used ONLY for:
- **ComQueue** + **ComStub** communication patterns
- Network protocols requiring robust framing (START token + CRC validation)
- File transfer protocols
- When using the CCSDS framing subtopology

**NOT used for simple GenericHub UART communication!**

## Official F´ Documentation Reference

From [GenericHub.fpp](https://fprime.jpl.nasa.gov/latest/Svc/GenericHub/docs/sdd/):

> "The driver must be a buffer driver, i.e., any combination of component instances that sends and receives Fw.Buffer objects across a network. For example, the driver may be a pair consisting of (1) a ByteStreamDriver component that implements ByteStreamDriverInterface and (2) a **ByteStreamBufferAdapter**."

Notice: **NO MENTION of Framer/Deframer for GenericHub!**

## Debugging Checklist

If you're getting "wrong data" errors from RPI:

1. ✅ **Verify RPI uses GenericHub** (not just Framer/Deframer)
2. ✅ **Verify RPI uses ByteStreamBufferAdapter** (same as STM32)
3. ✅ **Verify both use same buffer allocation size** (HUB_BUFFER_SIZE = 1024)
4. ✅ **Check endianness** (both should use same byte order - F´ default is big-endian)
5. ✅ **Verify FW_PORT_SERIALIZATION is enabled** (required for GenericHub)
6. ✅ **Check UART baud rate matches** (STM32: 115200, RPI: 115200)

## Example Event Packet from STM32

When STM32 sends an event through hub:

```
Byte 0-3:   0x00000002    (HUB_TYPE_EVENT = 2)
Byte 4-7:   0x00000000    (Port = 0)
Byte 8-11:  0x00000030    (Size = 48 bytes for example event)
Byte 12+:   [Event ID][Time][Severity][Args]...
```

RPI GenericHub receives this, deserializes the header, and extracts the event data.

## Conclusion

**Your STM32 code is correct!** The issue is likely:
- RPI is NOT using GenericHub
- RPI is using FprimeFramer/FprimeDeframer (wrong for this use case)
- RPI expects F´ protocol frames but STM32 sends GenericHub packets

**Solution:** Configure RPI to use the same architecture:
```
GenericHub ↔ ByteStreamBufferAdapter ↔ LinuxUartDriver
```
