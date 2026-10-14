import 'package:flutter/material.dart';

import 'helper.dart';
import '../utils/widgets/custom_toast.dart';

/// Global guard for actions that must be blocked while the storefront runs in
/// demo mode (changing country/market, editing the profile, checkout, …).
///
/// Centralises the "is this allowed?" check plus the user-facing message so
/// every call site behaves identically. Reuse anywhere an action should be
/// disabled in demo mode.
///
/// Usage:
/// ```dart
/// // Gate an action — runs only when not in demo mode:
/// DemoGuard.run(context, () => CountryBottomSheet.show(context));
///
/// // Guard inline and bail early:
/// if (DemoGuard.blocked(context)) return;
///
/// // Async action:
/// await DemoGuard.runAsync(context, () => repo.save());
/// ```
class DemoGuard {
  const DemoGuard._();

  /// Whether the app is currently running in demo mode.
  static bool get isDemo => AppHelpers.isDemo;

  /// Returns `true` (and shows a toast) when demo mode blocks the action;
  /// returns `false` when the action is allowed.
  ///
  /// Pass [message] to override the default customer demo-mode message for a
  /// specific action.
  static bool blocked(BuildContext context, {String? message}) {
    if (!AppHelpers.isDemo) return false;
    ToastManager.show(
      context: context,
      message: message ?? AppHelpers.demoModeMessage,
      type: ToastType.warning,
    );
    return true;
  }

  /// Runs [action] only when not in demo mode; otherwise shows the toast.
  static void run(
    BuildContext context,
    VoidCallback action, {
    String? message,
  }) {
    if (blocked(context, message: message)) return;
    action();
  }

  /// Async variant of [run]. Awaits [action] only when allowed.
  static Future<void> runAsync(
    BuildContext context,
    Future<void> Function() action, {
    String? message,
  }) async {
    if (blocked(context, message: message)) return;
    await action();
  }
}
