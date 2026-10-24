import 'native_bridge.dart';

/// A reading of the device's monotonic clock.
class BootTime {
  const BootTime({required this.elapsedMs, required this.bootId});

  /// Milliseconds since the device booted, counting time spent asleep.
  /// Unaffected by the user changing the date or time.
  final int elapsedMs;

  /// Identifies the current boot, so a reading can be compared with an earlier
  /// one only when both came from the same boot.
  final int bootId;
}

/// Time that the person holding the phone cannot wind forward.
///
/// The unlock lockout measures its waits with this rather than the wall clock,
/// which anyone can change in Settings to make a wait appear to have passed.
abstract class BootClock {
  /// Null where the platform can't provide one (iOS, tests); callers then fall
  /// back to the wall clock.
  Future<BootTime?> read();
}

/// Android's `SystemClock.elapsedRealtime()` and `Settings.Global.BOOT_COUNT`.
class NativeBootClock implements BootClock {
  const NativeBootClock(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<BootTime?> read() => _bridge.bootTime();
}
