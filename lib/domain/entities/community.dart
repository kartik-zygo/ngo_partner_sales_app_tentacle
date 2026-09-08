import 'package:equatable/equatable.dart';

class CommunityAuthor extends Equatable {
  const CommunityAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isTeam = false,
    this.reputation = 0,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool isTeam;
  final int reputation;

  factory CommunityAuthor.fromJson(Map<String, dynamic> json) => CommunityAuthor(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'NGO Member',
        avatarUrl: json['avatarUrl'] as String?,
        isTeam: json['isTeam'] as bool? ?? false,
        reputation: (json['reputation'] as num?)?.toInt() ?? 0,
      );

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [id, name, isTeam, reputation];
}

class CommunityAnswer extends Equatable {
  const CommunityAnswer({
    required this.id,
    required this.postId,
    required this.body,
    this.voteScore = 0,
    this.isAccepted = false,
    required this.author,
    this.myVote = 0,
    this.createdAt,
  });

  final String id;
  final String postId;
  final String body;
  final int voteScore;
  final bool isAccepted;
  final CommunityAuthor author;
  final int myVote;
  final DateTime? createdAt;

  factory CommunityAnswer.fromJson(Map<String, dynamic> json) => CommunityAnswer(
        id: json['id'] as String? ?? '',
        postId: json['postId'] as String? ?? '',
        body: json['body'] as String? ?? '',
        voteScore: (json['voteScore'] as num?)?.toInt() ?? 0,
        isAccepted: json['isAccepted'] as bool? ?? false,
        author: CommunityAuthor.fromJson(
            (json['author'] as Map<String, dynamic>?) ?? const {}),
        myVote: (json['myVote'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  CommunityAnswer copyWith({int? voteScore, int? myVote}) => CommunityAnswer(
        id: id,
        postId: postId,
        body: body,
        voteScore: voteScore ?? this.voteScore,
        isAccepted: isAccepted,
        author: author,
        myVote: myVote ?? this.myVote,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, voteScore, isAccepted, myVote];
}

class CommunityPost extends Equatable {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.body,
    this.postType = 'question',
    this.tags = const [],
    this.viewCount = 0,
    this.voteScore = 0,
    this.answerCount = 0,
    this.acceptedAnswerId,
    this.isResolved = false,
    this.isClosed = false,
    required this.author,
    this.myVote = 0,
    this.createdAt,
    this.answers = const [],
  });

  final String id;
  final String title;
  final String body;
  final String postType;
  final List<String> tags;
  final int viewCount;
  final int voteScore;
  final int answerCount;
  final String? acceptedAnswerId;
  final bool isResolved;
  final bool isClosed;
  final CommunityAuthor author;
  final int myVote;
  final DateTime? createdAt;
  final List<CommunityAnswer> answers;

  bool get isQuestion => postType == 'question';

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        postType: json['postType'] as String? ?? 'question',
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
        voteScore: (json['voteScore'] as num?)?.toInt() ?? 0,
        answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
        acceptedAnswerId: json['acceptedAnswerId'] as String?,
        isResolved: json['isResolved'] as bool? ?? false,
        isClosed: json['isClosed'] as bool? ?? false,
        author: CommunityAuthor.fromJson(
            (json['author'] as Map<String, dynamic>?) ?? const {}),
        myVote: (json['myVote'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        answers: (json['answers'] as List<dynamic>?)
                ?.map((e) => CommunityAnswer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  CommunityPost copyWith({int? voteScore, int? myVote, bool? isClosed}) =>
      CommunityPost(
        id: id,
        title: title,
        body: body,
        postType: postType,
        tags: tags,
        viewCount: viewCount,
        voteScore: voteScore ?? this.voteScore,
        answerCount: answerCount,
        acceptedAnswerId: acceptedAnswerId,
        isResolved: isResolved,
        isClosed: isClosed ?? this.isClosed,
        author: author,
        myVote: myVote ?? this.myVote,
        createdAt: createdAt,
        answers: answers,
      );

  @override
  List<Object?> get props =>
      [id, voteScore, answerCount, isResolved, isClosed, myVote];
}

class CommunityVoteResult {
  CommunityVoteResult({required this.voteScore, required this.myVote});
  final int voteScore;
  final int myVote;

  factory CommunityVoteResult.fromJson(Map<String, dynamic> json) =>
      CommunityVoteResult(
        voteScore: (json['voteScore'] as num?)?.toInt() ?? 0,
        myVote: (json['myVote'] as num?)?.toInt() ?? 0,
      );
}

class CommunityTag {
  CommunityTag({required this.tag, required this.count});
  final String tag;
  final int count;

  factory CommunityTag.fromJson(Map<String, dynamic> json) => CommunityTag(
        tag: json['tag'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
