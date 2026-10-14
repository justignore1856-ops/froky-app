import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/brand_list_page/model/brands_model.dart';
import '../../../brand_list_page/repo/brands_repo.dart';

part 'filter_brands_event.dart';
part 'filter_brands_state.dart';

class FilterBrandsBloc extends Bloc<FilterBrandsEvent, FilterBrandsState> {
  FilterBrandsBloc() : super(FilterBrandsInitial()) {
    on<FetchFilterBrands>(_onFetchFilterBrands);
  }

  final BrandsRepository repository = BrandsRepository();

  Future<void> _onFetchFilterBrands(FetchFilterBrands event, Emitter<FilterBrandsState> emit) async {
    emit(FilterBrandsLoading());
    try{
      List<BrandData> brandsData = [];
      final response = await repository.fetchFilterBrands(
        categorySlug: event.categorySlug,
        brandIds: event.brandsIds ?? []
      );
      final dynamic outer = response['data'];
      final dynamic inner = outer is Map ? outer['data'] : null;
      if (inner is! List) {
        emit(FilterBrandsFailed(
          error: response['message']?.toString() ?? 'No brands available',
        ));
        return;
      }
      brandsData = inner.map((data) => BrandData.fromJson(data)).toList();
      if (response['success'] == true) {
        emit(FilterBrandsLoaded(
            message: response['message'],
            brandsData: brandsData
        ));
      } else if (response['success'] == false) {
        emit(FilterBrandsFailed(error: response['message']));
      } else {
        emit(FilterBrandsFailed(error: response['message']));
      }
    }catch(e){
      emit(FilterBrandsFailed(error: e.toString()));
    }
  }

}
