import '../entities/community.dart';
import '../repositories/community_repository.dart';

class GetCommunityPostsUseCase {
  GetCommunityPostsUseCase(this._repo);
  final CommunityRepository _repo;
  Future<List<CommunityPost>> call({
    int page = 1,
    int limit = 30,
    String sort = 'newest',
    String? tag,
    String? search,
  }) =>
      _repo.getPosts(page: page, limit: limit, sort: sort, tag: tag, search: search);
}

class GetCommunityPostUseCase {
  GetCommunityPostUseCase(this._repo);
  final CommunityRepository _repo;
  Future<CommunityPost> call(String id) => _repo.getPost(id);
}

class AddCommunityAnswerUseCase {
  AddCommunityAnswerUseCase(this._repo);
  final CommunityRepository _repo;
  Future<CommunityAnswer> call(String postId, String body) =>
      _repo.addAnswer(postId, body);
}

class VoteCommunityPostUseCase {
  VoteCommunityPostUseCase(this._repo);
  final CommunityRepository _repo;
  Future<CommunityVoteResult> call(String postId, int value) =>
      _repo.votePost(postId, value);
}

class VoteCommunityAnswerUseCase {
  VoteCommunityAnswerUseCase(this._repo);
  final CommunityRepository _repo;
  Future<CommunityVoteResult> call(String answerId, int value) =>
      _repo.voteAnswer(answerId, value);
}

class DeleteCommunityPostUseCase {
  DeleteCommunityPostUseCase(this._repo);
  final CommunityRepository _repo;
  Future<void> call(String postId) => _repo.deletePost(postId);
}

class DeleteCommunityAnswerUseCase {
  DeleteCommunityAnswerUseCase(this._repo);
  final CommunityRepository _repo;
  Future<void> call(String answerId) => _repo.deleteAnswer(answerId);
}

class SetCommunityPostClosedUseCase {
  SetCommunityPostClosedUseCase(this._repo);
  final CommunityRepository _repo;
  Future<CommunityPost> call(String postId, bool closed) =>
      _repo.setPostClosed(postId, closed);
}

class GetCommunityTagsUseCase {
  GetCommunityTagsUseCase(this._repo);
  final CommunityRepository _repo;
  Future<List<CommunityTag>> call() => _repo.getTags();
}
