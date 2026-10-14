import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchProductDetail extends ProductDetailEvent {
  final String productSlug;
  final String? addressId;
  final String? marketCode;
  final bool silent;
  FetchProductDetail({
    required this.productSlug,
    this.addressId,
    this.marketCode,
    this.silent = false,
  });
  @override
  // TODO: implement props
  List<Object?> get props => [productSlug, addressId, marketCode, silent];
}