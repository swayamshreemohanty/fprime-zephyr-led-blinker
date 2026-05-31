// ======================================================================
// \title  Main.cpp
// \brief main program for the F' application. Intended for CLI-based systems (Linux, macOS)
//
// ======================================================================
// Used to access topology functions
#include <LedBlinker/Top/LedBlinkerTopologyAc.hpp>
#include <LedBlinker/Top/LedBlinkerTopology.hpp>
#include <Fw/Logger/Logger.hpp>
#include <Fw/Types/Assert.hpp>
#include <stdexcept>
#include <stdio.h>

#include <zephyr/sys/printk.h>

const struct device *serial = DEVICE_DT_GET(DT_CHOSEN(zephyr_console));

// Fatal error handler
extern "C" void k_sys_fatal_error_handler(unsigned int reason, const struct arch_esf *esf)
{
    // Fatal error occurred - halt execution
    printk("FATAL EXCEPTION (reason: %u)!\n", reason);
    (void)reason;
    (void)esf;
    
    while(1) {
        k_sleep(K_FOREVER);
    }
}

class ZephyrAssertHook : public Fw::AssertHook {
  public:
    void printAssert(const CHAR* msg) override {
        printk("ASSERT FAILED: %s\n", msg);
    }
    
    void doAssert() override {
        // Halt execution on assert
        while(1) {
            k_sleep(K_FOREVER);
        }
    }
};

ZephyrAssertHook assertHook;

int main()
{
    assertHook.registerHook();

    printk("Starting main\n");
    // Object for communicating state to the reference topology
    LedBlinker::TopologyState inputs;
    inputs.dev = serial;
    inputs.uartBaud = 115200;

    // Setup topology
    printk("Setting up topology...\n");
    LedBlinker::setupTopology(inputs);
    printk("Topology setup complete!\n");
    
    while(true)
    {
        LedBlinker::rateDriver.cycle();
        k_usleep(1);
    }

    return 0;
}
