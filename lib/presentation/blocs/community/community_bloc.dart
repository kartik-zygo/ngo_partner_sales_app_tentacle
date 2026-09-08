import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/community.dart';
import '../../../domain/usecases/community_usecases.dart';

part 'community_event.dart';
part 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  CommunityBloc({
    required GetCommunityPostsUseCase getPosts,
    required GetCommunityTagsUseCase getTags,
  })  : _getPosts = getPosts,
        _getTags = getTags,
        super(const CommunityState()) {
    on<CommunityLoaded>(_onLoaded);
    on<CommunitySortChanged>(_onSortChanged);
    on<CommunityTagSelected>(_onTagSelected);
    on<CommunitySearchChanged>(_onSearchChanged);
  }

  final GetCommunityPostsUseCase _getPosts;
  final GetCommunityTagsUseCase _getTags;

  Future<void> _reload(Emitter<CommunityState> emit) async {
    emit(state.copyWith(status: CommunityStatus.loading));
    try {
      final posts = await _getPosts(
        sort: state.sort,
        tag: state.tag,
        search: state.search.isEmpty ? null : state.search,
        limit: 50,
      );
      var tags = state.tags;
      if (tags.isEmpty) {
        try {
          tags = await _getTags();
        } catch (_) {}
      }
      emit(state.copyWith(status: CommunityStatus.success, posts: posts, tags: tags));
    } catch (e) {
      emit(state.copyWith(
        status: CommunityStatus.failure,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onLoaded(CommunityLoaded event, Emitter<CommunityState> emit) =>
      _reload(emit);

  Future<void> _onSortChanged(
      CommunitySortChanged event, Emitter<CommunityState> emit) async {
    if (event.sort == state.sort) return;
    emit(state.copyWith(sort: event.sort));
    await _reload(emit);
  }

  Future<void> _onTagSelected(
      CommunityTagSelected event, Emitter<CommunityState> emit) async {
    final next = state.tag == event.tag ? null : event.tag;
    emit(state.copyWith(tag: next, clearTag: next == null));
    await _reload(emit);
  }

  Future<void> _onSearchChanged(
      CommunitySearchChanged event, Emitter<CommunityState> emit) async {
    emit(state.copyWith(search: event.query));
    await _reload(emit);
  }
}
