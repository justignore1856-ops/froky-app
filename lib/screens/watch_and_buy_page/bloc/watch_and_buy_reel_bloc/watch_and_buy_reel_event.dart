import 'package:equatable/equatable.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';

abstract class WatchAndBuyReelEvent extends Equatable {
  const WatchAndBuyReelEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch player playlist starting with specific reel [slug] at index 0
class FetchPlayerReels extends WatchAndBuyReelEvent {
  final String slug;
  final WatchAndBuyItem? initialItem;

  const FetchPlayerReels({
    required this.slug,
    this.initialItem,
  });

  @override
  List<Object?> get props => [slug, initialItem];
}

/// Fetch next page of reels inside the vertical player using next_cursor
class FetchMorePlayerReels extends WatchAndBuyReelEvent {
  const FetchMorePlayerReels();
}

/// Toggle like on a reel (optimistic UI update + queues for batch sync)
/// If [forceLike] is true, only sets like to true if not already liked (never unlikes).
class TogglePlayerReelLike extends WatchAndBuyReelEvent {
  final int reelId;
  final bool? forceLike;

  const TogglePlayerReelLike({
    required this.reelId,
    this.forceLike,
  });

  @override
  List<Object?> get props => [reelId, forceLike];
}

/// Internal/timer event: Dispatches accumulated batch likes after 5s debounce window
class SyncPendingReelLikes extends WatchAndBuyReelEvent {
  const SyncPendingReelLikes();
}

/// Immediate flush event: Syncs pending likes immediately (e.g. on page exit/dispose)
class FlushPendingReelLikes extends WatchAndBuyReelEvent {
  const FlushPendingReelLikes();
}
