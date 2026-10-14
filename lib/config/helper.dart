import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../screens/my_orders/model/order_detail_model.dart';
import '../services/market/market_service.dart';
import 'api_base_helper.dart';

enum AuthIdentifierMode { requireBoth, emailPrimary, mobilePrimary }

class AppHelpers {
  static String localUserLocationHiveBoxName = 'userLocationBox';
  static String localUserLocationHiveBoxKey = 'user_location';
  static String selectedAddressHiveBoxName = 'selectedAddressBox';
  static String selectedAddressHiveBoxKey = 'selected_address';
  static String userHiveBoxName = 'UserDataBox';
  static ApiBaseHelper apiBaseHelper = ApiBaseHelper();
  static String systemVersion = '3.2.0';
  static double bottomNavBarHeight = Platform.isAndroid ? 68.h : 75.h;

  static String notificationSound = 'notification_sound';
  static bool get smsGatewayIsFirebase => SettingsData.instance.authentication?.smsGateway == 'firebase';

  static AuthIdentifierMode get authMode {
    switch (SettingsData.instance.authentication?.identifierMode) {
      case 'email_primary':
        return AuthIdentifierMode.emailPrimary;
      case 'mobile_primary':
        return AuthIdentifierMode.mobilePrimary;
      default:
        return AuthIdentifierMode.requireBoth;
    }
  }

  static bool get isEmailRequired => authMode != AuthIdentifierMode.mobilePrimary;
  static bool get isMobileRequired => authMode != AuthIdentifierMode.emailPrimary;

  static int get unreadNotificationCount => SettingsData.instance.notification?.notificationUnreadCount ?? 0;
  static String get isoCode => SettingsData.instance.system?.defaultISO2 ?? 'IN';
  static bool get countryValidationEnable => false;
  static List<String> get allowedCountries => ['IN'];
  static String get baseCurrencySymbol => SettingsData.instance.system?.currencySymbol ?? '₹';

  static bool get isDemo => SettingsData.instance.system?.demoMode ?? false;
  static String get demoModeMessage => SettingsData.instance.system?.customerDemoModeMessage ?? 'This is operation is allowed in Demo Mode.';
  static String get demoModeLocationMessage => SettingsData.instance.system?.customerLocationDemoModeMessage ?? 'Demo mode is enabled. Location will default automatically.';

  static String get defaultLat {
    return '23.2420';
  }

  static String get defaultLng {
    return '69.6669';
  }

  static String get currency {
    final settingsMarketSymbol = SettingsData.instance.markets?.current?.currency?.symbol;
    if (settingsMarketSymbol != null && settingsMarketSymbol.isNotEmpty) {
      return settingsMarketSymbol;
    }
    final settingsMarketCurrency = SettingsData.instance.markets?.current?.currencyCode;
    if (settingsMarketCurrency != null && settingsMarketCurrency.isNotEmpty) {
      return settingsMarketCurrency;
    }
    final marketCurrencySymbol = MarketService.currentCurrencySymbol();
    if (marketCurrencySymbol != null && marketCurrencySymbol.isNotEmpty) {
      return marketCurrencySymbol;
    }
    final marketCurrency = MarketService.currentCurrency();
    if (marketCurrency != null && marketCurrency.isNotEmpty) {
      return marketCurrency;
    }
    return SettingsData.instance.system?.currencySymbol ?? '₹';
  }

  static IconData wishListedIcon = TablerIcons.heart_filled;
  static IconData notWishListedIcon = TablerIcons.heart;
  static String authMessage = 'Please log in to continue. This helps us save your preferences and keep your shopping journey seamless.';

  static String defaultLocalCurrency = 'en_In';

  static Map<String, dynamic> defaultFullAddress = {
    "address_line1": "Bhuj",
    "address_line2": "",
    "city": "Bhuj",
    "landmark": "Hospital road",
    "state": "Gujarat",
    "zipcode": "370001",
    "mobile": "9000000000",
    "address_type": "home",
    "country": "India",
    "country_code": "IN",
    "latitude": 23.2420,
    "longitude": 69.6669
  };

}

