import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Central registry of the (few) icons the app uses, so the icon set is a
/// one-line swap and call sites read semantically.
abstract final class AppIcons {
  // Navigation
  static const IconData jobs = LucideIcons.list;
  static const IconData configs = LucideIcons.settings2;
  static const IconData machines = LucideIcons.monitor;
  static const IconData collapseSidebar = LucideIcons.panelLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData back = LucideIcons.chevronLeft;

  // Actions
  static const IconData add = LucideIcons.plus;
  static const IconData close = LucideIcons.x;
  static const IconData delete = LucideIcons.trash2;
  static const IconData terminal = LucideIcons.terminal;
  static const IconData benchmark = LucideIcons.gauge;
  static const IconData send = LucideIcons.arrowRight;
  static const IconData kill = LucideIcons.square;
  static const IconData profiler = LucideIcons.activity;
  static const IconData restart = LucideIcons.rotateCw;
  static const IconData copy = LucideIcons.copy;
  static const IconData testEndpoint = LucideIcons.externalLink;

  // Terminal multiplexer chrome
  static const IconData splitHorizontal = LucideIcons.columns2;
  static const IconData splitVertical = LucideIcons.rows3;
  static const IconData web = LucideIcons.globe;
  static const IconData fullscreen = LucideIcons.maximize2;
  static const IconData exitFullscreen = LucideIcons.minimize2;

  // Web view chrome
  static const IconData navBack = LucideIcons.arrowLeft;
  static const IconData navForward = LucideIcons.arrowRight;
  static const IconData refresh = LucideIcons.rotateCw;

  // Machine details
  static const IconData gpu = LucideIcons.cpu;
  static const IconData memory = LucideIcons.memoryStick;
  static const IconData server = LucideIcons.server;
}
