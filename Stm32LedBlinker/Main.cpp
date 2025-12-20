// ======================================================================
// \title  Main.cpp
// \brief main program for the F' application. Intended for CLI-based systems (Linux, macOS)
//
// ======================================================================
// Used to access topology functions
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopologyAc.hpp>
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopology.hpp>

// Used for logging
#include <Os/Log.hpp>

// Instantiate a system logger that will handle Fw::Logger::logMsg calls
Os::Log logger;

const struct device *serial = DEVICE_DT_GET(DT_NODELABEL(lpuart1));

/**
 * \brief execute the program
 *
 * This F´ program is designed to run using the Zephyr platform
 * 
 * @return: 0 on success, something else on failure
 */
int main()
{
    Fw::Logger::logMsg("Program Started\n");

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
