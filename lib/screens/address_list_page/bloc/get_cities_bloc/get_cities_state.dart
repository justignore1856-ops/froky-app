part of 'get_cities_bloc.dart';

abstract class GetCitiesState extends Equatable {
  const GetCitiesState();

  @override
  List<Object?> get props => [];
}

class GetCitiesInitial extends GetCitiesState {
  const GetCitiesInitial();
}

class GetCitiesLoading extends GetCitiesState {
  const GetCitiesLoading();
}

class GetCitiesLoaded extends GetCitiesState {
  final List<CityItem> cities;
  final String query;
  final int page;
  final bool hasMore;

  const GetCitiesLoaded({
    required this.cities,
    required this.query,
    this.page = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [cities, query, page, hasMore];
}

class GetCitiesFailed extends GetCitiesState {
  final String error;

  const GetCitiesFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
