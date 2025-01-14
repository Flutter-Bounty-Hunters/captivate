import 'package:logging/logging.dart';

class CaptivateLogs {
  static final network = Logger("network");

  static final _activeLoggers = <Logger>{};

  static void initAllLogs(Level level) {
    initLoggers(level, {Logger.root});
  }

  static void initLoggers(Level level, Set<Logger> loggers) {
    hierarchicalLoggingEnabled = true;

    for (final logger in loggers) {
      if (!_activeLoggers.contains(logger)) {
        print('Initializing logger: ${logger.name}');
        logger
          ..level = level
          ..onRecord.listen(_printLog);

        _activeLoggers.add(logger);
      }
    }
  }

  /// Returns `true` if the given [logger] is currently logging, or
  /// `false` otherwise.
  ///
  /// Generally, developers should call loggers, regardless of whether
  /// a given logger is active. However, sometimes you may want to log
  /// information that's costly to compute. In such a case, you can
  /// choose to compute the expensive information only if the given
  /// logger will actually log the information.
  static bool isLogActive(Logger logger) {
    return _activeLoggers.contains(logger);
  }

  static void deactivateLoggers(Set<Logger> loggers) {
    for (final logger in loggers) {
      if (_activeLoggers.contains(logger)) {
        print('Deactivating logger: ${logger.name}');
        logger.clearListeners();

        _activeLoggers.remove(logger);
      }
    }
  }

  const CaptivateLogs._();
}

void _printLog(LogRecord record) {
  print(
      '(${record.time.second}.${record.time.millisecond.toString().padLeft(3, '0')}) ${record.loggerName} > ${record.level.name}: ${record.message}');
}
