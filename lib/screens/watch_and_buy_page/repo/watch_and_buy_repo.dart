import 'dart:developer';
import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/seller_profile_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';

class WatchAndBuyRepository {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  /// Fetches Watch & Buy reels list from backend API
  Future<WatchAndBuyResponse> fetchReels({
    String? cursor,
    int perPage = 10,
    String? sessionId,
    String? slug,
  }) async {
    try {
      final query = <String, dynamic>{
        'per_page': perPage,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
        if (slug != null && slug.isNotEmpty) 'slug': slug,
      };

      log('WatchAndBuyRepository: Fetching reels with query $query');

      final response = await _apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyReelsApi,
        query,
      );

      if (response.data is Map<String, dynamic>) {
        return WatchAndBuyResponse.fromJson(response.data);
      } else {
        throw ApiException('Invalid response format from reels API');
      }
    } catch (e) {
      log('WatchAndBuyRepository error: $e');
      throw ApiException(e.toString());
    }
  }

  /// Sync batch of pending reel likes/unlikes via PUT API
  Future<List<ReelLikeSyncItem>> syncReelLikes({
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) return [];

    try {
      final body = {'items': items};
      log('WatchAndBuyRepository: Syncing ${items.length} likes payload: $body');

      final response = await _apiBaseHelper.putAPICall(
        ApiRoutes.watchAndBuyLikesApi,
        body,
      );

      if (response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) =>
                ReelLikeSyncItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      log('WatchAndBuyRepository syncReelLikes error: $e');
      return [];
    }
  }

  // ==========================================
  // STATUS APIS (Status Feed, Profile Statuses, Mark Seen)
  // ==========================================

  /// 1. Fetches Status Feed tray list
  Future<WatchStatusFeedResponse> fetchStatusFeed({
    String? cursor,
    String? sessionId,
    int perPage = 10,
  }) async {
    try {
      final query = <String, dynamic>{
        'per_page': perPage,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      };

      log('WatchAndBuyRepository: Fetching status feed with query $query');

      final response = await _apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyStatusFeedApi,
        query,
      );

      if (response.data is Map<String, dynamic>) {
        return WatchStatusFeedResponse.fromJson(response.data);
      } else {
        throw ApiException('Invalid response format from status feed API');
      }
    } catch (e) {
      log('WatchAndBuyRepository fetchStatusFeed error: $e');
      throw ApiException(e.toString());
    }
  }

  /// 2. Fetches profile active statuses for a specific username
  Future<WatchProfileStatusesResponse> fetchProfileStatuses({
    required String username,
    String? cursor,
    int perPage = 10,
  }) async {
    try {
      final query = <String, dynamic>{
        'per_page': perPage,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      };

      log('WatchAndBuyRepository: Fetching profile statuses for $username with query $query');

      final response = await _apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyProfileStatusesApi(username),
        query,
      );

      if (response.data is Map<String, dynamic>) {
        return WatchProfileStatusesResponse.fromJson(response.data);
      } else {
        throw ApiException('Invalid response format from profile statuses API');
      }
    } catch (e) {
      log('WatchAndBuyRepository fetchProfileStatuses error: $e');
      throw ApiException(e.toString());
    }
  }

  /// 3. Marks a list of status IDs as seen
  Future<List<WatchStatusSeenItem>> markStatusesSeen({
    required List<int> statusIds,
  }) async {
    final bool isLoggedIn =
        Global.userData != null && (Global.token?.isNotEmpty ?? false);
    if (!isLoggedIn) {
      return [];
    }

    if (statusIds.isEmpty) return [];

    try {
      final body = {
        'status_ids': statusIds,
      };

      log('WatchAndBuyRepository: Marking statuses seen: $body');

      final response = await _apiBaseHelper.putAPICall(
        ApiRoutes.watchAndBuyMarkStatusSeenApi,
        body,
      );

      if (response.data is Map<String, dynamic>) {
        final parsed = WatchStatusSeenResponse.fromJson(response.data);
        return parsed.data;
      }
      return [];
    } catch (e) {
      log('WatchAndBuyRepository markStatusesSeen error: $e');
      return [];
    }
  }

  // ==========================================
  // SELLER PROFILE API
  // ==========================================

  /// 4. Fetches seller profile and their published reels
  Future<SellerProfileResponse> fetchSellerProfile({
    required String username,
    int page = 1,
  }) async {
    try {
      final query = <String, dynamic>{
        if (page > 1) 'page': page,
      };

      log('WatchAndBuyRepository: Fetching seller profile for $username with query $query');

      final response = await _apiBaseHelper.getAPICall(
        ApiRoutes.sellerProfileApi(username),
        query,
      );

      if (response.data is Map<String, dynamic>) {
        return SellerProfileResponse.fromJson(response.data);
      } else {
        throw ApiException('Invalid response format from seller profile API');
      }
    } catch (e) {
      log('WatchAndBuyRepository fetchSellerProfile error: $e');
      throw ApiException(e.toString());
    }
  }
}

