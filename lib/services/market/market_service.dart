import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../config/constant.dart';
import '../recent_product/recent_product_service.dart';

/// Holds the customer's active market.
///
/// The panel resolves the market on every request via the DetectMarket
/// middleware. The resolution chain is:
///   X-Market header → ?market= query → user_market pivot → market cookie
///   → country header → Setting('default_market_id').
///
/// This service is the app-side half: it caches the resolved market code in
/// Hive and exposes it to [headers] in `security.dart` so subsequent requests
/// carry `X-Market: <code>`. Without it, every catalog call lands on the
/// seeded default market and the customer sees the wrong store/inventory data.
///
/// The picker UI (when it lands) calls [setCode] / [switchTo] to change the
/// active market. Until then, [bootstrap] populates the cache from
/// `/api/markets/current` once per launch so X-Market is sent on every call.
class MarketService {
  MarketService._();

  static const String boxName = 'marketBox';
  static const String _codeKey = 'selected_market_code';
  static const String _nameKey = 'selected_market_name';
  static const String _currencyKey = 'selected_market_currency';
  static const String _currencySymbolKey = 'selected_market_currency_symbol';
  static const String _countryIsoKey = 'selected_country_iso2';
  static const String _countryNameKey = 'selected_country_name';

  /// Broadcasts the new market code whenever it changes. Blocs can listen
  /// and refire their fetch events without a manual hook.
  static final StreamController<String?> _changes =
      StreamController<String?>.broadcast();

  static Stream<String?> get changes => _changes.stream;

  /// Open the Hive box. Idempotent — safe to call from app bootstrap.
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static String? currentCode() {
    if (!Hive.isBoxOpen(boxName)) return null;
    final v = Hive.box(boxName).get(_codeKey);
    return (v is String && v.isNotEmpty) ? v : null;
  }

  static String? currentName() {
    if (!Hive.isBoxOpen(boxName)) return null;
    final v = Hive.box(boxName).get(_nameKey);
    return (v is String && v.isNotEmpty) ? v : null;
  }

  static String? currentCurrency() {
    if (!Hive.isBoxOpen(boxName)) return null;
    final v = Hive.box(boxName).get(_currencyKey);
    return (v is String && v.isNotEmpty) ? v : null;
  }

  static String? currentCurrencySymbol() {
    if (!Hive.isBoxOpen(boxName)) return null;
    final v = Hive.box(boxName).get(_currencySymbolKey);
    return (v is String && v.isNotEmpty) ? v : null;
  }

  /// ISO 3166-1 alpha-2 of the country the customer explicitly picked.
  /// Null until the user has chosen one (cold-start visitors).
  static String? currentCountryIso2() {
    if (!Hive.isBoxOpen(boxName)) return null;
    final v = Hive.box(boxName).get(_countryIsoKey);
    return (v is String && v.isNotEmpty) ? v : null;
  }

  /// Display name of the picked country (e.g., "India"). Cached alongside
  /// the ISO code so the UI doesn't need to re-fetch the country list just
  /// to show the current selection.
  static String? currentCountryName() {
    if (!Hive.isBoxOpen(boxName)) return null;
    final v = Hive.box(boxName).get(_countryNameKey);
    return (v is String && v.isNotEmpty) ? v : null;
  }

  /// Persist which country the user picked. Independent from [cache] because
  /// the country pick is a UX artifact — the server doesn't track it (it
  /// only cares about the market). Emits a change event so listeners can
  /// refresh their displayed country name.
  static Future<void> cacheCountry({
    required String iso2,
    String? name,
  }) async {
    await init();
    final box = Hive.box(boxName);
    final previous = box.get(_countryIsoKey);
    await box.put(_countryIsoKey, iso2);
    if (name != null) await box.put(_countryNameKey, name);

    if (previous != iso2) {
      // Reuse the existing market `changes` stream so the account tile
      // re-renders without needing a separate stream subscription.
      _changes.add(currentCode());
    }
  }

  /// Cache the active market locally. Emits a change event so listeners can
  /// refresh their data.
  static Future<void> cache({
    required String code,
    String? name,
    String? currency,
    String? currencySymbol,
  }) async {
    await init();
    final box = Hive.box(boxName);
    final previous = box.get(_codeKey);
    await box.put(_codeKey, code);
    if (name != null) await box.put(_nameKey, name);
    if (currency != null) await box.put(_currencyKey, currency);
    if (currencySymbol != null) await box.put(_currencySymbolKey, currencySymbol);

    if (previous != code) {
      _changes.add(code);
    }
  }

