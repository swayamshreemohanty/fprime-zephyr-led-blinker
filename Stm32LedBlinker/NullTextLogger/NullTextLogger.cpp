#include <Stm32LedBlinker/NullTextLogger/NullTextLogger.hpp>

namespace Stm32LedBlinker {

  // ----------------------------------------------------------------------
  // Construction and destruction
  // ----------------------------------------------------------------------

  NullTextLogger ::
    NullTextLogger(
        const char *const compName
    ) : NullTextLoggerComponentBase(compName)
  {

  }

  NullTextLogger ::
    ~NullTextLogger()
  {

  }

  // ----------------------------------------------------------------------
  // Handler implementations for user-defined typed input ports
  // ----------------------------------------------------------------------

  void NullTextLogger ::
    TextLogger_handler(
        const FwIndexType portNum,
        FwEventIdType id,
        Fw::Time &timeTag,
        const Fw::LogSeverity& severity,
        Fw::LogBuffer &args
    )
  {
    // Do nothing - discard text events silently
    // Binary events still route to RPi GDS via GenericHub
  }

} // end namespace Stm32LedBlinker
