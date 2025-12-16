module LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
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
    }

    connections FaultProtection {
      eventLogger.FatalAnnounce -> fatalHandler.FatalReceive
    }

    connections HubCommunication {
      # GenericHub for command routing from RPi master
      # STM32 acts as remote node receiving commands via UART
      
      # Incoming commands: Deframer -> GenericHub -> CommandDispatcher
      deframer.comOut -> rpiHub.portIn[0]
      rpiHub.portOut[0] -> cmdDisp.seqCmdBuff
      
      # Command responses: CommandDispatcher -> GenericHub -> Framer
      cmdDisp.seqCmdStatus -> rpiHub.portIn[1]
      rpiHub.buffersOut[0] -> framer.bufferIn
      
      # Events and telemetry: Sent directly to framer as Com packets
      # These will be received by RPi and displayed in GDS
      eventLogger.PktSend -> framer.comIn
      tlmSend.PktSend -> framer.comIn
      
      # Deframer buffer/file output goes to hub for deserialization
      deframer.bufferOut -> rpiHub.buffersIn[0]
    }
    
    connections UartCommunication {
      # Connect framer output to UART driver for transmission
      framer.framedOut -> commDriver.$send
      
      # Connect UART driver received data to deframer
      commDriver.$recv -> deframer.framedIn
      
      # Framer buffer management - parallel ports for allocate/deallocate
      framer.framedAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.framerBuffers]
      framer.bufferDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.framerBuffers]
      
      # Deframer buffer management - parallel ports for allocate/deallocate  
      deframer.framedDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.deframerBuffers]
      deframer.bufferAllocate -> staticMemory.bufferAllocate[Ports_StaticMemory.deframerBuffers]
      deframer.bufferDeallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.deframerBuffers]
      
      # UART driver buffer management - parallel ports for allocate/deallocate
      commDriver.allocate -> staticMemory.bufferAllocate[Ports_StaticMemory.commDriverBuffers]
      commDriver.deallocate -> staticMemory.bufferDeallocate[Ports_StaticMemory.commDriverBuffers]
    }

    connections LedConnections {
      # Rate Group 1 (1Hz cycle) ouput is connected to led's run input
      rateGroup1.RateGroupMemberOut[3] -> led.run
      # led's gpioSet output is connected to gpioDriver's gpioWrite input
      led.gpioSet -> gpioDriver.gpioWrite
      
      # LED1 connections
      rateGroup1.RateGroupMemberOut[4] -> led1.run
      led1.gpioSet -> gpioDriver1.gpioWrite
      
      # LED2 connections
      rateGroup1.RateGroupMemberOut[5] -> led2.run
      led2.gpioSet -> gpioDriver2.gpioWrite
    }

    connections LedBlinker {
      # Add here connections to user-defined components
    }

  }

}
