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

    // Object for communicating state to the reference topology
    Stm32LedBlinker::TopologyState inputs;
    inputs.dev = serial;
    inputs.uartBaud = 115200;

    // Setup topology
    Stm32LedBlinker::setupTopology(inputs);

    while(true)
    {
        rateDriver.cycle();
        k_usleep(1);
    }

    return 0;
}
