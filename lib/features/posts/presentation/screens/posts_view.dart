import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:vita_folder_mobile/features/posts/presentation/cubit/posts_state.dart';
import 'package:vita_folder_mobile/features/posts/presentation/widgets/post_widget.dart';

class PostsView extends StatefulWidget {
  const PostsView({super.key});

  @override
  State<PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends State<PostsView> {
  @override
  void initState() {
    context.read<PostsCubit>().getPosts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostsCubit, PostsState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Posts'),
          ),
          body: Builder(builder: (_) {
            if (state is PostsLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is LoadedPosts) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PostsCubit>().getPosts();
                },
                child: ListView.builder(
                  itemCount: state.posts.length,
                  itemBuilder: (_, index) {
                    return PostWidget(
                      key: Key(state.posts[index].id.toString()),
                      title: state.posts[index].title,
                      body: state.posts[index].body,
                    );
                  },
                ),
              );
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }),
        );
      },
    );
  }
}
