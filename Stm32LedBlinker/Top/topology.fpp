module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
    }

  topology Stm32LedBlinker {

    # ----------------------------------------------------------------------
    # Subtopology imports
    # ----------------------------------------------------------------------
    import CdhCore.Subtopology
    import ComCcsds.Subtopology

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance chronoTime
    instance commDriver
    instance gpioDriver
    instance gpioDriver1
    instance gpioDriver2
    instance led
    instance led1
    instance led2
    instance rateDriver
    instance rateGroup1
    instance rateGroupDriver
    instance uartBufferAdapter
    instance rpiHub
    instance proxyGroundInterface
    instance proxySequencer

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance CdhCore.cmdDisp
    event connections instance CdhCore.events
    telemetry connections instance CdhCore.tlmSend
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    time connections instance chronoTime

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections ComCcsds_CdhCore {
      # STM32 receives commands from RPi via GenericHub (spoke side)
      # GenericHub deserializes incoming commands to typed port calls
      rpiHub.portOut[0] -> proxyGroundInterface.seqCmdBuf
      rpiHub.portOut[1] -> proxySequencer.seqCmdBuf
      
      # Proxies forward commands to command dispatcher
      proxyGroundInterface.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff
      proxySequencer.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff
      
      # Command responses flow back through proxies to hub
      CdhCore.cmdDisp.seqCmdStatus -> proxyGroundInterface.cmdResponseIn
      CdhCore.cmdDisp.seqCmdStatus -> proxySequencer.cmdResponseIn
      proxyGroundInterface.seqCmdStatus -> rpiHub.portIn[0]
      proxySequencer.seqCmdStatus -> rpiHub.portIn[1]
    }

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1 - All periodic components
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      rateGroup1.RateGroupMemberOut[0] -> commDriver.schedIn
      # disable ComCcsds periodic tasks; telemetry now flows through GenericHub
      # rateGroup1.RateGroupMemberOut[1] -> CdhCore.tlmSend.Run
      # rateGroup1.RateGroupMemberOut[2] -> ComCcsds.commsBufferManager.schedIn
      # rateGroup1.RateGroupMemberOut[3] -> ComCcsds.comQueue.run
      rateGroup1.RateGroupMemberOut[1] -> led.run
      rateGroup1.RateGroupMemberOut[2] -> led1.run
      rateGroup1.RateGroupMemberOut[3] -> led2.run
    }

    connections LedConnections {
      # LED GPIO connections
      led.gpioSet -> gpioDriver.gpioWrite
      led1.gpioSet -> gpioDriver1.gpioWrite
      led2.gpioSet -> gpioDriver2.gpioWrite
    }

    # ----------------------------------------------------------------------
    # RPi Communication - NASA GenericHub Pattern over UART
    # ----------------------------------------------------------------------
    # STM32 acts as remote spoke receiving commands from RPi hub
    # Events and telemetry are sent back to RPi for GDS display
    #
    # Communication Stack (Official F´ Hub Pattern - Spoke Side):
    # Send Path (STM32 → RPi):
    # 1. Events/Telemetry → GenericHub (serialization)
    # 2. GenericHub.dataOut → Framer (protocol wrapping)
    # 3. Framer → ByteStreamBufferAdapter (buffer conversion)
    # 4. ByteStreamBufferAdapter → UART Driver (transmission)
    #
    # Receive Path (RPi → STM32):
    # 1. UART Driver → ByteStreamBufferAdapter (reception)
    # 2. ByteStreamBufferAdapter → Deframer (protocol extraction)
    # 3. Deframer → GenericHub (deserialization)
    # 4. GenericHub.portOut → Command handlers
    
    connections RpiHub_Send {
      # GenericHub serializes responses/events/telemetry and sends buffers to framer
      rpiHub.dataOut -> rpiFramer.bufferIn
      rpiHub.dataOutAllocate -> ComCcsds.commsBufferManager.bufferGetCallee
      
      # Framer wraps buffers with F´ protocol and sends to buffer adapter
      rpiFramer.framedOut -> uartBufferAdapter.bufferIn
      rpiFramer.bufferDeallocate -> ComCcsds.commsBufferManager.bufferSendIn
      rpiFramer.framedAllocate -> ComCcsds.commsBufferManager.bufferGetCallee
      
      # Buffer adapter converts framed buffers to byte stream for UART driver
      uartBufferAdapter.bufferInReturn -> rpiFramer.framedReturn
      uartBufferAdapter.toByteStreamDriver -> commDriver.$send
      commDriver.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
    }

    connections RpiHub_Receive {
      # UART driver receives byte stream and passes to buffer adapter
      commDriver.$recv -> uartBufferAdapter.fromByteStreamDriver
      commDriver.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      commDriver.ready -> uartBufferAdapter.byteStreamDriverReady
      
      # Buffer adapter converts byte stream to buffers and sends to deframer
      uartBufferAdapter.bufferOut -> rpiDeframer.framedIn
      uartBufferAdapter.bufferOutReturn -> ComCcsds.commsBufferManager.bufferSendIn
      uartBufferAdapter.fromByteStreamDriverReturn -> ComCcsds.commsBufferManager.bufferSendIn
      
      # Deframer extracts F´ protocol packets and sends to hub
      rpiDeframer.bufferOut -> rpiHub.dataIn
      rpiDeframer.bufferAllocate -> ComCcsds.commsBufferManager.bufferGetCallee
      rpiDeframer.framedDeallocate -> ComCcsds.commsBufferManager.bufferSendIn
      
      # Hub deallocates processed buffers
      rpiHub.dataInDeallocate -> ComCcsds.commsBufferManager.bufferSendIn
    }

    connections RpiHub_EventsTelemetry {
      # Route STM32 events and telemetry through GenericHub to RPi
      # This allows RPi GDS to display STM32 events and telemetry
      CdhCore.events.LogSend -> rpiHub.LogRecv
      CdhCore.tlmSend.TlmSend -> rpiHub.TlmRecv
    }

  }

}
