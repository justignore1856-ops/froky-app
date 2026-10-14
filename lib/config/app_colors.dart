import 'package:flutter/material.dart';

/// Semantic colours Material's [ColorScheme] doesn't cover (success / warning /
/// info and their container + on-colours). Defined per theme so dark mode is a
/// one-file change later. Access via `Theme.of(context).extension<AppColors>()`
/// or the `context.appColors` shortcut below.
///
/// Core neutrals (surface/onSurface/outline) and brand primary already live in
/// [ColorScheme]/`AppTheme` — use those, not this class, for those roles.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;

  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
  });

  static const AppColors light = AppColors(
    success: Color(0xFF1BA672),
    onSuccess: Colors.white,
    successContainer: Color(0xFFEAF3DE),
    warning: Color(0xFFF59E0B),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFF8E1),
    info: Color(0xFF2196F3),
    onInfo: Colors.white,
    infoContainer: Color(0xFFE3F2FD),
  );

  static const AppColors dark = AppColors(
    success: Color(0xFF2ECC8F),
    onSuccess: Color(0xFF08301F),
    successContainer: Color(0xFF143D2C),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF3A2A05),
    warningContainer: Color(0xFF3D3115),
    info: Color(0xFF4DA3F5),
    onInfo: Color(0xFF04233F),
    infoContainer: Color(0xFF16324A),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
