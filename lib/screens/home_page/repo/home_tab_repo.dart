import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';
import '../../../config/helper.dart';

class HomeTabRepository {
  static const String _boxName = 'HomeTabCacheBox';
  static const String _cacheKey = 'HomeTabsData';

  Future<Map<String, dynamic>?> getCachedHomeTabs() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_cacheKey);
      if (raw != null) {
        if (raw is Map) {
          return Map<String, dynamic>.from(raw);
        } else if (raw is String) {
          return jsonDecode(raw) as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCachedHomeTabs(Map<String, dynamic> data) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_cacheKey, data);
    } catch (_) {}
  }

  /// Fetches tab items for the home page tab bar with platform=app.
  /// Gated by X-Market header.
  Future<Map<String, dynamic>> fetchHomeTabs({
    String platform = 'app',
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.homeTabApi,
        {'platform': platform},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        unawaited(saveCachedHomeTabs(data));
      }
      return data;
    } catch (e) {
      throw ApiException('Failed to fetch home tabs');
    }
  }
}