String formatNumber(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

class MediaQueryHelper {
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
}

bool isTablet(BuildContext context) {
  final shortestSide = MediaQuery.of(context).size.shortestSide;
  return shortestSide >= 600;
}

bool isCartItemReachedMaxLimit(BuildContext context) {
  final int totalCartItems = context.read<GetUserCartBloc>().totalCartItems;
  final maxCartItemLimit = SettingsData.instance.system?.maximumItemsAllowedInCart ?? 0;
  // 0 / null / negative = no cap configured — treat as unlimited.
  if (maxCartItemLimit <= 0) return false;
  return totalCartItems >= maxCartItemLimit;
}

double getMaxCrossAxisExtent(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth > 500) {
    return 200.w; // Large screens (e.g., desktops)
  } else if (screenWidth > 300) {
    return 150.w; // Tablets
  } else {
    return 120.w; // Phones
  }
}

String formatIsoDateToCustomFormat(String isoDate) {
  DateTime dateTime = DateTime.parse(isoDate);
  final formatter = DateFormat('dd MMM yyyy', 'en_US');
  return formatter.format(dateTime);
}

String capitalizeFirstLetter(String s) {
  if (s.isEmpty) return s; // Handle empty string

  int firstLetterIndex = 0;
  while (firstLetterIndex < s.length && !RegExp(r'[a-zA-Z]').hasMatch(s[firstLetterIndex])) {
    firstLetterIndex++;
  }

  if (firstLetterIndex >= s.length) return s;

  return s.substring(0, firstLetterIndex) +
      s[firstLetterIndex].toUpperCase() +
      s.substring(firstLetterIndex + 1);
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'N/A';

  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final day = dateTime.day;
  final month = months[dateTime.month - 1];
  final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'pm' : 'am';

  return '$day $month, $hour:$minute $period';
}

String normalize(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'\s+'), '')
      .toLowerCase();
}

String formatPrice(num value, {String locale = 'en_IN'}) {
  final formatter = NumberFormat.decimalPattern(locale);
  return formatter.format(value);
}

List<String> removeUnderscoresFromStringList(List<String> labels) {
  return labels.map((label) => label.replaceAll('_', ' ')).toList();
}

String removeUnderscores(String label) {
  return label.replaceAll('_', ' ').trim();
}

// 1) Add a hex parser (utility or extension)
Color? hexStringToColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (value.isEmpty) return null;

  // Remove leading '#'
  if (value.startsWith('#')) value = value.substring(1);

  // Support shorthand 3/4-digit? If needed, expand here; otherwise only 6/8.
  if (value.length == 6) {
    // RRGGBB -> AARRGGBB with alpha FF
    value = 'FF$value';
  } else if (value.length == 8) {
    // already AARRGGBB
  } else {
    return null; // invalid length
  }

  try {
    final intColor = int.parse(value, radix: 16);
    return Color(intColor);
  } catch (_) {
    return null;
  }
}

Future<FormData> formDataWithImages({
  required Map<String, dynamic> fields,
  required List<XFile> images,
  required String imageFieldLabel,
}) async {
  final data = FormData.fromMap(fields);
  for (int i = 0; i < images.length; i++) {
    final xfile = images[i];

    // This is the MOST important part
    final multipartFile = await MultipartFile.fromFile(
      xfile.path,
      filename: xfile.name.isNotEmpty ? xfile.name : 'image_$i.jpg',
    );

    // Correct key: 'images[]' → tells PHP/Laravel to treat as array
    data.files.add(MapEntry('$imageFieldLabel[]', multipartFile));
  }
  return data;
}

class ItemStatus {
  final String? message;
  final Color color;
  final IconData icon;

  ItemStatus({this.message, required this.color, required this.icon});
}

