import 'package:equatable/equatable.dart';

abstract class WatchAndBuyFeedEvent extends Equatable {
  const WatchAndBuyFeedEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch initial discovery feed or pull-to-refresh
class FetchWatchAndBuyFeed extends WatchAndBuyFeedEvent {
  final bool isRefresh;
  const FetchWatchAndBuyFeed({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Fetch next page of discovery feed using next_cursor
class FetchMoreWatchAndBuyFeed extends WatchAndBuyFeedEvent {
  const FetchMoreWatchAndBuyFeed();
}

/// Real-time sync event: updates like status and count of a reel in feed state
class UpdateFeedReelLike extends WatchAndBuyFeedEvent {
  final int reelId;
  final bool isLiked;
  final int likeCount;

  const UpdateFeedReelLike({
    required this.reelId,
    required this.isLiked,
    required this.likeCount,
  });

  @override
  List<Object?> get props => [reelId, isLiked, likeCount];
}
