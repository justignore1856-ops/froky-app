import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_and_buy_reel_bloc/watch_and_buy_reel_event.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_and_buy_reel_bloc/watch_and_buy_reel_state.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/repo/watch_and_buy_repo.dart';

export 'watch_and_buy_reel_event.dart';
export 'watch_and_buy_reel_state.dart';

typedef ReelLikeCallback = void Function(
    int reelId, bool isLiked, int likeCount);

class WatchAndBuyReelBloc
    extends Bloc<WatchAndBuyReelEvent, WatchAndBuyReelState> {
  final WatchAndBuyRepository _repository;
  final ReelLikeCallback? onLikeChanged;

  /// Accumulates pending like mutations: { reel_id : liked_status }
  final Map<int, bool> _pendingLikeBatch = {};
  Timer? _debounceTimer;

  WatchAndBuyReelBloc({
    WatchAndBuyRepository? repository,
    this.onLikeChanged,
  })  : _repository = repository ?? WatchAndBuyRepository(),
        super(WatchAndBuyReelInitial()) {
    on<FetchPlayerReels>(_onFetchPlayerReels);
    on<FetchMorePlayerReels>(_onFetchMorePlayerReels);
    on<TogglePlayerReelLike>(_onToggleLike);
    on<SyncPendingReelLikes>(_onSyncPendingLikes);
    on<FlushPendingReelLikes>(_onFlushPendingLikes);
  }

  Future<void> _onFetchPlayerReels(
    FetchPlayerReels event,
    Emitter<WatchAndBuyReelState> emit,
  ) async {
    final initialItem = event.initialItem;

    if (initialItem != null) {
      final likedIds = <int>{};
      final likeCounts = <int, int>{};
      if (initialItem.likedByMe) {
        likedIds.add(initialItem.id);
      }
      likeCounts[initialItem.id] = initialItem.likeCount;

      // Instantly emit loaded state with the hero item to start playback at 0ms
      emit(
        WatchAndBuyReelLoaded(
          items: [initialItem],
          hasMore: true,
          isLoadingMore: false,
          likedIds: likedIds,
          likeCounts: likeCounts,
        ),
      );
    } else {
      emit(WatchAndBuyReelLoading());
    }

    try {
      final response = await _repository.fetchReels(
        slug: event.slug.isNotEmpty ? event.slug : null,
        perPage: 10,
      );

      final items = response.items.map((item) {
        if (_pendingLikeBatch.containsKey(item.id)) {
          final isLiked = _pendingLikeBatch[item.id]!;
          final delta =
              (isLiked ? 1 : -1) * (item.likedByMe == isLiked ? 0 : 1);
          final adjustedCount = (item.likeCount + delta).clamp(0, 9999999);
          return item.copyWith(
            likedByMe: isLiked,
            likeCount: adjustedCount,
          );
        }
        return item;
      }).toList();

      final likedIds = <int>{};
      final likeCounts = <int, int>{};

      for (var item in items) {
        if (item.likedByMe) {
          likedIds.add(item.id);
        }
        likeCounts[item.id] = item.likeCount;
      }

      emit(
        WatchAndBuyReelLoaded(
          items: items.isNotEmpty
              ? items
              : (initialItem != null ? [initialItem] : []),
          nextCursor: response.meta?.nextCursor,
          sessionId: response.meta?.sessionId,
          hasMore: response.meta?.nextCursor != null &&
              response.meta!.nextCursor!.isNotEmpty,
          isLoadingMore: false,
          likedIds: likedIds,
          likeCounts: likeCounts,
        ),
      );
    } catch (e) {
      if (initialItem == null) {
        emit(WatchAndBuyReelError(message: e.toString()));
      }
    }
  }

  Future<void> _onFetchMorePlayerReels(
    FetchMorePlayerReels event,
    Emitter<WatchAndBuyReelState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WatchAndBuyReelLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _repository.fetchReels(
        cursor: currentState.nextCursor,
        sessionId: currentState.sessionId,
        perPage: 10,
      );

      final newItems = response.items.map((item) {
        if (_pendingLikeBatch.containsKey(item.id)) {
          final isLiked = _pendingLikeBatch[item.id]!;
          final delta =
              (isLiked ? 1 : -1) * (item.likedByMe == isLiked ? 0 : 1);
          final adjustedCount = (item.likeCount + delta).clamp(0, 9999999);
          return item.copyWith(
            likedByMe: isLiked,
            likeCount: adjustedCount,
          );
        }
        return item;
      }).toList();

      final updatedItems = List<WatchAndBuyItem>.from(currentState.items)
        ..addAll(newItems);

      final updatedLikedIds = Set<int>.from(currentState.likedIds);
      final updatedLikeCounts = Map<int, int>.from(currentState.likeCounts);

      for (var item in newItems) {
        if (item.likedByMe) {
          updatedLikedIds.add(item.id);
        }
        updatedLikeCounts[item.id] = item.likeCount;
      }

      emit(
        currentState.copyWith(
          items: updatedItems,
          nextCursor: response.meta?.nextCursor,
          sessionId: response.meta?.sessionId ?? currentState.sessionId,
          hasMore: response.meta?.nextCursor != null &&
              response.meta!.nextCursor!.isNotEmpty,
          isLoadingMore: false,
          likedIds: updatedLikedIds,
          likeCounts: updatedLikeCounts,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onToggleLike(
    TogglePlayerReelLike event,
    Emitter<WatchAndBuyReelState> emit,
  ) {
    if (state is! WatchAndBuyReelLoaded) return;
    final currentState = state as WatchAndBuyReelLoaded;

    final updatedLikedIds = Set<int>.from(currentState.likedIds);
    final updatedLikeCounts = Map<int, int>.from(currentState.likeCounts);
    final wasLiked = updatedLikedIds.contains(event.reelId);

    // If forceLike is true and already liked, do not toggle/unlike on double tap
    if (event.forceLike == true && wasLiked) {
      return;
    }

    final willBeLiked = !wasLiked;
    final currentCount = updatedLikeCounts[event.reelId] ?? 0;

    if (wasLiked) {
      updatedLikedIds.remove(event.reelId);
      updatedLikeCounts[event.reelId] = (currentCount - 1).clamp(0, 9999999);
    } else {
      updatedLikedIds.add(event.reelId);
      updatedLikeCounts[event.reelId] = currentCount + 1;
    }

    final newCount = updatedLikeCounts[event.reelId]!;

    final updatedItems = currentState.items.map((item) {
      if (item.id == event.reelId) {
        return item.copyWith(
          likedByMe: willBeLiked,
          likeCount: newCount,
        );
      }
      return item;
    }).toList();

    // 1. Optimistic UI update at 0ms
    emit(
      currentState.copyWith(
        items: updatedItems,
        likedIds: updatedLikedIds,
        likeCounts: updatedLikeCounts,
      ),
    );

    // 2. Notify feed and caller of like mutation
    onLikeChanged?.call(event.reelId, willBeLiked, newCount);

    // 3. Queue into batch map
    _pendingLikeBatch[event.reelId] = willBeLiked;

    // 4. Reset 5-second debounce timer window
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      if (!isClosed) {
        add(const SyncPendingReelLikes());
      }
    });
  }

  Future<void> _onSyncPendingLikes(
    SyncPendingReelLikes event,
    Emitter<WatchAndBuyReelState> emit,
  ) async {
    await _performBatchSync();
  }

  Future<void> _onFlushPendingLikes(
    FlushPendingReelLikes event,
    Emitter<WatchAndBuyReelState> emit,
  ) async {
    _debounceTimer?.cancel();
    await _performBatchSync();
  }

  Future<void> _performBatchSync() async {
    // If pending list is empty, DO NOT call the API
    if (_pendingLikeBatch.isEmpty) return;

    final itemsToSync = _pendingLikeBatch.entries
        .map((e) => {
              'reel_id': e.key,
              'liked': e.value,
            })
        .toList();

    _pendingLikeBatch.clear();

    log('WatchAndBuyReelBloc: 5s debounce window expired. Calling PUT API with ${itemsToSync.length} items: $itemsToSync');
    final syncResults = await _repository.syncReelLikes(items: itemsToSync);
    if (syncResults.isNotEmpty) {
      for (final result in syncResults) {
        onLikeChanged?.call(result.reelId, result.likedByMe, result.likeCount);
      }
    }
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    if (_pendingLikeBatch.isNotEmpty) {
      final itemsToSync = _pendingLikeBatch.entries
          .map((e) => {
                'reel_id': e.key,
                'liked': e.value,
              })
          .toList();
      _pendingLikeBatch.clear();
      _repository.syncReelLikes(items: itemsToSync);
    }
    return super.close();
  }
}
