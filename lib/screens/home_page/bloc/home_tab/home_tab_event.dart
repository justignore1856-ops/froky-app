import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class HomeTabEvent extends Equatable {
  const HomeTabEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeTabs extends HomeTabEvent {
  final BuildContext? context;
  const FetchHomeTabs({this.context});

  @override
  List<Object?> get props => [context];
}
