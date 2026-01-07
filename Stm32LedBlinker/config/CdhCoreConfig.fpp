module CdhCoreConfig {
    # Base ID for the CdhCore Subtopology
    constant BASE_ID = 0x01000000
    
    module QueueSizes {
        constant cmdDisp     = 5     # Reduced for embedded
        constant events      = 10    # Reduced for embedded
        constant tlmSend     = 5     # Reduced for embedded
        constant $health     = 5     # Reduced for embedded
    }
    
    module StackSizes {
        # Increased stack sizes for embedded STM32 with events/telemetry enabled
        constant cmdDisp     = 8 * 1024
        constant events      = 8 * 1024
        constant tlmSend     = 8 * 1024
    }

    module Priorities {
        constant cmdDisp     = 10
        constant $health     = 11
        constant events      = 12
        constant tlmSend     = 13
    }
}
