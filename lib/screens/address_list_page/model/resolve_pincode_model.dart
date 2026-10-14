import '../../../config/helper.dart';

class ResolvePincodeModel {
  bool? success;
  String? message;
  ResolvePincodeData? data;

  ResolvePincodeModel({this.success, this.message, this.data});

  ResolvePincodeModel.fromJson(Map<String, dynamic> json) {
    success = parseBool(json['success']);
    message = parseString(json['message']);
    data = json['data'] != null
        ? ResolvePincodeData.fromJson(json['data'])
        : null;
  }
}

class ResolvePincodeData {
  final List<PincodeMatch> matches;

  ResolvePincodeData({this.matches = const []});

  ResolvePincodeData.fromJson(Map<String, dynamic> json)
      : matches = (json['matches'] as List<dynamic>? ?? [])
            .map((e) => PincodeMatch.fromJson(e as Map<String, dynamic>))
            .toList();
}

class PincodeMatch {
  final String countryIso2;
  final String countryName;
  final String stateCode;
  final String stateName;
  final List<String> cities;

  const PincodeMatch({
    required this.countryIso2,
    required this.countryName,
    required this.stateCode,
    required this.stateName,
    this.cities = const [],
  });

  factory PincodeMatch.fromJson(Map<String, dynamic> json) {
    final rawCities = json['cities'] as List<dynamic>? ?? [];
    return PincodeMatch(
      countryIso2: (parseString(json['country_iso2'])).toUpperCase(),
      countryName: parseString(json['country_name']),
      stateCode: parseString(json['state_code']),
      stateName: parseString(json['state_name']),
      cities: rawCities.map((e) => e.toString()).toList(),
    );
  }
}
