import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/launch_config.dart';
import '../../../repositories/config_repository.dart';

part 'configs_providers.g.dart';

@riverpod
Stream<List<LaunchConfig>> configsStream(Ref ref) =>
    ref.watch(configRepositoryProvider).watchConfigs();
