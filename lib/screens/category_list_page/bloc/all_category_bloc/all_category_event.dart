import 'package:equatable/equatable.dart';

abstract class AllCategoriesEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchAllCategories extends AllCategoriesEvent {
  final bool? isHome;
  FetchAllCategories({this.isHome});

  @override
  // TODO: implement props
  List<Object?> get props => [isHome];
}

class FetchMoreAllCategories extends AllCategoriesEvent {
  final bool? isHome;
  FetchMoreAllCategories({this.isHome});

  @override
  // TODO: implement props
  List<Object?> get props => [isHome];
}