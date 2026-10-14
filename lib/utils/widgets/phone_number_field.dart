import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/theme.dart';
import '../../l10n/app_localizations.dart';

class PhoneFieldData {
  /// ISO 3166-1 alpha-2 country code, e.g. "IN".
  final String iso;

  /// Dial code including the leading plus, e.g. "+91".
  final String dialCode;

  /// National number, digits only, no country code, e.g. "9876543210".
  final String national;

  /// Full E.164 number, e.g. "+919876543210".
  final String complete;

  const PhoneFieldData({
    required this.iso,
    required this.dialCode,
    required this.national,
    required this.complete,
  });

  bool get isEmpty => national.isEmpty;
}

class PhoneNumberField extends StatefulWidget {
  final String? initialIso;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<PhoneFieldData>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final TextInputAction textInputAction;
  final bool enabled;

  const PhoneNumberField({
    super.key,
    this.initialIso,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.errorText,
    this.textInputAction = TextInputAction.done,
    this.enabled = true,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late TextEditingController _controller;
  late Country _country;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
    _country = _resolveCountry(widget.initialIso ?? AppHelpers.isoCode);
    // Emit an initial value so the parent starts with a valid dial code even
    // before the user types anything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emit();
    });
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Country _resolveCountry(String iso) {
    final upper = iso.toUpperCase();
    return countries.firstWhere(
      (c) => c.code.toUpperCase() == upper,
      orElse: () => countries.firstWhere(
        (c) => c.code.toUpperCase() == 'IN',
        orElse: () => countries.first,
      ),
    );
  }

  String _dial(Country c) => '+${c.dialCode}';

  String _flag(String iso2) {
    if (iso2.length != 2) return '🏳';
    const base = 0x1F1E6; // regional-indicator "A"
    final upper = iso2.toUpperCase();
    return String.fromCharCodes(upper.codeUnits.map((c) => base + (c - 65)));
  }

  void _emit() {
    final national = _controller.text.replaceAll(RegExp(r'[^\d]'), '');
    widget.onChanged?.call(PhoneFieldData(
      iso: _country.code,
      dialCode: _dial(_country),
      national: national,
      complete: '${_dial(_country)}$national',
    ));
  }

  Future<void> _openPicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(current: _country, flagOf: _flag),
    );
    if (selected != null && mounted) {
      setState(() => _country = selected);
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    final hasError = widget.errorText != null;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Separate country-picker button ──────────────────────────
            GestureDetector(
              onTap: widget.enabled ? _openPicker : null,
              child: Container(
                height: isTablet(context) ? 70 : 55,
                padding:
                EdgeInsets.symmetric(horizontal: 8.w,),
                decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: radius,
                    border: Border.all(
                        color: scheme.outlineVariant,
                        width: 0.5
                    )
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _flag(_country.code),
                      style:
                      AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w400),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _dial(_country),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: scheme.onSurfaceVariant, size: 20,),
                  ],
                ),
              ),
            ),

            SizedBox(width: 8.w),
            // ── Number field ────────────────────────────────────────────
            Expanded(
              child: CustomTextFormField(
                controller: _controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                textInputAction: widget.textInputAction,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                ],
                hintText: widget.labelText,
                // cursorColor: scheme.tertiary,
                onChanged: (_) => _emit(),
                // decoration: InputDecoration(
                //
                //
                //   filled: true,
                //   fillColor: scheme.surfaceContainer,
                //   contentPadding:
                //       EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                //   border: outline(borderColor),
                //   enabledBorder: outline(borderColor),
                //   focusedBorder: outline(
                //       hasError ? scheme.error : AppTheme.primaryColor),
                // ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.label.copyWith(
                color: scheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final Country current;
  final String Function(String iso2) flagOf;

  const _CountryPickerSheet({required this.current, required this.flagOf});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  late List<Country> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<Country>.from(countries)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final query = q.trim().toLowerCase();
    final digits = query.replaceAll('+', '');
    setState(() {
      _filtered = countries.where((c) {
        if (query.isEmpty) return true;
        return c.name.toLowerCase().contains(query) ||
            c.code.toLowerCase().contains(query) ||
            (digits.isNotEmpty && c.dialCode.contains(digits));
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: CustomTextFormField(
              controller: _searchController,
              onChanged: _onSearch,
              hintText: l10n?.selectCountry ?? 'Search country',
              prefixIcon: Icons.search,
            ),
          ),
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n?.noData ?? 'No countries found',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final c = _filtered[i];
                      final selected = c.code == widget.current.code;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Text(widget.flagOf(c.code),
                              style: AppTextStyles.headline.copyWith(fontWeight: FontWeight.w400)),
                          title: Text(
                            c.name,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                          trailing: Text(
                            '+${c.dialCode}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // selected: selected,
                          onTap: () => Navigator.of(context).pop(c),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
        ],
      ),
    );
  }
}
