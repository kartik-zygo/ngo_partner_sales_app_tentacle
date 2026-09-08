import '../../domain/entities/community.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/remote_data_source.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl(this._remote);

  final RemoteDataSource _remote;

  @override
  Future<List<CommunityPost>> getPosts({
    int page = 1,
    int limit = 30,
    String sort = 'newest',
    String? tag,
    String? search,
  }) =>
      _remote.getCommunityPosts(
          page: page, limit: limit, sort: sort, tag: tag, search: search);

  @override
  Future<CommunityPost> getPost(String id) => _remote.getCommunityPost(id);

  @override
  Future<CommunityAnswer> addAnswer(String postId, String body) =>
      _remote.addCommunityAnswer(postId, body);

  @override
  Future<CommunityVoteResult> votePost(String postId, int value) =>
      _remote.voteCommunityPost(postId, value);

  @override
  Future<CommunityVoteResult> voteAnswer(String answerId, int value) =>
      _remote.voteCommunityAnswer(answerId, value);

  @override
  Future<void> deletePost(String postId) => _remote.deleteCommunityPost(postId);

  @override
  Future<void> deleteAnswer(String answerId) =>
      _remote.deleteCommunityAnswer(answerId);

  @override
  Future<CommunityPost> setPostClosed(String postId, bool closed) =>
      _remote.setCommunityPostClosed(postId, closed);

  @override
  Future<List<CommunityTag>> getTags() => _remote.getCommunityTags();
}
