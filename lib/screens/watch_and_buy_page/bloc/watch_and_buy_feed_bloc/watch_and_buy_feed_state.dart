import 'package:equatable/equatable.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';

abstract class WatchAndBuyFeedState extends Equatable {
  const WatchAndBuyFeedState();

  @override
  List<Object?> get props => [];
}

class WatchAndBuyFeedInitial extends WatchAndBuyFeedState {}

class WatchAndBuyFeedLoading extends WatchAndBuyFeedState {}

class WatchAndBuyFeedLoaded extends WatchAndBuyFeedState {
  final List<WatchAndBuyItem> items;
  final String? nextCursor;
  final String? sessionId;
  final bool hasMore;
  final bool isLoadingMore;

  const WatchAndBuyFeedLoaded({
    required this.items,
    this.nextCursor,
    this.sessionId,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  WatchAndBuyFeedLoaded copyWith({
    List<WatchAndBuyItem>? items,
    String? nextCursor,
    String? sessionId,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return WatchAndBuyFeedLoaded(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      sessionId: sessionId ?? this.sessionId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        items,
        nextCursor,
        sessionId,
        hasMore,
        isLoadingMore,
      ];
}

class WatchAndBuyFeedError extends WatchAndBuyFeedState {
  final String message;
  const WatchAndBuyFeedError({required this.message});

  @override
  List<Object?> get props => [message];
}
