import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/perf/presentation/benchmark_tool_screen.dart';
import '../../features/saved_benchmarks/presentation/saved_benchmarks_screen.dart';
import '../../features/machines/presentation/add_machine_screen.dart';
import '../../features/machines/presentation/machines_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../shell/app_shell.dart';

part 'routes.g.dart';

/// The persistent shell (title bar + sidebar) wrapping every top-level screen.
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<BenchmarkToolRoute>(path: '/'),
    TypedGoRoute<SavedBenchmarksRoute>(path: '/benchmarks'),
    TypedGoRoute<MachinesRoute>(path: '/machines'),
    TypedGoRoute<AddMachineRoute>(path: '/machines/new'),
    TypedGoRoute<EditMachineRoute>(path: '/machines/:id/edit'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      AppShell(child: navigator);
}

class BenchmarkToolRoute extends GoRouteData with $BenchmarkToolRoute {
  const BenchmarkToolRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BenchmarkToolScreen();
}

class SavedBenchmarksRoute extends GoRouteData with $SavedBenchmarksRoute {
  const SavedBenchmarksRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SavedBenchmarksScreen();
}

class MachinesRoute extends GoRouteData with $MachinesRoute {
  const MachinesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MachinesScreen();
}

class AddMachineRoute extends GoRouteData with $AddMachineRoute {
  const AddMachineRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AddMachineScreen();
}

class EditMachineRoute extends GoRouteData with $EditMachineRoute {
  const EditMachineRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AddMachineScreen(machineId: id);
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

/// The app router. Built from the typed routes above.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: $appRoutes,
);
