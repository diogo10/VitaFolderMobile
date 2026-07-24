import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/features/people/data/datasource/people_local_datasource.dart';
import 'package:vita_folder_mobile/features/people/data/repository/people_repository_impl.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/create_family_usecase.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/get_people_usecase.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';

class PeopleServiceLocator {
  final GetIt sl;
  PeopleServiceLocator(this.sl);

  void init() {
    sl.registerSingleton<PeopleLocalDatasource>(
      PeopleLocalDatasource(),
      instanceName: 'peopleLocalDatasource',
    );

    sl.registerSingleton<PeopleRepository>(
      PeopleRepositoryImpl(
        
      ),
      instanceName: 'peopleRepositoryImpl',
    );

    sl.registerSingleton<GetPeopleUsecase>(
      GetPeopleUsecase(
        repository: sl(instanceName: 'peopleRepositoryImpl'),
      ),
      instanceName: 'getPeopleUsecase',
    );

    sl.registerSingleton<CreateFamilyUsecase>(
      CreateFamilyUsecase(
        repository: sl(instanceName: 'peopleRepositoryImpl'),
      ),
      instanceName: 'createFamilyUsecase',
    );

    sl.registerSingleton<PeopleCubit>(
      PeopleCubit(
        getPeopleUsecase: sl(instanceName: 'getPeopleUsecase'),
        createFamilyUsecase: sl(instanceName: 'createFamilyUsecase'),
      ),
      instanceName: 'peopleCubit',
    );

    sl.registerSingleton<InvitePeopleCubit>(
      InvitePeopleCubit(
        edgetFunctions: sl(instanceName: 'edgetFunctions'),
      ),
      instanceName: 'invitePeopleCubit',
    );
  }
}
