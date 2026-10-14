part of 'wishlist_product_bloc.dart';

abstract class WishlistProductEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchWishlistProductData extends WishlistProductEvent {
  final int wishlistId;
  FetchWishlistProductData({required this.wishlistId});

  @override
  // TODO: implement props
  List<Object?> get props => [wishlistId];
}

/// Loads the default "Favorite" wishlist directly (items + count), without
/// needing to resolve a wishlist id first.
class FetchFavoriteWishlist extends WishlistProductEvent {}


class RemoveProductLocally extends WishlistProductEvent {
  final int itemId;
  RemoveProductLocally({required this.itemId});

  @override
  // TODO: implement props
  List<Object?> get props => [itemId];
}