module ComFprimeConfig {
    #Base ID for the ComFprime Subtopology, all components are offsets from this base ID
    constant BASE_ID = 0x03000000
    
    module QueueSizes {
        constant comQueue    = 50
    }
    
    module StackSizes {
        constant comQueue   = 4 * 1024
    }

    module Priorities {
        constant comQueue   = 29
    }

    # Queue configuration constants
    module QueueDepths {
        constant events      = 20            
        constant tlm         = 20            
        constant file        = 10           
    }

    module QueuePriorities {
        constant events      = 0              
        constant tlm         = 2              
        constant file        = 1             
    }

    # Buffer management constants
    module BuffMgr {
        constant frameAccumulatorSize  = 1024     
        constant commsBuffSize         = 1024      
        constant commsFileBuffSize     = 1024      
        constant commsBuffCount        = 10      
        constant commsFileBuffCount    = 5        
        constant commsBuffMgrId        = 200      
    }
}
