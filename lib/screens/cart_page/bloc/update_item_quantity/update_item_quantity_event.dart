import 'package:equatable/equatable.dart';

abstract class UpdateItemQuantityEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class UpdateItemQuantityRequest extends UpdateItemQuantityEvent{
  final int cartItemId;
  final int quantity;
  final int? minQuantity;
  final int? maxQuantity;

  UpdateItemQuantityRequest({
    required this.cartItemId,
    required this.quantity,
    this.minQuantity,
    this.maxQuantity,
  });

  @override
  List<Object?> get props => [cartItemId, quantity, minQuantity, maxQuantity];
}
