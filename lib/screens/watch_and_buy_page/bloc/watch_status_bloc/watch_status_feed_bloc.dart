import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_status_bloc/watch_status_feed_event.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_status_bloc/watch_status_feed_state.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/repo/watch_and_buy_repo.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_status_preload_service.dart';

export 'watch_status_feed_event.dart';
export 'watch_status_feed_state.dart';

class WatchStatusFeedBloc
    extends Bloc<WatchStatusFeedEvent, WatchStatusFeedState> {
  final WatchAndBuyRepository _repository;

  WatchStatusFeedBloc({WatchAndBuyRepository? repository})
      : _repository = repository ?? WatchAndBuyRepository(),
        super(WatchStatusFeedInitial()) {
    on<FetchStatusFeed>(_onFetchStatusFeed);
    on<FetchMoreStatusFeed>(_onFetchMoreStatusFeed);
    on<MarkProfileStatusAsSeenLocally>(_onMarkProfileStatusAsSeenLocally);
  }

  Future<void> _onFetchStatusFeed(
    FetchStatusFeed event,
    Emitter<WatchStatusFeedState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(WatchStatusFeedLoading());
    }

    try {
      final response = await _repository.fetchStatusFeed(perPage: 10);
      emit(
        WatchStatusFeedLoaded(
          items: response.items,
          nextCursor: response.meta?.nextCursor,
          sessionId: response.meta?.sessionId,
          hasMore: response.meta?.nextCursor != null &&
              response.meta!.nextCursor!.isNotEmpty,
          isLoadingMore: false,
        ),
      );
      // Background preload status slides and media; on pull-to-refresh force refresh the profile status caches
      WatchStatusPreloadService().preloadStatusFeed(
        response.items,
        forceRefresh: event.isRefresh,
      );
    } catch (e) {
      log('WatchStatusFeedBloc _onFetchStatusFeed error: $e');
      emit(WatchStatusFeedError(message: e.toString()));
    }
  }

  Future<void> _onFetchMoreStatusFeed(
    FetchMoreStatusFeed event,
    Emitter<WatchStatusFeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WatchStatusFeedLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _repository.fetchStatusFeed(
        cursor: currentState.nextCursor,
        sessionId: currentState.sessionId,
        perPage: 10,
      );

      final updatedItems =
          List<WatchStatusFeedItem>.from(currentState.items)
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
      WatchStatusPreloadService().preloadStatusFeed(response.items);
    } catch (e) {
      log('WatchStatusFeedBloc _onFetchMoreStatusFeed error: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onMarkProfileStatusAsSeenLocally(
    MarkProfileStatusAsSeenLocally event,
    Emitter<WatchStatusFeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! WatchStatusFeedLoaded) return;

    final updatedItems = currentState.items.map((item) {
      if (item.profile.username == event.username) {
        return item.copyWith(
          profile: item.profile.copyWith(hasUnseenStatus: false),
        );
      }
      return item;
    }).toList();

    emit(currentState.copyWith(items: updatedItems));
  }
}
