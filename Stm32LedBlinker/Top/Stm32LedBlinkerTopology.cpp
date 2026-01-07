// ======================================================================
// \title  Stm32LedBlinkerTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================
// Provides access to autocoded functions
#include <Stm32LedBlinker/Top/Stm32LedBlinkerTopologyAc.hpp>
#include <config/FppConstantsAc.hpp>

// Hub pattern components
#include <Fw/Types/MallocAllocator.hpp>

#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>

// Define GPIO specs for all 3 LEDs
static const struct gpio_dt_spec led_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);   // Green LED
static const struct gpio_dt_spec led1_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios);  // Yellow LED
static const struct gpio_dt_spec led2_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios);  // Red LED

// Allows easy reference to objects in FPP/autocoder required namespaces
using namespace Stm32LedBlinker;

// The reference topology divides the incoming clock signal (1kHz) into sub-signals: 10Hz
// 100Hz rate group (10 divisor) = LED runs at ~5Hz with blink interval 10
Svc::RateGroupDriver::DividerSet rateGroupDivisors = {{ {10, 0} }};

// Rate groups may supply a context token to each of the attached children whose purpose is set by the project. The
// reference topology sets each token to zero as these contexts are unused in this project.
U32 rateGroup1Context[FppConstant_PassiveRateGroupOutputPorts::PassiveRateGroupOutputPorts] = {};

// Memory allocator for buffer manager
Fw::MallocAllocator hubMallocator;

// Buffer manager configuration - sized for embedded STM32
enum BufferConstants {
    HUB_BUFFER_SIZE = 512,    // Size of each buffer
    HUB_BUFFER_COUNT = 100,   // Number of buffers - large pool for telemetry buffering
    HUB_BUFFER_MANAGER_ID = 100
};

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

    printk("  configureTopology: Configuring GPIO for all 3 LEDs...\n");
    // Open GPIO for all 3 LEDs
    gpioDriver.open(led_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    printk("    GPIO driver opened for Green LED\n");
    
    gpioDriver1.open(led1_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    printk("    GPIO driver opened for Yellow LED\n");
    
    gpioDriver2.open(led2_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    printk("    GPIO driver opened for Red LED\n");

    // Configure Hub Pattern components for remote spoke node communication
    printk("  configureTopology: Configuring hub buffer manager...\n");
    Svc::BufferManager::BufferBins hubBuffMgrBins;
    memset(&hubBuffMgrBins, 0, sizeof(hubBuffMgrBins));
    hubBuffMgrBins.bins[0].bufferSize = HUB_BUFFER_SIZE;
    hubBuffMgrBins.bins[0].numBuffers = HUB_BUFFER_COUNT;
    bufferManager.setup(HUB_BUFFER_MANAGER_ID, 0, hubMallocator, hubBuffMgrBins);
    printk("    Hub buffer manager configured with %d buffers of %d bytes\n", HUB_BUFFER_COUNT, HUB_BUFFER_SIZE);

    // GenericHub and ByteStreamBufferAdapter are passive and don't need explicit configuration
    // They use the same architecture as RPi: GenericHub <-> ByteStreamBufferAdapter <-> UartDriver
    printk("  configureTopology: GenericHub and ByteStreamBufferAdapter ready for RPi communication\n");
}

// Public functions for use in main program are namespaced with deployment name Stm32LedBlinker
namespace Stm32LedBlinker {
void setupTopology(const TopologyState& state) {
    printk("  initComponents...\n");
    // Autocoded initialization. Function provided by autocoder.
    initComponents(state);
    printk("  initComponents DONE\n");
    printk("  setBaseIds...\n");
    // Autocoded id setup. Function provided by autocoder.
    setBaseIds();
    printk("  setBaseIds DONE\n");
    // Autocoded connection wiring. Function provided by autocoder.
    printk("  connectComponents...\n");
    connectComponents();
    printk("  connectComponents DONE\n");
    
    // CRITICAL: Configure topology BEFORE regCommands to ensure BufferManager
    // is set up before any events/telemetry can be generated
    printk("  configureTopology...\n");
    // Project-specific component configuration. Function provided above. May be inlined, if desired.
    configureTopology();
    printk("  configureTopology DONE\n");
    
    printk("  regCommands...\n");
    // Autocoded command registration. Function provided by autocoder.
    regCommands();
    printk("  regCommands DONE\n");
    printk("  configComponents...\n");
    // Autocoded component configuration. Function provided by autocoder.
    configComponents(state);
    printk("  configComponents DONE\n");

    printk("  loadParameters (skipped - no PrmDb)...\n");
    // No parameter loading - this is a spoke node without PrmDb
    
    // NOTE: In hub-native topology, startTasks() only starts any active components
    // This spoke topology has NO active components - all passive for minimal memory footprint
    printk("  Starting active component tasks (none in spoke node)...\n");
    startTasks(state);
    
    printk("  configure rateDriver...\n");
    rateDriver.configure(1);
    
    printk("  configure uartDriver (UART for hub communication)...\n");
    uartDriver.configure(state.dev, state.uartBaud);
    printk("  uartDriver configured at %d baud\n", state.uartBaud);
    
    printk("  start rateDriver...\n");
    rateDriver.start();
    printk("setupTopology complete! STM32 remote spoke node ready for RPi master communication.\n");
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);
    
    // Clean up buffer manager
    bufferManager.cleanup();
}
};  // namespace Stm32LedBlinker
