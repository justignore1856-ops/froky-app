import '../../../config/helper.dart';

enum CountryAddressingType { zipcode, city }

CountryAddressingType _parseCountryType(String? raw) {
  final normalized = (raw ?? '').trim().toLowerCase();
  if (normalized == 'city') return CountryAddressingType.city;
  return CountryAddressingType.zipcode;
}

class CountryModel {
  bool? success;
  String? message;
  CountryData? data;

  CountryModel({this.success, this.message, this.data});

  CountryModel.fromJson(Map<String, dynamic> json) {
    success = parseBool(json['success']);
    message = parseString(json['message']);
    data = json['data'] != null ? CountryData.fromJson(json['data']) : null;
  }
}

class CountryData {
  List<CountryItem> items;

  CountryData({this.items = const []});

  CountryData.fromJson(Map<String, dynamic> json)
      : items = (json['items'] as List<dynamic>? ?? [])
            .map((e) => CountryItem.fromJson(e as Map<String, dynamic>))
            .toList();
}

class CountryItem {
  final String iso2;
  final String name;
  final CountryAddressingType type;

  const CountryItem({
    required this.iso2,
    required this.name,
    required this.type,
  });

  factory CountryItem.fromJson(Map<String, dynamic> json) {
    return CountryItem(
      iso2: (parseString(json['iso2'])).toUpperCase(),
      name: parseString(json['name']),
      type: _parseCountryType(parseString(json['type'])),
    );
  }

  bool get requiresZipcode => type == CountryAddressingType.zipcode;
}
