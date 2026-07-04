// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$appShellRoute];

RouteBase get $appShellRoute => ShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(path: '/', factory: $JobsRoute._fromState),
    GoRouteData.$route(path: '/configs', factory: $ConfigsRoute._fromState),
    GoRouteData.$route(path: '/machines', factory: $MachinesRoute._fromState),
    GoRouteData.$route(
      path: '/machines/new',
      factory: $AddMachineRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/machines/:id/edit',
      factory: $EditMachineRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/jobs/new/custom',
      factory: $NewCustomJobRoute._fromState,
    ),
    GoRouteData.$route(path: '/jobs/:id', factory: $JobDetailRoute._fromState),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $JobsRoute on GoRouteData {
  static JobsRoute _fromState(GoRouterState state) => const JobsRoute();

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

mixin $ConfigsRoute on GoRouteData {
  static ConfigsRoute _fromState(GoRouterState state) => const ConfigsRoute();

  @override
  String get location => GoRouteData.$location('/configs');

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

mixin $NewCustomJobRoute on GoRouteData {
  static NewCustomJobRoute _fromState(GoRouterState state) =>
      NewCustomJobRoute(configId: state.uri.queryParameters['config-id']);

  NewCustomJobRoute get _self => this as NewCustomJobRoute;

  @override
  String get location => GoRouteData.$location(
    '/jobs/new/custom',
    queryParams: {if (_self.configId != null) 'config-id': _self.configId},
  );

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

mixin $JobDetailRoute on GoRouteData {
  static JobDetailRoute _fromState(GoRouterState state) =>
      JobDetailRoute(id: state.pathParameters['id']!);

  JobDetailRoute get _self => this as JobDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/jobs/${Uri.encodeComponent(_self.id)}');

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
