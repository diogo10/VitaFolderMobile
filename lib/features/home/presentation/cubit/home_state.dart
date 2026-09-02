import 'package:house_mira/features/home/domain/entities/home_entity.dart';

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

class HomeLoaded extends HomeState {
  final HomeEntity data;

  const HomeLoaded({required this.data});

  @override
  bool operator ==(Object other) => other is HomeLoaded && other.data == data;

  @override
  int get hashCode => Object.hash(runtimeType, data);
}

class HomeEmpty extends HomeState {
  final bool hasReminders;

  const HomeEmpty({this.hasReminders = false});

  @override
  bool operator ==(Object other) =>
      other is HomeEmpty && other.hasReminders == hasReminders;

  @override
  int get hashCode => Object.hash(runtimeType, hasReminders);
}

class HomeError extends HomeState {
  const HomeError();
}
