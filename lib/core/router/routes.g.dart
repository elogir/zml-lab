// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$appShellRoute];

RouteBase get $appShellRoute => ShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/',
      hasOverriddenOnExit: false,
      factory: $BenchmarkToolRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/benchmarks',
      hasOverriddenOnExit: false,
      factory: $SavedBenchmarksRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/machines',
      hasOverriddenOnExit: false,
      factory: $MachinesRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/machines/new',
      hasOverriddenOnExit: false,
      factory: $AddMachineRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/machines/:id/edit',
      hasOverriddenOnExit: false,
      factory: $EditMachineRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings',
      hasOverriddenOnExit: false,
      factory: $SettingsRoute._fromState,
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $BenchmarkToolRoute on GoRouteData {
  static BenchmarkToolRoute _fromState(GoRouterState state) =>
      const BenchmarkToolRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SavedBenchmarksRoute on GoRouteData {
  static SavedBenchmarksRoute _fromState(GoRouterState state) =>
      const SavedBenchmarksRoute();

  @override
  String get location => GoRouteData.$location('/benchmarks');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MachinesRoute on GoRouteData {
  static MachinesRoute _fromState(GoRouterState state) => const MachinesRoute();

  @override
  String get location => GoRouteData.$location('/machines');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AddMachineRoute on GoRouteData {
  static AddMachineRoute _fromState(GoRouterState state) =>
      const AddMachineRoute();

  @override
  String get location => GoRouteData.$location('/machines/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EditMachineRoute on GoRouteData {
  static EditMachineRoute _fromState(GoRouterState state) =>
      EditMachineRoute(id: state.pathParameters['id']!);

  EditMachineRoute get _self => this as EditMachineRoute;

  @override
  String get location =>
      GoRouteData.$location('/machines/${Uri.encodeComponent(_self.id)}/edit');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
