import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/services/market/market_service.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/get_address_list_bloc/get_address_list_bloc.dart';
import '../bloc/get_cities_bloc/get_cities_bloc.dart';
import '../bloc/get_countries_bloc/get_countries_bloc.dart';
import '../bloc/resolve_pincode_bloc/resolve_pincode_bloc.dart';
import '../model/city_model.dart';
import '../model/country_model.dart';
import '../model/get_address_list_model.dart';
import '../model/resolve_pincode_model.dart';
import '../widgets/searchable_dropdown_field.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class AddEditAddressPage extends StatelessWidget {
  final bool isEdit;
  final AddressListData? address;
  final bool isDefaultShipping;
  final int? deliveryZoneId;

  const AddEditAddressPage({
    super.key,
    required this.isEdit,
    this.address,
    this.isDefaultShipping = false,
    this.deliveryZoneId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GetCountriesBloc>(
          create: (_) => GetCountriesBloc()..add(const FetchCountries()),
        ),
        BlocProvider<GetCitiesBloc>(create: (_) => GetCitiesBloc()),
        BlocProvider<ResolvePincodeBloc>(create: (_) => ResolvePincodeBloc()),
      ],
      child: _AddEditAddressView(
        isEdit: isEdit,
        address: address,
        isDefaultShipping: isDefaultShipping,
        deliveryZoneId: deliveryZoneId,
      ),
    );
  }
}

class _AddEditAddressView extends StatefulWidget {
  final bool isEdit;
  final AddressListData? address;
  final bool isDefaultShipping;
  final int? deliveryZoneId;

  const _AddEditAddressView({
    required this.isEdit,
    required this.address,
    required this.isDefaultShipping,
    required this.deliveryZoneId,
  });

  @override
  State<_AddEditAddressView> createState() => _AddEditAddressViewState();
}

