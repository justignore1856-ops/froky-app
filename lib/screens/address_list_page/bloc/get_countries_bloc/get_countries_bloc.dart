import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/country_model.dart';
import '../../repo/address_repo.dart';

part 'get_countries_event.dart';
part 'get_countries_state.dart';

class GetCountriesBloc extends Bloc<GetCountriesEvent, GetCountriesState> {
  GetCountriesBloc({AddressRepository? repository})
      : _repository = repository ?? AddressRepository(),
        super(const GetCountriesInitial()) {
    on<FetchCountries>(_onFetchCountries);
  }

  final AddressRepository _repository;

  Future<void> _onFetchCountries(
      FetchCountries event, Emitter<GetCountriesState> emit) async {
    emit(const GetCountriesLoading());
    try {
      final countries = await _repository.fetchCountries();
      emit(GetCountriesLoaded(countries: countries));
    } catch (e) {
      emit(GetCountriesFailed(error: e.toString()));
    }
  }
}
