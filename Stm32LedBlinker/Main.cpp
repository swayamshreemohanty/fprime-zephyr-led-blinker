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
    
    int loop_count = 0;
    while(true)
    {
        if (loop_count % 1000 == 0) {
            printk("Main loop iteration %d\n", loop_count);
        }
        
        if (loop_count == 0) {
            printk("  Calling rateDriver.cycle()...\n");
        }
        Stm32LedBlinker::rateDriver.cycle();
        
        if (loop_count == 0) {
            printk("  rateDriver.cycle() completed\n");
            printk("  Calling k_usleep(1)...\n");
        }
        k_usleep(1);
        
        if (loop_count == 0) {
            printk("  k_usleep(1) completed\n");
            printk("  First loop iteration complete!\n");
        }
        
        loop_count++;
    }

    printk("ERROR: Exited main loop unexpectedly!\n");
    return 0;
}
