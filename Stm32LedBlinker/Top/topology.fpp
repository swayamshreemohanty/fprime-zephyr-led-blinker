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
    event connections instance CdhCore.events
    telemetry connections instance CdhCore.tlmSend
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    time connections instance chronoTime

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections ComCcsds_CdhCore {
      # STM32 operates standalone with local event/telemetry processing
      # Events and telemetry go to ComQueue for local UART output
      CdhCore.events.PktSend -> ComCcsds.comQueue.comPacketQueueIn[ComCcsds.Ports_ComPacketQueue.EVENTS]
      CdhCore.tlmSend.PktSend -> ComCcsds.comQueue.comPacketQueueIn[ComCcsds.Ports_ComPacketQueue.TELEMETRY]

      # Router to CmdSplitter for command routing
      # Local UART commands from ComCcsds router go through splitter
      ComCcsds.fprimeRouter.commandOut -> cmdSplitter.CmdBuff[0]
      
      # Remote commands from RPi GenericHub also go through splitter
      rpiHub.serialOut[0] -> cmdSplitter.CmdBuff[1]
      
      # All commands (local or remote) route to command dispatcher
      cmdSplitter.RemoteCmd[0] -> CdhCore.cmdDisp.seqCmdBuff
      
      # Command responses route back through splitter
      CdhCore.cmdDisp.seqCmdStatus -> cmdSplitter.seqCmdStatus[1]
      cmdSplitter.forwardSeqCmdStatus[0] -> ComCcsds.fprimeRouter.cmdResponseIn
      cmdSplitter.forwardSeqCmdStatus[1] -> rpiHub.serialIn[0]
    }

    connections Communications {
      # ComDriver <-> ByteStreamBufferAdapter
      # ComDriver buffer allocations (single connection point)
      commDriver.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      commDriver.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
      
      # UART receive path: commDriver -> ByteStreamBufferAdapter
      commDriver.$recv -> uartBufferAdapter.fromByteStreamDriver
      uartBufferAdapter.fromByteStreamDriverReturn -> ComCcsds.commsBufferManager.bufferSendIn
      
      # UART send path: ByteStreamBufferAdapter -> commDriver
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
      rateGroup1.RateGroupMemberOut[3] -> ComCcsds.comQueue.run
      rateGroup1.RateGroupMemberOut[4] -> led.run
      rateGroup1.RateGroupMemberOut[5] -> led1.run
      rateGroup1.RateGroupMemberOut[6] -> led2.run
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
    }

    connections recv_hub {
      # Buffer adapter delivers to GenericHub for deserialization
      uartBufferAdapter.bufferOut -> rpiHub.fromBufferDriver
      rpiHub.fromBufferDriverReturn -> uartBufferAdapter.bufferOutReturn
    }

    connections hub {
      # GenericHub needs buffer allocation for serializing telemetry/events
      rpiHub.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      rpiHub.deallocate -> ComCcsds.commsBufferManager.bufferSendIn
    }

  }

}
