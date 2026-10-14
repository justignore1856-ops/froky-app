import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/resolve_pincode_model.dart';
import '../../repo/address_repo.dart';

part 'resolve_pincode_event.dart';
part 'resolve_pincode_state.dart';

class ResolvePincodeBloc extends Bloc<ResolvePincodeEvent, ResolvePincodeState> {
  ResolvePincodeBloc({AddressRepository? repository})
      : _repository = repository ?? AddressRepository(),
        super(const ResolvePincodeInitial()) {
    on<ResolvePincode>(_onResolvePincode);
    on<ClearPincodeResolution>(_onClear);
  }

  final AddressRepository _repository;
  int _requestId = 0;

  Future<void> _onResolvePincode(
      ResolvePincode event, Emitter<ResolvePincodeState> emit) async {
    final pincode = event.pincode.trim();
    if (pincode.isEmpty) {
      emit(const ResolvePincodeInitial());
      return;
    }
    final currentRequest = ++_requestId;
    emit(ResolvePincodeLoading(pincode: pincode));
    try {
      final matches = await _repository.resolvePincode(pincode);
      if (currentRequest != _requestId) return;
      if (matches.isEmpty) {
        emit(ResolvePincodeNotFound(pincode: pincode));
        return;
      }
      final expectedIso2 = (event.expectedCountryIso2 ?? '').toUpperCase();
      List<PincodeMatch> filtered = matches;
      if (expectedIso2.isNotEmpty) {
        final scoped =
            matches.where((m) => m.countryIso2 == expectedIso2).toList();
        if (scoped.isNotEmpty) filtered = scoped;
      }
      emit(ResolvePincodeLoaded(pincode: pincode, matches: filtered));
    } catch (e) {
      if (currentRequest != _requestId) return;
      emit(ResolvePincodeFailed(pincode: pincode, error: e.toString()));
    }
  }

  void _onClear(
      ClearPincodeResolution event, Emitter<ResolvePincodeState> emit) {
    _requestId++;
    emit(const ResolvePincodeInitial());
  }
}
