import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';

/// 1. Status Feed (Tray) Response
class WatchStatusFeedResponse {
  final bool success;
  final String message;
  final List<WatchStatusFeedItem> items;
  final WatchStatusFeedMeta? meta;

  const WatchStatusFeedResponse({
    required this.success,
    required this.message,
    required this.items,
    this.meta,
  });

  factory WatchStatusFeedResponse.fromJson(Map<String, dynamic> json) {
    List<WatchStatusFeedItem> itemsList = [];
    WatchStatusFeedMeta? metaData;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      if (data['items'] is List) {
        itemsList = (data['items'] as List)
            .map((e) =>
                WatchStatusFeedItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data['meta'] is Map<String, dynamic>) {
        metaData = WatchStatusFeedMeta.fromJson(
            Map<String, dynamic>.from(data['meta']));
      }
    } else if (json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((e) =>
              WatchStatusFeedItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return WatchStatusFeedResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      items: itemsList,
      meta: metaData,
    );
  }
}

class WatchStatusFeedMeta {
  final String? sessionId;
  final String? nextCursor;
  final int perPage;

  const WatchStatusFeedMeta({
    this.sessionId,
    this.nextCursor,
    this.perPage = 10,
  });

  factory WatchStatusFeedMeta.fromJson(Map<String, dynamic> json) {
    return WatchStatusFeedMeta(
      sessionId: json['session_id'] != null
          ? parseString(json['session_id'])
          : null,
      nextCursor: json['next_cursor'] != null
          ? parseString(json['next_cursor'])
          : null,
      perPage: parseInt(json['per_page']) > 0
          ? parseInt(json['per_page'])
          : 10,
    );
  }
}

class WatchStatusFeedItem {
  final WatchProfile profile;
  final int statusCount;

  const WatchStatusFeedItem({
    required this.profile,
    required this.statusCount,
  });

  factory WatchStatusFeedItem.fromJson(Map<String, dynamic> json) {
    return WatchStatusFeedItem(
      profile: json['profile'] is Map<String, dynamic>
          ? WatchProfile.fromJson(Map<String, dynamic>.from(json['profile']))
          : const WatchProfile(
              id: 0,
              type: 'seller',
              username: '',
              photoUrl: '',
              status: 'active',
              hasActiveStatus: false,
              hasUnseenStatus: false,
            ),
      statusCount: parseInt(json['status_count']),
    );
  }

  WatchStatusFeedItem copyWith({
    WatchProfile? profile,
    int? statusCount,
  }) {
    return WatchStatusFeedItem(
      profile: profile ?? this.profile,
      statusCount: statusCount ?? this.statusCount,
    );
  }
}

/// 2. Profile Statuses Response (Viewer)
class WatchProfileStatusesResponse {
  final bool success;
  final String message;
  final WatchProfile? profile;
  final List<WatchStatusItem> items;
  final WatchStatusPagination? pagination;

  const WatchProfileStatusesResponse({
    required this.success,
    required this.message,
    this.profile,
    required this.items,
    this.pagination,
  });

  factory WatchProfileStatusesResponse.fromJson(Map<String, dynamic> json) {
    WatchProfile? profileData;
    List<WatchStatusItem> itemsList = [];
    WatchStatusPagination? paginationData;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      if (data['profile'] is Map<String, dynamic>) {
        profileData =
            WatchProfile.fromJson(Map<String, dynamic>.from(data['profile']));
      }
      if (data['items'] is List) {
        itemsList = (data['items'] as List)
            .map((e) =>
                WatchStatusItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data['pagination'] is Map<String, dynamic>) {
        paginationData = WatchStatusPagination.fromJson(
            Map<String, dynamic>.from(data['pagination']));
      }
    }

    return WatchProfileStatusesResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      profile: profileData,
      items: itemsList,
      pagination: paginationData,
    );
  }
}

class WatchStatusPagination {
  final int perPage;
  final int total;
  final String? nextCursor;
  final String? previousCursor;
  final bool hasMorePages;

