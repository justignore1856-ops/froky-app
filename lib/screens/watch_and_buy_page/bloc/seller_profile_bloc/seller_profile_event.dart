import 'package:equatable/equatable.dart';

abstract class SellerProfileEvent extends Equatable {
  const SellerProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchSellerProfile extends SellerProfileEvent {
  final String username;
  final bool isRefresh;

  const FetchSellerProfile({
    required this.username,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [username, isRefresh];
}

class FetchMoreSellerProfileReels extends SellerProfileEvent {
  final String username;

  const FetchMoreSellerProfileReels({
    required this.username,
  });

  @override
  List<Object?> get props => [username];
}

class UpdateSellerProfileReelLike extends SellerProfileEvent {
  final int reelId;
  final bool isLiked;
  final int likeCount;

  const UpdateSellerProfileReelLike({
    required this.reelId,
    required this.isLiked,
    required this.likeCount,
  });

  @override
  List<Object?> get props => [reelId, isLiked, likeCount];
}
