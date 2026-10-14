import 'package:equatable/equatable.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';

abstract class WatchAndBuyReelState extends Equatable {
  const WatchAndBuyReelState();

  @override
  List<Object?> get props => [];
}

class WatchAndBuyReelInitial extends WatchAndBuyReelState {}

class WatchAndBuyReelLoading extends WatchAndBuyReelState {}

class WatchAndBuyReelLoaded extends WatchAndBuyReelState {
  final List<WatchAndBuyItem> items;
  final String? nextCursor;
  final String? sessionId;
  final bool hasMore;
  final bool isLoadingMore;
  final Set<int> likedIds;
  final Map<int, int> likeCounts;

  const WatchAndBuyReelLoaded({
    required this.items,
    this.nextCursor,
    this.sessionId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.likedIds = const {},
    this.likeCounts = const {},
  });

  WatchAndBuyReelLoaded copyWith({
    List<WatchAndBuyItem>? items,
    String? nextCursor,
    String? sessionId,
    bool? hasMore,
    bool? isLoadingMore,
    Set<int>? likedIds,
    Map<int, int>? likeCounts,
  }) {
    return WatchAndBuyReelLoaded(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      sessionId: sessionId ?? this.sessionId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      likedIds: likedIds ?? this.likedIds,
      likeCounts: likeCounts ?? this.likeCounts,
    );
  }

  @override
  List<Object?> get props => [
        items,
        nextCursor,
        sessionId,
        hasMore,
        isLoadingMore,
        likedIds,
        likeCounts,
      ];
}

class WatchAndBuyReelError extends WatchAndBuyReelState {
  final String message;
  const WatchAndBuyReelError({required this.message});

  @override
  List<Object?> get props => [message];
}
