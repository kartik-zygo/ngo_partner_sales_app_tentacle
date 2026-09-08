part of 'community_bloc.dart';

enum CommunityStatus { initial, loading, success, failure }

class CommunityState extends Equatable {
  const CommunityState({
    this.status = CommunityStatus.initial,
    this.posts = const [],
    this.tags = const [],
    this.sort = 'newest',
    this.tag,
    this.search = '',
    this.error,
  });

  final CommunityStatus status;
  final List<CommunityPost> posts;
  final List<CommunityTag> tags;
  final String sort;
  final String? tag;
  final String search;
  final String? error;

  CommunityState copyWith({
    CommunityStatus? status,
    List<CommunityPost>? posts,
    List<CommunityTag>? tags,
    String? sort,
    String? tag,
    bool clearTag = false,
    String? search,
    String? error,
  }) {
    return CommunityState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      tags: tags ?? this.tags,
      sort: sort ?? this.sort,
      tag: clearTag ? null : (tag ?? this.tag),
      search: search ?? this.search,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, posts, tags, sort, tag, search, error];
}