class _AddEditAddressViewState extends State<_AddEditAddressView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  CountryItem? _selectedCountry;
  CityItem? _selectedCity;
  String _selectedAddressType = 'home';
  bool _isDefaultShipping = false;
  bool _submitAttempted = false;

  List<String>? _pincodeCityWhitelist;
  Timer? _pincodeDebounce;

  static const List<String> _addressTypes = ['home', 'office', 'other'];
  static const Map<String, IconData> _addressTypeIcons = {
    'home': Icons.home_outlined,
    'office': Icons.apartment_rounded,
    'other': Icons.location_on_outlined,
  };

  @override
  void initState() {
    super.initState();
    _selectedAddressType = widget.address?.addressType ?? 'home';
    _isDefaultShipping =
        widget.address?.isDefaultShipping ?? widget.isDefaultShipping;

    if (widget.address != null) {
      _addressLine1Controller.text = widget.address!.addressLine1 ?? '';
      _addressLine2Controller.text = widget.address!.addressLine2 ?? '';
      _stateController.text = widget.address!.state ?? '';
      _zipcodeController.text = widget.address!.zipcode ?? '';
      _landmarkController.text = widget.address!.landmark ?? '';
      _mobileController.text = widget.address!.mobile ?? '';
    } else if ((Global.userData?.mobile ?? '').isNotEmpty) {
      _mobileController.text = Global.userData!.mobile;
    }
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    _scrollController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _stateController.dispose();
    _zipcodeController.dispose();
    _landmarkController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onCountriesLoaded(List<CountryItem> countries) {
    if (countries.isEmpty || _selectedCountry != null) return;

    CountryItem? preferred;
    final editIso2 = (widget.address?.countryCode ?? '').toUpperCase();
    if (editIso2.isNotEmpty) {
      preferred = countries.firstWhere(
        (c) => c.iso2 == editIso2,
        orElse: () => countries.first,
      );
    } else {
      final activeIso2 = (MarketService.currentCountryIso2() ?? '').toUpperCase();
      if (activeIso2.isNotEmpty) {
        preferred = countries.firstWhere(
          (c) => c.iso2 == activeIso2,
          orElse: () => countries.first,
        );
      } else {
        preferred = countries.first;
      }
    }

    setState(() {
      _selectedCountry = preferred;
    });

    if (widget.isEdit && (widget.address?.city ?? '').isNotEmpty) {
      _selectedCity = CityItem(
        name: widget.address!.city ?? '',
        stateCode: '',
        stateName: widget.address!.state ?? '',
        countryIso2: preferred.iso2,
        countryName: widget.address!.country ?? preferred.name,
      );
    }

    _refetchCities();
  }

  void _refetchCities() {
    final country = _selectedCountry;
    if (country == null) return;
    context.read<GetCitiesBloc>().add(FetchCities(iso2: country.iso2));
  }

  Future<void> _pickCountry(List<CountryItem> countries) async {
    final chosen = await showSearchablePickerSheet<CountryItem>(
      context: context,
      title: AppLocalizations.of(context)?.selectCountry ?? 'Select Country',
      searchHint:
          AppLocalizations.of(context)?.searchCountry ?? 'Search country',
      emptyLabel:
          AppLocalizations.of(context)?.noCountriesFound ?? 'No countries found',
      remoteSearch: true,
      itemsBuilder: (query) {
        final trimmed = query.trim().toLowerCase();
        final filtered = trimmed.isEmpty
            ? countries
            : countries
                .where((c) =>
                    c.name.toLowerCase().contains(trimmed) ||
                    c.iso2.toLowerCase().contains(trimmed))
                .toList();
        return filtered
            .map((c) => DropdownPickerOption<CountryItem>(
                  value: c,
                  label: c.name,
                  subtitle: c.iso2,
                ))
            .toList();
      },
    );

    if (chosen == null || !mounted) return;
    if (chosen.iso2 == _selectedCountry?.iso2) return;

    setState(() {
      _selectedCountry = chosen;
      _selectedCity = null;
      _stateController.clear();
      _zipcodeController.clear();
      _pincodeCityWhitelist = null;
    });
    context.read<ResolvePincodeBloc>().add(const ClearPincodeResolution());
    _refetchCities();
  }

  Future<void> _pickCity() async {
    final country = _selectedCountry;
    if (country == null) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)?.pleaseSelectCountry ??
            'Please select a country first',
        type: ToastType.info,
      );
      return;
    }

    final whitelist = _pincodeCityWhitelist;
    final resolvedStateName = _resolvePincodeStateName();
    final resolvedStateCode = _resolvePincodeStateCode();
    final chosen = await showSearchablePickerSheet<CityItem>(
      context: context,
      title: AppLocalizations.of(context)?.selectCity ?? 'Select City',
      searchHint: AppLocalizations.of(context)?.searchCity ?? 'Search city',
      emptyLabel:
          AppLocalizations.of(context)?.noCitiesFound ?? 'No cities found',
      remoteSearch: false,
      itemsBuilder: (query) {
        if (whitelist == null) return const [];
        final trimmed = query.trim().toLowerCase();
        final filtered = trimmed.isEmpty
            ? whitelist
            : whitelist
                .where((n) => n.toLowerCase().contains(trimmed))
                .toList();
        return filtered
            .map((name) => DropdownPickerOption<CityItem>(
                  value: CityItem(
                    name: name,
                    stateCode: resolvedStateCode,
                    stateName: resolvedStateName,
                    countryIso2: country.iso2,
                    countryName: country.name,
                  ),
                  label: name,
                  subtitle:
                      resolvedStateName.isEmpty ? null : resolvedStateName,
                ))
            .toList();
      },
      remotePagedBuilder: whitelist != null
          ? null
          : (query, page) async {
              try {
                final result = await _fetchCitiesPage(
                  iso2: country.iso2,
                  query: query,
                  page: page,
                );
                return DropdownPickerPage<CityItem>(
                  options: result.items
                      .map((c) => DropdownPickerOption<CityItem>(
                            value: c,
                            label: c.name,
                            subtitle:
                                c.stateName.isEmpty ? null : c.stateName,
                          ))
                      .toList(),
                  hasMore: result.hasMore,
                );
              } catch (_) {
                return const DropdownPickerPage<CityItem>(
                  options: [],
                  hasMore: false,
                );
              }
            },
    );

    if (chosen == null || !mounted) return;
    setState(() {
      _selectedCity = chosen;
      if (chosen.stateName.isNotEmpty) {
        _stateController.text = chosen.stateName;
      }
    });
  }

  Future<({List<CityItem> items, bool hasMore})> _fetchCitiesPage({
    required String iso2,
    required String query,
    required int page,
  }) async {
    final completer = Completer<({List<CityItem> items, bool hasMore})>();
    final bloc = context.read<GetCitiesBloc>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((state) {
      if (state is GetCitiesLoaded) {
        completer.complete((items: state.cities, hasMore: state.hasMore));
        sub.cancel();
      } else if (state is GetCitiesFailed) {
        completer.complete((items: <CityItem>[], hasMore: false));
        sub.cancel();
      }
    });
    bloc.add(SearchCities(iso2: iso2, query: query, page: page));
    return completer.future;
  }

  String _resolvePincodeStateName() {
    final state = context.read<ResolvePincodeBloc>().state;
    if (state is ResolvePincodeLoaded) {
      return state.primaryMatch?.stateName ?? '';
    }
    return '';
  }

  String _resolvePincodeStateCode() {
    final state = context.read<ResolvePincodeBloc>().state;
    if (state is ResolvePincodeLoaded) {
      return state.primaryMatch?.stateCode ?? '';
    }
    return '';
  }

  void _onZipcodeChanged(String value) {
    _pincodeDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 4) {
      _pincodeCityWhitelist = null;
      context.read<ResolvePincodeBloc>().add(const ClearPincodeResolution());
      return;
    }
    _pincodeDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<ResolvePincodeBloc>().add(ResolvePincode(
            pincode: trimmed,
            expectedCountryIso2: _selectedCountry?.iso2,
          ));
    });
  }

  Future<void> _applyPincodeMatch(PincodeMatch match) async {
    setState(() {
      _stateController.text = match.stateName;
      _pincodeCityWhitelist = match.cities;
      if (match.cities.length == 1) {
        // pincode maps to a single city — auto-fill it
        _selectedCity = CityItem(
          name: match.cities.first,
          stateCode: match.stateCode,
          stateName: match.stateName,
          countryIso2: match.countryIso2,
          countryName: match.countryName,
        );
      } else if (_selectedCity != null &&
          !match.cities
              .map((c) => c.toLowerCase())
              .contains(_selectedCity!.name.toLowerCase())) {
        _selectedCity = null;
      }
    });
  }

  Future<void> _pickPincodeMarket(List<PincodeMatch> matches) async {
    final chosen = await showSearchablePickerSheet<PincodeMatch>(
      context: context,
      title: AppLocalizations.of(context)?.chooseMarketForPincode ??
          'Choose region',
      itemsBuilder: (query) {
        final trimmed = query.trim().toLowerCase();
        final filtered = trimmed.isEmpty
            ? matches
            : matches
                .where((m) =>
                    m.stateName.toLowerCase().contains(trimmed) ||
                    m.countryName.toLowerCase().contains(trimmed))
                .toList();
        return filtered
            .map((m) => DropdownPickerOption<PincodeMatch>(
                  value: m,
                  label: '${m.stateName}, ${m.countryName}',
                  subtitle: '${m.cities.length} cities',
                ))
            .toList();
      },
    );
    if (chosen == null || !mounted) return;
    _applyPincodeMatch(chosen);
  }

  bool _validate() {
    _submitAttempted = true;
    final formValid = _formKey.currentState?.validate() ?? false;
    final country = _selectedCountry;
    final l10n = AppLocalizations.of(context);
    if (country == null) {
      ToastManager.show(
        context: context,
        message: l10n?.pleaseSelectCountry ?? 'Please select a country',
        type: ToastType.error,
      );
      return false;
    }
    if (_selectedCity == null) {
      ToastManager.show(
        context: context,
        message: l10n?.pleaseSelectCity ?? 'Please select a city',
        type: ToastType.error,
      );
      return false;
    }
    if (country.requiresZipcode) {
      final zip = _zipcodeController.text.trim();
      if (zip.isEmpty) {
        ToastManager.show(
          context: context,
          message: l10n?.pleaseEnterZipcode ?? 'Please enter a pincode',
          type: ToastType.error,
        );
        return false;
      }
    }
    return formValid;
  }

  void _submit() {
    if (!_validate()) return;
    final country = _selectedCountry!;
    final city = _selectedCity!;
    final zipcode =
        country.requiresZipcode ? _zipcodeController.text.trim() : '';

    if (widget.isEdit && widget.address?.id != null) {
      context.read<GetAddressListBloc>().add(UpdateAddressRequest(
            addressId: widget.address!.id!,
            addressLine1: _addressLine1Controller.text.trim(),
            addressLine2: _addressLine2Controller.text.trim(),
            city: city.name,
            landmark: _landmarkController.text.trim(),
            state: _stateController.text.trim(),
            zipcode: zipcode,
            mobile: _mobileController.text.trim(),
            addressType: _selectedAddressType,
            country: country.name,
            countryCode: country.iso2,
            latitude: '',
            longitude: '',
            isDefaultShipping: _isDefaultShipping,
          ));
    } else {
      context.read<GetAddressListBloc>().add(AddAddressRequest(
            addressLine1: _addressLine1Controller.text.trim(),
            addressLine2: _addressLine2Controller.text.trim(),
            city: city.name,
            landmark: _landmarkController.text.trim(),
            state: _stateController.text.trim(),
            zipcode: zipcode,
            mobile: _mobileController.text.trim(),
            addressType: _selectedAddressType,
            country: country.name,
            countryCode: country.iso2,
            latitude: '',
            longitude: '',
            deliveryZoneId: widget.deliveryZoneId,
            isDefaultShipping: _isDefaultShipping,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<GetCountriesBloc, GetCountriesState>(
          listener: (context, state) {
            if (state is GetCountriesLoaded) {
              _onCountriesLoaded(state.countries);
            } else if (state is GetCountriesFailed) {
              ToastManager.show(
                context: context,
                message: state.error,
                type: ToastType.error,
              );
            }
          },
        ),
        BlocListener<ResolvePincodeBloc, ResolvePincodeState>(
          listener: (context, state) {
            if (state is ResolvePincodeLoaded) {
              if (state.isAmbiguous) {
                _pickPincodeMarket(state.matches);
              } else if (state.primaryMatch != null) {
                _applyPincodeMatch(state.primaryMatch!);
              }
            } else if (state is ResolvePincodeNotFound) {
              ToastManager.show(
                context: context,
                message: l10n.pincodeNotFound,
                type: ToastType.info,
              );
              setState(() {
                _pincodeCityWhitelist = null;
              });
            } else if (state is ResolvePincodeInitial) {
              setState(() {
                _pincodeCityWhitelist = null;
              });
            }
          },
        ),
        BlocListener<GetAddressListBloc, GetAddressListState>(
          listener: (context, state) {
            if (state is GetAddressListLoaded) {
              if (state.isAdded || state.isUpdated) {
                if (Navigator.of(context).canPop()) {
                  GoRouter.of(context).pop();
                }
              } else if (state.failed) {
                ToastManager.show(
                  context: context,
                  message: state.message,
                  type: ToastType.error,
                );
              }
            } else if (state is GetAddressListFailed) {
              ToastManager.show(
                context: context,
                message: state.error,
                type: ToastType.error,
              );
            }
          },
        ),
      ],
      child: CustomScaffold(
        showViewCart: false,
        showAppBar: true,
        title: widget.isEdit ? l10n.editAddress : l10n.addNewAddress,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: TabletConstrainedBody(
        child: BlocBuilder<GetCountriesBloc, GetCountriesState>(
          builder: (context, countriesState) {
            if (countriesState is GetCountriesLoading ||
                countriesState is GetCountriesInitial) {
              return _buildLoadingState();
            }
            if (countriesState is GetCountriesFailed) {
              return _buildRetryState(countriesState.error);
            }
            final countries = countriesState is GetCountriesLoaded
                ? countriesState.countries
                : <CountryItem>[];
            return _buildForm(countries);
          },
        ),
      ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryColor,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildRetryState(String error) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 52, color: colorScheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.somethingWentWrong,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context
                  .read<GetCountriesBloc>()
                  .add(const FetchCountries()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List<CountryItem> countries) {
    final l10n = AppLocalizations.of(context)!;
    final country = _selectedCountry;
    final showZipcode = country?.requiresZipcode ?? true;

    return BlocBuilder<GetAddressListBloc, GetAddressListState>(
      buildWhen: (previous, current) => current is GetAddressListLoaded,
      builder: (context, addressListState) {
        final isSubmitting = addressListState is GetAddressListLoaded &&
            (addressListState.isAdding || addressListState.isUpdating);

        return Form(
          key: _formKey,
          autovalidateMode: _submitAttempted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(l10n.deliveryLocation),
                      const SizedBox(height: 12),
                      _card(
                        child: Column(
                          children:   [
                            SearchableDropdownField<CountryItem>(
                              label: l10n.country,
                              value: country?.name,
                              hint: l10n.selectCountry,
                              prefixIcon: Icons.public_outlined,
                              onTap: () => _pickCountry(countries),
                              validator: () => country == null
                                  ? l10n.pleaseSelectCountry
                                  : null,
                            ),
                            if (showZipcode) ...[
                              const SizedBox(height: 12),
                              BlocBuilder<ResolvePincodeBloc,
                                  ResolvePincodeState>(
                                builder: (context, pincodeState) {
                                  final loading =
                                      pincodeState is ResolvePincodeLoading;
                                  return CustomTextFormField(
                                    controller: _zipcodeController,
                                    labelText: l10n.zipcode,
                                    prefixIcon: Icons.markunread_mailbox_outlined,
                                    keyboardType: TextInputType.text,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.singleLineFormatter,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    onChanged: _onZipcodeChanged,
                                    suffix: loading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : null,
                                    validator: (value) {
                                      if (!showZipcode) return null;
                                      final v = (value ?? '').trim();
                                      if (v.isEmpty) {
                                        return l10n.pleaseEnterZipcode;
                                      }
                                      if (v.length < 4) {
                                        return l10n.pleaseEnterValidZipcode;
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            BlocBuilder<GetCitiesBloc, GetCitiesState>(
                              builder: (context, cityState) {
                                final loading = cityState is GetCitiesLoading;
                                return SearchableDropdownField<CityItem>(
                                  label: l10n.city,
                                  value: _selectedCity?.name,
                                  // hint: l10n.selectCity,
                                  prefixIcon: Icons.location_city_outlined,
                                  loading: loading,
                                  enabled: country != null,
                                  onTap: _pickCity,
                                  validator: () => _selectedCity == null
                                      ? l10n.pleaseSelectCity
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: _stateController,
                              labelText: l10n.state,
                              prefixIcon: Icons.map_outlined,
                              // enabled: false,
                              readOnly: true,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return l10n.pleaseEnterState;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(l10n.addressDetails),
                      const SizedBox(height: 12),
                      _card(
                        child: Column(
                          children: [
                            CustomTextFormField(
                              controller: _addressLine1Controller,
                              labelText: l10n.addressLine1,
                              prefixIcon: Icons.home_outlined,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(120),
                              ],
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return l10n.pleaseEnterAddressLine1;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: _addressLine2Controller,
                              labelText: l10n.addressLine2Optional,
                              prefixIcon: Icons.home_work_outlined,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(120),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: _landmarkController,
                              labelText: l10n.landmark,
                              prefixIcon: Icons.push_pin_outlined,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(80),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(l10n.contactDetails),
                      const SizedBox(height: 12),
                      _card(
                        child: CustomTextFormField(
                          controller: _mobileController,
                          labelText: l10n.mobileNumber,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return l10n.pleaseEnterMobileNumber;
                            if (v.length < 7) {
                              return l10n.pleaseEnterValidPhoneNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(l10n.saveAddressAs),
                      const SizedBox(height: 12),
                      _buildAddressTypeSelector(l10n),
                      const SizedBox(height: 16),
                      _buildDefaultToggle(l10n),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(l10n, isSubmitting),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }

  Widget _buildAddressTypeSelector(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: _addressTypes.map((type) {
        final isFirst = _addressTypes.first == type;
        final label = _labelForAddressType(type, l10n);
        final selected = _selectedAddressType == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: isFirst ? 0 : 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedAddressType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                      : colorScheme.surface,
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryColor
                        : colorScheme.outlineVariant.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(
                      _addressTypeIcons[type],
                      color: selected
                          ? AppTheme.primaryColor
                          : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppTheme.primaryColor
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _labelForAddressType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'home':
        return l10n.home;
      case 'office':
        return l10n.office;
      default:
        return l10n.other;
    }
  }

  Widget _buildDefaultToggle(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.setAsDefaultAddress,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch.adaptive(
            value: _isDefaultShipping,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _isDefaultShipping = v),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, bool isSubmitting) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    isSubmitting ? null : () => GoRouter.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(l10n.cancel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : _submit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(widget.isEdit
                        ? Icons.check_rounded
                        : Icons.add_location_alt_outlined),
                label: Text(widget.isEdit ? l10n.update : l10n.save),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
