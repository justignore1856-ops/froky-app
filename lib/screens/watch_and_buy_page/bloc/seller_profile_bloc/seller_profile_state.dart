import 'package:equatable/equatable.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/seller_profile_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';

abstract class SellerProfileState extends Equatable {
  const SellerProfileState();

  @override
  List<Object?> get props => [];
}

class SellerProfileInitial extends SellerProfileState {}

class SellerProfileLoading extends SellerProfileState {}

class SellerProfileLoaded extends SellerProfileState {
  final WatchProfile profile;
  final List<WatchAndBuyItem> reels;
  final SellerProfilePagination pagination;
  final bool isLoadingMore;

  const SellerProfileLoaded({
    required this.profile,
    required this.reels,
    required this.pagination,
    this.isLoadingMore = false,
  });

  SellerProfileLoaded copyWith({
    WatchProfile? profile,
    List<WatchAndBuyItem>? reels,
    SellerProfilePagination? pagination,
    bool? isLoadingMore,
  }) {
    return SellerProfileLoaded(
      profile: profile ?? this.profile,
      reels: reels ?? this.reels,
      pagination: pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [profile, reels, pagination, isLoadingMore];
}

class SellerProfileError extends SellerProfileState {
  final String message;

  const SellerProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
