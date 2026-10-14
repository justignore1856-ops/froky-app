import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/market/market_service.dart';
import 'custom_circular_progress_indicator.dart';
import 'custom_toast.dart';

class CountryBottomSheet extends StatefulWidget {
  const CountryBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 20),
                ),
              ),
            ),
          ),
          const CountryBottomSheet(),
        ],
      ),
    );
  }

  @override
  State<CountryBottomSheet> createState() => _CountryBottomSheetState();
}

class _CountryOption {
  final String iso2;
  final String name;
  final String marketCode;
  final String marketName;

  const _CountryOption({
    required this.iso2,
    required this.name,
    required this.marketCode,
    required this.marketName,
  });
}

class _CountryBottomSheetState extends State<CountryBottomSheet> {
  bool _loading = true;
  bool _switching = false;
  String? _switchingIso;
  List<_CountryOption> _countries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final markets = await MarketService.listAvailable();
    if (!mounted) return;

    final seen = <String>{};
    final flat = <_CountryOption>[];

    for (final m in markets) {
      final code = (m['code'] as String?) ?? '';
      final marketName = (m['name'] as String?) ?? code;
      final countries = m['countries'];
      if (countries is! List) continue;

      for (final c in countries) {
        if (c is! Map) continue;
        final iso = (c['iso2'] as String?)?.toUpperCase();
        final name = c['name'] as String?;
        if (iso == null || iso.isEmpty || name == null) continue;
        if (seen.contains(iso)) continue;
        seen.add(iso);
        flat.add(_CountryOption(
          iso2: iso,
          name: name,
          marketCode: code,
          marketName: marketName,
        ));
      }
    }

    flat.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _countries = flat;
      _loading = false;
    });
  }

  /// Convert an ISO 3166-1 alpha-2 code (e.g. "IN") to its flag emoji
  /// using regional-indicator codepoints. Works without any asset/CDN.
  String _flag(String iso2) {
    if (iso2.length != 2) return '🏳';
    const base = 0x1F1E6; // regional-indicator A
    final upper = iso2.toUpperCase();
    return String.fromCharCodes(
      upper.codeUnits.map((c) => base + (c - 65)),
    );
  }

  Future<void> _select(_CountryOption option) async {
    if (option.marketCode == MarketService.currentCode()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _switching = true;
      _switchingIso = option.iso2;
    });

    final ok = await MarketService.switchTo(option.marketCode);

    if (!mounted) return;
    setState(() {
      _switching = false;
      _switchingIso = null;
    });

    final l10n = AppLocalizations.of(context);
    if (ok) {

      await MarketService.cacheCountry(iso2: option.iso2, name: option.name);
      if (!mounted) return;
      Navigator.of(context).pop();
      ToastManager.show(
        context: context,
        message: l10n?.countrySwitched ?? 'Country updated',
        type: ToastType.success,
      );
    } else {
      ToastManager.show(
        context: context,
        message: l10n?.countrySwitchFailed ??
            l10n?.somethingWentWrong ??
            'Something went wrong',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14.r),
          topRight: Radius.circular(14.r),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Text(
                  l10n?.selectCountry ?? 'Select Country',
                  style: AppTextStyles.titleMedium,
                ),
              ],
            ),
          ),
          Divider(
            height: 1.h,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // Country list
          Flexible(child: _buildList()),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 10.h),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CustomCircularProgressIndicator()),
      );
    }

    if (_countries.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            l10n?.noData ?? 'No countries available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final currentMarketCode = MarketService.currentCode();

    return RadioGroup<String>(
      // We key the radio group on iso2 so two countries in the same market
      // can both be displayed (and the user can pick a specific one).
      groupValue: _countries
          .firstWhere(
            (c) => c.marketCode == currentMarketCode,
            orElse: () => const _CountryOption(
              iso2: '',
              name: '',
              marketCode: '',
              marketName: '',
            ),
          )
          .iso2,
      onChanged: (value) {
        // RadioGroup.onChanged is non-nullable. We bail inside instead of
        // passing null when a switch is already in flight.
        if (_switching) return;
        if (value == null || value.isEmpty) return;
        final picked = _countries.firstWhere(
          (c) => c.iso2 == value,
          orElse: () => const _CountryOption(
            iso2: '',
            name: '',
            marketCode: '',
            marketName: '',
          ),
        );
        if (picked.iso2.isNotEmpty) _select(picked);
      },
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: _countries.length,
        separatorBuilder: (_, __) => const SizedBox.shrink(),
        itemBuilder: (context, index) {
          final c = _countries[index];
          final isSelected = c.marketCode == currentMarketCode;
          final isThisSwitching = _switching && _switchingIso == c.iso2;

          return RadioListTile<String>(
            title: Row(
              children: [
                Text(
                  _flag(c.iso2),
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w400),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    c.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[800],
                    ),
                  ),
                ),
                if (isThisSwitching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CustomCircularProgressIndicator(),
                  ),
              ],
            ),
            // Subtitle intentionally omitted — the market name behind a
            // country is an admin-facing concept and only adds noise to the
            // customer dropdown.
            value: c.iso2,
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
            dense: true,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
