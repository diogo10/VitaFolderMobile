import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/posts/domain/entities/post_entity.dart';

abstract interface class PostRepository {
  Future<Either<Failure, List<PostEntity>>> getPosts();
}
