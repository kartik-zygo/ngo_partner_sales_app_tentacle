import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_primitives.dart';
import '../../../domain/entities/community.dart';
import '../../../injection_container.dart';
import '../../blocs/community/community_bloc.dart';
import 'community_post_moderation_detail_page.dart';
import 'community_ui.dart';

/// Staff console for the NGO Community Hub — browse, answer (as Team) and
/// moderate questions & discussions posted by NGOs.
class CommunityModerationPage extends StatelessWidget {
  const CommunityModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunityBloc>(
      create: (_) => sl<CommunityBloc>()..add(const CommunityLoaded()),
      child: const _CommunityModerationView(),
    );
  }
}

class _CommunityModerationView extends StatefulWidget {
  const _CommunityModerationView();

  @override
  State<_CommunityModerationView> createState() => _CommunityModerationViewState();
}

class _CommunityModerationViewState extends State<_CommunityModerationView> {
  final _searchCtrl = TextEditingController();

  static const _sorts = [
    ('newest', 'New'),
    ('top', 'Top'),
    ('unanswered', 'Unanswered'),
    ('active', 'Active'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _open(CommunityPost post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CommunityPostModerationDetailPage(post: post),
      ),
    );
    if (changed == true && mounted) {
      context.read<CommunityBloc>().add(const CommunityLoaded());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        title: Text('Community Hub',
            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppColors.charcoal)),
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildSortBar(),
          Expanded(
            child: BlocBuilder<CommunityBloc, CommunityState>(
              builder: (context, state) {
                return RefreshIndicator(
                  color: CommunityTheme.accent,
                  onRefresh: () async =>
                      context.read<CommunityBloc>().add(const CommunityLoaded()),
                  child: _buildList(state),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EC)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.poppins(fontSize: 13),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search posts',
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                onSubmitted: (v) => context
                    .read<CommunityBloc>()
                    .add(CommunitySearchChanged(v.trim())),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  context.read<CommunityBloc>().add(const CommunitySearchChanged(''));
                  setState(() {});
                },
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBar() {
    return BlocBuilder<CommunityBloc, CommunityState>(
      buildWhen: (a, b) => a.sort != b.sort || a.tags != b.tags || a.tag != b.tag,
      builder: (context, state) {
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: _sorts.map((s) {
                  final selected = state.sort == s.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          context.read<CommunityBloc>().add(CommunitySortChanged(s.$1)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected ? CommunityTheme.gradient : null,
                          color: selected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? Colors.transparent : const Color(0xFFE6E8EC),
                          ),
                        ),
                        child: Text(s.$2,
                            style: GoogleFonts.poppins(
                              color: selected ? Colors.white : AppColors.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (state.tags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: state.tags.take(15).map((t) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CommunityTagChip(
                        tag: t.tag,
                        count: t.count,
                        selected: state.tag == t.tag,
                        onTap: () => context
                            .read<CommunityBloc>()
                            .add(CommunityTagSelected(t.tag)),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildList(CommunityState state) {
    if (state.status == CommunityStatus.loading && state.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: CommunityTheme.accent));
    }
    if (state.status == CommunityStatus.failure && state.posts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          EmptyStateView(
            title: 'Couldn\'t load the community',
            subtitle: state.error ?? 'Pull to refresh and try again.',
          ),
        ],
      );
    }
    if (state.posts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          EmptyStateView(
            title: 'No posts yet',
            subtitle: 'NGO questions & discussions will appear here.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.posts.length,
      itemBuilder: (context, i) {
        final post = state.posts[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StaggerItem(index: i, child: _PostCard(post: post, onTap: () => _open(post))),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});
  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!post.isQuestion)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 1),
                    child: Icon(Icons.forum_outlined, size: 15, color: CommunityTheme.accent2),
                  ),
                Expanded(
                  child: Text(post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.charcoal)),
                ),
                if (post.isResolved) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, size: 17, color: AppColors.positive),
                ],
                if (post.isClosed) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.danger),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12, height: 1.4, color: AppColors.muted)),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: post.tags.take(4).map((t) => CommunityTagChip(tag: t, small: true)).toList()),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _stat(Icons.arrow_upward_rounded, '${post.voteScore}', post.voteScore > 0 ? CommunityTheme.accent : AppColors.muted),
                const SizedBox(width: 12),
                _stat(Icons.forum_outlined, '${post.answerCount}', post.answerCount > 0 ? AppColors.positive : AppColors.muted),
                const SizedBox(width: 12),
                _stat(Icons.visibility_outlined, '${post.viewCount}', AppColors.muted),
                const Spacer(),
                Flexible(child: CommunityAuthorBadge(author: post.author, time: post.createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(value, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}
