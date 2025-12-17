module LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
    }

    enum Ports_StaticMemory {
      framer
      deframer
      deframing
    }

  topology LedBlinker {

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance cmdDisp
    instance commDriver
    instance comQueue
    instance comStub
    instance eventLogger
    instance fatalAdapter
    instance fatalHandler
    instance fprimeRouter
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
      rateGroup1.RateGroupMemberOut[0] -> commDriver.schedIn
      rateGroup1.RateGroupMemberOut[1] -> tlmSend.Run
      rateGroup1.RateGroupMemberOut[2] -> systemResources.run
      # LED components scheduled at 1Hz
      rateGroup1.RateGroupMemberOut[3] -> led.run
      rateGroup1.RateGroupMemberOut[4] -> led1.run
      rateGroup1.RateGroupMemberOut[5] -> led2.run
    }

    connections FaultProtection {
      eventLogger.FatalAnnounce -> fatalHandler.FatalReceive
    }

    connections Communications {
      # ComDriver buffer allocations
      commDriver.allocate -> staticMemory.bufferAllocate[Ports_StaticMemory.deframer]
      commDriver.deallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.framer]
      
      # ComDriver <-> ComStub (Uplink)
      commDriver.$recv -> comStub.drvReceiveIn
      comStub.drvReceiveReturnOut -> staticMemory.bufferDeallocate[Ports_StaticMemory.deframer]
      
      # ComStub <-> ComDriver (Downlink)
      comStub.drvSendOut -> commDriver.$send
      commDriver.ready -> comStub.drvConnected
      
      # ComQueue to/from ComStub
      comQueue.dataOut -> comStub.dataIn
      comStub.dataReturnOut -> comQueue.dataReturnIn
      comStub.comStatusOut -> comQueue.comStatusIn
      
      # Events and telemetry to ComQueue
      eventLogger.PktSend -> comQueue.comPacketQueueIn[0]
      tlmSend.PktSend -> comQueue.comPacketQueueIn[1]
      
      # ComStub to Router
      comStub.dataOut -> fprimeRouter.dataIn
      fprimeRouter.dataReturnOut -> comStub.dataReturnIn
      
      # Router to Command Dispatcher
      fprimeRouter.commandOut -> cmdDisp.seqCmdBuff
      cmdDisp.seqCmdStatus -> fprimeRouter.cmdResponseIn
      
      # Router buffer management
      fprimeRouter.bufferAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.deframing]
      fprimeRouter.bufferDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.deframing]
    }

    connections LedConnections {
      # LED GPIO connections
      led.gpioSet -> gpioDriver.gpioWrite
      led1.gpioSet -> gpioDriver1.gpioWrite
      led2.gpioSet -> gpioDriver2.gpioWrite
    }

    connections LedBlinker {
      # Add here connections to user-defined components
    }

  }

}
