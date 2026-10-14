import 'package:equatable/equatable.dart';

abstract class WatchStatusFeedEvent extends Equatable {
  const WatchStatusFeedEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch initial status tray list
class FetchStatusFeed extends WatchStatusFeedEvent {
  final bool isRefresh;
  const FetchStatusFeed({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Fetch next page of status tray items using cursor
class FetchMoreStatusFeed extends WatchStatusFeedEvent {
  const FetchMoreStatusFeed();
}

/// Mark all statuses of a given [username] as seen locally in the tray
class MarkProfileStatusAsSeenLocally extends WatchStatusFeedEvent {
  final String username;
  const MarkProfileStatusAsSeenLocally({required this.username});

  @override
  List<Object?> get props => [username];
}
