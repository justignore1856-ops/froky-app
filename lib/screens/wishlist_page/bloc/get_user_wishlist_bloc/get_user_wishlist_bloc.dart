
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/wishlist_page/model/user_wishlist_model.dart';
import 'package:hyper_commerce/screens/wishlist_page/repo/wishlist_repo.dart';
import 'get_user_wishlist_state.dart';
part 'get_user_wishlist_event.dart';

class UserWishlistBloc extends Bloc<UserWishlistEvent, UserWishlistState> {
  UserWishlistBloc() : super(UserWishlistInitial()) {
    on<GetUserWishlistRequest>(_onGetUserWishlistRequest);
    on<GetMoreUserWishlistRequest>(_onGetMoreUserWishlistRequest);
    on<CreateNewWishlist>(_onCreateNewWishlist);
    on<UpdateUserWishlist>(_onUpdateUserWishlist);
    on<DeleteWishlist>(_onDeleteWishlist);
    on<MoveItemToAnotherWishlist>(_onMoveItemToAnotherWishlist);
    on<ToggleFavorite>(_onToggleFavorite);

  }

  final UserWishlistRepository repository = UserWishlistRepository();
  int currentPage = 0;
  int perPage = 48;
  int? lastPage;
  bool hasReachedMax = false;
  bool isLoadingMore = false;
  bool loadMore = false;
  
  // Local cache for the heart state: Map<productId_productVariantId_storeId, wishlistItemId>.
  // A null value means "known not favorited"; absence means "unknown".
  final Map<String, int?> _localWishlistCache = {};

  // Helper method to generate cache key
  String _getCacheKey(int productId, int productVariantId, int storeId) {
    return '${productId}_${productVariantId}_$storeId';
  }
  
  // Public method to check if product is wishlisted (checks both server state and local cache)
  bool isProductWishlisted(int productId, int productVariantId, int storeId) {
    final cacheKey = _getCacheKey(productId, productVariantId, storeId);
    if (_localWishlistCache.containsKey(cacheKey)) {
      return _localWishlistCache[cacheKey] != null;
    }
    // If not in cache, check server state
    if (state is UserWishlistLoaded) {
      final loadedState = state as UserWishlistLoaded;
      for (final wishlist in loadedState.wishlistData) {
        for (final item in wishlist.items) {
          if (item.product?.id == productId &&
              item.variant?.id == productVariantId &&
              item.store?.id == storeId) {
            // Update cache with server state
            _localWishlistCache[cacheKey] = item.id;
            return true;
          }
        }
            }
    }
    return false;
  }
  
