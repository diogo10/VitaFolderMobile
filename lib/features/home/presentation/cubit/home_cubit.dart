import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  GetHomeDataUsecase getHomeDataUsecase;

  HomeCubit({required this.getHomeDataUsecase}) : super(HomeInitial());

  Future<void> getHomeData() async {
    emit(HomeLoading());
    final result = await getHomeDataUsecase();

    result.fold(
      (err) => _handleError(err),
      (data) => emit(HomeLoaded(data: data)),
    );
  }

  void _handleError(Exception err) {
    if (err is NoDataException) {
      emit(HomeEmpty());
    } else {
      emit(HomeError());
    }
  }
}
