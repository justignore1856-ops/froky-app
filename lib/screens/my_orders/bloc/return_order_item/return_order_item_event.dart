part of 'return_order_item_bloc.dart';

abstract class ReturnOrderItemEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class ReturnOrderItemRequest extends ReturnOrderItemEvent {
  final int orderItemId;
  final String reason;
  final String remark;
  final int quantity;
  final List<XFile> images;

  ReturnOrderItemRequest({
    required this.orderItemId,
    required this.reason,
    this.remark = '',
    this.quantity = 1,
    this.images = const [],
  });

  @override
  // TODO: implement props
  List<Object?> get props => [orderItemId, reason, remark, quantity, images];
}

class CancelReturnRequest extends ReturnOrderItemEvent {
  final int orderItemId;

  CancelReturnRequest({required this.orderItemId});

  @override
  // TODO: implement props
  List<Object?> get props => [orderItemId];
}

class CancelOrderItem extends ReturnOrderItemEvent {
  final int orderItemId;

  CancelOrderItem({
    required this.orderItemId,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [orderItemId];
}