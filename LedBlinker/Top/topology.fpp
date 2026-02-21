module LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
    }

  topology LedBlinker {

    # ----------------------------------------------------------------------
    # Instances used in the topology - Remote Spoke Node
    # ----------------------------------------------------------------------
    # This is a SPOKE (remote) NODE in GenericHub pattern
    # All events/telemetry route through hub to RPi master
    # Commands come from RPi master via hub

    instance chronoTime
    instance uartDriver
    instance gpioDriver
    instance led
    instance rateDriver
    instance rateGroup1
    instance rateGroupDriver

    # Command infrastructure
    instance cmdDisp

    # Communication stack components
    instance framer
    instance deframer
    instance frameAccumulator
    instance fprimeRouter
    instance comStub
    instance commsBufferManager
    instance tlmSend
    instance tlmChan
    instance eventLogger
    instance textLogger

    # ----------------------------------------------------------------------
    # Pattern graph specifiers - Standard F Prime Communication
    # ----------------------------------------------------------------------

    # Commands route to local CommandDispatcher
    command connections instance cmdDisp

    # Events route to active event logger
    event connections instance eventLogger
    
    # Telemetry routes to telemetry database
    telemetry connections instance tlmChan

    # Text events go to text logger
    text event connections instance textLogger

    # Time connections to local time component
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
      rateGroup1.RateGroupMemberOut[0] -> tlmChan.Run
      rateGroup1.RateGroupMemberOut[1] -> uartDriver.schedIn  # Poll UART RX buffer
      rateGroup1.RateGroupMemberOut[2] -> led.run
      rateGroup1.RateGroupMemberOut[3] -> tlmSend.run
    }

    connections LedConnections {
      # LED GPIO connections
      led.gpioSet -> gpioDriver.gpioWrite
    }

    # ----------------------------------------------------------------------
    # Communication Stack - Downlink (Events/Telemetry to GDS)
    # ----------------------------------------------------------------------
    
    connections Downlink {
      # EventLogger -> ComQueue
      eventLogger.PktSend -> tlmSend.comPacketQueueIn[0]
      
      # TlmChan -> ComQueue
      tlmChan.PktSend -> tlmSend.comPacketQueueIn[1]
      
      # ComQueue -> Framer
      tlmSend.dataOut -> framer.dataIn
      framer.dataReturnOut -> tlmSend.dataReturnIn
      framer.comStatusOut -> tlmSend.comStatusIn

      # Framer -> ComStub
      framer.dataOut -> comStub.dataIn
      comStub.dataReturnOut -> framer.dataReturnIn
      comStub.comStatusOut -> framer.comStatusIn
      
      # ComStub -> UART (TX)
      comStub.drvSendOut -> uartDriver.$send
      uartDriver.ready -> comStub.drvConnected
      
      # Framer buffer management
      framer.bufferAllocate -> commsBufferManager.bufferGetCallee
      framer.bufferDeallocate -> commsBufferManager.bufferSendIn
    }

    # ----------------------------------------------------------------------
    # Communication Stack - Uplink (Commands from GDS)
    # ----------------------------------------------------------------------
    
    connections Uplink {
      # UART -> ComStub (RX)
      uartDriver.$recv -> comStub.drvReceiveIn
      comStub.drvReceiveReturnOut -> uartDriver.recvReturnIn

      # ComStub -> FrameAccumulator
      comStub.dataOut -> frameAccumulator.dataIn
      frameAccumulator.dataReturnOut -> comStub.dataReturnIn

      # FrameAccumulator -> Deframer
      frameAccumulator.dataOut -> deframer.dataIn
      deframer.dataReturnOut -> frameAccumulator.dataReturnIn
      
      # Deframer -> FprimeRouter
      deframer.dataOut -> fprimeRouter.dataIn
      fprimeRouter.dataReturnOut -> deframer.dataReturnIn
      
      # FprimeRouter -> CommandDispatcher
      fprimeRouter.commandOut -> cmdDisp.seqCmdBuff[0]
      cmdDisp.seqCmdStatus[0] -> fprimeRouter.cmdResponseIn
      
      # FprimeRouter buffer management
      fprimeRouter.bufferAllocate -> commsBufferManager.bufferGetCallee
      fprimeRouter.bufferDeallocate -> commsBufferManager.bufferSendIn

      # TlmSend buffer management
      tlmSend.bufferReturnOut[0] -> commsBufferManager.bufferSendIn

      # FrameAccumulator buffer management
      frameAccumulator.bufferAllocate -> commsBufferManager.bufferGetCallee
      frameAccumulator.bufferDeallocate -> commsBufferManager.bufferSendIn

    }
    
    connections UartBufferManagement {
      # UART driver buffer allocation/deallocation
      uartDriver.allocate -> commsBufferManager.bufferGetCallee
      uartDriver.deallocate -> commsBufferManager.bufferSendIn
    }

  }

}
