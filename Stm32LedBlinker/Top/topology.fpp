module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
    }

  topology Stm32LedBlinker {

    # ----------------------------------------------------------------------
    # Instances used in the topology - Hub-Native Spoke Node
    # ----------------------------------------------------------------------
    # This is a SPOKE NODE topology - no local command dispatcher needed
    # All events/telemetry route through GenericHub to RPi master node
    # RPi master handles command dispatch and routes commands back via hub

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

    # Hub pattern components for spoke node
    instance rpiHub
    instance uartBufferAdapter
    instance hubBufferManager
    
    # Local text logger for debugging (passive - no active components)
    instance textLogger

    # ----------------------------------------------------------------------
    # Pattern graph specifiers - Hub-Native Configuration
    # ----------------------------------------------------------------------

    # Events route directly to GenericHub, which forwards to RPi
    event connections instance rpiHub

    # Telemetry routes directly to GenericHub, which forwards to RPi
    telemetry connections instance rpiHub

    # Text events go to local logger for serial debug output
    text event connections instance textLogger

    # Time connections to local time component
    time connections instance chronoTime
    
    # NOTE: No command connections - spoke nodes receive commands via hub.serialOut
    # Command routing would require CmdDispatcher, which is on the master (RPi) side

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
