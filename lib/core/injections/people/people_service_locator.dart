import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/data/repository/people_repository_impl.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/create_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/delete_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_my_family_id_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/remove_member_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/update_family_name_usecase.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';

class PeopleServiceLocator {
  PeopleServiceLocator(this.sl);
  final GetIt sl;

  void init() {
    sl
      ..registerSingleton<PeopleRepository>(
        PeopleRepositoryImpl(
          authService: sl<AuthService>(instanceName: 'authService'),
        ),
        instanceName: 'peopleRepositoryImpl',
      )
      ..registerSingleton<GetPeopleUsecase>(
        GetPeopleUsecase(repository: sl(instanceName: 'peopleRepositoryImpl')),
        instanceName: 'getPeopleUsecase',
      )
      ..registerSingleton<GetMyFamilyIdUsecase>(
        GetMyFamilyIdUsecase(
          repository: sl(instanceName: 'peopleRepositoryImpl'),
        ),
        instanceName: 'getMyFamilyIdUsecase',
      )
      ..registerSingleton<CreateFamilyUsecase>(
        CreateFamilyUsecase(
          repository: sl(instanceName: 'peopleRepositoryImpl'),
        ),
        instanceName: 'createFamilyUsecase',
      )
      ..registerSingleton<JoinFamilyUsecase>(
        JoinFamilyUsecase(repository: sl(instanceName: 'peopleRepositoryImpl')),
        instanceName: 'joinFamilyUsecase',
      )
      ..registerSingleton<UpdateFamilyNameUsecase>(
        UpdateFamilyNameUsecase(
          repository: sl(instanceName: 'peopleRepositoryImpl'),
        ),
        instanceName: 'updateFamilyNameUsecase',
      )
      ..registerSingleton<RemoveMemberUsecase>(
        RemoveMemberUsecase(
          repository: sl(instanceName: 'peopleRepositoryImpl'),
        ),
        instanceName: 'removeMemberUsecase',
      )
      ..registerSingleton<DeleteFamilyUsecase>(
        DeleteFamilyUsecase(
          repository: sl(instanceName: 'peopleRepositoryImpl'),
        ),
        instanceName: 'deleteFamilyUsecase',
      )
      ..registerSingleton<PeopleCubit>(
        PeopleCubit(
          getPeopleUsecase: sl(instanceName: 'getPeopleUsecase'),
          createFamilyUsecase: sl(instanceName: 'createFamilyUsecase'),
          joinFamilyUsecase: sl(instanceName: 'joinFamilyUsecase'),
          authService: sl(instanceName: 'authService'),
        ),
        instanceName: 'peopleCubit',
      )
      ..registerSingleton<FamilySettingsCubit>(
        FamilySettingsCubit(
          getPeopleUsecase: sl(instanceName: 'getPeopleUsecase'),
          getMyFamilyIdUsecase: sl(instanceName: 'getMyFamilyIdUsecase'),
          updateFamilyNameUsecase: sl(instanceName: 'updateFamilyNameUsecase'),
          removeMemberUsecase: sl(instanceName: 'removeMemberUsecase'),
          deleteFamilyUsecase: sl(instanceName: 'deleteFamilyUsecase'),
          authService: sl(instanceName: 'authService'),
        ),
        instanceName: 'familySettingsCubit',
      )
      ..registerSingleton<InvitePeopleCubit>(
        InvitePeopleCubit(edgetFunctions: sl(instanceName: 'edgetFunctions')),
        instanceName: 'invitePeopleCubit',
      );
  }
}
