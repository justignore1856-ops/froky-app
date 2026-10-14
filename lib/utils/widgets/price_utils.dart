import '../../config/helper.dart';
import '../money_format.dart';

class PriceUtils {
  /// Calculate discount percentage
  static double calculateDiscountPercentage(double originalPrice, double salePrice) {
    if (originalPrice <= 0 || salePrice <= 0) return 0.0;
    if (salePrice >= originalPrice) return 0.0;

    final discount = ((originalPrice - salePrice) / originalPrice) * 100;
    return discount.toDouble();
  }

  static String formatPrice(double price) {
    return formatWithSymbol(price, AppHelpers.currency);
  }

  static String formatWithSymbol(double price, String? symbol) {
    final s = (symbol != null && symbol.isNotEmpty) ? symbol : AppHelpers.currency;
    return '$s${formatNumber(price.toDouble())}';
  }


  static String formatWithFormat(
      double amount,
      MoneyFormat format,
      String? symbol,
      ) {
    final sym = (symbol != null && symbol.isNotEmpty)
        ? symbol
        : AppHelpers.currency;

    final isNegative = amount < 0;
    final abs = amount.abs();

    // Step 1 — round to the market's decimal count.
    final rounded = abs.toStringAsFixed(format.decimalPlaces);

    // Step 2 — split integer + fraction.
    final dotIdx = rounded.indexOf('.');
    final intPart = dotIdx >= 0
        ? rounded.substring(0, dotIdx)
        : rounded;

    var fracPart = dotIdx >= 0
        ? rounded.substring(dotIdx + 1)
        : '';

    // Remove trailing zeros from decimal part.
    // 50 -> 5, 500 -> 5, 000 -> empty.
    fracPart = fracPart.replaceFirst(RegExp(r'0+$'), '');

    // Step 3 — grouping (western 3/3/3 vs indian 3/2/2).
    final intGrouped = _groupInteger(
      intPart,
      format.thousandSeparator,
      format.groupingStyle,
    );

    // Step 4 — stitch with the market's decimal separator.
    final number = fracPart.isNotEmpty
        ? '$intGrouped${format.decimalSeparator}$fracPart'
        : intGrouped;

    // Step 5 — compose with symbol per position + optional space.
    final space = format.spaceBetweenSymbol ? ' ' : '';

    final withSym = format.symbolPosition == 'after'
        ? '$number$space$sym'
        : '$sym$space$number';

    if (!isNegative) return withSym;

    // Step 6 — wrap with the negative template.
    final tpl = format.negativeFormat.contains('{n}')
        ? format.negativeFormat
        : '-{n}';

    return tpl.replaceFirst('{n}', withSym);
  }

  /// Group an integer-string per the chosen grouping style.
  ///   western : `1,234,567`
  ///   indian  : `12,34,567`
  static String _groupInteger(String digits, String separator, String style) {
    if (separator.isEmpty || digits.length <= 3) return digits;
    if (style == 'indian') {
      final reversed = digits.split('').reversed.join();
      final first = reversed.substring(0, 3);
      final rest = reversed.substring(3);
      final chunks = <String>[];
      for (var i = 0; i < rest.length; i += 2) {
        chunks.add(rest.substring(i, i + 2 > rest.length ? rest.length : i + 2));
      }
      return ([first, ...chunks].join(separator)).split('').reversed.join();
    }
    // Western — straight 3-digit grouping. Regex-based for parity with
    // backend's number_format(grouping = 3).
    return digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}$separator',
    );
  }

  /// Check if there's a valid discount
  static bool hasDiscount(double originalPrice, double salePrice) {
    return originalPrice > 0 && salePrice > 0 && salePrice < originalPrice;
  }

  /// Get discount amount
  static double getDiscountAmount(double originalPrice, double salePrice) {
    if (!hasDiscount(originalPrice, salePrice)) return 0.0;
    return originalPrice - salePrice;
  }
}
