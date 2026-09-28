import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/repositories/post_repository.dart';
import 'package:week4_api/data/network_errors.dart';
import 'package:week4_api/data/paged_posts.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository({this.items, this.throwError = false}) : super(Dio());
  final List<Post>? items;
  final bool throwError;

  @override
  Future<List<Post>> fetchPostsPage({required int page, required int limit}) async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    return items ?? [];
  }
}

void main() {
  test('Post.fromJson parsing aman null', () {
    final json = {'id': 1, 'title': 'Test Title'};
    final post = Post.fromJson(json);
    
    expect(post.id, 1);
    expect(post.title, 'Test Title');
    expect(post.userId, 0); // Diuji default value-nya
  });

  test('friendlyErrorMessage connection error', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );
    expect(friendlyErrorMessage(err), contains('Koneksi bermasalah'));
  });

  test('Provider dengan repository palsu sukses', () async {
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          FakePostRepository(items: [
            const Post(userId: 1, id: 1, title: 'Title', body: 'Body'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(postRepositoryProvider);
    final posts = await repo.fetchPostsPage(page: 1, limit: 10);
    
    expect(posts.length, 1);
    expect(posts.first.title, 'Title');
  });
}