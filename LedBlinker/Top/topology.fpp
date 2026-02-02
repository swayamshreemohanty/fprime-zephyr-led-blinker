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
    instance gpioDriver1
    instance gpioDriver2
    instance led
    instance led1
    instance led2
    instance rateDriver
    instance rateGroup1
    instance rateGroupDriver

    # Command infrastructure
    instance cmdDisp

    # Communication stack components
    instance comQueue
    instance framer
    instance deframer
    instance frameAccumulator
    instance fprimeRouter
    instance commsBufferManager
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
      rateGroup1.RateGroupMemberOut[0] -> comQueue.run
      rateGroup1.RateGroupMemberOut[1] -> uartDriver.schedIn  # Poll UART RX buffer
      rateGroup1.RateGroupMemberOut[2] -> tlmChan.Run
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
    # Communication Stack - Downlink (Events/Telemetry to GDS)
    # ----------------------------------------------------------------------
    
    connections Downlink {
      # EventLogger -> ComQueue
      eventLogger.PktSend -> comQueue.dataInPacket[0]
      
      # TlmChan -> ComQueue
      tlmChan.PktSend -> comQueue.dataInPacket[1]
      
      # ComQueue -> Framer
      comQueue.dataOut -> framer.dataIn
      framer.dataReturnOut -> comQueue.dataReturnIn
      framer.comStatusOut -> comQueue.comStatusIn
      
      # Framer buffer management
      framer.bufferAllocate -> commsBufferManager.bufferGetCallee
      framer.bufferDeallocate -> commsBufferManager.bufferSendIn
      
      # Framer -> UART (TX)
      framer.dataOut -> uartDriver.$send
      uartDriver.sendReturnIn -> framer.dataReturnIn
      uartDriver.ready -> framer.comStatusIn
    }

    # ----------------------------------------------------------------------
    # Communication Stack - Uplink (Commands from GDS)
    # ----------------------------------------------------------------------
    
    connections Uplink {
      # UART -> FrameAccumulator (RX)
      uartDriver.$recv -> frameAccumulator.dataIn
      frameAccumulator.dataReturnOut -> uartDriver.recvReturnIn
      
      # FrameAccumulator buffer management
      frameAccumulator.bufferAllocate -> commsBufferManager.bufferGetCallee
      frameAccumulator.bufferDeallocate -> commsBufferManager.bufferSendIn
      
      # FrameAccumulator -> Deframer
      frameAccumulator.dataOut -> deframer.dataIn
      deframer.dataReturnOut -> frameAccumulator.dataReturnIn
      
      # Deframer -> FprimeRouter
      deframer.dataOut -> fprimeRouter.dataIn
      fprimeRouter.dataReturnOut -> deframer.dataReturnIn
      
      # FprimeRouter buffer management
      fprimeRouter.bufferAllocate -> commsBufferManager.bufferGetCallee
      fprimeRouter.bufferDeallocate -> commsBufferManager.bufferSendIn
      
      # FprimeRouter -> CommandDispatcher
      fprimeRouter.commandOut -> cmdDisp.seqCmdBuff[0]
      cmdDisp.seqCmdStatus[0] -> fprimeRouter.cmdResponseIn
    }
    
    connections UartBufferManagement {
      # UART driver buffer allocation/deallocation
      uartDriver.allocate -> commsBufferManager.bufferGetCallee
      uartDriver.deallocate -> commsBufferManager.bufferSendIn
    }

  }

}
