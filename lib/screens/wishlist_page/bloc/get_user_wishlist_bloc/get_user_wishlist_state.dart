import 'package:equatable/equatable.dart';

import '../../model/user_wishlist_model.dart';

abstract class UserWishlistState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserWishlistInitial extends UserWishlistState {}

class UserWishlistLoading extends UserWishlistState {}

class UserWishlistLoaded extends UserWishlistState {
  final String message;
  final List<WishlistData> wishlistData;
  final bool hasReachedMax;
  // Bumped on optimistic cache-only changes so the state is never equal to the
  // previous one — otherwise Bloc de-duplicates the emit and the heart icons
  // (which read the cache) never rebuild.
  final int revision;

  UserWishlistLoaded({
    required this.message,
    required this.wishlistData,
    required this.hasReachedMax,
    this.revision = 0,
  });

  UserWishlistLoaded copyWith({
    String? message,
    List<WishlistData>? wishlistData,
    bool? hasReachedMax,
    int? revision,
  }) {
    return UserWishlistLoaded(
      message: message ?? this.message,
      wishlistData: wishlistData ?? this.wishlistData,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      revision: revision ?? this.revision,
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [message, wishlistData, hasReachedMax, revision];
}

/// Explicit empty state — distinct from UserWishlistLoaded with an empty list.
class UserWishlistEmpty extends UserWishlistState {
  final String message;
  UserWishlistEmpty({this.message = ''});

  @override
  List<Object?> get props => [message];
}

class UserWishlistFailed extends UserWishlistState {
  final String message;

  UserWishlistFailed({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
