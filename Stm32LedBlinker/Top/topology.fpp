module Stm32LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup1
    }

  topology Stm32LedBlinker {

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
    instance proxyGroundInterface
    instance proxySequencer

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

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1 - Periodic scheduling
      # NOTE: uartDriver.schedIn removed - UART transmits on-demand, not periodically
      # This prevents buffer exhaustion from periodic forced transmissions
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      rateGroup1.RateGroupMemberOut[0] -> bufferManager.schedIn
      rateGroup1.RateGroupMemberOut[1] -> led.run
      rateGroup1.RateGroupMemberOut[2] -> led1.run
      rateGroup1.RateGroupMemberOut[3] -> led2.run
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
    # Matches RemoteDeployment from fprime-generichub-reference but with
    # ByteStreamBufferAdapter (current F´ API) instead of ComStub+Framer
    # 
    # Architecture: Hub ↔ ByteStreamBufferAdapter ↔ UART Driver

    connections HubToDriver {
      # Hub -> ByteStreamBufferAdapter -> UART Driver (downlink)
      hub.toBufferDriver -> bufferAdapter.bufferIn
      bufferAdapter.bufferInReturn -> hub.toBufferDriverReturn
      bufferAdapter.toByteStreamDriver -> uartDriver.$send
      
      # UART Driver -> ByteStreamBufferAdapter -> Hub (uplink)
      uartDriver.$recv -> bufferAdapter.fromByteStreamDriver
      uartDriver.ready -> bufferAdapter.byteStreamDriverReady
      bufferAdapter.fromByteStreamDriverReturn -> uartDriver.recvReturnIn
      bufferAdapter.bufferOut -> hub.fromBufferDriver
      hub.fromBufferDriverReturn -> bufferAdapter.bufferOutReturn
    }

    connections HubBufferManagement {
      # Hub buffer allocation/deallocation
      hub.allocate -> bufferManager.bufferGetCallee
      hub.deallocate -> bufferManager.bufferSendIn
      
      # UART driver buffer allocation/deallocation
      uartDriver.allocate -> bufferManager.bufferGetCallee
      uartDriver.deallocate -> bufferManager.bufferSendIn
    }

    connections HubToDeployment {
      # Hub receives commands from RPi and forwards to proxy components
      # This matches the RPi local command routing pattern
      hub.serialOut[0] -> proxyGroundInterface.seqCmdBuf
      hub.serialOut[1] -> proxySequencer.seqCmdBuf
      
      # Proxies forward commands to local CommandDispatcher
      proxyGroundInterface.comCmdOut -> cmdDisp.seqCmdBuff
      proxySequencer.comCmdOut -> cmdDisp.seqCmdBuff
      
      # CommandDispatcher sends responses back to proxies
      cmdDisp.seqCmdStatus -> proxyGroundInterface.cmdResponseIn
      cmdDisp.seqCmdStatus -> proxySequencer.cmdResponseIn
      
      # Proxies send responses back to hub, which forwards to RPi
      proxyGroundInterface.seqCmdStatus -> hub.serialIn[0]
      proxySequencer.seqCmdStatus -> hub.serialIn[1]
    }

  }

}
