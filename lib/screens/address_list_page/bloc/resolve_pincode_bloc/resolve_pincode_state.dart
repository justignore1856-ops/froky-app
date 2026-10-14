part of 'resolve_pincode_bloc.dart';

abstract class ResolvePincodeState extends Equatable {
  const ResolvePincodeState();

  @override
  List<Object?> get props => [];
}

class ResolvePincodeInitial extends ResolvePincodeState {
  const ResolvePincodeInitial();
}

class ResolvePincodeLoading extends ResolvePincodeState {
  final String pincode;

  const ResolvePincodeLoading({required this.pincode});

  @override
  List<Object?> get props => [pincode];
}

class ResolvePincodeLoaded extends ResolvePincodeState {
  final String pincode;
  final List<PincodeMatch> matches;

  const ResolvePincodeLoaded({required this.pincode, required this.matches});

  bool get isAmbiguous => matches.length > 1;

  PincodeMatch? get primaryMatch => matches.isEmpty ? null : matches.first;

  @override
  List<Object?> get props => [pincode, matches];
}

class ResolvePincodeNotFound extends ResolvePincodeState {
  final String pincode;

  const ResolvePincodeNotFound({required this.pincode});

  @override
  List<Object?> get props => [pincode];
}

class ResolvePincodeFailed extends ResolvePincodeState {
  final String pincode;
  final String error;

  const ResolvePincodeFailed({required this.pincode, required this.error});

  @override
  List<Object?> get props => [pincode, error];
}
