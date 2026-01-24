// ======================================================================
// \title  LedBlinkerTopologyDefs.hpp
// \brief required header file containing the required definitions for the topology autocoder
//
// ======================================================================
#ifndef LedBlinker_LedBlinkerTOPOLOGYDEFS_HPP
#define LedBlinker_LedBlinkerTOPOLOGYDEFS_HPP

#include "Fw/Types/MallocAllocator.hpp"
#include "LedBlinker/Top/FppConstantsAc.hpp"

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/uart.h>

// Ping entries for rate group - extend the global PingEntries namespace
namespace PingEntries {
    namespace LedBlinker_rateGroup1 {enum { WARN = 3, FATAL = 5 };}
}

// Definitions are placed within a namespace named after the deployment
namespace LedBlinker {

/**
 * \brief required type definition to carry state
 *
 * The topology autocoder requires an object that carries state with the name `LedBlinker::TopologyState`. Only the type
 * definition is required by the autocoder and the contents of this object are otherwise opaque to the autocoder. The
 * contents are entirely up to the definition of the project. This deployment uses hub pattern for communication.
 */
struct TopologyState {
    const struct device *dev;
    PlatformIntType uartBaud;
};

/**
 * \brief required ping constants
 *
 * The topology autocoder requires a WARN and FATAL constant definition for each component that supports the health-ping
 * interface. These are expressed as enum constants placed in a namespace named for the component instance. These
 * are all placed in the PingEntries namespace.
 *
 * Each constant specifies how many missed pings are allowed before a WARNING_HI/FATAL event is triggered. In the
 * following example, the health component will emit a WARNING_HI event if the component instance cmdDisp does not
 * respond for 3 pings and will FATAL if responses are not received after a total of 5 pings.
 *
 * ```c++
 * namespace PingEntries {
 * namespace cmdDisp {
 *     enum { WARN = 3, FATAL = 5 };
 * }
 * }
 * ```
 */
}  // namespace LedBlinker
#endif
