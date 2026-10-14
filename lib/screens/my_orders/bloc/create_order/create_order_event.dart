part of 'create_order_bloc.dart';

abstract class CreateOrderEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class CreateOrderRequest extends CreateOrderEvent {
  final String paymentType;
  final String? promoCode;
  final String? giftCard;
  final int addressId;
  final bool? useWallet;
  final String? orderNote;
  final String? idempotencyKey;
  final Map<int, List<CartItemAttachment>>? attachments;

  CreateOrderRequest({
    required this.paymentType,
    this.promoCode,
    this.giftCard,
    required this.addressId,
    this.useWallet,
    this.orderNote,
    this.idempotencyKey,
    this.attachments
  });

  @override
  // TODO: implement props
  List<Object?> get props => [
    paymentType,
    promoCode,
    giftCard,
    addressId,
    useWallet,
    orderNote,
    idempotencyKey,
    attachments
  ];
}
