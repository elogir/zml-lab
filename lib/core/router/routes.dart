import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/configs/presentation/configs_screen.dart';
import '../../features/job_detail/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/saved_benchmarks/presentation/saved_benchmarks_screen.dart';
import '../../features/machines/presentation/add_machine_screen.dart';
import '../../features/machines/presentation/machines_screen.dart';
import '../../features/new_job/presentation/custom_job_screen.dart';
import '../shell/app_shell.dart';

part 'routes.g.dart';

/// The persistent shell (title bar + sidebar) wrapping every top-level screen.
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<JobsRoute>(path: '/'),
    TypedGoRoute<ConfigsRoute>(path: '/configs'),
    TypedGoRoute<SavedBenchmarksRoute>(path: '/benchmarks'),
    TypedGoRoute<MachinesRoute>(path: '/machines'),
    TypedGoRoute<AddMachineRoute>(path: '/machines/new'),
    TypedGoRoute<EditMachineRoute>(path: '/machines/:id/edit'),
    TypedGoRoute<NewCustomJobRoute>(path: '/jobs/new/custom'),
    TypedGoRoute<JobDetailRoute>(path: '/jobs/:id'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      AppShell(child: navigator);
}

class JobsRoute extends GoRouteData with $JobsRoute {
  const JobsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JobsScreen();
}

class ConfigsRoute extends GoRouteData with $ConfigsRoute {
  const ConfigsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ConfigsScreen();
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

class NewCustomJobRoute extends GoRouteData with $NewCustomJobRoute {
  const NewCustomJobRoute({this.configId});

  final String? configId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomJobScreen(configId: configId);
}

class JobDetailRoute extends GoRouteData with $JobDetailRoute {
  const JobDetailRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JobDetailScreen(jobId: id);
}

/// The app router. Built from the typed routes above.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: $appRoutes,
);