  /// Wipe the cached market (logout / reset flow).
  static Future<void> clear() async {
    if (!Hive.isBoxOpen(boxName)) return;
    await Hive.box(boxName).clear();
    _changes.add(null);
  }

  /// Bootstrap helper: asks the panel which market this request resolves to
  /// and caches the answer. Fire-and-forget; on failure we keep the previous
  /// cache (the server will still resolve via cookie/default).
  ///
  /// Call once on app launch BEFORE the home page issues its catalog fetches.
  static Future<void> bootstrap() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '${AppConstant.baseUrl}markets/current',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (currentCode() != null) 'X-Market': currentCode()!,
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is Map) {
          final code = data['code'];
          if (code is String && code.isNotEmpty) {
            String? symbol;
            final currencyData = data['currency'];
            if (currencyData is Map) {
              symbol = currencyData['symbol'] is String ? currencyData['symbol'] as String : null;
            }
            await cache(
              code: code,
              name: data['name'] is String ? data['name'] as String : null,
              currency: data['currency_code'] is String
                  ? data['currency_code'] as String
                  : null,
              currencySymbol: symbol,
            );
            // Seed a default country pick so the home top-address label and
            // account subtitle show the country instead of the "select
            // country" prompt on a cold start. No-op once the user has
            // explicitly picked one.
            await _seedDefaultCountry(data, code);
          }
        }
      }
    } catch (e) {
      log('MarketService.bootstrap failed: $e');
    }
  }

  /// First-launch helper: caches a default country for the active market so
  /// surfaces that read the country pick (home top-address label, account
  /// subtitle) aren't left on the "select country" prompt.
  ///
  /// Picks the same country the [CountryBottomSheet] highlights for the active
  /// market — the first by display name — so the picker and the home page
  /// agree. Only runs when the user hasn't explicitly chosen a country yet.
  ///
  /// [currentMarket] is the `/api/markets/current` payload; if it already
  /// embeds a `countries` list we use it directly and skip the extra request.
  static Future<void> _seedDefaultCountry(
    Map currentMarket,
    String marketCode,
  ) async {
    if (currentCountryIso2() != null) return; // respect an explicit pick

    // Prefer countries embedded in the current-market payload.
    List? countries;
    final embedded = currentMarket['countries'];
    if (embedded is List && embedded.isNotEmpty) {
      countries = embedded;
    }

    // Fall back to the full markets list, matching the active market by code.
    if (countries == null) {
      final markets = await listAvailable();
      for (final m in markets) {
        if ((m['code'] as String?) == marketCode) {
          final c = m['countries'];
          if (c is List) countries = c;
          break;
        }
      }
    }

    if (countries == null || countries.isEmpty) return;

    // Flatten to (iso2, name), dedupe, sort by name — same order the picker
    // uses — then take the first.
    final seen = <String>{};
    final options = <MapEntry<String, String>>[];
    for (final c in countries) {
      if (c is! Map) continue;
      final iso = (c['iso2'] as String?)?.toUpperCase();
      final name = c['name'] as String?;
      if (iso == null || iso.isEmpty || name == null) continue;
      if (!seen.add(iso)) continue;
      options.add(MapEntry(iso, name));
    }
    if (options.isEmpty) return;
    options.sort((a, b) => a.value.compareTo(b.value));

    await cacheCountry(iso2: options.first.key, name: options.first.value);
  }

  static List<Map<String, dynamic>>? _availableCache;

  /// List the active markets the storefront supports. Used by the picker.
  /// Cached in memory after the first successful fetch — the country/market
  /// map is static per deploy and is hit on every product detail load.
  static Future<List<Map<String, dynamic>>> listAvailable() async {
    final cached = _availableCache;
    if (cached != null) return cached;
    try {
      final dio = Dio();
      final response = await dio.get(
        '${AppConstant.baseUrl}markets',
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is List) {
          _availableCache = data
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (m) => Map<String, dynamic>.from(m),
              )
              .toList();
          return _availableCache!;
        }
      }
    } catch (e) {
      log('MarketService.listAvailable failed: $e');
    }
    return const [];
  }

  /// Resolve an ISO 3166-1 alpha-2 country code to the market that covers it,
  /// then switch. Returns the resolved market map on success (so the caller
  /// can toast the market name), or null if no market covers that country.
  ///
  /// Used by the AddressBottomSheet flows: tapping a saved address (which
  /// carries country_code) or dropping a pin on the map (which we
  /// reverse-geocode to a country) both call into this.
  static Future<Map<String, dynamic>?> switchByCountry(String iso2) async {
    final market = await marketForCountry(iso2);
    if (market == null) return null;

    final code = (market['code'] as String?) ?? '';
    if (code.isEmpty) return null;

    final ok = await switchTo(code);
    return ok ? market : null;
  }

  /// Switch the active market AND cached country pick to cover [iso2],
  /// resolving the display name from the switched market's country list
  /// (falling back to [fallbackName]). This is the address-driven entry point:
  /// selecting a saved address on the cart/checkout or setting a default
  /// address funnels through here so the storefront follows the address.
  ///
  /// No-op (returns false) when [iso2] isn't a 2-letter code, already reflects
  /// the active country, or no market covers it (keeps the current market).
  static Future<bool> switchAndCacheForCountry({
    required String iso2,
    String? fallbackName,
  }) async {
    final upper = iso2.trim().toUpperCase();
    if (upper.length != 2) return false;
    if (upper == currentCountryIso2()) return false;

    final market = await switchByCountry(upper);
    if (market == null) return false;

    // Prefer the market's canonical country name; fall back to the caller's.
    String? countryName = fallbackName?.trim();
    final countries = market['countries'];
    if (countries is List) {
      for (final c in countries) {
        if (c is Map && (c['iso2'] as String?)?.toUpperCase() == upper) {
          final n = c['name'];
          if (n is String && n.isNotEmpty) countryName = n;
          break;
        }
      }
    }
    if (countryName != null && countryName.isEmpty) countryName = null;

    await cacheCountry(iso2: upper, name: countryName);
    return true;
  }

  /// Find the active market that covers a given ISO 3166-1 alpha-2 country
  /// code. Each country belongs to exactly one market (enforced by the panel
  /// migration `enforce_unique_country_per_market`). Returns null if no
  /// market covers it.
  ///
  /// Pure read — does NOT switch the active market. Use [switchByCountry]
  /// if you want both the lookup AND the switch in one call.
  static Future<Map<String, dynamic>?> marketForCountry(String iso2) async {
    final upper = iso2.trim().toUpperCase();
    if (upper.length != 2) return null;

    final markets = await listAvailable();
    for (final m in markets) {
      final countries = m['countries'];
      if (countries is! List) continue;
      for (final c in countries) {
        // MarketResource emits {id, iso2, name} objects; tolerate bare-string
        // entries for forward/back-compat with older panel deploys.
        String? cIso;
        if (c is Map) {
          final v = c['iso2'];
          if (v is String) cIso = v.toUpperCase();
        } else if (c is String) {
          cIso = c.toUpperCase();
        }
        if (cIso == upper) return Map<String, dynamic>.from(m);
      }
    }
    return null;
  }

  /// Market code covering [iso2], for callers that only need to stamp
  /// `X-Market` on a single request without switching the active market.
  static Future<String?> marketCodeForCountry(String iso2) async {
    final market = await marketForCountry(iso2);
    final code = market?['code'];
    return (code is String && code.isNotEmpty) ? code : null;
  }

  /// Cheap "do we ship to this country?" check used by the
  /// LocationPickerWidget to gate the Save button without a server round
  /// trip. Returns true when [marketForCountry] resolves to something.
  static Future<bool> isCountryCovered(String iso2) async {
    return (await marketForCountry(iso2)) != null;
  }

  /// Switch the active market. Calls `/api/markets/switch` so the server-side
  /// user_market pivot is updated for authenticated users.
  ///
  /// Returns true on success.
  static Future<bool> switchTo(String code) async {
    try {
      final previousCode = currentCode();
      final dio = Dio();
      final response = await dio.post(
        '${AppConstant.baseUrl}markets/switch',
        data: {'code': code},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final marketData = response.data['data']?['market'];
        if (marketData is Map) {
          String? symbol;
          final currencyData = marketData['currency'];
          if (currencyData is Map) {
            symbol = currencyData['symbol'] is String ? currencyData['symbol'] as String : null;
          }
          final resolvedCode = (marketData['code'] as String?) ?? code;
          await cache(
            code: resolvedCode,
            name: marketData['name'] is String
                ? marketData['name'] as String
                : null,
            currency: marketData['currency_code'] is String
                ? marketData['currency_code'] as String
                : null,
            currencySymbol: symbol,
          );
          // Switching country/market changes the catalog, so the locally
          // cached recently-viewed products no longer apply — wipe them.
          if (previousCode != resolvedCode) {
            await RecentlyViewedService.clear();
          }
          return true;
        }
      }
    } catch (e) {
      log('MarketService.switchTo($code) failed: $e');
    }
    return false;
  }
}
