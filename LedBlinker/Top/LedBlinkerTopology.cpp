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

#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>

// Define GPIO specs for all 3 LEDs
static const struct gpio_dt_spec led_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);   // Green LED
static const struct gpio_dt_spec led1_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios);  // Yellow LED
static const struct gpio_dt_spec led2_pin = GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios);  // Red LED

// Allows easy reference to objects in FPP/autocoder required namespaces
using namespace LedBlinker;

// The reference topology divides the incoming clock signal (1kHz) into sub-signals: 10Hz
// 100Hz rate group (10 divisor) = LED runs at ~5Hz with blink interval 10
Svc::RateGroupDriver::DividerSet rateGroupDivisors = {{ {10, 0} }};

// Rate groups may supply a context token to each of the attached children whose purpose is set by the project. The
// reference topology sets each token to zero as these contexts are unused in this project.
U32 rateGroup1Context[FppConstant_PassiveRateGroupOutputPorts::PassiveRateGroupOutputPorts] = {};

// Memory allocator for buffer manager
Fw::MallocAllocator commsAllocator;

// Buffer manager configuration - sized for F Prime communication stack
enum BufferConstants {
    COMMS_BUFFER_SIZE = 2048,      // Size for framed packets
    COMMS_BUFFER_COUNT = 50,       // Number of communication buffers
    COMMS_BUFFER_MANAGER_ID = 200
};

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

    // Open GPIO for all 3 LEDs
    gpioDriver.open(led_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    gpioDriver1.open(led1_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);
    gpioDriver2.open(led2_pin, Zephyr::ZephyrGpioDriver::GpioConfiguration::OUT);

    // Configure communication buffer manager
    Svc::BufferManager::BufferBins commsBuffMgrBins;
    memset(&commsBuffMgrBins, 0, sizeof(commsBuffMgrBins));
    commsBuffMgrBins.bins[0].bufferSize = COMMS_BUFFER_SIZE;
    commsBuffMgrBins.bins[0].numBuffers = COMMS_BUFFER_COUNT;
    commsBufferManager.setup(COMMS_BUFFER_MANAGER_ID, 0, commsAllocator, commsBuffMgrBins);
    
    // Configure ComQueue with prioritized queues for events and telemetry
    Svc::ComQueue::QueueConfigurationTable queueConfig;
    queueConfig.entries[0].depth = 100;      // Events queue depth
    queueConfig.entries[0].priority = 0;     // Highest priority (0 = highest)
    queueConfig.entries[1].depth = 100;      // Telemetry queue depth
    queueConfig.entries[1].priority = 1;     // Lower priority than events
    comQueue.configure(queueConfig);
    
    // Configure FrameAccumulator with buffer size for incoming frames
    frameAccumulator.configure(COMMS_BUFFER_SIZE);
}

// Public functions for use in main program are namespaced with deployment name LedBlinker
namespace LedBlinker {
void setupTopology(const TopologyState& state) {
    // Autocoded initialization. Function provided by autocoder.
    initComponents(state);
    
    // Autocoded id setup. Function provided by autocoder.
    setBaseIds();
    
    // Autocoded connection wiring. Function provided by autocoder.
    connectComponents();
    
    // CRITICAL: Configure topology BEFORE regCommands
    // BufferManager.setup() must be called before components register commands
    configureTopology();
    
    // No parameter loading - this is an embedded deployment without PrmDb
    
    // Register commands AFTER configuration
    regCommands();
    
    // Start active component tasks
    startTasks(state);
    
    rateDriver.configure(1);
    
    uartDriver.configure(state.dev, state.uartBaud);
    
    rateDriver.start();
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);
    
    // Clean up buffer manager
    bufferManager.cleanup();
}
};  // namespace LedBlinker
