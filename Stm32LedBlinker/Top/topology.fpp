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
      # STM32 receives commands from RPi via GenericHub (obcB pattern)
      rpiHub.serialOut[0] -> proxyGroundInterface.seqCmdBuf
      rpiHub.serialOut[1] -> proxySequencer.seqCmdBuf
      proxyGroundInterface.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff
      proxySequencer.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff
      CdhCore.cmdDisp.seqCmdStatus -> proxyGroundInterface.cmdResponseIn
      CdhCore.cmdDisp.seqCmdStatus -> proxySequencer.cmdResponseIn
      proxyGroundInterface.seqCmdStatus -> rpiHub.serialIn[0]
      proxySequencer.seqCmdStatus -> rpiHub.serialIn[1]
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
    # ----------------------------------------------------------------------
    # RPi Communication - NASA GenericHub Pattern over UART
    # ----------------------------------------------------------------------
    # STM32 acts as remote node receiving commands from RPi master
    # GenericHub handles serialization directly without Framer/Deframer
    
    connections send_hub {
      # GenericHub serializes telemetry/events and sends to buffer adapter
      rpiHub.toBufferDriver -> uartBufferAdapter.bufferIn
      # Adapter drives UART TX
      uartBufferAdapter.toByteStreamDriver -> commDriver.$send
      commDriver.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
    }

    connections recv_hub {
      # UART RX into adapter, then into GenericHub for deserialization
      commDriver.$recv -> uartBufferAdapter.fromByteStreamDriver
      commDriver.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      commDriver.ready -> uartBufferAdapter.byteStreamDriverReady
      uartBufferAdapter.bufferOut -> rpiHub.fromBufferDriver
    }

    connections hub {
      # GenericHub needs buffer allocation for serializing telemetry/events
      rpiHub.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      rpiHub.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
      
      # Route STM32 events and telemetry TO RPi via GenericHub
      CdhCore.events.LogSend -> rpiHub.eventIn
      CdhCore.tlmSend.TlmSend -> rpiHub.tlmIn
    }

  }

}
