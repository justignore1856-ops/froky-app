import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/city_model.dart';
import '../../repo/address_repo.dart';

part 'get_cities_event.dart';
part 'get_cities_state.dart';

class GetCitiesBloc extends Bloc<GetCitiesEvent, GetCitiesState> {
  GetCitiesBloc({AddressRepository? repository})
      : _repository = repository ?? AddressRepository(),
        super(const GetCitiesInitial()) {
    on<FetchCities>(_onFetchCities);
    on<SearchCities>(_onSearchCities);
    on<ResetCities>(_onResetCities);
  }

  final AddressRepository _repository;
  int _requestId = 0;

  static const int _perPage = 20;

  Future<void> _onFetchCities(
      FetchCities event, Emitter<GetCitiesState> emit) async {
    if (event.iso2.trim().isEmpty) {
      emit(const GetCitiesInitial());
      return;
    }
    final currentRequest = ++_requestId;
    emit(const GetCitiesLoading());
    try {
      final data = await _repository.fetchCities(
        iso2: event.iso2,
        stateCode: event.stateCode,
        page: 1,
        perPage: _perPage,
      );
      if (currentRequest != _requestId) return;
      emit(GetCitiesLoaded(
        cities: data.items,
        query: '',
        page: 1,
        hasMore: data.hasMore,
      ));
    } catch (e) {
      if (currentRequest != _requestId) return;
      emit(GetCitiesFailed(error: e.toString()));
    }
  }

  Future<void> _onSearchCities(
      SearchCities event, Emitter<GetCitiesState> emit) async {
    if (event.iso2.trim().isEmpty) return;
    final currentRequest = ++_requestId;
    emit(const GetCitiesLoading());
    try {
      final data = await _repository.fetchCities(
        iso2: event.iso2,
        stateCode: event.stateCode,
        query: event.query,
        page: event.page,
        perPage: _perPage,
      );
      if (currentRequest != _requestId) return;
      emit(GetCitiesLoaded(
        cities: data.items,
        query: event.query,
        page: event.page,
        hasMore: data.hasMore,
      ));
    } catch (e) {
      if (currentRequest != _requestId) return;
      emit(GetCitiesFailed(error: e.toString()));
    }
  }

  void _onResetCities(ResetCities event, Emitter<GetCitiesState> emit) {
    _requestId++;
    emit(const GetCitiesInitial());
  }
}
