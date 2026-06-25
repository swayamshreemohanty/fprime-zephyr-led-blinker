// ======================================================================
// \title  Main.cpp
// \brief main program for the F' application. Intended for CLI-based systems (Linux, macOS)
//
// ======================================================================
// Used to access topology functions
#include <LedBlinker/Top/LedBlinkerTopologyAc.hpp>
#include <LedBlinker/Top/LedBlinkerTopology.hpp>
#include <Fw/Logger/Logger.hpp>
#include <stdexcept>
#include <stdio.h>
#include <Fw/Types/Assert.hpp>
#include <zephyr/kernel.h>

class ZephyrAssertHook : public Fw::AssertHook {
  public:
    void printAssert(const CHAR* msg) override {
        printf("ZEPHYR ASSERT FAILED: %s\n", msg);
    }
    void doAssert() override {
        printf("System halted due to assert.\n");
        while (true) {
            k_msleep(1000);
        }
    }
};

ZephyrAssertHook assertHook;

const struct device *serial = DEVICE_DT_GET(DT_CHOSEN(zephyr_console));

int main()
{
    assertHook.registerHook();

    printf("Starting main...\n");
    // Object for communicating state to the reference topology
    LedBlinker::TopologyState inputs;
    inputs.dev = serial;
    inputs.uartBaud = 115200;

    printf("Setting up topology...\n");
    // Setup topology
    LedBlinker::setupTopology(inputs);
    
    printf("Entering loop...\n");
    while(true)
    {
        LedBlinker::rateDriver.cycle();
        k_usleep(1);
    }

    return 0;
}
