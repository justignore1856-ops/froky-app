import 'package:equatable/equatable.dart';

import '../../model/home_layout_models.dart';

abstract class HomeLayoutState extends Equatable {
  const HomeLayoutState();

  @override
  List<Object?> get props => [];
}

class HomeLayoutInitial extends HomeLayoutState {}

class HomeLayoutLoading extends HomeLayoutState {
  final Map<String, dynamic>? layoutQuery;

  const HomeLayoutLoading({this.layoutQuery});

  @override
  List<Object?> get props => [layoutQuery];
}

class HomeLayoutLoaded extends HomeLayoutState {
  final String message;
  final String scopeType;
  final List<HomeSection> sections;
  final Map<String, dynamic>? layoutQuery;

  /// No more pages to load.
  final bool hasReachedMax;

  /// A next-page request is in flight (show a bottom loader).
  final bool isLoadingMore;

  const HomeLayoutLoaded({
    required this.message,
    required this.scopeType,
    required this.sections,
    this.layoutQuery,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  HomeLayoutLoaded copyWith({
    String? message,
    String? scopeType,
    List<HomeSection>? sections,
    Map<String, dynamic>? layoutQuery,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return HomeLayoutLoaded(
      message: message ?? this.message,
      scopeType: scopeType ?? this.scopeType,
      sections: sections ?? this.sections,
      layoutQuery: layoutQuery ?? this.layoutQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [message, scopeType, sections, layoutQuery, hasReachedMax, isLoadingMore];
}

class HomeLayoutFailed extends HomeLayoutState {
  final String error;
  final Map<String, dynamic>? layoutQuery;

  const HomeLayoutFailed({required this.error, this.layoutQuery});

  @override
  List<Object?> get props => [error, layoutQuery];
}

