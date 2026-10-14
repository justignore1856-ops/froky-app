part of 'get_cities_bloc.dart';

abstract class GetCitiesEvent extends Equatable {
  const GetCitiesEvent();

  @override
  List<Object?> get props => [];
}

class FetchCities extends GetCitiesEvent {
  final String iso2;
  final String? stateCode;

  const FetchCities({required this.iso2, this.stateCode});

  @override
  List<Object?> get props => [iso2, stateCode];
}

class SearchCities extends GetCitiesEvent {
  final String iso2;
  final String query;
  final String? stateCode;
  final int page;

  const SearchCities({
    required this.iso2,
    required this.query,
    this.stateCode,
    this.page = 1,
  });

  @override
  List<Object?> get props => [iso2, query, stateCode, page];
}

class ResetCities extends GetCitiesEvent {
  const ResetCities();
}
