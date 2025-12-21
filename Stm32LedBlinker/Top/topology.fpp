module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
    }

    enum Ports_StaticMemory {
      framer
      deframer
    }

  topology Stm32LedBlinker {

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance cmdDisp
    instance comQueue
    instance comStub
    instance commDriver
    instance deframer
    instance eventLogger
    instance fatalAdapter
    instance fatalHandler
    instance fprimeRouter
    instance framer
    instance gpioDriver
    instance gpioDriver1
    instance gpioDriver2
    instance led
    instance led1
    instance led2
    instance rateDriver
    instance rateGroup1
    instance rateGroupDriver
    instance staticMemory
    instance systemResources
    instance textLogger
    instance timeHandler
    instance tlmSend

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance cmdDisp

    event connections instance eventLogger

    telemetry connections instance tlmSend

    text event connections instance textLogger

    time connections instance timeHandler

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      # GDS components (commDriver, comQueue) temporarily removed from rate group
      # They cause system hang - need to debug UART/buffer configuration
      rateGroup1.RateGroupMemberOut[0] -> tlmSend.Run
      rateGroup1.RateGroupMemberOut[1] -> systemResources.run
      rateGroup1.RateGroupMemberOut[2] -> led.run
      rateGroup1.RateGroupMemberOut[3] -> led1.run
      rateGroup1.RateGroupMemberOut[4] -> led2.run
    }

    connections FaultProtection {
      eventLogger.FatalAnnounce -> fatalHandler.FatalReceive
    }

    connections Downlink {
      # Telemetry and Events to ComQueue
      tlmSend.PktSend -> comQueue.comPacketQueueIn[0]
      eventLogger.PktSend -> comQueue.comPacketQueueIn[1]
      
      # ComQueue to Framer
      comQueue.dataOut -> framer.dataIn
      framer.dataReturnOut -> comQueue.dataReturnIn

      # Framer buffer management
      framer.bufferAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.framer]
      framer.bufferDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.framer]

      # Framer to ComStub to ByteStream driver
      framer.dataOut -> comStub.dataIn
      comStub.dataReturnOut -> framer.dataReturnIn
      comStub.drvSendOut -> commDriver.$send
      commDriver.ready -> comStub.drvConnected

      # ComStatus
      framer.comStatusOut -> comQueue.comStatusIn
      comStub.comStatusOut -> framer.comStatusIn
    }
    
    connections Uplink {
      # ByteStream driver to ComStub to Deframer
      commDriver.allocate -> staticMemory.bufferAllocate[Ports_StaticMemory.deframer]
      commDriver.$recv -> comStub.drvReceiveIn
      comStub.drvReceiveReturnOut -> commDriver.recvReturnIn
      
      comStub.dataOut -> deframer.dataIn
      deframer.dataReturnOut -> comStub.dataReturnIn

      # Deframer to Router
      deframer.dataOut -> fprimeRouter.dataIn
      fprimeRouter.dataReturnOut -> deframer.dataReturnIn

      # Router buffer management
      fprimeRouter.bufferAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.framer]
      fprimeRouter.bufferDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.framer]

      # Router to Command Dispatcher
      fprimeRouter.commandOut -> cmdDisp.seqCmdBuff
      cmdDisp.seqCmdStatus -> fprimeRouter.cmdResponseIn
    }

    connections LedConnections {
      # LED GPIO connections
      led.gpioSet -> gpioDriver.gpioWrite
      led1.gpioSet -> gpioDriver1.gpioWrite
      led2.gpioSet -> gpioDriver2.gpioWrite
    }

    connections Stm32LedBlinker {
      # Add here connections to user-defined components
    }

  }

}
