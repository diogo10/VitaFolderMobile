import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/posts/domain/entities/post_entity.dart';
import 'package:vita_folder_mobile/features/posts/domain/repository/post_repository.dart';

class GetPostUsecase {
  final PostRepository repository;

  GetPostUsecase({required this.repository});

  Future<Either<Failure, List<PostEntity>>> call() async {
    return await repository.getPosts();
  }
}