  const WatchStatusPagination({
    this.perPage = 10,
    this.total = 0,
    this.nextCursor,
    this.previousCursor,
    this.hasMorePages = false,
  });

  factory WatchStatusPagination.fromJson(Map<String, dynamic> json) {
    return WatchStatusPagination(
      perPage: parseInt(json['per_page']),
      total: parseInt(json['total']),
      nextCursor: json['next_cursor'] != null
          ? parseString(json['next_cursor'])
          : null,
      previousCursor: json['previous_cursor'] != null
          ? parseString(json['previous_cursor'])
          : null,
      hasMorePages: parseBool(json['has_more_pages']),
    );
  }
}

enum WatchStatusContentType { image, video, text }

class WatchStatusItem {
  final int id;
  final String uuid;
  final String source;
  final WatchStatusContentType contentType;
  final String? text;
  final String mediaUrl;
  final String? coverUrl;
  final String mediaMime;
  final int mediaSizeBytes;
  final int width;
  final int height;
  final int? durationMs;
  final List<WatchProductItem> products;
  final WatchStatusCreator? creator;
  final String? createdAt;
  final String? expiresAt;
  final bool seenByMe;

  const WatchStatusItem({
    required this.id,
    required this.uuid,
    required this.source,
    required this.contentType,
    this.text,
    required this.mediaUrl,
    this.coverUrl,
    required this.mediaMime,
    required this.mediaSizeBytes,
    required this.width,
    required this.height,
    this.durationMs,
    required this.products,
    this.creator,
    this.createdAt,
    this.expiresAt,
    required this.seenByMe,
  });

  bool get hasMedia => mediaUrl.trim().isNotEmpty;

  bool get isVideo =>
      contentType == WatchStatusContentType.video && hasMedia;

  bool get isImage =>
      contentType == WatchStatusContentType.image && hasMedia;

  bool get isTextOnly =>
      contentType == WatchStatusContentType.text ||
      (!hasMedia && text != null && text!.trim().isNotEmpty);

  Duration get slideDuration {
    if (contentType == WatchStatusContentType.video &&
        durationMs != null &&
        durationMs! > 0) {
      return Duration(milliseconds: durationMs!);
    }
    final int dynamicDurationSeconds =
        SettingsData.instance.watchAndBuy?.maxStatusDurationSeconds ?? 15;
    return Duration(
        seconds: dynamicDurationSeconds > 0 ? dynamicDurationSeconds : 15);
  }

  String get formattedCreatedAt => formatRelativeTime(createdAt);

