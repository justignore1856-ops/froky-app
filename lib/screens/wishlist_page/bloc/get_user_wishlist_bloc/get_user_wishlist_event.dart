part of 'get_user_wishlist_bloc.dart';

abstract class UserWishlistEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class GetUserWishlistRequest extends UserWishlistEvent {}

class GetMoreUserWishlistRequest extends UserWishlistEvent {}

class CreateNewWishlist extends UserWishlistEvent {
  final String title;
  CreateNewWishlist({required this.title});
  @override
  // TODO: implement props
  List<Object?> get props => [title];
}

class UpdateUserWishlist extends UserWishlistEvent {
  final String title;
  final int wishlistId;
  UpdateUserWishlist({required this.title, required this.wishlistId});
  @override
  // TODO: implement props
  List<Object?> get props => [title, wishlistId];
}

class DeleteWishlist extends UserWishlistEvent {
  final int wishlistId;
  DeleteWishlist({required this.wishlistId});
  @override
  // TODO: implement props
  List<Object?> get props => [wishlistId];
}

class MoveItemToAnotherWishlist extends UserWishlistEvent {
  final int itemId;
  final int wishlistId;
  MoveItemToAnotherWishlist({
    required this.itemId,
    required this.wishlistId,
  });
  @override
  // TODO: implement props
  List<Object?> get props => [itemId, wishlistId];
}

class ToggleFavorite extends UserWishlistEvent {
  final int productId;
  final int productVariantId;
  final int storeId;
  final bool currentlyFavorited;

  ToggleFavorite({
    required this.productId,
    required this.productVariantId,
    required this.storeId,
    required this.currentlyFavorited,
  });
  @override
  List<Object?> get props =>
      [productId, productVariantId, storeId, currentlyFavorited];
}

