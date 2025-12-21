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

// Define GPIO specs for all 3 LEDs
static const struct gpio_dt_spec led_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);   // Green LED
static const struct gpio_dt_spec led1_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios);  // Yellow LED
static const struct gpio_dt_spec led2_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios);  // Red LED

// Allows easy reference to objects in FPP/autocoder required namespaces
using namespace Stm32LedBlinker;

// Memory allocator for components that need dynamic memory
Fw::MallocAllocator mallocAllocator;

// Buffers for static memory and comQueue
Svc::ComQueue::QueueConfigurationTable configurationTable;
U8 mallocBuffer[3000];

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
    printk("  configureTopology: Setting up rate group driver...\n");
    // Rate group driver needs a divisor list
    rateGroupDriver.configure(rateGroupDivisors);

    printk("  configureTopology: Setting up rate groups...\n");
    // Rate groups require context arrays.
    rateGroup1.configure(rateGroup1Context, FW_NUM_ARRAY_ELEMENTS(rateGroup1Context));

    printk("  configureTopology: Setting up comQueue...\n");
    // ComQueue configuration - set all queues to same priority and depth
    for (U32 i = 0; i < FW_NUM_ARRAY_ELEMENTS(configurationTable.entries); i++) {
        configurationTable.entries[i].priority = 0;
        configurationTable.entries[i].depth = 3;
    }
    comQueue.configure(configurationTable, 0, mallocAllocator);

    printk("  configureTopology: Configuring GPIO for all 3 LEDs...\n");
    // Open GPIO for all 3 LEDs
    gpioDriver.open(led_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    printk("    GPIO driver opened for Green LED\n");
    
    gpioDriver1.open(led1_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    printk("    GPIO driver opened for Yellow LED\n");
    
    gpioDriver2.open(led2_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    printk("    GPIO driver opened for Red LED\n");
}

// Public functions for use in main program are namespaced with deployment name Stm32LedBlinker
namespace Stm32LedBlinker {
void setupTopology(const TopologyState& state) {
    printk("  initComponents...\n");
    // Autocoded initialization. Function provided by autocoder.
    initComponents(state);
    printk("  setBaseIds...\n");
    // Autocoded id setup. Function provided by autocoder.
    setBaseIds();
    printk("  connectComponents...\n");
    // Autocoded connection wiring. Function provided by autocoder.
    connectComponents();
    printk("  regCommands...\n");
    // Autocoded command registration. Function provided by autocoder.
    regCommands();
    printk("  configureTopology...\n");
    // Project-specific component configuration. Function provided above. May be inlined, if desired.
    configureTopology();
    printk("  loadParameters (skipped - no PrmDb)...\n");
    // Autocoded parameter loading. Function provided by autocoder.
    // loadParameters();  // No PrmDb component in topology
    
    // NOTE: startTasks() starts the active components (cmdDisp, eventLogger, tlmSend, comQueue)
    printk("  Starting active component tasks...\n");
    startTasks(state);
    
    // Disable commDriver for now - causes crashes
    // printk("  configure commDriver...\n");
    // commDriver.configure(state.dev, state.uartBaud);
    
    printk("  configure rateDriver...\n");
    rateDriver.configure(1);
    printk("  start rateDriver...\n");
    rateDriver.start();
    printk("setupTopology complete!\n");
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);
}
};  // namespace Stm32LedBlinker
