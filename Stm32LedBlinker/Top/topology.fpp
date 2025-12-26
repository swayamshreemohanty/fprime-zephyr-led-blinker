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
    # NOTE: Removed ComCcsds subtopology for hub pattern spoke node
    # The hub pattern routes all commands/events/telemetry through GenericHub to RPi master
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

    # Hub pattern components for spoke node
    instance rpiHub
    instance uartBufferAdapter
    instance hubBufferManager

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    # Commands are dispatched locally by CdhCore.cmdDisp
    command connections instance CdhCore.cmdDisp

    # Events route THROUGH the hub to RPi master (not local processing)
    event connections instance rpiHub

    # Telemetry routes THROUGH the hub to RPi master (not local processing)
    telemetry connections instance rpiHub

    # Text events still go to local logger (optional, for debug)
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
    # Hub Pattern - Spoke Node (STM32) Communication with RPi Master
    # ----------------------------------------------------------------------
    # STM32 is a remote spoke node controlled by RPi master hub
    # Uses same architecture as RPi: GenericHub <-> ByteStreamBufferAdapter <-> UartDriver
    # Commands flow: RPi -> UART -> uartBufferAdapter -> rpiHub -> cmdDisp
    # Events/Telemetry flow: components -> rpiHub -> uartBufferAdapter -> UART -> RPi

    connections HubSend {
      # GenericHub sends serialized telemetry/events to ByteStreamBufferAdapter
      rpiHub.toBufferDriver -> uartBufferAdapter.bufferIn
      rpiHub.allocate -> hubBufferManager.bufferGetCallee
      
      # Return ownership of buffers to GenericHub after they're sent
      uartBufferAdapter.bufferInReturn -> rpiHub.toBufferDriverReturn
      
      # ByteStreamBufferAdapter converts to byte stream and sends to UART driver
      uartBufferAdapter.toByteStreamDriver -> commDriver.$send
    }

    connections HubReceive {
      # UART driver receives byte stream and passes to ByteStreamBufferAdapter
      commDriver.$recv -> uartBufferAdapter.fromByteStreamDriver
      commDriver.allocate -> hubBufferManager.bufferGetCallee
      commDriver.deallocate -> hubBufferManager.bufferSendIn
      commDriver.ready -> uartBufferAdapter.byteStreamDriverReady
      
      # Return ownership of buffers received from UART driver
      uartBufferAdapter.fromByteStreamDriverReturn -> commDriver.recvReturnIn
      
      # ByteStreamBufferAdapter converts byte stream to buffers and sends to GenericHub
      uartBufferAdapter.bufferOut -> rpiHub.fromBufferDriver
      
      # Hub returns processed buffers
      rpiHub.fromBufferDriverReturn -> uartBufferAdapter.bufferOutReturn
    }

    connections HubPortRouting {
      # Hub deserializes commands from RPi and routes directly to cmdDisp
      # This is the simplest approach for embedded spoke nodes
      # NOTE: serial ports can connect directly to typed ports (Fw.Com)
      # Due to FPP matched port rules, we can only use ONE index per instance
      rpiHub.serialOut[0] -> CdhCore.cmdDisp.seqCmdBuff[0]
      
      # Command responses route back to hub for transmission to RPi
      CdhCore.cmdDisp.seqCmdStatus[0] -> rpiHub.serialIn[0]
      
      # Buffer management for hub - deallocate used buffers
      rpiHub.deallocate -> hubBufferManager.bufferSendIn
    }

  }

}
