import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../model/user_location/user_location_model.dart';
import '../../../../services/address/selected_address_hive.dart';
import '../../../../services/location/location_service.dart';
import '../../../../services/market/market_service.dart';
import '../../model/get_address_list_model.dart';
import '../../repo/address_repo.dart';

part 'get_address_list_event.dart';
part 'get_address_list_state.dart';

class GetAddressListBloc extends Bloc<GetAddressListEvent, GetAddressListState> {
  GetAddressListBloc() : super(GetAddressListInitial()) {
    on<FetchUserAddressList>(_onFetchUserAddressList);
    on<RemoveAddressLocally>(_onRemoveAddressLocally);
    on<AddAddressRequest>(_onAddAddressRequest);
    on<UpdateAddressRequest>(_onUpdateAddressRequest);
    on<RemoveAddressRequest>(_onRemoveAddressRequest);
    on<RemoveAddressOptimistically>(_onRemoveAddressOptimistically);
    on<UndoRemoveAddress>(_onUndoRemoveAddress);
    on<CommitRemoveAddress>(_onCommitRemoveAddress);
    on<SetDefaultShippingRequest>(_onSetDefaultShipping);
  }

  int currentPage = 0;
  int perPage = 0;
  bool _hasReachedMax = false;
  bool loadMore = false;
  final AddressRepository repository = AddressRepository();
  String fullAddress = '';

  // Addresses removed from the UI but not yet committed to the API, kept so
  // they can be restored on undo or on a failed delete. Keyed by address id.
  final Map<int, MapEntry<int, AddressListData>> _pendingRemovals = {};

  Future<void> _onFetchUserAddressList(FetchUserAddressList event, Emitter<GetAddressListState> emit) async {
    emit(GetAddressListLoading());
    try{
      List<AddressListData> addressList = [];
      perPage = 18;
      currentPage = 1;
      _hasReachedMax = false;
      loadMore = false;
      final response = await repository.fetchAddressList(deliveryZoneId: event.deliveryZoneId);
      addressList = List<AddressListData>.from(response['data']['data'].map((data) => AddressListData.fromJson(data)));
      currentPage += 1;
      _hasReachedMax = addressList.length < perPage;
      final bool isFetchingAllAddresses = event.deliveryZoneId == null || event.deliveryZoneId.toString() == '';
      if(response['success'] == true) {
        if (isFetchingAllAddresses && addressList.isEmpty) {
          log('No addresses exist globally → clearing Hive selected address');
          HiveSelectedAddressHelper.clearSelectedAddress();
        }
        if (!HiveSelectedAddressHelper.hasSelectedAddress() && addressList.isNotEmpty) {
          HiveSelectedAddressHelper.setSelectedAddress(addressList.first);
        }
        emit(GetAddressListLoaded(
            message: response['message'],
            addressList: addressList,
            hasReachedMax: _hasReachedMax,
          isUpdating: false,
          isAdding: false,
          isRemoving: false,
          isUpdated: false,
          isAdded: false,
          isRemoved: false,
        ));

      } else if (response['error'] == true) {
        emit(GetAddressListFailed(error: response['message']));
      }
    }catch (e) {
      emit(GetAddressListFailed(error: e.toString()));
    }
  }

  Future<void> _onRemoveAddressLocally(RemoveAddressLocally event, Emitter<GetAddressListState> emit) async {
    if (state is GetAddressListLoaded) {
      final currentState = state as GetAddressListLoaded;

      emit(currentState.copyWith(isRemoving: true));


      final updatedAddressList = currentState.addressList.where((address) => address.id != event.addressId).toList();

      emit(currentState.copyWith(
        addressList: updatedAddressList,
        isRemoving: false,
        isRemoved: true,
      ));

      await Future.delayed(const Duration(seconds: 2));
      if (state is GetAddressListLoaded) {
        emit((state as GetAddressListLoaded).copyWith(isRemoved: false));
      }
    }
  }

