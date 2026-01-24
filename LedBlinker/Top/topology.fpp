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

    # Hub pattern components for remote spoke node
    instance hub
    instance bufferAdapter
    instance bufferManager
    instance eventLogger
    instance textLogger

    # ----------------------------------------------------------------------
    # Pattern graph specifiers - Remote Spoke Node
    # ----------------------------------------------------------------------
    # Commands route through hub from RPi, then to local CommandDispatcher
    # Events route locally; Telemetry routes through hub to RPi

    # Commands route to local CommandDispatcher
    command connections instance cmdDisp

    # CRITICAL FOR ZEPHYR: Events MUST route locally to eventLogger
    # Routing through hub causes port object name crash during regCommands()
    # This is different from Linux reference - Zephyr has different initialization
    event connections instance eventLogger
    
    # Telemetry routes directly to hub (spoke node pattern)
    # Components send telemetry -> hub collects and transmits to RPi
    telemetry connections instance hub

    # Text events go to text logger
    text event connections instance textLogger

    # Time connections to local time component
    time connections instance chronoTime

    # BufferAdapter connections
    connections BufferAdapterConnections {
      bufferAdapter.Log -> eventLogger.LogRecv
      bufferAdapter.LogText -> textLogger.TextLogger
      bufferAdapter.Time -> chronoTime.timeGetPort
    }

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1 - Periodic scheduling
      # CRITICAL: uartDriver.schedIn MUST be connected to poll UART RX ring buffer
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      rateGroup1.RateGroupMemberOut[0] -> bufferManager.schedIn
      rateGroup1.RateGroupMemberOut[1] -> uartDriver.schedIn  # Poll UART RX buffer
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
    # Hub Pattern - UART Communication (Remote Spoke Node)
    # ----------------------------------------------------------------------
    # GenericHub ↔ ByteStreamBufferAdapter ↔ UART Driver
    # Adapter bridges BufferSend (hub) to ByteStreamSend (uart)

    connections HubToAdapter {
      # Hub -> ByteStreamBufferAdapter (downlink/TX)
      hub.toBufferDriver -> bufferAdapter.bufferIn
      bufferAdapter.bufferInReturn -> hub.toBufferDriverReturn
      
      # ByteStreamBufferAdapter -> Hub (uplink/RX)
      bufferAdapter.bufferOut -> hub.fromBufferDriver
      hub.fromBufferDriverReturn -> bufferAdapter.bufferOutReturn
    }
    
    connections HubCommandRouting {
      # Hub serialOut -> CommandDispatcher (incoming commands from RPI)
      # Commands arrive as serialized Fw.Com buffers
      hub.serialOut[0] -> cmdDisp.seqCmdBuff[0]
      cmdDisp.seqCmdStatus[0] -> hub.serialIn[0]
    }

    connections AdapterToUart {
      # ByteStreamBufferAdapter -> UART Driver (TX)
      bufferAdapter.toByteStreamDriver -> uartDriver.$send
      
      # UART Driver -> ByteStreamBufferAdapter (RX)
      uartDriver.$recv -> bufferAdapter.fromByteStreamDriver
      bufferAdapter.fromByteStreamDriverReturn -> uartDriver.recvReturnIn
      
      # UART ready signal to adapter
      uartDriver.ready -> bufferAdapter.byteStreamDriverReady
    }

    connections HubBufferManagement {
      # Hub buffer allocation/deallocation
      hub.allocate -> bufferManager.bufferGetCallee
      hub.deallocate -> bufferManager.bufferSendIn
      
      # UART driver buffer allocation/deallocation
      uartDriver.allocate -> bufferManager.bufferGetCallee
      uartDriver.deallocate -> bufferManager.bufferSendIn
    }

  }

}
