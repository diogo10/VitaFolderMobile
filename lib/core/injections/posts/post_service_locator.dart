import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/features/posts/data/datasource/post_remote_datasource.dart';
import 'package:vita_folder_mobile/features/posts/data/repository/post_repository_impl.dart';
import 'package:vita_folder_mobile/features/posts/domain/repository/post_repository.dart';
import 'package:vita_folder_mobile/features/posts/domain/usecase/get_post_usecase.dart';
import 'package:vita_folder_mobile/features/posts/presentation/cubit/posts_cubit.dart';

class PostServiceLocator {
  final GetIt sl;
  PostServiceLocator(this.sl);

  void init() {
    sl.registerSingleton<PostRemoteDatasource>(
      PostRemoteDatasource(),
      instanceName: 'postRemoteDatasource',
    );

    sl.registerSingleton<PostRepository>(
      PostRepositoryImpl(
        postRemoteDatasource: sl(instanceName: 'postRemoteDatasource'),
      ),
      instanceName: 'postRepositoryImpl',
    );

    sl.registerSingleton<GetPostUsecase>(
      GetPostUsecase(
        repository: sl(instanceName: 'postRepositoryImpl'),
      ),
      instanceName: 'getPostUsecase',
    );

    sl.registerSingleton<PostsCubit>(
      PostsCubit(
        getPostUsecase: sl(instanceName: 'getPostUsecase'),
      ),
      instanceName: 'postsCubit',
    );
  }
}
