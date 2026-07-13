import 'package:vita_folder_mobile/features/posts/domain/entities/post_entity.dart';

sealed class PostsState {
  PostsState();
}

class PostInitialState extends PostsState {
  PostInitialState();
}

class PostsLoading extends PostsState {
  PostsLoading();
}

class LoadedPosts extends PostsState {
  List<PostEntity> posts;
  LoadedPosts({required this.posts});
}

class PostError extends PostsState {
  PostError();
}
