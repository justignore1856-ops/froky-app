import 'package:equatable/equatable.dart';

import '../../model/product_detail_model.dart';

abstract class ProductDetailState extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final List<ProductData> productData;
  final String message;
  final bool isRefreshing;
  ProductDetailLoaded({
    required this.message,
    required this.productData,
    this.isRefreshing = false,
  });

  ProductDetailLoaded copyWith({
    List<ProductData>? productData,
    String? message,
    bool? isRefreshing,
  }) {
    return ProductDetailLoaded(
      message: message ?? this.message,
      productData: productData ?? this.productData,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [message, productData, isRefreshing];
}

class ProductDetailFailed extends ProductDetailState {
  final String error;
  ProductDetailFailed({required this.error});

  @override
  // TODO: implement props
  List<Object?> get props => [error];
}