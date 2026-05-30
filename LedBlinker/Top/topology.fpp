module LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
    }

  topology LedBlinker {

    # ----------------------------------------------------------------------
    # Subtopology imports
    # ----------------------------------------------------------------------
    import CdhCore.Subtopology
    import ComFprime.Subtopology

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance chronoTime
    instance uartDriver
    instance gpioDriver
    instance led
    instance rateDriver
    instance rateGroup1
    instance rateGroupDriver

    # ----------------------------------------------------------------------
    # Pattern graph specifiers - Standard F Prime Communication
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

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1 - Periodic scheduling
      # CRITICAL: uartDriver.schedIn MUST be connected to poll UART RX ring buffer
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      rateGroup1.RateGroupMemberOut[0] -> CdhCore.tlmSend.Run
      rateGroup1.RateGroupMemberOut[1] -> uartDriver.schedIn  # Poll UART RX buffer
      rateGroup1.RateGroupMemberOut[2] -> led.run
      rateGroup1.RateGroupMemberOut[3] -> ComFprime.comQueue.run
      rateGroup1.RateGroupMemberOut[4] -> CdhCore.$health.Run
    }

    connections LedConnections {
      # LED GPIO connections
      led.gpioSet -> gpioDriver.gpioWrite
    }

    connections ComFprime_CdhCore {
      # Core events and telemetry to communication queue
      CdhCore.events.PktSend -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.EVENTS]
      CdhCore.tlmSend.PktSend -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.TELEMETRY]

      # Command routing
      ComFprime.fprimeRouter.commandOut -> CdhCore.cmdDisp.seqCmdBuff[0]
      CdhCore.cmdDisp.seqCmdStatus[0] -> ComFprime.fprimeRouter.cmdResponseIn
    }

    connections Communications {
      # UART GDS Driver buffer allocations
      uartDriver.allocate      -> ComFprime.commsBufferManager.bufferGetCallee
      uartDriver.deallocate    -> ComFprime.commsBufferManager.bufferSendIn
      
      # UART Driver <-> ComStub (Uplink)
      uartDriver.$recv -> ComFprime.comStub.drvReceiveIn
      ComFprime.comStub.drvReceiveReturnOut -> uartDriver.recvReturnIn
      
      # ComStub <-> UART (Downlink)
      ComFprime.comStub.drvSendOut      -> uartDriver.$send
      uartDriver.ready         -> ComFprime.comStub.drvConnected
    }

  }

}
