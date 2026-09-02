import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUsecase getHomeDataUsecase;
  final HasRemindersUsecase hasRemindersUsecase;

  HomeCubit({
    required this.getHomeDataUsecase,
    required this.hasRemindersUsecase,
  }) : super(const HomeInitial());

  Future<void> getHomeData({bool isRefresh = false}) async {
    if (!isRefresh) {
      emit(const HomeLoading());
    }
    final result = await getHomeDataUsecase();

    await result.fold((err) async => _handleError(err), (data) async {
      final hasReminders = await _hasReminders();
      emit(HomeLoaded(data: data.copyWith(hasReminders: hasReminders)));
    });
  }

  Future<bool> _hasReminders() async {
    final result = await hasRemindersUsecase();
    return result.fold((err) {
      debugPrint('Failed to load reminders for home: $err');
      return false;
    }, (hasReminders) => hasReminders);
  }

  Future<void> _handleError(Exception err) async {
    if (err is NoDataException) {
      final hasReminders = await _hasReminders();
      emit(HomeEmpty(hasReminders: hasReminders));
    } else {
      emit(const HomeError());
    }
  }
}
