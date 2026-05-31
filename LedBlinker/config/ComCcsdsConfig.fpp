module ComCcsdsConfig {
    #Base ID for the ComCcsds Subtopology, all components are offsets from this base ID
    constant BASE_ID = 0x02000000
    
    module QueueSizes {
        constant comQueue    = 50
        constant aggregator  = 10
    }
    
    module StackSizes {
        constant comQueue   = 4 * 1024
        constant aggregator = 4 * 1024
    }

    module Priorities {
        constant aggregator = 30
        constant comQueue   = 29
    }

    # Queue configuration constants
    module QueueDepths {
        constant events      = 10             
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
        constant commsBuffCount        = 5        
        constant commsFileBuffCount    = 5       
        constant commsBuffMgrId        = 200      
    }
}
