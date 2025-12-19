// ======================================================================
// \title  Stm32LedBlinkerTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================
// Provides access to autocoded functions
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopologyAc.hpp>
#include <config/FppConstantsAc.hpp>

#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>

#if DT_NODE_HAS_STATUS(DT_ALIAS(led0), okay)
static const struct gpio_dt_spec led_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);
#elif DT_NODE_HAS_STATUS(DT_ALIAS(led1), okay)
static const struct gpio_dt_spec led_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios);
#elif DT_NODE_HAS_STATUS(DT_ALIAS(led2), okay)
static const struct gpio_dt_spec led_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios);
#else
// No LED alias found; keep spec empty so configureTopology can skip opening the GPIO
static const struct gpio_dt_spec led_pin = {};
#endif

// Allows easy reference to objects in FPP/autocoder required namespaces
using namespace Stm32LedBlinker;

// The reference topology divides the incoming clock signal (1kHz) into sub-signals: 10Hz, 5Hz, and 1Hz
Svc::RateGroupDriver::DividerSet rateGroupDivisors = {{ {100, 0}, {200, 0}, {1000, 0} }};

// Rate groups may supply a context token to each of the attached children whose purpose is set by the project. The
// reference topology sets each token to zero as these contexts are unused in this project.
U32 rateGroup1Context[FppConstant_PassiveRateGroupOutputPorts::PassiveRateGroupOutputPorts] = {};

/**
 * \brief configure/setup components in project-specific way
 *
 * This is a *helper* function which configures/sets up each component requiring project specific input. This includes
 * allocating resources, passing-in arguments, etc. This function may be inlined into the topology setup function if
 * desired, but is extracted here for clarity.
 */
void configureTopology() {
    // Rate group driver needs a divisor list
    rateGroupDriver.configure(rateGroupDivisors);

    // Rate groups require context arrays.
    rateGroup1.configure(rateGroup1Context, FW_NUM_ARRAY_ELEMENTS(rateGroup1Context));

    if (led_pin.port != nullptr) {
        gpioDriver.open(led_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    }
}

// Public functions for use in main program are namespaced with deployment name Stm32LedBlinker
namespace Stm32LedBlinker {
void setupTopology(const TopologyState& state) {
    // Autocoded initialization. Function provided by autocoder.
    initComponents(state);
    // Autocoded id setup. Function provided by autocoder.
    setBaseIds();
    // Autocoded connection wiring. Function provided by autocoder.
    connectComponents();
    // Autocoded command registration. Function provided by autocoder.
    regCommands();
    // Project-specific component configuration. Function provided above. May be inlined, if desired.
    configureTopology();
    // Autocoded parameter loading. Function provided by autocoder.
    // loadParameters();
    
    // Autocoded task kick-off (active components). Function provided by autocoder.
    startTasks(state);
    
    rateDriver.configure(1);
    commDriver.configure(state.dev, state.uartBaud);
    rateDriver.start();
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);
}
};  // namespace Stm32LedBlinker
