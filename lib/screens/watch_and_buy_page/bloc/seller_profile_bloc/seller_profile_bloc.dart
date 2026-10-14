import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/seller_profile_bloc/seller_profile_event.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/seller_profile_bloc/seller_profile_state.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/seller_profile_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/repo/watch_and_buy_repo.dart';

export 'seller_profile_event.dart';
export 'seller_profile_state.dart';

class SellerProfileBloc extends Bloc<SellerProfileEvent, SellerProfileState> {
  final WatchAndBuyRepository _repository;

  SellerProfileBloc({WatchAndBuyRepository? repository})
      : _repository = repository ?? WatchAndBuyRepository(),
        super(SellerProfileInitial()) {
    on<FetchSellerProfile>(_onFetchSellerProfile);
    on<FetchMoreSellerProfileReels>(_onFetchMoreSellerProfileReels);
    on<UpdateSellerProfileReelLike>(_onUpdateReelLike);
  }

  Future<void> _onFetchSellerProfile(
    FetchSellerProfile event,
    Emitter<SellerProfileState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(SellerProfileLoading());
    }

    try {
      final response = await _repository.fetchSellerProfile(
        username: event.username,
        page: 1,
      );

      if (response.profile != null) {
        emit(
          SellerProfileLoaded(
            profile: response.profile!,
            reels: response.reels,
            pagination: response.pagination ??
                SellerProfilePagination(
                  currentPage: 1,
                  lastPage: 1,
                  total: response.reels.length,
                ),
            isLoadingMore: false,
          ),
        );
      } else {
        emit(const SellerProfileError(message: 'Seller profile not found.'));
      }
    } catch (e) {
      log('SellerProfileBloc _onFetchSellerProfile error: $e');
      emit(SellerProfileError(message: e.toString()));
    }
  }

  Future<void> _onFetchMoreSellerProfileReels(
    FetchMoreSellerProfileReels event,
    Emitter<SellerProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SellerProfileLoaded ||
        !currentState.pagination.hasMorePages ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.pagination.currentPage + 1;
      final response = await _repository.fetchSellerProfile(
        username: event.username,
        page: nextPage,
      );

      final updatedReels = List<WatchAndBuyItem>.from(currentState.reels)
        ..addAll(response.reels);

      emit(
        currentState.copyWith(
          reels: updatedReels,
          pagination: response.pagination ??
              currentState.pagination.copyWith(currentPage: nextPage),
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      log('SellerProfileBloc _onFetchMoreSellerProfileReels error: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onUpdateReelLike(
    UpdateSellerProfileReelLike event,
    Emitter<SellerProfileState> emit,
  ) {
    if (state is! SellerProfileLoaded) return;
    final currentState = state as SellerProfileLoaded;

    bool found = false;
    final updatedReels = currentState.reels.map((item) {
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
      emit(currentState.copyWith(reels: updatedReels));
    }
  }
}
