import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/helper.dart';
import '../../../cart_page/widgets/cart_product_item.dart';
import '../../../payment_options/model/payment_response_model.dart';
import '../../../payment_options/model/payment_status.dart';
import '../../repo/order_repo.dart';

part 'create_order_event.dart';
part 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  CreateOrderBloc() : super(CreateOrderInitial()) {
    on<CreateOrderRequest>(_onCreateOrderRequest);
  }
  final OrderRepository repository = OrderRepository();

  bool isLoading = false;

  Future<void> _onCreateOrderRequest(CreateOrderRequest event, Emitter<CreateOrderState> emit) async {
    emit(CreateOrderProgress());
    isLoading = true;
    try{
      final response = await repository.createOrder(
        paymentType: event.paymentType,
        promoCode: event.promoCode ?? '',
        giftCard: event.giftCard ?? '',
        addressId: event.addressId,
        useWallet: event.useWallet ?? false,
        orderNote: event.orderNote ?? '',
        idempotencyKey: event.idempotencyKey,
        attachments: event.attachments!
      );

      if(response['success'] == true) {
        isLoading = false;
        final data = parseMap(response['data']);
        final items = parseList(data['items']);
        final paymentResponse =
            PaymentResponse.fromNullable(data['payment_response']);
        emit(CreateOrderSuccess(
          message: parseString(response['message']),
          orderSlug: parseString(data['slug']),
          orderItemId:
              items.isNotEmpty ? parseInt(parseMap(items.first)['id']) : 0,
          paymentType: event.paymentType,
          paymentResponse: paymentResponse,
          paymentStatus:
              OrderPaymentStatus.fromString(parseString(data['payment_status'])),
          topStatus: OrderTopStatus.fromString(parseString(data['status'])),
        ));
      } else {
        emit(CreateOrderFailure(error: response['message']));
      }
    } catch(e) {
      isLoading = false;
      emit(CreateOrderFailure(error: e.toString()));
    }
  }
}
