import '../../../config/helper.dart';

class CityModel {
  bool? success;
  String? message;
  CityData? data;

  CityModel({this.success, this.message, this.data});

  CityModel.fromJson(Map<String, dynamic> json) {
    success = parseBool(json['success']);
    message = parseString(json['message']);
    data = json['data'] != null ? CityData.fromJson(json['data']) : null;
  }
}

class CityData {
  List<CityItem> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  CityData({
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 0,
    this.perPage = 0,
    this.total = 0,
  });

  bool get hasMore => currentPage > 0 && currentPage < lastPage;

  CityData.fromJson(Map<String, dynamic> json)
      : items = (json['items'] as List<dynamic>? ?? [])
            .map((e) => CityItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPage = parseInt(json['current_page']),
        lastPage = parseInt(json['last_page']),
        perPage = parseInt(json['per_page']),
        total = parseInt(json['total']);
}

class CityItem {
  final String name;
  final String stateCode;
  final String stateName;
  final String countryIso2;
  final String countryName;

  const CityItem({
    required this.name,
    required this.stateCode,
    required this.stateName,
    required this.countryIso2,
    required this.countryName,
  });

  factory CityItem.fromJson(Map<String, dynamic> json) {
    return CityItem(
      name: parseString(json['name']),
      stateCode: parseString(json['state_code']),
      stateName: parseString(json['state_name']),
      countryIso2: (parseString(json['country_iso2'])).toUpperCase(),
      countryName: parseString(json['country_name']),
    );
  }
}