ItemStatus getItemStatus(OrderItems item) {
  // No return → no banner needed (pill handles item-level status)
  if (item.returns.isEmpty) {
    return ItemStatus(color: Colors.transparent, icon: Icons.info);
  }

  final returnData = item.returns.first;
  final returnStatus = returnData.returnStatus;
  final pickupStatus = returnData.pickupStatus ?? 'pending';
  final refundAmount = returnData.refundAmount ?? 0;

  switch (returnStatus) {
    case 'requested':
      return ItemStatus(
        message: 'Return request submitted successfully',
        color: Colors.orange.shade700,
        icon: Icons.access_time,
      );

    case 'seller_approved':
      switch (pickupStatus) {
        case 'scheduled':
          return ItemStatus(
            message: 'Pickup scheduled! Delivery partner will contact you soon',
            color: Colors.blue.shade600,
            icon: Icons.schedule,
          );
        case 'in_transit':
          return ItemStatus(
            message: 'Delivery partner is on the way to collect your return',
            color: Colors.blue.shade700,
            icon: Icons.local_shipping_outlined,
          );
        case 'picked_up':
          return ItemStatus(
            message: 'Return picked up successfully',
            color: AppTheme.successColor,
            icon: Icons.check_circle_outline,
          );
        case 'failed':
          return ItemStatus(
            message: 'Pickup failed. Will be rescheduled soon',
            color: AppTheme.errorColor,
            icon: Icons.error_outline,
          );
        default: // pending
          return ItemStatus(
            message: 'Return approved! Waiting for pickup to be scheduled',
            color: Colors.orange.shade700,
            icon: Icons.pending_actions,
          );
      }

    case 'picked_up':
      return ItemStatus(
        message: 'Return collected & on the way to warehouse',
        color: AppTheme.successColor,
        icon: Icons.inventory_2_outlined,
      );

    case 'received':
      return ItemStatus(
        message: 'Return received at warehouse. Processing your refund...',
        color: AppTheme.successColor,
        icon: Icons.warehouse_outlined,
      );

    case 'refund_processed':
      return ItemStatus(
        message: '₹$refundAmount refunded successfully!',
        color: AppTheme.successColor,
        icon: Icons.check_circle,
      );

    case 'rejected':
      return ItemStatus(
        message: 'Return request rejected by seller',
        color: AppTheme.errorColor,
        icon: Icons.block,
      );

    case 'cancelled':
      return ItemStatus(
        message: 'Return request has been cancelled.',
        color: AppTheme.successColor,
        icon: Icons.check_circle,
      );

    case 'received_by_seller':
      return ItemStatus(
        message: 'Received by seller',
        color: AppTheme.successColor,
        icon: Icons.check_circle,
      );

    case 'completed':
      return ItemStatus(
        message: 'Completed',
        color: AppTheme.successColor,
        icon: Icons.check_circle,
      );

    default:
      return ItemStatus(
        message: 'Return in progress',
        color: Colors.orange.shade700,
        icon: Icons.sync,
      );
  }
}

Future<void> makePhoneCall({required String phoneNumber, required BuildContext context}) async {
  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    if(context.mounted) {
      ToastManager.show(
          context: context,
          message: 'Could not launch dialer'
      );
    }
  }
}

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

String getAppLogoUrl(BuildContext context) {
  const String darkLogoUrl  = "assets/images/app_launcher_logo/launcher_icon.png";
  return darkLogoUrl;
}

String generateId(double lat, double lng, String? address) {
  final cleanAddress = (address ?? '').trim().toLowerCase();
  final key = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}_$cleanAddress';
  return key.hashCode.toString(); // or use uuid.v5 if you want
}

String generateUuidV4() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

int parseInt(dynamic value, {String context = 'parseInt'}) {
  if (value == null || value == "") {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

double parseDouble(dynamic value, {String context = 'parseDouble'}) {
  if (value == null || value == "") {
    return 0.0;
  }

  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }

  return 0.0;
}

String parseString(dynamic value, {String context = 'parseString'}) {
  if (value == null) {
    return "";
  }

  return value.toString();
}

bool parseBool(dynamic value, {String context = 'parseBool'}) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  final str = value.toString().trim().toLowerCase();

  if (str == 'true' || str == '1' || str == 'yes' || str == 'on') {
    return true;
  }

  // Anything else (including 'false', '0', 'no', 'off', empty, unrecognized) → false.
  return false;
}

Map<String, dynamic> parseMap(dynamic value, {String context = 'parseMap'}) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  // Handle Map<dynamic, dynamic> (e.g. from some decoders / Hive) by coercing keys to String.
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  // null / missing / unsupported type → empty map.
  return {};
}

