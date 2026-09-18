import 'package:flutter/foundation.dart';
import 'package:house_mira/features/home/domain/entities/home_entity.dart';

@immutable
sealed class HomeState {
  const HomeState();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

@immutable
class HomeLoaded extends HomeState {
  const HomeLoaded({required this.data});
  final HomeEntity data;

  @override
  bool operator ==(Object other) => other is HomeLoaded && other.data == data;

  @override
  int get hashCode => Object.hash(runtimeType, data);
}

@immutable
class HomeEmpty extends HomeState {
  const HomeEmpty({this.hasReminders = false});
  final bool hasReminders;

  @override
  bool operator ==(Object other) =>
      other is HomeEmpty && other.hasReminders == hasReminders;

  @override
  int get hashCode => Object.hash(runtimeType, hasReminders);
}

class HomeError extends HomeState {
  const HomeError();
}
