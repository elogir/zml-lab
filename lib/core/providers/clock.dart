import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// A once-per-second wall-clock tick. Widgets that show live uptime watch
/// this so only they rebuild, not the lists that contain them.
@riverpod
Stream<DateTime> clock(Ref ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
}
