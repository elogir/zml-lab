import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'machine.freezed.dart';
part 'machine.g.dart';

/// A remote host that inference jobs can be launched on.
@freezed
abstract class Machine with _$Machine {
  const Machine._();

  const factory Machine({
    required String id,
    required String name,
    required String address,
    @Default(22) int sshPort,
    String? user,
    String? sshKey,
    Vendor? vendor,
    String? gpus,
    String? memory,
    @Default(true) bool online,
  }) = _Machine;

  factory Machine.fromJson(Map<String, dynamic> json) =>
      _$MachineFromJson(json);

  /// `user@address` when a user is set, else just the address.
  String get sshTarget => user == null ? address : '$user@$address';

  /// Whether this host runs jobs directly, without SSH. Inferred from the
  /// address pointing at the machine the app itself runs on.
  bool get isLocal {
    final a = address.trim().toLowerCase();
    return a == 'localhost' || a == '127.0.0.1' || a == '::1' || a == '0.0.0.0';
  }
}
