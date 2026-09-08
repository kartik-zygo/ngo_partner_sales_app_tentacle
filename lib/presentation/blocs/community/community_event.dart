part of 'community_bloc.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();
  @override
  List<Object?> get props => [];
}

class CommunityLoaded extends CommunityEvent {
  const CommunityLoaded();
}

class CommunitySortChanged extends CommunityEvent {
  const CommunitySortChanged(this.sort);
  final String sort;
  @override
  List<Object?> get props => [sort];
}

class CommunityTagSelected extends CommunityEvent {
  const CommunityTagSelected(this.tag);
  final String tag;
  @override
  List<Object?> get props => [tag];
}

class CommunitySearchChanged extends CommunityEvent {
  const CommunitySearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}
