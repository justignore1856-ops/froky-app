import 'package:equatable/equatable.dart';

abstract class CartAddonEditEvent extends Equatable {
  const CartAddonEditEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the full product detail so the edit sheet can show every variant.
class FetchCartAddonCatalog extends CartAddonEditEvent {
  final String productSlug;
  final String countryCode;

  const FetchCartAddonCatalog({required this.productSlug, required this.countryCode});

  @override
  List<Object?> get props => [productSlug, countryCode];
}
