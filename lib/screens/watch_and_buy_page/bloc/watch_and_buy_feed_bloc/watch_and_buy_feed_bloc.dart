import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_and_buy_feed_bloc/watch_and_buy_feed_event.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_and_buy_feed_bloc/watch_and_buy_feed_state.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/repo/watch_and_buy_repo.dart';

export 'watch_and_buy_feed_event.dart';
export 'watch_and_buy_feed_state.dart';

class WatchAndBuyFeedBloc
    extends Bloc<WatchAndBuyFeedEvent, WatchAndBuyFeedState> {
  final WatchAndBuyRepository _repository;

  WatchAndBuyFeedBloc({WatchAndBuyRepository? repository})
      : _repository = repository ?? WatchAndBuyRepository(),
        super(WatchAndBuyFeedInitial()) {
    on<FetchWatchAndBuyFeed>(_onFetchFeed);
    on<FetchMoreWatchAndBuyFeed>(_onFetchMoreFeed);
    on<UpdateFeedReelLike>(_onUpdateFeedReelLike);
  }

  void _onUpdateFeedReelLike(
    UpdateFeedReelLike event,
    Emitter<WatchAndBuyFeedState> emit,
  ) {
    if (state is! WatchAndBuyFeedLoaded) return;
    final currentState = state as WatchAndBuyFeedLoaded;

    bool found = false;
    final updatedItems = currentState.items.map((item) {
      if (item.id == event.reelId) {
        found = true;
        return item.copyWith(
          likedByMe: event.isLiked,
          likeCount: event.likeCount,
        );
      }
      return item;
    }).toList();

    if (found) {
      emit(currentState.copyWith(items: updatedItems));
    }
  }

  Future<void> _onFetchFeed(
    FetchWatchAndBuyFeed event,
    Emitter<WatchAndBuyFeedState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(WatchAndBuyFeedLoading());
    }

    try {
      final response = await _repository.fetchReels(perPage: 10);

      emit(
        WatchAndBuyFeedLoaded(
          items: response.items,
          nextCursor: response.meta?.nextCursor,
          sessionId: response.meta?.sessionId,
          hasMore: response.meta?.nextCursor != null &&
              response.meta!.nextCursor!.isNotEmpty,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(WatchAndBuyFeedError(message: e.toString()));
    }
  }

  Future<void> _onFetchMoreFeed(
    FetchMoreWatchAndBuyFeed event,
    Emitter<WatchAndBuyFeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WatchAndBuyFeedLoaded ||
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

      final updatedItems = List<WatchAndBuyItem>.from(currentState.items)
        ..addAll(response.items);

      emit(
        currentState.copyWith(
          items: updatedItems,
          nextCursor: response.meta?.nextCursor,
          sessionId: response.meta?.sessionId ?? currentState.sessionId,
          hasMore: response.meta?.nextCursor != null &&
              response.meta!.nextCursor!.isNotEmpty,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
