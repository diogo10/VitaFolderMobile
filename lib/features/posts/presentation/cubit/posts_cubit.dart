import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/posts/domain/usecase/get_post_usecase.dart';
import 'package:vita_folder_mobile/features/posts/presentation/cubit/posts_state.dart';

class PostsCubit extends Cubit<PostsState> {
  GetPostUsecase getPostUsecase;

  PostsCubit({required this.getPostUsecase}) : super(PostInitialState());

  Future<void> getPosts() async {
    emit(PostsLoading());
    final posts = await getPostUsecase();

    posts.fold(
      (err) => emit(PostError()),
      (posts) => emit(LoadedPosts(posts: posts)),
    );
  }
}
