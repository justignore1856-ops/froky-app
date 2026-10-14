import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_detail_bloc/product_detail_event.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_detail_bloc/product_detail_state.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_commerce/screens/product_detail_page/repo/product_detail_repo.dart';


class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc() : super(ProductDetailInitial()) {
    on<FetchProductDetail>(_onFetchProductDetail);
  }

  final ProductDetailRepository repository = ProductDetailRepository();

  Future<void> _onFetchProductDetail(FetchProductDetail event, Emitter<ProductDetailState> emit) async {
    final previousState = state;
    // Silent refresh keeps the current page on screen and only shows a light
    // overlay loader; the shimmer is reserved for the very first load.
    final bool silentRefresh =
        event.silent && previousState is ProductDetailLoaded;

    if (silentRefresh) {
      emit(previousState.copyWith(isRefreshing: true));
    } else {
      emit(ProductDetailLoading());
    }

    try {
      final response = await repository.fetchProductDetail(
        productSlug: event.productSlug,
        addressId: event.addressId,
        marketCode: event.marketCode,
      );

      final productDetailModel = ProductDetailModel.fromJson(response);

      if (productDetailModel.success == true && productDetailModel.data != null) {
        emit(ProductDetailLoaded(
          message: productDetailModel.message,
          productData: [productDetailModel.data!],
        ));
      } else if (silentRefresh) {
        emit(previousState.copyWith(isRefreshing: false));
      } else {
        emit(ProductDetailFailed(error: productDetailModel.message));
      }
    } catch (e) {
      if (silentRefresh) {
        emit(previousState.copyWith(isRefreshing: false));
      } else {
        emit(ProductDetailFailed(error: e.toString()));
      }
    }
  }
}