  Future<void> _onAddAddressRequest(AddAddressRequest event, Emitter<GetAddressListState> emit) async {
    if (state is GetAddressListLoaded) {
      final currentState = state as GetAddressListLoaded;

      emit(currentState.copyWith(isAdding: true, failed: false));

      try {
        final response = await repository.addAddressRequest(
            addressLine1: event.addressLine1,
            addressLine2: event.addressLine2,
            city: event.city,
            landmark: event.landmark,
            state: event.state,
            zipcode: event.zipcode,
            mobile: event.mobile,
            addressType: event.addressType,
            country: event.country,
            countryCode: event.countryCode,
            latitude: event.latitude,
            longitude: event.longitude,
            isDefaultShipping: event.isDefaultShipping
        );



        final bool succeeded =
            response['success'] == true && response['data'] != null;

        if (succeeded) {
          final createdAddress = AddressListData.fromJson(response['data']);
          // The API echo can omit the country fields; fall back to what the
          // user submitted so the default-address market switch still has an
          // ISO-2 country code to work with.
          if ((createdAddress.countryCode ?? '').trim().isEmpty) {
            createdAddress.countryCode = event.countryCode;
          }
          if ((createdAddress.country ?? '').trim().isEmpty) {
            createdAddress.country = event.country;
          }
          if (event.isDefaultShipping) {
            await _applyDefaultLocally(createdAddress);
          } else if (!HiveSelectedAddressHelper.hasSelectedAddress()) {
            await HiveSelectedAddressHelper.setSelectedAddress(createdAddress);
          }

          add(FetchUserAddressList(deliveryZoneId: event.deliveryZoneId));

          emit(currentState.copyWith(
            isAdding: false,
            isAdded: true,
            failed: false,
          ));

          await Future.delayed(const Duration(seconds: 1));
          if (state is GetAddressListLoaded) {
            emit((state as GetAddressListLoaded).copyWith(isAdded: false));
          }
        } else {
          // Keep the Loaded state so the form can retry; surface real message.
          emit(currentState.copyWith(
            isAdding: false,
            failed: true,
            message:
                (response['message'] ?? 'Failed to add address').toString(),
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          isAdding: false,
          failed: true,
          message: e.toString(),
        ));
      }
    }
  }

  Future<void> _onUpdateAddressRequest(UpdateAddressRequest event, Emitter<GetAddressListState> emit) async {
    if (state is GetAddressListLoaded) {
      final currentState = state as GetAddressListLoaded;
      emit(currentState.copyWith(isUpdating: true, failed: false));
      try {
        final response = await repository.updateAddress(
          addressId: event.addressId,
          addressLine1: event.addressLine1,
          addressLine2: event.addressLine2,
          city: event.city,
          landmark: event.landmark,
          state: event.state,
          zipcode: event.zipcode,
          mobile: event.mobile,
          addressType: event.addressType,
          country: event.country,
          countryCode: event.countryCode,
          latitude: event.latitude,
          longitude: event.longitude,
          isDefaultShipping: event.isDefaultShipping,
        );

        if (response['success'] == true && response['data'] != null) {
          final updatedAddress =
          AddressListData.fromJson(response['data']);

          if (event.isDefaultShipping) {
            await _applyDefaultLocally(updatedAddress);
          } else if (HiveSelectedAddressHelper.getSelectedAddress()?.id ==
              updatedAddress.id) {
            // Keep the locally selected copy in sync with edits.
            await HiveSelectedAddressHelper.setSelectedAddress(updatedAddress);
          }

          final updatedList = currentState.addressList.map((address) {
            return address.id == updatedAddress.id
                ? updatedAddress
                : address;
          }).toList();

          emit(currentState.copyWith(
            addressList: updatedList,
            isUpdating: false,
            isUpdated: true,
            failed: false,
            message: response['message'] ?? 'Address updated',
          ));

          await Future.delayed(const Duration(seconds: 1));
          if (state is GetAddressListLoaded) {
            emit((state as GetAddressListLoaded)
                .copyWith(isUpdated: false));
          }
        } else {
          emit(currentState.copyWith(
            isUpdating: false,
            failed: true,
            message:
                (response['message'] ?? 'Failed to update address').toString(),
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          isUpdating: false,
          failed: true,
          message: e.toString(),
        ));
      }
    }
  }

  Future<void> _onRemoveAddressRequest(RemoveAddressRequest event, Emitter<GetAddressListState> emit) async {
    if (state is GetAddressListLoaded) {
      final currentState = state as GetAddressListLoaded;
      emit(currentState.copyWith(isRemoving: true));

      try {
        final response = await repository.removeAddress(
          addressId: event.addressId,
        );

        if (response['success'] == true) {
          final updatedAddressList = currentState.addressList.where((address) => address.id != event.addressId).toList();

          if (updatedAddressList.isEmpty) {
            HiveSelectedAddressHelper.clearSelectedAddress();
          } else if (HiveSelectedAddressHelper.getSelectedAddress()?.id == event.addressId) {
            HiveSelectedAddressHelper.clearSelectedAddress();
          }

          emit(GetAddressListLoaded(
            message: response['message'] ?? currentState.message,
            addressList: updatedAddressList,
            hasReachedMax: currentState.hasReachedMax,
            isUpdating: false,
            isUpdated: false,
            isAdding: false,
            isAdded: false,
            isRemoving: false,
            isRemoved: true,
          ));
        } else {
          emit(GetAddressListLoaded(
            message: currentState.message,
            addressList: currentState.addressList,
            hasReachedMax: currentState.hasReachedMax,
            isUpdating: false,
            isUpdated: false,
            isAdding: false,
            isAdded: false,
            isRemoving: false,
            isRemoved: false,
          ));
          emit(GetAddressListFailed(error: response['message'] ?? 'Failed to remove address'));
        }
      } catch (e) {
        // Reset isRemoving on error
        emit(GetAddressListLoaded(
          message: currentState.message,
          addressList: currentState.addressList,
          hasReachedMax: currentState.hasReachedMax,
          isUpdating: false,
          isUpdated: false,
          isAdding: false,
          isAdded: false,
          isRemoving: false,
          isRemoved: false,
        ));
        emit(GetAddressListFailed(error: e.toString()));
      }
    }
  }

  void _onRemoveAddressOptimistically(
      RemoveAddressOptimistically event, Emitter<GetAddressListState> emit) {
    if (state is GetAddressListLoaded) {
      final currentState = state as GetAddressListLoaded;
      final index =
          currentState.addressList.indexWhere((a) => a.id == event.addressId);
      if (index == -1) return;

      _pendingRemovals[event.addressId] =
          MapEntry(index, currentState.addressList[index]);

      final updatedList =
          List<AddressListData>.from(currentState.addressList)..removeAt(index);

      emit(currentState.copyWith(
        addressList: updatedList,
        isRemoveFailed: false,
      ));
    }
  }

  void _onUndoRemoveAddress(
      UndoRemoveAddress event, Emitter<GetAddressListState> emit) {
    final pending = _pendingRemovals.remove(event.addressId);
    if (pending == null || state is! GetAddressListLoaded) return;

    final currentState = state as GetAddressListLoaded;
    final restoredList = List<AddressListData>.from(currentState.addressList);
    restoredList.insert(
        pending.key.clamp(0, restoredList.length), pending.value);

    emit(currentState.copyWith(addressList: restoredList));
  }

  Future<void> _onCommitRemoveAddress(
      CommitRemoveAddress event, Emitter<GetAddressListState> emit) async {
    if (!_pendingRemovals.containsKey(event.addressId)) return;

    try {
      final response =
          await repository.removeAddress(addressId: event.addressId);

      if (response['success'] == true) {
        _pendingRemovals.remove(event.addressId);
        if (state is GetAddressListLoaded) {
          final currentState = state as GetAddressListLoaded;
          if (currentState.addressList.isEmpty ||
              HiveSelectedAddressHelper.getSelectedAddress()?.id ==
                  event.addressId) {
            HiveSelectedAddressHelper.clearSelectedAddress();
          }
          emit(currentState.copyWith(
            message: response['message'] ?? currentState.message,
            isRemoved: true,
          ));
          await Future.delayed(const Duration(seconds: 1));
          if (state is GetAddressListLoaded) {
            emit((state as GetAddressListLoaded).copyWith(isRemoved: false));
          }
        }
      } else {
        _restoreFailedRemoval(event.addressId, emit);
      }
    } catch (e) {
      _restoreFailedRemoval(event.addressId, emit);
    }
  }

  // Persist the given address as the local default: selected address + the
  // stored delivery location the home header/delivery estimates read from.
  Future<void> _applyDefaultLocally(AddressListData address) async {
    await HiveSelectedAddressHelper.setSelectedAddress(address);

    // Follow the default address's country: switch the active market/country
    // so currency and catalog match the newly defaulted delivery country.
    // Done before the lat/lng guard below so it runs even for addresses that
    // were saved without coordinates.
    await _applyMarketForDefault(address);

    final lat = double.tryParse(address.latitude ?? '');
    final lng = double.tryParse(address.longitude ?? '');
    if (lat == null || lng == null) return;

    final fullAddress = [
      address.addressLine1,
      address.addressLine2,
      address.city,
      address.state,
      address.zipcode,
      address.country,
    ].where((p) => p != null && p.trim().isNotEmpty).join(', ');

    await LocationService.storeLocation(UserLocation(
      latitude: lat,
      longitude: lng,
      fullAddress: fullAddress,
      area: address.addressLine1?.trim() ?? '',
      city: address.city?.trim() ?? '',
      state: address.state?.trim() ?? '',
      country: address.country?.trim() ?? '',
      pincode: address.zipcode?.trim() ?? '',
      landmark: address.landmark?.trim() ?? '',
    ));
  }

  /// Switch the app's active market and cached country to match the country of
  /// the address just made default. Runs for every "set as default" path —
  /// including adding a new address and choosing it as the default.
  ///
  /// No-op when the address has no ISO-2 country code, when the country is
  /// already the active one, or when no market covers it (keeps the current
  /// market rather than leaving the app in an unsupported country).
  Future<void> _applyMarketForDefault(AddressListData address) async {
    try {
      await MarketService.switchAndCacheForCountry(
        iso2: address.countryCode ?? '',
        fallbackName: address.country,
      );
    } catch (e) {
      log('Failed to switch market for default address: $e');
    }
  }

  Future<void> _onSetDefaultShipping(
      SetDefaultShippingRequest event, Emitter<GetAddressListState> emit) async {
    final address = event.address;
    if (address.id == null) return;

    await _applyDefaultLocally(address);

    if (state is GetAddressListLoaded) {
      final currentState = state as GetAddressListLoaded;
      final updatedList = currentState.addressList
          .map((a) => AddressListData(
                id: a.id,
                userId: a.userId,
                addressLine1: a.addressLine1,
                addressLine2: a.addressLine2,
                city: a.city,
                landmark: a.landmark,
                state: a.state,
                zipcode: a.zipcode,
                mobile: a.mobile,
                addressType: a.addressType,
                country: a.country,
                countryCode: a.countryCode,
                latitude: a.latitude,
                longitude: a.longitude,
                isDefaultShipping: a.id == address.id,
                createdAt: a.createdAt,
                updatedAt: a.updatedAt,
              ))
          .toList();
      emit(currentState.copyWith(addressList: updatedList));
    }

    try {
      await repository.updateAddress(
        addressId: address.id!,
        addressLine1: address.addressLine1 ?? '',
        addressLine2: address.addressLine2 ?? '',
        city: address.city ?? '',
        landmark: address.landmark ?? '',
        state: address.state ?? '',
        zipcode: address.zipcode ?? '',
        mobile: address.mobile ?? '',
        addressType: address.addressType ?? 'home',
        country: address.country ?? '',
        countryCode: address.countryCode ?? '',
        latitude: address.latitude ?? '',
        longitude: address.longitude ?? '',
        isDefaultShipping: true,
      );
    } catch (e) {
      log('Set default shipping failed: $e');
    }
  }

  void _restoreFailedRemoval(int addressId, Emitter<GetAddressListState> emit) {
    final pending = _pendingRemovals.remove(addressId);
    if (pending == null || state is! GetAddressListLoaded) return;

    final currentState = state as GetAddressListLoaded;
    final restoredList = List<AddressListData>.from(currentState.addressList);
    restoredList.insert(
        pending.key.clamp(0, restoredList.length), pending.value);

    emit(currentState.copyWith(
      addressList: restoredList,
      isRemoveFailed: true,
    ));
  }
}