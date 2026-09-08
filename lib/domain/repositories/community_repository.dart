import '../entities/community.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> getPosts({
    int page,
    int limit,
    String sort,
    String? tag,
    String? search,
  });
  Future<CommunityPost> getPost(String id);
  Future<CommunityAnswer> addAnswer(String postId, String body);
  Future<CommunityVoteResult> votePost(String postId, int value);
  Future<CommunityVoteResult> voteAnswer(String answerId, int value);
  Future<void> deletePost(String postId);
  Future<void> deleteAnswer(String answerId);
  Future<CommunityPost> setPostClosed(String postId, bool closed);
  Future<List<CommunityTag>> getTags();
}
