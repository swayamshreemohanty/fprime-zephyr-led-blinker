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
    # CdhCore provides cmdDisp, eventLogger, tlmSend, health, textLogger
    import CdhCore.Subtopology

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

    # Hub pattern components for spoke node (temporarily simplified)
    instance rpiHub
    instance uartBufferAdapter
    instance hubBufferManager

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    # Commands are dispatched locally by CdhCore.cmdDisp
    command connections instance CdhCore.cmdDisp

    # Events processed locally (hub routing TBD - causes crash during regCommands)
    event connections instance CdhCore.events

    # Telemetry processed locally (hub routing TBD - causes crash during regCommands)
    telemetry connections instance CdhCore.tlmSend

    # Text events go to local logger (for serial debug output)
    text event connections instance CdhCore.textLogger

    # Health connections to local health component
    health connections instance CdhCore.$health

    # Time connections to local time component
    time connections instance chronoTime

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1 - All periodic components
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      rateGroup1.RateGroupMemberOut[0] -> commDriver.schedIn
      rateGroup1.RateGroupMemberOut[1] -> hubBufferManager.schedIn
      rateGroup1.RateGroupMemberOut[2] -> led.run
      rateGroup1.RateGroupMemberOut[3] -> led1.run
      rateGroup1.RateGroupMemberOut[4] -> led2.run
    }

    connections LedConnections {
      # LED GPIO connections
      led.gpioSet -> gpioDriver.gpioWrite
      led1.gpioSet -> gpioDriver1.gpioWrite
      led2.gpioSet -> gpioDriver2.gpioWrite
    }

    # ----------------------------------------------------------------------
    # Hub Pattern - Basic UART Communication (simplified for testing)
    # ----------------------------------------------------------------------
    # For now, just wire up buffer allocation - no command routing through hub yet
    # This allows us to test basic LED functionality first

    connections HubBufferManagement {
      # Hub buffer allocation
      rpiHub.allocate -> hubBufferManager.bufferGetCallee
      rpiHub.deallocate -> hubBufferManager.bufferSendIn
      
      # UART driver buffer allocation  
      commDriver.allocate -> hubBufferManager.bufferGetCallee
      commDriver.deallocate -> hubBufferManager.bufferSendIn
    }

    connections HubUartConnection {
      # Basic hub to UART wiring
      rpiHub.toBufferDriver -> uartBufferAdapter.bufferIn
      uartBufferAdapter.bufferInReturn -> rpiHub.toBufferDriverReturn
      uartBufferAdapter.toByteStreamDriver -> commDriver.$send
      
      # UART receive to hub
      commDriver.$recv -> uartBufferAdapter.fromByteStreamDriver
      commDriver.ready -> uartBufferAdapter.byteStreamDriverReady
      uartBufferAdapter.fromByteStreamDriverReturn -> commDriver.recvReturnIn
      uartBufferAdapter.bufferOut -> rpiHub.fromBufferDriver
      rpiHub.fromBufferDriverReturn -> uartBufferAdapter.bufferOutReturn
    }

  }

}
