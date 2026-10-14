/// Per-market number-formatting rules.
///
/// Mirrors the `format` dict surfaced by the backend's `PricePresenter` (see
/// `hypercommerce-panel/app/Support/PricePresenter.php`). Every variant /
/// cart-line / wishlist-line response carries one of these; the
/// [MarketResource] also exposes it on its `format` field so the app can
/// reformat *any* number (wallet balances, dashboard totals, computed
/// running totals) consistently with what the server rendered.
///
/// Defaults are US-style — chosen so a null/missing payload still produces
/// a sensible string (`$1,234.56`).
class MoneyFormat {
  /// `"before"` (e.g. `$100`) or `"after"` (e.g. `100€`).
  final String symbolPosition;

  /// Insert a space between symbol and number — `"100 €"` vs `"100€"`.
  final bool spaceBetweenSymbol;

  /// Character separating thousands. Common: `","`, `"."`, `" "`, `""`.
  final String thousandSeparator;

  /// Character separating the integer + fractional halves.
  final String decimalSeparator;

  /// `"western"` (1,234,567) or `"indian"` (12,34,567 — lakh grouping).
  final String groupingStyle;

  /// Number of digits after the decimal separator. May differ from the
  /// currency's default (a market can override INR-with-no-paise as 0).
  final int decimalPlaces;

  /// Template applied to the formatted-with-symbol string when negative.
  /// `{n}` is the placeholder. Examples: `"-{n}"`, `"({n})"`, `"{n}-"`.
  final String negativeFormat;

  const MoneyFormat({
    this.symbolPosition = 'before',
    this.spaceBetweenSymbol = false,
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
    this.groupingStyle = 'western',
    this.decimalPlaces = 2,
    this.negativeFormat = '-{n}',
  });

  /// Sentinel default — what we use when a payload pre-dates this rollout
  /// or a model didn't carry a `format` block.
  static const MoneyFormat defaults = MoneyFormat();

  /// Parse from a JSON map. Permissive: any missing field falls back to the
  /// US-style default. A null map returns [defaults].
  factory MoneyFormat.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return MoneyFormat(
      symbolPosition:
          _readString(json['symbol_position'], defaults.symbolPosition),
      spaceBetweenSymbol:
          _readBool(json['space_between_symbol'], defaults.spaceBetweenSymbol),
      thousandSeparator: _readString(
          json['thousand_separator'], defaults.thousandSeparator),
      decimalSeparator:
          _readString(json['decimal_separator'], defaults.decimalSeparator),
      groupingStyle:
          _readString(json['grouping_style'], defaults.groupingStyle),
      decimalPlaces:
          _readInt(json['decimal_places'], defaults.decimalPlaces),
      negativeFormat:
          _readString(json['negative_format'], defaults.negativeFormat),
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol_position': symbolPosition,
        'space_between_symbol': spaceBetweenSymbol,
        'thousand_separator': thousandSeparator,
        'decimal_separator': decimalSeparator,
        'grouping_style': groupingStyle,
        'decimal_places': decimalPlaces,
        'negative_format': negativeFormat,
      };

  static String _readString(dynamic v, String fallback) {
    if (v == null) return fallback;
    final s = v.toString();
    return s.isEmpty ? fallback : s;
  }

  static bool _readBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }

  static int _readInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
