import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/get_people_usecase.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_state.dart';

class PeopleCubit extends Cubit<PeopleState> {
  GetPeopleUsecase getPeopleUsecase;

  PeopleCubit({required this.getPeopleUsecase}) : super(PeopleInitial());

  Future<void> getPeople() async {
    emit(PeopleLoading());
    final result = await getPeopleUsecase();

    result.fold(
      (err) => emit(PeopleError()),
      (people) => emit(PeopleLoaded(people: people)),
    );
  }
}
