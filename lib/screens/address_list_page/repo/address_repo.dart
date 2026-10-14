
import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';

import '../../../config/helper.dart';
import '../model/city_model.dart';
import '../model/country_model.dart';
import '../model/resolve_pincode_model.dart';

class AddressRepository {

  Future<List<CountryItem>> fetchCountries() async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.geoCountriesApi,
        {},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model =
            CountryModel.fromJson(response.data as Map<String, dynamic>);
        return model.data?.items ?? <CountryItem>[];
      }
      return <CountryItem>[];
    } catch (e) {
      rethrow;
    }
  }

  Future<CityData> fetchCities({
    required String iso2,
    String? stateCode,
    String? query,
    int? page,
    int? perPage,
  }) async {
    try {
      final params = <String, dynamic>{
        'iso2': iso2,
        if (stateCode != null && stateCode.trim().isNotEmpty)
          'state_code': stateCode.trim(),
        if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      };
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.geoCitiesApi,
        params,
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = CityModel.fromJson(response.data as Map<String, dynamic>);
        return model.data ?? CityData();
      }
      return CityData();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PincodeMatch>> resolvePincode(String pincode) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.resolvePincodeApi,
        {'pincode': pincode.trim()},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = ResolvePincodeModel.fromJson(
            response.data as Map<String, dynamic>);
        return model.data?.matches ?? <PincodeMatch>[];
      }
      return <PincodeMatch>[];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addAddressRequest({
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String landmark,
    required String state,
    required String zipcode,
    required String mobile,
    required String addressType,
    required String country,
    required String countryCode,
    required String latitude,
    required String longitude,
    bool isDefaultShipping = false,
  }) async {
    try{

      /*final response = await AppHelpers.apiBaseHelper.postAPICall(
        ApiRoutes.addAddressApi,
          AppHelpers.isDemo ? AppHelpers.defaultFullAddress
            : {
          "address_line1": addressLine1,
          "address_line2": addressLine2,
          "city": city,
          "landmark": landmark,
          "state": state,
          "zipcode": zipcode,
          "mobile": mobile,
          "address_type": addressType.toLowerCase(),
          "country": country,
          "country_code": countryCode,
          "latitude": latitude,
          "longitude": longitude,
          "is_default_shipping": isDefaultShipping
        }
      );*/

      final response = await AppHelpers.apiBaseHelper.postAPICall(
          ApiRoutes.addAddressApi,
          {
            "address_line1": addressLine1,
            "address_line2": addressLine2,
            "city": city,
            "landmark": landmark,
            "state": state,
            "zipcode": zipcode,
            "mobile": mobile,
            "address_type": addressType.toLowerCase(),
            "country": country,
            "country_code": countryCode,
            "latitude": latitude,
            "longitude": longitude,
            "is_default_shipping": isDefaultShipping
          }
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      }
      return <String, dynamic>{};
    } catch (e) {
      // Propagate the real server/validation message to the bloc.
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchAddressList({int? deliveryZoneId}) async {
    try{
      String apiUrl = '';
      if(deliveryZoneId != null) {
        apiUrl = '${ApiRoutes.getAddressesApi}?zone_id=$deliveryZoneId';
      } else {
        apiUrl = ApiRoutes.getAddressesApi;
      }
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        apiUrl,
        {},
      );
      if(response.statusCode == 200 || response.data['success'] == true) {
        return response.data;
      } else {
        return {};
      }
    }catch(e){
      throw ApiException('Failed to get address list');
    }
  }

  Future<Map<String, dynamic>> removeAddress ({required int addressId}) async {
    try{
      final response = await AppHelpers.apiBaseHelper.deleteAPICall(
          '${ApiRoutes.removeAddressesApi}${addressId.toString()}',
          {}
      );
      if (response.statusCode == 200) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      }
      return <String, dynamic>{};
    } catch (e) {
      // Propagate the real server/validation message to the bloc.
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAddress ({
    required int addressId,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String landmark,
    required String state,
    required String zipcode,
    required String mobile,
    required String addressType,
    required String country,
    required String countryCode,
    required String latitude,
    required String longitude,
    bool isDefaultShipping = false,
  }) async {
    try{
      final response = await AppHelpers.apiBaseHelper.putAPICall(
          '${ApiRoutes.updateAddressesApi}${addressId.toString()}',
          AppHelpers.isDemo ? AppHelpers.defaultFullAddress
              : {
            'address_line1': addressLine1,
            'address_line2': addressLine2,
            'city': city,
            'landmark': landmark,
            'state': state,
            'zipcode': zipcode,
            'mobile': mobile,
            'address_type': addressType.toLowerCase(),
            'country': country,
            'country_code': countryCode,
            'latitude': latitude,
            'longitude': longitude,
            'is_default_shipping': isDefaultShipping
          }
      );
      if (response.statusCode == 200) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      }
      return <String, dynamic>{};
    } catch (e) {
      // Propagate the real server/validation message to the bloc.
      rethrow;
    }
  }
}

