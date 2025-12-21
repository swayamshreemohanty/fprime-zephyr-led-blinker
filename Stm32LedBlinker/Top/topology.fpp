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
    instance cmdSplitter

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance CdhCore.cmdDisp
    event connections instance rpiHub
    telemetry connections instance rpiHub
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    time connections instance chronoTime

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections ComCcsds_CdhCore {
      # Core events and telemetry routed to GenericHub instead of comQueue
      # This allows RPi master to receive STM32 telemetry/events

      # Router to CmdSplitter for command routing
      # Commands from RPi hub are routed through splitter
      ComCcsds.fprimeRouter.commandOut -> cmdSplitter.CmdBuff
      cmdSplitter.RemoteCmd[0] -> CdhCore.cmdDisp.seqCmdBuff
      
      # Command responses route back through splitter to hub
      CdhCore.cmdDisp.seqCmdStatus -> cmdSplitter.seqCmdStatus[1]
      cmdSplitter.forwardSeqCmdStatus[0] -> ComCcsds.fprimeRouter.cmdResponseIn
      cmdSplitter.forwardSeqCmdStatus[1] -> ComCcsds.fprimeRouter.cmdResponseIn
    }

    connections Communications {
      # ComDriver buffer allocations
      commDriver.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      commDriver.deallocate -> ComCcsds.commsBufferManager.bufferSendIn

      # ComDriver <-> ByteStreamBufferAdapter (Uplink from RPi)
      commDriver.$recv -> uartBufferAdapter.fromByteStreamDriver
      uartBufferAdapter.fromByteStreamDriverReturn -> ComCcsds.commsBufferManager.bufferSendIn
      
      # ByteStreamBufferAdapter <-> ComDriver (Downlink to RPi)
      uartBufferAdapter.toByteStreamDriver -> commDriver.$send
      commDriver.ready -> uartBufferAdapter.byteStreamDriverReady
    }

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1 - All periodic components
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      rateGroup1.RateGroupMemberOut[0] -> commDriver.schedIn
      rateGroup1.RateGroupMemberOut[1] -> CdhCore.tlmSend.Run
      rateGroup1.RateGroupMemberOut[2] -> ComCcsds.commsBufferManager.schedIn
      rateGroup1.RateGroupMemberOut[3] -> led.run
      rateGroup1.RateGroupMemberOut[4] -> led1.run
      rateGroup1.RateGroupMemberOut[5] -> led2.run
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
    # STM32 acts as remote node receiving commands from RPi master
    # Events and telemetry are sent back to RPi for GDS display
    
    connections send_hub {
      # GenericHub serializes telemetry/events and sends to buffer adapter
      rpiHub.toBufferDriver -> uartBufferAdapter.bufferIn
      uartBufferAdapter.bufferInReturn -> rpiHub.toBufferDriverReturn
      
      # Buffer adapter manages UART transmission
      commDriver.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
    }

    connections recv_hub {
      # UART receives commands from RPi and delivers to buffer adapter
      commDriver.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      
      # Buffer adapter delivers to GenericHub for deserialization
      uartBufferAdapter.bufferOut -> rpiHub.fromBufferDriver
      rpiHub.fromBufferDriverReturn -> uartBufferAdapter.bufferOutReturn
    }

    connections hub {
      # Hub deserializes commands from RPi and routes to command dispatcher
      rpiHub.serialOut[0] -> ComCcsds.fprimeRouter.serialRecv[0]
      ComCcsds.fprimeRouter.serialSend[0] -> rpiHub.serialIn[0]
      
      # GenericHub needs buffer allocation for serializing telemetry/events
      rpiHub.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      rpiHub.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
    }

  }

}
