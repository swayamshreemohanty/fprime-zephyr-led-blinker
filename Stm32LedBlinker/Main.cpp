// ======================================================================
// \title  Main.cpp
// \brief main program for the F' application. Intended for CLI-based systems (Linux, macOS)
//
// ======================================================================
// Used to access topology functions
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopologyAc.hpp>
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopology.hpp>
#include <Fw/Logger/Logger.hpp>

const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(usart3));

// Fatal error handler
extern "C" void k_sys_fatal_error_handler(unsigned int reason, const struct arch_esf *esf)
{
    printk("\n\n*** FATAL ERROR ***\n");
    printk("Reason: %u\n", reason);
    printk("ESF: %p\n", esf);
    
    // Try to print some useful info
    #if defined(CONFIG_THREAD_STACK_INFO)
    struct k_thread *current = k_current_get();
    if (current) {
        printk("Current thread: %s\n", k_thread_name_get(current));
        size_t unused;
        if (k_thread_stack_space_get(current, &unused) == 0) {
            printk("Stack unused: %zu bytes\n", unused);
        }
    }
    #endif
    
    while(1) {
        k_sleep(K_FOREVER);
    }
}

int main()
{
    printk("Starting F' LED Blinker\n");

    // Object for communicating state to the reference topology
    Stm32LedBlinker::TopologyState inputs;
    inputs.dev = serial;
    inputs.uartBaud = 115200;

    printk("Setting up topology...\n");
    // Setup topology
    Stm32LedBlinker::setupTopology(inputs);

    printk("Entering main loop\n");
    printk("DEBUG: About to enter while loop...\n");
    
    U32 cycleCount = 0;
    while(true)
    {
        if (cycleCount == 0) {
            printk("DEBUG: First iteration of while loop\n");
        }
        
        // Call cycle which will trigger rate groups if timer expired
        if (cycleCount < 5) {
            printk("DEBUG: Before rateDriver.cycle() - iteration %u\n", cycleCount);
        }
        
        Stm32LedBlinker::rateDriver.cycle();
        
        if (cycleCount < 5) {
            printk("DEBUG: After rateDriver.cycle() - iteration %u\n", cycleCount);
        }
        
        cycleCount++;
        if (cycleCount % 100 == 0) {
            printk("Main loop running, cycles: %u\n", cycleCount);
        }
        
        // Small yield to allow timer ISR to run
        if (cycleCount < 5) {
            printk("DEBUG: Before k_usleep() - iteration %u\n", cycleCount);
        }
        k_usleep(1);
        if (cycleCount < 5) {
            printk("DEBUG: After k_usleep() - iteration %u\n", cycleCount);
        }
    }

    printk("ERROR: Exited main loop unexpectedly!\n");
    return 0;
}
