import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';

sealed class HomeState {
  HomeState();
}

class HomeInitial extends HomeState {
  HomeInitial();
}

class HomeLoading extends HomeState {
  HomeLoading();
}

class HomeLoaded extends HomeState {
  final HomeEntity data;
  HomeLoaded({required this.data});
}

class HomeEmpty extends HomeState {
  HomeEmpty();
}

class HomeError extends HomeState {
  HomeError();
}
