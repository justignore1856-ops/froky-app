import 'package:equatable/equatable.dart';

abstract class HomeLayoutEvent extends Equatable {
  const HomeLayoutEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeLayout extends HomeLayoutEvent {
  final Map<String, dynamic>? layoutQuery;

  const FetchHomeLayout({
    this.layoutQuery,
  });

  @override
  List<Object?> get props => [layoutQuery];
}

class FetchMoreHomeLayout extends HomeLayoutEvent {
  const FetchMoreHomeLayout();
}
