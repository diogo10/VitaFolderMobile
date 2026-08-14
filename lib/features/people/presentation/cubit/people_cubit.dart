import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/get_people_usecase.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/create_family_usecase.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/join_family_usecase.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_state.dart';

class PeopleCubit extends Cubit<PeopleState> {
  GetPeopleUsecase getPeopleUsecase;
  CreateFamilyUsecase createFamilyUsecase;
  JoinFamilyUsecase joinFamilyUsecase;

  PeopleCubit({
    required this.getPeopleUsecase,
    required this.createFamilyUsecase,
    required this.joinFamilyUsecase,
  }) : super(PeopleInitial());

  Future<void> createFamily({required String name}) async {
    emit(PeopleLoading());
    final result = await createFamilyUsecase(name: name);

    result.fold((err) => emit(PeopleError()), (created) {
      getPeople();
    });
  }

  Future<void> joinFamily({required String familyCode}) async {
    emit(PeopleLoading());
    final result = await joinFamilyUsecase(familyCode: familyCode);

    result.fold((err) => emit(PeopleInvalidFamilyCode()), (joined) {
      getPeople();
    });
  }

  Future<void> getPeople({bool isRefresh = false}) async {
    if (!isRefresh) {
      emit(PeopleLoading());
    }
    final result = await getPeopleUsecase();

    result.fold((err) => emit(PeopleError()), (people) {
      if (people.family.name.isEmpty || people.family.inviteCode.isEmpty) {
        emit(PeopleEmpty());
        return;
      }
      emit(
        PeopleLoaded(
          people: people.people,
          inviteCode: people.family.inviteCode,
          familyName: people.family.name,
        ),
      );
    });
  }
}
