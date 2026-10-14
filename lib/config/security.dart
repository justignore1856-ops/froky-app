import '../services/market/market_service.dart';
import 'global.dart';

Map<String, String>? get headers {
  final String? token = Global.token;
  final String? marketCode = MarketService.currentCode();

  final Map<String, String> base = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  if (token != null) {
    base['Authorization'] = 'Bearer $token';
  }
  if (marketCode != null) {
    base['X-Market'] = marketCode;
  }

  return base;
}
