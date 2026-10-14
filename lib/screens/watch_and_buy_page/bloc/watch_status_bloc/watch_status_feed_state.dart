import 'package:equatable/equatable.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';

abstract class WatchStatusFeedState extends Equatable {
  const WatchStatusFeedState();

  @override
  List<Object?> get props => [];
}

class WatchStatusFeedInitial extends WatchStatusFeedState {}

class WatchStatusFeedLoading extends WatchStatusFeedState {}

class WatchStatusFeedLoaded extends WatchStatusFeedState {
  final List<WatchStatusFeedItem> items;
  final String? nextCursor;
  final String? sessionId;
  final bool hasMore;
  final bool isLoadingMore;

  const WatchStatusFeedLoaded({
    required this.items,
    this.nextCursor,
    this.sessionId,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  WatchStatusFeedLoaded copyWith({
    List<WatchStatusFeedItem>? items,
    String? nextCursor,
    String? sessionId,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return WatchStatusFeedLoaded(
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

class WatchStatusFeedError extends WatchStatusFeedState {
  final String message;
  const WatchStatusFeedError({required this.message});

  @override
  List<Object?> get props => [message];
}
