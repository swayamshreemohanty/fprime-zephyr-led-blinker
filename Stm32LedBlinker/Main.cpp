// ======================================================================
// \title  Main.cpp
// \brief main program for the F' application. Intended for CLI-based systems (Linux, macOS)
//
// ======================================================================
// Used to access topology functions
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopologyAc.hpp>
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopology.hpp>
#include <Fw/Logger/Logger.hpp>

const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(lpuart1));

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
    
    while(true)
    {
        // Call cycle which will trigger rate groups if timer expired
        Stm32LedBlinker::rateDriver.cycle();
        
        // Small yield to allow timer ISR to run
        k_usleep(1);
    }

    printk("ERROR: Exited main loop unexpectedly!\n");
    return 0;
}
