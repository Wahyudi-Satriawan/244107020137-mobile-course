import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(dioProvider));
});

class PagedPostsState {
  const PagedPostsState({
    this.items = const [],
    this.page = 1,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> items;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
}

class PagedPostsNotifier extends Notifier<PagedPostsState> {
  @override
  PagedPostsState build() {
    Future.microtask(loadFirstPage);
    return const PagedPostsState();
  }

  Future<void> loadFirstPage() async {
    final repository = ref.read(postRepositoryProvider);
    state = const PagedPostsState(); // Reset loading
    try {
      final items = await repository.fetchPostsPage(page: 1, limit: 10);
      state = PagedPostsState(items: items, page: 1, hasMore: items.length == 10);
    } catch (e) {
      state = PagedPostsState(error: e);
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final repo = ref.read(postRepositoryProvider);
    final currentItems = state.items;
    final currentPage = state.page;

    state = PagedPostsState(
      items: currentItems,
      page: currentPage,
      isLoadingMore: true,
      hasMore: state.hasMore,
    );

    try {
      final items = await repo.fetchPostsPage(page: currentPage + 1, limit: 10);
      state = PagedPostsState(
        items: [...currentItems, ...items],
        page: currentPage + 1,
        hasMore: items.length == 10,
      );
    } catch (e) {
      state = PagedPostsState(items: currentItems, page: currentPage, error: e);
    }
  }
}

final pagedPostsProvider = NotifierProvider<PagedPostsNotifier, PagedPostsState>(
  PagedPostsNotifier.new,
);