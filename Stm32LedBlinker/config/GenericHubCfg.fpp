module Svc {
  module GenericHubCfg {

    @ Hub connections. Connections on all deployments should mirror these settings.
    @ These values match the F-Prime GenericHub documentation standard pattern.
    @ Serial ports: for typed port calls (commands, parameters, etc.)
    @ Buffer ports: for buffer data transfers (files, data products, etc.)
    
    constant NumSerialInputPorts = 10
    constant NumSerialOutputPorts = 10
    constant NumBufferInputPorts = 10
    constant NumBufferOutputPorts = 10

  }
}