  factory WatchStatusItem.fromJson(Map<String, dynamic> json) {
    final typeStr = parseString(
      json['content_type'] ??
          json['media_type'] ??
          json['type'] ??
          json['contentType'] ??
          json['mediaType'],
    ).toLowerCase();

    final mimeStr = parseString(
      json['media_mime'] ??
          json['mime_type'] ??
          json['mime'] ??
          json['mimeType'],
    ).toLowerCase();

    final rawMediaUrl = parseString(
      json['media_url'] ??
          json['video_url'] ??
          json['mediaUrl'] ??
          json['videoUrl'] ??
          json['url'] ??
          json['media'],
    ).trim();

    final rawCoverUrl = parseString(
      json['cover_url'] ??
          json['thumbnail_url'] ??
          json['coverUrl'] ??
          json['thumbnailUrl'] ??
          json['thumbnail'] ??
          json['poster_url'] ??
          json['preview_url'],
    ).trim();

    final cleanUrl =
        rawMediaUrl.split('?').first.split('#').first.toLowerCase();
    final bool hasVideoExtension = cleanUrl.endsWith('.mp4') ||
        cleanUrl.endsWith('.mov') ||
        cleanUrl.endsWith('.m4v') ||
        cleanUrl.endsWith('.webm') ||
        cleanUrl.endsWith('.m3u8') ||
        cleanUrl.endsWith('.3gp') ||
        cleanUrl.endsWith('.mkv') ||
        cleanUrl.endsWith('.avi');

    final int? rawDuration = json['duration_ms'] != null
        ? parseInt(json['duration_ms'])
        : (json['durationMs'] != null
            ? parseInt(json['durationMs'])
            : (json['duration'] != null ? parseInt(json['duration']) : null));

    final isVideo = typeStr == 'video' ||
        typeStr.contains('video') ||
        mimeStr.contains('video') ||
        hasVideoExtension ||
        (rawDuration != null &&
            rawDuration > 0 &&
            !cleanUrl.endsWith('.jpg') &&
            !cleanUrl.endsWith('.png') &&
            !cleanUrl.endsWith('.jpeg') &&
            !cleanUrl.endsWith('.webp'));

    final isText = typeStr == 'text' ||
        (rawMediaUrl.isEmpty &&
            (json['text'] != null &&
                json['text'].toString().trim().isNotEmpty));

    List<WatchProductItem> productsList = [];
    if (json['products'] is List) {
      productsList = (json['products'] as List)
          .map((p) =>
              WatchProductItem.fromJson(Map<String, dynamic>.from(p)))
          .toList();
    }

    return WatchStatusItem(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      source: parseString(json['source']),
      contentType: isVideo
          ? WatchStatusContentType.video
          : isText
              ? WatchStatusContentType.text
              : WatchStatusContentType.image,
      text: json['text'] != null ? parseString(json['text']) : null,
      mediaUrl: rawMediaUrl,
      coverUrl: rawCoverUrl.isNotEmpty ? rawCoverUrl : null,
      mediaMime: parseString(json['media_mime']),
      mediaSizeBytes: parseInt(json['media_size_bytes']),
      width: parseInt(json['width']) > 0 ? parseInt(json['width']) : 720,
      height: parseInt(json['height']) > 0 ? parseInt(json['height']) : 1280,
      durationMs: rawDuration,
      products: productsList,
      creator: json['creator'] is Map<String, dynamic>
          ? WatchStatusCreator.fromJson(Map<String, dynamic>.from(json['creator']))
          : null,
      createdAt:
          json['created_at'] != null ? parseString(json['created_at']) : null,
      expiresAt:
          json['expires_at'] != null ? parseString(json['expires_at']) : null,
      seenByMe: parseBool(json['seen_by_me']),
    );
  }

  WatchStatusItem copyWith({
    bool? seenByMe,
    String? coverUrl,
  }) {
    return WatchStatusItem(
      id: id,
      uuid: uuid,
      source: source,
      contentType: contentType,
      text: text,
      mediaUrl: mediaUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      mediaMime: mediaMime,
      mediaSizeBytes: mediaSizeBytes,
      width: width,
      height: height,
      durationMs: durationMs,
      products: products,
      creator: creator,
      createdAt: createdAt,
      expiresAt: expiresAt,
      seenByMe: seenByMe ?? this.seenByMe,
    );
  }
}

class WatchStatusCreator {
  final int id;
  final String name;

  const WatchStatusCreator({
    required this.id,
    required this.name,
  });

  factory WatchStatusCreator.fromJson(Map<String, dynamic> json) {
    return WatchStatusCreator(
      id: parseInt(json['id']),
      name: parseString(json['name']),
    );
  }
}

/// 3. Mark Status Seen Response
class WatchStatusSeenResponse {
  final bool success;
  final String message;
  final List<WatchStatusSeenItem> data;

  const WatchStatusSeenResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory WatchStatusSeenResponse.fromJson(Map<String, dynamic> json) {
    List<WatchStatusSeenItem> items = [];
    if (json['data'] is List) {
      items = (json['data'] as List)
          .map((e) =>
              WatchStatusSeenItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return WatchStatusSeenResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: items,
    );
  }
}

class WatchStatusSeenItem {
  final int statusId;
  final String? seenAt;

  const WatchStatusSeenItem({
    required this.statusId,
    this.seenAt,
  });

  factory WatchStatusSeenItem.fromJson(Map<String, dynamic> json) {
    return WatchStatusSeenItem(
      statusId: parseInt(json['status_id']),
      seenAt: json['seen_at'] != null ? parseString(json['seen_at']) : null,
    );
  }
}
