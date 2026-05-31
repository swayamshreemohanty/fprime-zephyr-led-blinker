// ======================================================================
// \title  LedBlinkerTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================
// Provides access to autocoded functions
#include <LedBlinker/Top/LedBlinkerTopologyAc.hpp>
#include <config/FppConstantsAc.hpp>

// Communication stack components
#include <Fw/Types/MallocAllocator.hpp>

// Subtopologies
#include <Svc/Subtopologies/CdhCore/SubtopologyTopologyDefs.hpp>
#include <Svc/Subtopologies/CdhCore/PingEntries.hpp>
#include <Svc/Subtopologies/ComCcsds/SubtopologyTopologyDefs.hpp>
#include <Svc/Subtopologies/ComCcsds/PingEntries.hpp>

#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/sys/printk.h>

// Define GPIO specs for all 3 LEDs
static const struct gpio_dt_spec led_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);   // Green LED

// Allows easy reference to objects in FPP/autocoder required namespaces
using namespace LedBlinker;

// The reference topology divides the incoming clock signal (1kHz) into sub-signals: 10Hz
// 100Hz rate group (10 divisor) = LED runs at ~5Hz with blink interval 10
Svc::RateGroupDriver::DividerSet rateGroupDivisors = {{ {100, 0} }};

// Rate groups may supply a context token to each of the attached children whose purpose is set by the project. The
// reference topology sets each token to zero as these contexts are unused in this project.
// Must match PassiveRateGroupOutputPorts (defined as 10 in AcConstants.fpp)
static constexpr FwSizeType RATE_GROUP1_CONTEXT_COUNT = 10;
U32 rateGroup1Context[RATE_GROUP1_CONTEXT_COUNT] = {};

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

    // Open GPIO for LED
    gpioDriver.open(led_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
}

// Public functions for use in main program are namespaced with deployment name LedBlinker
namespace LedBlinker {
void setupTopology(const TopologyState& state) {
    printk(" - initComponents()\n");
    // Autocoded initialization. Function provided by autocoder.
    initComponents(state);
    
    printk(" - setBaseIds()\n");
    // Autocoded id setup. Function provided by autocoder.
    setBaseIds();
    
    printk(" - connectComponents()\n");
    // Autocoded connection wiring. Function provided by autocoder.
    connectComponents();
    
    // printk(" - configComponents()\n");
    // // Autocoded configuration. Function provided by autocoder.
    configComponents(state);
    
    printk(" - configureTopology()\n");
    // CRITICAL: Configure topology BEFORE regCommands
    // BufferManager.setup() must be called before components register commands
    configureTopology();
    
    // No parameter loading - this is an embedded deployment without PrmDb
    
    printk(" - regCommands()\n");
    // Register commands AFTER configuration
    regCommands();
    
    printk(" - startTasks()\n");
    // Start active component tasks
    startTasks(state);
    
    printk(" - configure drivers\n");
    rateDriver.configure(1);
    
    uartDriver.configure(state.dev, state.uartBaud);
    
    printk(" - rateDriver.start()\n");
    rateDriver.start();
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);
}
};  // namespace LedBlinker
