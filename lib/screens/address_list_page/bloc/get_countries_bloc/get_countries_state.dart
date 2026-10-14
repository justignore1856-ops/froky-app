part of 'get_countries_bloc.dart';

abstract class GetCountriesState extends Equatable {
  const GetCountriesState();

  @override
  List<Object?> get props => [];
}

class GetCountriesInitial extends GetCountriesState {
  const GetCountriesInitial();
}

class GetCountriesLoading extends GetCountriesState {
  const GetCountriesLoading();
}

class GetCountriesLoaded extends GetCountriesState {
  final List<CountryItem> countries;

  const GetCountriesLoaded({required this.countries});

  @override
  List<Object?> get props => [countries];
}

class GetCountriesFailed extends GetCountriesState {
  final String error;

  const GetCountriesFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
