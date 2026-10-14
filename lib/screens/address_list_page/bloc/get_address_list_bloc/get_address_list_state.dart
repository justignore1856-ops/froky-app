part of 'get_address_list_bloc.dart';

abstract class GetAddressListState extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class GetAddressListInitial extends GetAddressListState {}

class GetAddressListLoading extends GetAddressListState {}

class GetAddressListLoaded extends GetAddressListState {
  final String message;
  final List<AddressListData> addressList;
  final bool hasReachedMax;

  final bool isUpdating;
  final bool isAdding;
  final bool isRemoving;
  final bool isUpdated;
  final bool isAdded;
  final bool isRemoved;
  final bool isRemoveFailed;
  final bool failed;

  GetAddressListLoaded({
    required this.addressList,
    required this.message,
    required this.hasReachedMax,
    this.isUpdating = false,
    this.isAdding = false,
    this.isRemoving = false,
    this.isUpdated = false,
    this.isAdded = false,
    this.isRemoved = false,
    this.isRemoveFailed = false,
    this.failed = false,
  });

  GetAddressListLoaded copyWith({
    String? message,
    List<AddressListData>? addressList,
    bool? hasReachedMax,
    bool? isUpdating,
    bool? isUpdated,
    bool? isAdding,
    bool? isAdded,
    bool? isRemoving,
    bool? isRemoved,
    bool? isRemoveFailed,
    bool? failed
  }) {
    return GetAddressListLoaded(
      message: message ?? this.message,
      addressList: addressList ?? this.addressList,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isUpdating: isUpdating ?? this.isUpdating,
      isUpdated: isUpdated ?? this.isUpdated,
      isAdding: isAdding ?? this.isAdding,
      isAdded: isAdded ?? this.isAdded,
      isRemoving: isRemoving ?? this.isRemoving,
      isRemoved: isRemoved ?? this.isRemoved,
      isRemoveFailed: isRemoveFailed ?? this.isRemoveFailed,
      failed: failed ?? this.failed
    );
  }


  @override
  // TODO: implement props
  List<Object?> get props => [
    addressList,
    message,
    hasReachedMax,
    isUpdating,
    isAdding,
    isRemoving,
    isUpdated,
    isAdded,
    isRemoved,
    isRemoveFailed,
    failed
  ];


}

class GetAddressListFailed extends GetAddressListState {
  final String error;
  GetAddressListFailed({required this.error});
  @override
  // TODO: implement props
  List<Object?> get props => [error];
}