import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'machine.freezed.dart';
part 'machine.g.dart';

/// A host inference servers run on: the benchmark target's address, its
/// hardware (for recordings), and a reachability dot.
@freezed
abstract class Machine with _$Machine {
  const Machine._();

  const factory Machine({
    required String id,
    required String name,
    required String address,
    Vendor? vendor,
    String? gpus,
    String? memory,
    @Default(true) bool online,
  }) = _Machine;

  factory Machine.fromJson(Map<String, dynamic> json) =>
      _$MachineFromJson(json);

  /// Whether this is the machine the app itself runs on, inferred from the
  /// address.
  bool get isLocal {
    final a = address.trim().toLowerCase();
    return a == 'localhost' || a == '127.0.0.1' || a == '::1' || a == '0.0.0.0';
  }
}