  // Whether the bloc knows the wishlist status of THIS specific product —
  // either because it was toggled this session (cache) or because it appears in
  // a loaded wishlist. Must NOT return true just because some state is loaded,
  // otherwise it overrides the card's own `isWishListed` flag (sourced from the
  // product API's `favorite`) for products the bloc has never seen.
  bool hasProductData(int productId, int productVariantId, int storeId) {
    final cacheKey = _getCacheKey(productId, productVariantId, storeId);
    // If in cache, we have data (even if value is null, it means we know it's not wishlisted)
    if (_localWishlistCache.containsKey(cacheKey)) {
      return true;
    }
    if (state is UserWishlistLoaded) {
      final loadedState = state as UserWishlistLoaded;
      for (final wishlist in loadedState.wishlistData) {
        for (final item in wishlist.items) {
          if (item.product?.id == productId &&
              item.variant?.id == productVariantId &&
              item.store?.id == storeId) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _onGetUserWishlistRequest(GetUserWishlistRequest event, Emitter<UserWishlistState> emit) async {
    emit(UserWishlistLoading());
    try{
      List<WishlistData> wishlistData = [];
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;
      final response = await repository.getUserWishlist(perPage: perPage, currentPage: currentPage);
      wishlistData = List<WishlistData>.from(response['data']['data'].map((data) => WishlistData.fromJson(data)));

      final currentTotal = int.parse(response['data']['current_page'].toString());
      final lastPageNum = int.parse(response['data']['last_page'].toString());
      hasReachedMax = currentTotal >= lastPageNum || wishlistData.length < perPage;
      if(response['success'] == true){
        _updateLocalCacheFromWishlistData(wishlistData);
        if (wishlistData.isEmpty) {
          emit(UserWishlistEmpty(message: response['message']?.toString() ?? ''));
        } else {
          emit(UserWishlistLoaded(
              message: response['message'],
              wishlistData: wishlistData,
              hasReachedMax: hasReachedMax
          ));
        }
      } else if (response['error'] == true){
        emit(UserWishlistFailed(message: response['message']));
      }
    }catch(e) {
      emit(UserWishlistFailed(message: e.toString()));
    }
  }
  
  // Helper method to update local cache from wishlist data
  void _updateLocalCacheFromWishlistData(List<WishlistData> wishlistData) {
    for (final wishlist in wishlistData) {
      for (final item in wishlist.items) {
        if (item.product?.id != null && item.variant?.id != null && item.store?.id != null) {
          final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
          _localWishlistCache[cacheKey] = item.id;
        }
      }
        }
  }

  Future<void> _onGetMoreUserWishlistRequest(GetMoreUserWishlistRequest event, Emitter<UserWishlistState> emit) async {
    if (hasReachedMax || isLoadingMore) return;
    final currentState = state;
    if(currentState is UserWishlistLoaded) {
      isLoadingMore = true;
      try{
        List<WishlistData> newWishlistData = [];
        currentPage += 1;

        final response = await repository.getUserWishlist(perPage: perPage, currentPage: currentPage);
        newWishlistData = List<WishlistData>.from(response['data']['data'].map((data) => WishlistData.fromJson(data)));

        final currentTotal = int.parse(response['data']['current_page'].toString());
        final lastPageNum = int.parse(response['data']['last_page'].toString());
        hasReachedMax = currentTotal >= lastPageNum || newWishlistData.length < perPage;
        final updatedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        for (final newWishlist in newWishlistData) {
          if (!updatedWishlistData.any((existing) => existing.id == newWishlist.id)) {
            updatedWishlistData.add(newWishlist);
          }
        }
        // Update local cache with new wishlist data
        _updateLocalCacheFromWishlistData(newWishlistData);
        emit(UserWishlistLoaded(
            message: response['message'],
            wishlistData: updatedWishlistData,
            hasReachedMax: hasReachedMax
        ));

      } catch(e) {
        currentPage -= 1;
        emit(UserWishlistFailed(message: e.toString()));
      } finally {
        isLoadingMore = false;
      }
    }

  }

  Future<void> _onCreateNewWishlist(CreateNewWishlist event, Emitter<UserWishlistState> emit) async {
    emit(UserWishlistLoading());
    try{

      final response = await repository.createWishlist(title: event.title);

      if(response['success'] == true){
        add(GetUserWishlistRequest());
      } else if (response['success'] == false){
        emit(UserWishlistFailed(message: response['message']));
      }
    }catch(e) {
      emit(UserWishlistFailed(message: e.toString()));
    }
  }

Future<void> _onUpdateUserWishlist(UpdateUserWishlist event, Emitter<UserWishlistState> emit) async {
    // Store original wishlist to revert if API fails
    WishlistData? originalWishlist;
    
    // Optimistically update the wishlist in state without showing loading
    if (state is UserWishlistLoaded) {
      final currentState = state as UserWishlistLoaded;
      originalWishlist = currentState.wishlistData.firstWhere(
        (wishlist) => wishlist.id == event.wishlistId,
        orElse: () => WishlistData(),
      );
      
      final updatedWishlistData = currentState.wishlistData.map((wishlist) {
        if (wishlist.id == event.wishlistId) {
          // Create updated wishlist with new title
          return WishlistData(
            id: wishlist.id,
            title: event.title,
            slug: wishlist.slug,
            itemsCount: wishlist.itemsCount,
            items: wishlist.items,
            createdAt: wishlist.createdAt,
            updatedAt: wishlist.updatedAt,
          );
        }
        return wishlist;
      }).toList();
      
      // Emit updated state immediately
      emit(UserWishlistLoaded(
        message: currentState.message,
        wishlistData: updatedWishlistData,
        hasReachedMax: currentState.hasReachedMax,
      ));
    }
    
    // Call API in background
    try{
      final response = await repository.updateWishlist(title: event.title, wishlistId: event.wishlistId);

      if(response['success'] == true){
        // API succeeded - state already updated optimistically, no need to refresh
      } else if (response['error'] == true){
        // Revert optimistic update on error
        if (state is UserWishlistLoaded && originalWishlist != null && originalWishlist.id != null) {
          final currentState = state as UserWishlistLoaded;
          final revertedWishlistData = currentState.wishlistData.map((wishlist) {
            if (wishlist.id == originalWishlist!.id) {
              return originalWishlist;
            }
            return wishlist;
          }).toList();
          
          emit(UserWishlistLoaded(
            message: response['message'] ?? 'Update failed',
            wishlistData: revertedWishlistData,
            hasReachedMax: currentState.hasReachedMax,
          ));
        } else {
          // If we can't revert, just refresh silently
          add(GetUserWishlistRequest());
        }
      }
    }catch(e) {
      // Revert optimistic update on error
      if (state is UserWishlistLoaded && originalWishlist != null && originalWishlist.id != null) {
        final currentState = state as UserWishlistLoaded;
        final revertedWishlistData = currentState.wishlistData.map((wishlist) {
          if (wishlist.id == originalWishlist!.id) {
            return originalWishlist;
          }
          return wishlist;
        }).toList();
        
        emit(UserWishlistLoaded(
          message: e.toString(),
          wishlistData: revertedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
        ));
      } else {
        // If we can't revert, just refresh silently
        add(GetUserWishlistRequest());
      }
    }
  }

  Future<void> _onDeleteWishlist(DeleteWishlist event, Emitter<UserWishlistState> emit) async {
    // Store the deleted wishlist to revert if API fails
    WishlistData? deletedWishlist;
    
    // Optimistically remove the wishlist from state without showing loading
    if (state is UserWishlistLoaded) {
      final currentState = state as UserWishlistLoaded;
      deletedWishlist = currentState.wishlistData.firstWhere(
        (wishlist) => wishlist.id == event.wishlistId,
        orElse: () => WishlistData(),
      );
      
      final updatedWishlistData = currentState.wishlistData
          .where((wishlist) => wishlist.id != event.wishlistId)
          .toList();
      
      // Also remove items from local cache if this wishlist had any
      for (final item in deletedWishlist.items) {
        if (item.product?.id != null && item.variant?.id != null && item.store?.id != null) {
          final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
          _localWishlistCache.remove(cacheKey);
        }
      }

      // Emit updated state immediately
      emit(UserWishlistLoaded(
        message: currentState.message,
        wishlistData: updatedWishlistData,
        hasReachedMax: currentState.hasReachedMax,
      ));
    }
    
    // Call API in background
    try{
      final response = await repository.deleteWishlist(wishlistId: event.wishlistId);

      if(response['success'] == true){
        // API succeeded - state already updated optimistically, no need to refresh
      } else if (response['error'] == true){
        // Revert optimistic update on error
        if (state is UserWishlistLoaded && deletedWishlist != null && deletedWishlist.id != null) {
          final currentState = state as UserWishlistLoaded;
          final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
          revertedWishlistData.add(deletedWishlist);
          
          // Restore cache entries
          for (final item in deletedWishlist.items) {
            if (item.product?.id != null && item.variant?.id != null && item.store?.id != null && item.id != null) {
              final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
              _localWishlistCache[cacheKey] = item.id;
            }
          }

          emit(UserWishlistLoaded(
            message: response['message'] ?? 'Delete failed',
            wishlistData: revertedWishlistData,
            hasReachedMax: currentState.hasReachedMax,
          ));
        } else {
          // If we can't revert, just refresh
          add(GetUserWishlistRequest());
        }
      }
    }catch(e) {
      // Revert optimistic update on error
      if (state is UserWishlistLoaded && deletedWishlist != null && deletedWishlist.id != null) {
        final currentState = state as UserWishlistLoaded;
        final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        revertedWishlistData.add(deletedWishlist);
        
        // Restore cache entries
        for (final item in deletedWishlist.items) {
          if (item.product?.id != null && item.variant?.id != null && item.store?.id != null && item.id != null) {
            final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
            _localWishlistCache[cacheKey] = item.id;
          }
        }

        emit(UserWishlistLoaded(
          message: e.toString(),
          wishlistData: revertedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
        ));
      } else {
        // If we can't revert, just refresh
        add(GetUserWishlistRequest());
      }
    }
  }

  /// One-tap heart toggle via the `/user/wishlists/toggle` endpoint.
  ///
  /// Flips the icon immediately from the UI's known state, then trusts the
  /// API's `is_favorited` / `item_id` to settle the cache. Because the endpoint
  /// itself decides add-vs-remove, we never need a client-held item id — this
  /// is what makes the heart reliable even when the full wishlist was never
  /// loaded (e.g. the user only ever taps hearts).
  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<UserWishlistState> emit) async {
    final cacheKey =
        _getCacheKey(event.productId, event.productVariantId, event.storeId);

    // Capture prior cache state so we can revert cleanly on failure.
    final bool hadCacheKey = _localWishlistCache.containsKey(cacheKey);
    final int? originalCacheValue =
        hadCacheKey ? _localWishlistCache[cacheKey] : null;

    // Optimistic flip: -1 is the "favorited, id pending" sentinel.
    _localWishlistCache[cacheKey] = event.currentlyFavorited ? null : -1;
    _emitWithBumpedRevision(emit);

    try {
      final response = await repository.toggleFavoriteWishlist(
        productId: event.productId,
        productVariantId: event.productVariantId,
        storeId: event.storeId,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final bool isFavorited =
            data is Map && data['is_favorited'] == true;
        final int? itemId =
            data is Map && data['item_id'] is int ? data['item_id'] as int : null;

        // Settle the cache from the authoritative server result.
        _localWishlistCache[cacheKey] = isFavorited ? itemId : null;

        // Keep a loaded "Favorite" list consistent if it is in memory: drop the
        // row on un-favorite so the wishlist screen doesn't show a stale item.
        if (!isFavorited && state is UserWishlistLoaded) {
          _removeItemFromLoadedFavorite(
              event.productId, event.productVariantId, event.storeId, emit);
        } else {
          _emitWithBumpedRevision(emit);
        }
      } else {
        _revertToggle(cacheKey, hadCacheKey, originalCacheValue, emit);
      }
    } catch (e) {
      _revertToggle(cacheKey, hadCacheKey, originalCacheValue, emit);
    }
  }

  // Restore the cache entry to its pre-toggle value and rebuild the icons.
  void _revertToggle(String cacheKey, bool hadCacheKey, int? originalCacheValue,
      Emitter<UserWishlistState> emit) {
    if (hadCacheKey) {
      _localWishlistCache[cacheKey] = originalCacheValue;
    } else {
      _localWishlistCache.remove(cacheKey);
    }
    _emitWithBumpedRevision(emit);
  }

  // Remove a product row from the loaded "Favorite" wishlist (count + items)
  // so an open wishlist screen reflects an un-favorite immediately.
  void _removeItemFromLoadedFavorite(int productId, int productVariantId,
      int storeId, Emitter<UserWishlistState> emit) {
    if (state is! UserWishlistLoaded) return;
    final currentState = state as UserWishlistLoaded;
    final updatedWishlistData = List<WishlistData>.from(currentState.wishlistData);

    for (int i = 0; i < updatedWishlistData.length; i++) {
      final wishlist = updatedWishlistData[i];
      final hasItem = wishlist.items.any((item) =>
          item.product?.id == productId &&
          item.variant?.id == productVariantId &&
          item.store?.id == storeId);
      if (!hasItem) continue;

      final updatedItems = List<WishlistItem>.from(wishlist.items)
        ..removeWhere((item) =>
            item.product?.id == productId &&
            item.variant?.id == productVariantId &&
            item.store?.id == storeId);
      updatedWishlistData[i] = wishlist.copyWith(
        items: updatedItems,
        itemsCount: (wishlist.itemsCount ?? 1) > 0
            ? (wishlist.itemsCount ?? 1) - 1
            : 0,
      );
    }

    emit(UserWishlistLoaded(
      message: currentState.message,
      wishlistData: updatedWishlistData,
      hasReachedMax: currentState.hasReachedMax,
      revision: currentState.revision + 1,
    ));
  }

  // Emit a fresh state (bumped revision) so BlocBuilder rebuilds the hearts
  // even when only the cache changed.
  void _emitWithBumpedRevision(Emitter<UserWishlistState> emit) {
    if (state is UserWishlistLoaded) {
      final s = state as UserWishlistLoaded;
      emit(s.copyWith(revision: s.revision + 1));
    } else {
      emit(UserWishlistLoaded(
        message: '',
        wishlistData: const [],
        hasReachedMax: true,
        revision: 1,
      ));
    }
  }

  Future<void> _onMoveItemToAnotherWishlist(MoveItemToAnotherWishlist event, Emitter<UserWishlistState> emit) async {
    emit(UserWishlistLoading());
    try{
      final response = await repository.moveItemToAnotherWishlist(itemId: event.itemId, wishlistId: event.wishlistId);

      if(response['success'] == true){
        add(GetUserWishlistRequest());
      } else if (response['error'] == true){
        emit(UserWishlistFailed(message: response['message']));
      }
    }catch(e) {
      emit(UserWishlistFailed(message: e.toString()));
    }
  }
}