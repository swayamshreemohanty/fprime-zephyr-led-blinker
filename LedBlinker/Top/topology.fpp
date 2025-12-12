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
    }

    connections FaultProtection {
      eventLogger.FatalAnnounce -> fatalHandler.FatalReceive
    }

    # ----------------------------------------------------------------------
    # GenericHub Pattern Communication with RPi Master
    # ----------------------------------------------------------------------
    # NASA official pattern for distributed F-Prime systems
    # STM32 = Remote Node, RPi = Master Node
    # Commands from RPi -> STM32, Telemetry/Events from STM32 -> RPi
    # ----------------------------------------------------------------------
    
    connections HubDownlink {
      # Send telemetry and events to RPi via GenericHub
      tlmSend.PktSend -> rpiHub.portIn[0]
      eventLogger.PktSend -> rpiHub.portIn[1]
    }
    
    connections HubUplink {
      # Receive commands from RPi via GenericHub
      rpiHub.portOut[0] -> cmdDisp.seqCmdBuff
      cmdDisp.seqCmdStatus -> rpiHub.portIn[2]
    }
    
    connections HubUartLink {
      # GenericHub <-> Framer/Deframer <-> UART Driver
      # Hub serializes typed ports, framer adds protocol framing
      
      # Downlink: Hub -> Framer -> UART
      rpiHub.buffersOut[0] -> framer.bufferIn
      framer.framedOut -> commDriver.$send
      framer.bufferDeallocate -> staticMemory.bufferDeallocate[0]
      framer.framedAllocate -> staticMemory.bufferAllocate[0]
      
      # Uplink: UART -> Deframer -> Hub
      commDriver.$recv -> deframer.framedIn
      deframer.bufferOut -> rpiHub.buffersIn[0]
      deframer.framedDeallocate -> staticMemory.bufferDeallocate[1]
      deframer.bufferAllocate -> staticMemory.bufferAllocate[1]
      
      # UART Driver buffer management
      commDriver.allocate -> staticMemory.bufferAllocate[2]
      commDriver.deallocate -> staticMemory.bufferDeallocate[2]
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
