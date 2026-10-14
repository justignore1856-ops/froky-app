import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';

import '../../../config/helper.dart';
import '../../../services/location/location_service.dart';

class UserWishlistRepository {
  Future<Map<String, dynamic>> getUserWishlist({
    required int currentPage,
    required int perPage,
}) async {
    try{
      final response = await AppHelpers.apiBaseHelper.getAPICall(
          '${ApiRoutes.getWishlistApi}?page=$currentPage&per_page=$perPage',
          {}
      );
      if(response.statusCode == 200){
        return response.data;
      } else {
        return {};
      }
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> createWishlist({
    required String title}) async {
    try{
      final response = await AppHelpers.apiBaseHelper.postAPICall(
        ApiRoutes.createWishlistApi,
        {'title': title},
      );
      if(response.statusCode == 200){
        return response.data;
      } else {
        return {};
      }
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  /// One-tap toggle on the default "Favorite" wishlist.
  /// Adds the item if absent, removes it if present — the backend decides and
  /// returns the resulting state in `data` ({is_favorited, item_id, items_count}).
  /// No client-side item id is needed, which is why this is preferred over the
  /// separate add/remove calls for the heart shortcut.
  Future<Map<String, dynamic>> toggleFavoriteWishlist({
    required int productId,
    required int productVariantId,
    required int storeId,
  }) async {
    try{
      final response = await AppHelpers.apiBaseHelper.postAPICall(
        ApiRoutes.toggleFavoriteWishlistApi,
        {
          'product_id': productId,
          'product_variant_id': productVariantId,
          'store_id': storeId,
        },
      );
      if(response.statusCode == 200){
        return response.data;
      } else {
        return {};
      }
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateWishlist({
    required String title, required int wishlistId}) async {
    try{
      final response = await AppHelpers.apiBaseHelper.putAPICall(
        ApiRoutes.updateWishlistApi+wishlistId.toString(),
        {'title': title},
      );
      if(response.statusCode == 200){
        return response.data;
      } else {
        return {};
      }
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteWishlist({
    required int wishlistId}) async {
    try{
      final response = await AppHelpers.apiBaseHelper.deleteAPICall(
        ApiRoutes.deleteWishlistApi+wishlistId.toString(),
        {},
      );
      if(response.statusCode == 200){
        return response.data;
      } else {
        return {};
      }
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> moveItemToAnotherWishlist({
    required int itemId,
    required int wishlistId,
  }) async {
    try{
      final response = await AppHelpers.apiBaseHelper.putAPICall(
        '${ApiRoutes.moveItemToAnotherWishlistApi}$itemId/move',
        {'target_wishlist_id': wishlistId},
      );
      if(response.statusCode == 200){
        return response.data;
      } else {
        return {};
      }
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  /// Fetches the default "Favorite" wishlist (items + count) in one call.
  /// The backend creates it on demand, so the response is never empty by
  /// absence — only by having no items yet.
  Future<Map<String, dynamic>> getFavoriteWishlist({
    required int currentPage,
    required int perPage,
  }) async {
    try {
      final location = LocationService.getStoredLocation();
      var url =
          '${ApiRoutes.favoriteWishlistApi}?page=$currentPage&per_page=$perPage';
      if (location != null) {
        url += '&latitude=${location.latitude}&longitude=${location.longitude}';
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(url, {});
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchWishlistProduct({
    required int wishlistId,
    required int currentPage,
    required int perPage,
  }) async {
    try{
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService!.latitude;
      final longitude = locationService.longitude;

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        '${ApiRoutes.wishlistProductApi}$wishlistId?page=$currentPage&per_page=$perPage&latitude=$latitude&longitude=$longitude',
        {}
      );

      if(response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    }catch(e) {
      throw ApiException(e.toString());
    }
  }
}