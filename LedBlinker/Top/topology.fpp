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
    instance deframer
    instance eventLogger
    instance fatalAdapter
    instance fatalHandler
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
    instance rpiHub

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

    connections send_hub {
      # Send events and telemetry to framer as Com packets
      eventLogger.PktSend -> framer.comIn
      tlmSend.PktSend -> framer.comIn
      
      # Hub sends serialized data via framer to UART
      rpiHub.dataOut -> framer.bufferIn
      rpiHub.dataOutAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.framer]
      
      framer.framedOut -> commDriver.$send
      framer.bufferDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.framer]
      framer.framedAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.framer]
      
      commDriver.deallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.framer]
    }

    connections recv_hub {
      # Hub receives deserialized data via deframer from UART
      commDriver.$recv -> deframer.framedIn
      commDriver.allocate -> staticMemory.bufferAllocate[Ports_StaticMemory.deframer]

      deframer.comOut -> rpiHub.portIn[0]
      deframer.bufferOut -> rpiHub.dataIn
      deframer.bufferAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.deframing]
      deframer.framedDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.deframer]
      
      rpiHub.dataInDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.deframing]
    }

    connections hub {
      # Hub routes commands from RPi master to local command dispatcher
      rpiHub.portOut[0] -> cmdDisp.seqCmdBuff
      
      # Command responses sent back to RPi master via hub  
      cmdDisp.seqCmdStatus -> rpiHub.portIn[1]
      
      # Hub deallocates buffers
      rpiHub.buffersOut -> staticMemory.bufferDeallocate[Ports_StaticMemory.deframing]
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
