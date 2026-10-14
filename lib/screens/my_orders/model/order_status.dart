import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/theme.dart';

enum OrderStatus {
  unfulfilled,
  inProgress,
  onHold,
  partiallyFulfilled,
  fulfilled,
  unknown,
}

extension OrderStatusX on OrderStatus {
  static OrderStatus fromString(String? raw) {
    if (raw == null) return OrderStatus.unknown;
    switch (raw.toLowerCase().trim()) {
      case 'unfulfilled':
        return OrderStatus.unfulfilled;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'on_hold':
        return OrderStatus.onHold;
      case 'partially_fulfilled':
        return OrderStatus.partiallyFulfilled;
      case 'fulfilled':
        return OrderStatus.fulfilled;
      default:
        return OrderStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.unfulfilled:
        return 'Unfulfilled';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.onHold:
        return 'On Hold';
      case OrderStatus.partiallyFulfilled:
        return 'Partially Fulfilled';
      case OrderStatus.fulfilled:
        return 'Fulfilled';
      case OrderStatus.unknown:
        return 'Processing';
    }
  }

  // Cancel is allowed up to on-hold, in sequence: unfulfilled → in_progress → on_hold.
  bool get allowsCancel =>
      this == OrderStatus.unfulfilled ||
      this == OrderStatus.inProgress ||
      this == OrderStatus.onHold;

  bool get allowsReturn => this == OrderStatus.fulfilled;

  bool get isInTransit => this == OrderStatus.partiallyFulfilled;

  bool get isTerminal => this == OrderStatus.fulfilled;

  IconData get icon {
    switch (this) {
      case OrderStatus.unfulfilled:
        return TablerIcons.clock;
      case OrderStatus.inProgress:
        return TablerIcons.package;
      case OrderStatus.onHold:
        return TablerIcons.player_pause;
      case OrderStatus.partiallyFulfilled:
        return TablerIcons.truck_delivery;
      case OrderStatus.fulfilled:
        return TablerIcons.circle_check;
      case OrderStatus.unknown:
        return TablerIcons.help_circle;
    }
  }

  HeroPalette palette(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case OrderStatus.unfulfilled:
        return dark
            ? const HeroPalette(bg: Color(0xFF0C4A6E), fg: Color(0xFFBAE6FD), accent: Color(0xFF38BDF8))
            : const HeroPalette(bg: Color(0xFFE0F2FE), fg: Color(0xFF075985), accent: Color(0xFF0369A1));
      case OrderStatus.inProgress:
        return dark
            ? const HeroPalette(bg: Color(0xFF134E4A), fg: Color(0xFF99F6E4), accent: Color(0xFF2DD4BF))
            : const HeroPalette(bg: Color(0xFFCCFBF1), fg: Color(0xFF134E4A), accent: Color(0xFF0F766E));
      case OrderStatus.onHold:
        return dark
            ? const HeroPalette(bg: Color(0xFF78350F), fg: Color(0xFFFCD34D), accent: Color(0xFFF59E0B))
            : const HeroPalette(bg: Color(0xFFFEF3C7), fg: Color(0xFF78350F), accent: Color(0xFF92400E));
      case OrderStatus.partiallyFulfilled:
        return dark
            ? const HeroPalette(bg: Color(0xFF1E1B4B), fg: Color(0xFFA5B4FC), accent: Color(0xFF818CF8))
            : const HeroPalette(bg: Color(0xFFE0E7FF), fg: Color(0xFF1E1B4B), accent: Color(0xFF4338CA));
      case OrderStatus.fulfilled:
        return dark
            ? const HeroPalette(bg: Color(0xFF14532D), fg: Color(0xFF86EFAC), accent: Color(0xFF22C55E))
            : const HeroPalette(bg: Color(0xFFDCFCE7), fg: Color(0xFF14532D), accent: Color(0xFF166534));
      case OrderStatus.unknown:
        return HeroPalette(
          bg: Theme.of(context).colorScheme.onPrimary,
          fg: Theme.of(context).colorScheme.onSurface,
          accent: AppTheme.primaryColor,
        );
    }
  }
}

class HeroPalette {
  final Color bg;
  final Color fg;
  final Color accent;

  const HeroPalette({
    required this.bg,
    required this.fg,
    required this.accent,
  });
}
