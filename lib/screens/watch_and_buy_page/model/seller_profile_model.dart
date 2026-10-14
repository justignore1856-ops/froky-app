import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';

class SellerProfileResponse {
  final bool success;
  final String message;
  final WatchProfile? profile;
  final List<WatchAndBuyItem> reels;
  final SellerProfilePagination? pagination;

  const SellerProfileResponse({
    required this.success,
    required this.message,
    this.profile,
    required this.reels,
    this.pagination,
  });

  factory SellerProfileResponse.fromJson(Map<String, dynamic> json) {
    WatchProfile? profileData;
    List<WatchAndBuyItem> reelsList = [];
    SellerProfilePagination? paginationData;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      if (data['profile'] is Map<String, dynamic>) {
        profileData =
            WatchProfile.fromJson(Map<String, dynamic>.from(data['profile']));
      }
      if (data['reels'] is List) {
        reelsList = (data['reels'] as List)
            .map((e) =>
                WatchAndBuyItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data['pagination'] is Map<String, dynamic>) {
        paginationData = SellerProfilePagination.fromJson(
            Map<String, dynamic>.from(data['pagination']));
      }
    }

    return SellerProfileResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      profile: profileData,
      reels: reelsList,
      pagination: paginationData,
    );
  }
}

class SellerProfilePagination {
  final int currentPage;
  final int lastPage;
  final int total;

  const SellerProfilePagination({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  bool get hasMorePages => currentPage < lastPage;

  SellerProfilePagination copyWith({
    int? currentPage,
    int? lastPage,
    int? total,
  }) {
    return SellerProfilePagination(
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
    );
  }

  factory SellerProfilePagination.fromJson(Map<String, dynamic> json) {
    return SellerProfilePagination(
      currentPage: parseInt(json['current_page']) > 0
          ? parseInt(json['current_page'])
          : 1,
      lastPage: parseInt(json['last_page']) > 0
          ? parseInt(json['last_page'])
          : 1,
      total: parseInt(json['total']),
    );
  }
}
