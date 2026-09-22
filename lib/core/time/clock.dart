/// Abstract port for retrieving the current timestamp.
/// Enables deterministic time-dependent unit testing.
abstract interface class Clock {
  DateTime nowUtc();
}

/// Production system clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
