part of 'resolve_pincode_bloc.dart';

abstract class ResolvePincodeEvent extends Equatable {
  const ResolvePincodeEvent();

  @override
  List<Object?> get props => [];
}

class ResolvePincode extends ResolvePincodeEvent {
  final String pincode;
  final String? expectedCountryIso2;

  const ResolvePincode({required this.pincode, this.expectedCountryIso2});

  @override
  List<Object?> get props => [pincode, expectedCountryIso2];
}

class ClearPincodeResolution extends ResolvePincodeEvent {
  const ClearPincodeResolution();
}
