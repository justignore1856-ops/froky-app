import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/market/market_service.dart';
import '../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../utils/widgets/custom_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom sheet that lists the storefronts (markets) supported by this
/// installation and lets the user switch. Replaces the old delivery-zone /
/// location picker that the home header used to open.
class MarketPickerBottomSheet extends StatefulWidget {
  const MarketPickerBottomSheet({super.key});

  @override
  State<MarketPickerBottomSheet> createState() =>
      _MarketPickerBottomSheetState();
}

class _MarketPickerBottomSheetState extends State<MarketPickerBottomSheet> {
  bool _loading = true;
  bool _switching = false;
  String? _switchingCode;
  List<Map<String, dynamic>> _markets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await MarketService.listAvailable();
    if (!mounted) return;
    setState(() {
      _markets = results;
      _loading = false;
    });
  }

  Future<void> _select(Map<String, dynamic> market) async {
    final code = market['code'] as String?;
    if (code == null || code.isEmpty) return;
    if (code == MarketService.currentCode()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _switching = true;
      _switchingCode = code;
    });

    final ok = await MarketService.switchTo(code);

    if (!mounted) return;
    setState(() {
      _switching = false;
      _switchingCode = null;
    });

    if (ok) {
      Navigator.of(context).pop();
    } else {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)?.somethingWentWrong ??
            'Something went wrong',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = MarketService.currentCode();
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              // TODO(i18n): add labels.select_market + run flutter gen-l10n.
              'Select Market',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose the storefront for your region.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildList(currentCode)),
        ],
      ),
    );
  }

  Widget _buildList(String? currentCode) {
    if (_loading) {
      return const Center(child: CustomCircularProgressIndicator());
    }

    if (_markets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No markets available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _markets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final market = _markets[index];
        final code = market['code'] as String? ?? '';
        final name = market['name'] as String? ?? code;
        final currency = market['currency_code'] as String?;
        final isSelected = code == currentCode;
        final isThisSwitching = _switching && _switchingCode == code;

        return InkWell(
          onTap: _switching ? null : () => _select(market),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.onSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    TablerIcons.world,
                    size: 22,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency != null && currency.isNotEmpty
                            ? '$code · $currency'
                            : code,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isThisSwitching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isSelected)
                  const Icon(
                    TablerIcons.circle_check_filled,
                    color: AppTheme.primaryColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Convenience opener that mirrors `showHomeLocationBottomSheet`.
void showMarketPickerBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const MarketPickerBottomSheet(),
  );
}
