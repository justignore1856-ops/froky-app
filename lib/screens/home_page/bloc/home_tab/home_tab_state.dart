import 'package:equatable/equatable.dart';
import '../../model/home_tab_model.dart';

abstract class HomeTabState extends Equatable {
  const HomeTabState();

  @override
  List<Object?> get props => [];
}

class HomeTabInitial extends HomeTabState {}

class HomeTabLoading extends HomeTabState {}

class HomeTabLoaded extends HomeTabState {
  final String message;
  final List<HomeTabItem> homeTabs;

  const HomeTabLoaded({
    required this.message,
    required this.homeTabs,
  });

  @override
  List<Object?> get props => [message, homeTabs];
}

class HomeTabFailed extends HomeTabState {
  final String error;

  const HomeTabFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
