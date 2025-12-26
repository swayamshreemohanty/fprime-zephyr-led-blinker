#ifndef Stm32LedBlinker_NullTextLogger_HPP
#define Stm32LedBlinker_NullTextLogger_HPP

#include "Stm32LedBlinker/NullTextLogger/NullTextLoggerComponentAc.hpp"

namespace Stm32LedBlinker {

  class NullTextLogger :
    public NullTextLoggerComponentBase
  {

    public:

      // ----------------------------------------------------------------------
      // Construction, initialization, and destruction
      // ----------------------------------------------------------------------

      //! Construct object NullTextLogger
      //!
      NullTextLogger(
          const char *const compName /*!< The component name*/
      );

      //! Destroy object NullTextLogger
      //!
      ~NullTextLogger();

    PRIVATE:

      // ----------------------------------------------------------------------
      // Handler implementations for user-defined typed input ports
      // ----------------------------------------------------------------------

      //! Handler implementation for TextLogger
      //!
      void TextLogger_handler(
          const FwIndexType portNum, /*!< The port number*/
          FwEventIdType id, /*!< Log ID*/
          Fw::Time &timeTag, /*!< Time Tag*/
          const Fw::LogSeverity& severity, /*!< The severity argument*/
          Fw::LogBuffer &args /*!< Buffer containing serialized log entry*/
      );

  };

} // end namespace Stm32LedBlinker

#endif
