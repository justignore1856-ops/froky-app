import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/home_layout_models.dart';
import '../../repo/home_layout_repo.dart';
import 'home_layout_event.dart';
import 'home_layout_state.dart';


class HomeLayoutBloc extends Bloc<HomeLayoutEvent, HomeLayoutState> {
  final HomeLayoutRepository repository = HomeLayoutRepository();

  static const int _perPage = 10;

  int _currentPage = 1;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;
  final String _categorySlug = '';
  Map<String, dynamic>? _layoutQuery;
  String _message = '';
  String _scopeType = 'global';
  final List<HomeSection> _sections = [];
  int _fetchRequestId = 0;

  HomeLayoutBloc() : super(HomeLayoutInitial()) {
    on<FetchHomeLayout>(_onFetchHomeLayout);
    on<FetchMoreHomeLayout>(_onFetchMoreHomeLayout);
  }

  Future<void> _onFetchHomeLayout(
    FetchHomeLayout event,
    Emitter<HomeLayoutState> emit,
  ) async {
    // Claim a unique ID for this request before any await.
    final myRequestId = ++_fetchRequestId;

    _currentPage = 1;
    _hasReachedMax = false;
    _isLoadingMore = false;
    _layoutQuery = event.layoutQuery;
    _sections.clear();
    emit(HomeLayoutLoading(layoutQuery: _layoutQuery));
    try {
      final raw = await repository.fetchHomeLayout(
        categorySlug: _categorySlug,
        layoutQuery: _layoutQuery,
        page: _currentPage,
        perPage: _perPage,
      );

      if (myRequestId != _fetchRequestId) return;

      final response = HomeLayoutResponse.fromJson(raw);
      if (response.success) {
        _message = response.message;
        _scopeType = response.scopeType;
        _sections
          ..clear()
          ..addAll(response.sections);
        // No pagination metadata in the payload — stop when a page returns
        // fewer than the requested page size.
        _hasReachedMax = response.sections.length < _perPage;
        emit(HomeLayoutLoaded(
          message: _message,
          scopeType: _scopeType,
          sections: List.of(_sections),
          layoutQuery: _layoutQuery,
          hasReachedMax: _hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        emit(HomeLayoutFailed(
          error: response.message,
          layoutQuery: _layoutQuery,
        ));
      }
    } catch (e) {
      if (myRequestId != _fetchRequestId) return;
      emit(HomeLayoutFailed(
        error: e.toString(),
        layoutQuery: _layoutQuery,
      ));
    }
  }

  Future<void> _onFetchMoreHomeLayout(
    FetchMoreHomeLayout event,
    Emitter<HomeLayoutState> emit,
  ) async {
    if (_hasReachedMax || _isLoadingMore) return;
    final current = state;
    if (current is! HomeLayoutLoaded) return;

    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = _currentPage + 1;
      final raw = await repository.fetchHomeLayout(
        categorySlug: _categorySlug,
        layoutQuery: _layoutQuery,
        page: nextPage,
        perPage: _perPage,
      );
      final response = HomeLayoutResponse.fromJson(raw);
      if (response.success) {
        _currentPage = nextPage;
        _sections.addAll(response.sections);
        _hasReachedMax = response.sections.length < _perPage;
        emit(HomeLayoutLoaded(
          message: _message,
          scopeType: _scopeType,
          sections: List.of(_sections),
          layoutQuery: _layoutQuery,
          hasReachedMax: _hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        // Keep what we have; just stop the bottom loader.
        emit(current.copyWith(isLoadingMore: false));
      }
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    } finally {
      _isLoadingMore = false;
    }
  }
}