List<dynamic> parseList(dynamic value, {String context = 'parseList'}) {
  if (value is List) {
    return value;
  }

  // null / missing / unsupported type → empty list.
  return [];
}

const String darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#212121"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#2c2c2c"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    }
  ]
  ''';

Future<String> downloadAndSaveImage(String url, String fileName) async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';

  final response = await http.get(Uri.parse(url));
  final file = File(filePath);

  await file.writeAsBytes(response.bodyBytes);

  return filePath;
}

String? getDialCodeFromIso(String isoCode) {
  try {
    final country = countries.firstWhere(
          (c) => c.code.toUpperCase() == isoCode.toUpperCase(),
    );
    return '+${country.dialCode}';
  } catch (e) {
    return null;
  }
}

String? getIsoFromDialCode(String dialCode) {
  try {
    final cleanedDialCode = dialCode.replaceAll('+', '');

    final country = countries.firstWhere(
          (element) => element.dialCode == cleanedDialCode,
    );

    return country.code;
  } catch (e) {
    return null;
  }
}

String filterPaymentMethodLabel(String paymentMethodLabel) {
  final value = paymentMethodLabel.toLowerCase();

  if (value.contains('razorpay')) {
    return 'Razorpay';
  } else if (value.contains('paystack')) {
    return 'Paystack';
  } else if (value.contains('stripe')) {
    return 'Stripe';
  } else if (value.contains('flutterwave')) {
    return 'Flutterwave';
  } else if (value.contains('mercadopago') || value.contains('mercado_pago')) {
    return 'Mercado Pago';
  } else if (value.contains('xendit')) {
    return 'Xendit';
  } else if (value.contains('cod') || value.contains('cashondelivery')) {
    return 'Cash on Delivery';
  }

  return paymentMethodLabel;
}

IconData filterPaymentMethodIcon(String paymentMethodLabel) {
  final value = paymentMethodLabel.toLowerCase();
  if (value.contains('cod') || value.contains('cashondelivery')) {
    return HeroiconsOutline.banknotes;
  } else if (value.contains('wallet')) {
    return HeroiconsOutline.wallet;
  } else {
    return RemixIcons.bank_line;
  }
}

DateTime? etaDate(DateTime from, int? amount, String? unit) {
  if (amount == null) return null;
  switch ((unit ?? 'days').toLowerCase()) {
    case 'minute':
    case 'minutes':
      return from.add(Duration(minutes: amount));
    case 'hour':
    case 'hours':
      return from.add(Duration(hours: amount));
    case 'week':
    case 'weeks':
      return from.add(Duration(days: amount * 7));
    case 'month':
    case 'months':
      return DateTime(from.year, from.month + amount, from.day);
    default:
      return from.add(Duration(days: amount));
  }
}

/// Formats raw timestamp or ISO-8601 date string into compact relative time (e.g., '1m', '12h', '2d', '1w', '1mo', '1y')
String formatRelativeTime(String? rawTime) {
  if (rawTime == null || rawTime.trim().isEmpty) return '';
  final trimmed = rawTime.trim();

  // If already in compact format (e.g., "1m", "12h", "2d", "1w")
  if (RegExp(r'^\d+[smhdw]$').hasMatch(trimmed) ||
      RegExp(r'^\d+(mo|y)$').hasMatch(trimmed)) {
    return trimmed;
  }

  DateTime? dt = DateTime.tryParse(trimmed);
  if (dt == null) {
    final intVal = int.tryParse(trimmed);
    if (intVal != null) {
      if (intVal > 100000000000) {
        dt = DateTime.fromMillisecondsSinceEpoch(intVal, isUtc: true);
      } else if (intVal > 1000000) {
        dt = DateTime.fromMillisecondsSinceEpoch(intVal * 1000, isUtc: true);
      }
    }
  }

  if (dt == null) {
    return trimmed;
  }

  final now = DateTime.now();
  final difference = now.difference(dt.toLocal());

  if (difference.isNegative || difference.inMinutes < 1) {
    return '1m';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '${weeks > 0 ? weeks : 1}w';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '${months > 0 ? months : 1}mo';
  } else {
    final years = (difference.inDays / 365).floor();
    return '${years > 0 ? years : 1}y';
  }
}