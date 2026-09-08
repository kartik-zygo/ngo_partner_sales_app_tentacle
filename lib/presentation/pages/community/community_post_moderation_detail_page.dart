import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/community.dart';
import '../../../domain/usecases/community_usecases.dart';
import 'community_ui.dart';

/// Staff view of a community thread: read, answer (with TEAM badge), vote,
/// and moderate (delete posts/answers, close/reopen the thread).
class CommunityPostModerationDetailPage extends StatefulWidget {
  const CommunityPostModerationDetailPage({super.key, required this.post});
  final CommunityPost post;

  @override
  State<CommunityPostModerationDetailPage> createState() =>
      _CommunityPostModerationDetailPageState();
}

class _CommunityPostModerationDetailPageState
    extends State<CommunityPostModerationDetailPage> {
  final _getPost = GetIt.instance<GetCommunityPostUseCase>();
  final _addAnswer = GetIt.instance<AddCommunityAnswerUseCase>();
  final _votePost = GetIt.instance<VoteCommunityPostUseCase>();
  final _voteAnswer = GetIt.instance<VoteCommunityAnswerUseCase>();
  final _deletePost = GetIt.instance<DeleteCommunityPostUseCase>();
  final _deleteAnswer = GetIt.instance<DeleteCommunityAnswerUseCase>();
  final _setClosed = GetIt.instance<SetCommunityPostClosedUseCase>();

  final _answerCtrl = TextEditingController();
  late CommunityPost _post;
  bool _loading = true;
  bool _posting = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await _getPost(_post.id);
      if (!mounted) return;
      setState(() => _post = fresh);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onVotePost(int desired) async {
    try {
      final r = await _votePost(_post.id, _post.myVote == desired ? 0 : desired);
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(voteScore: r.voteScore, myVote: r.myVote);
        _changed = true;
      });
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _onVoteAnswer(CommunityAnswer a, int desired) async {
    try {
      final r = await _voteAnswer(a.id, a.myVote == desired ? 0 : desired);
      if (!mounted) return;
      setState(() {
        _post = _replaceAnswer(a.copyWith(voteScore: r.voteScore, myVote: r.myVote));
        _changed = true;
      });
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.length < 2 || _posting) return;
    FocusScope.of(context).unfocus();
    setState(() => _posting = true);
    try {
      await _addAnswer(_post.id, text);
      _answerCtrl.clear();
      final fresh = await _getPost(_post.id);
      if (!mounted) return;
      setState(() {
        _post = fresh;
        _changed = true;
      });
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleClosed() async {
    try {
      final fresh = await _setClosed(_post.id, !_post.isClosed);
      if (!mounted) return;
      setState(() {
        _post = fresh;
        _changed = true;
      });
      _snack(_post.isClosed ? 'Thread closed' : 'Thread reopened', error: false);
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _confirmDeletePost() async {
    final ok = await _confirm('Delete this post?',
        'This removes the question/discussion and all its answers for everyone.');
    if (ok != true) return;
    try {
      await _deletePost(_post.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _confirmDeleteAnswer(CommunityAnswer a) async {
    final ok = await _confirm('Delete this answer?', 'This cannot be undone.');
    if (ok != true) return;
    try {
      await _deleteAnswer(a.id);
      final fresh = await _getPost(_post.id);
      if (!mounted) return;
      setState(() {
        _post = fresh;
        _changed = true;
      });
    } catch (e) {
      _snack(e);
    }
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(body, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  CommunityPost _replaceAnswer(CommunityAnswer updated) {
    final answers = _post.answers.map((a) => a.id == updated.id ? updated : a).toList();
    return CommunityPost(
      id: _post.id, title: _post.title, body: _post.body, postType: _post.postType,
      tags: _post.tags, viewCount: _post.viewCount, voteScore: _post.voteScore,
      answerCount: _post.answerCount, acceptedAnswerId: _post.acceptedAnswerId,
      isResolved: _post.isResolved, isClosed: _post.isClosed, author: _post.author,
      myVote: _post.myVote, createdAt: _post.createdAt, answers: answers,
    );
  }

  void _snack(Object e, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
      backgroundColor: error ? AppColors.danger : AppColors.positive,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          title: Text(_post.isQuestion ? 'Question' : 'Discussion',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.charcoal)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'close') _toggleClosed();
                if (v == 'delete') _confirmDeletePost();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'close',
                  child: Text(_post.isClosed ? 'Reopen thread' : 'Close thread'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete post')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: CommunityTheme.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      color: CommunityTheme.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _questionCard(),
          const SizedBox(height: 16),
          Text(
            '${_post.answers.length} ${_post.isQuestion ? (_post.answers.length == 1 ? 'Answer' : 'Answers') : (_post.answers.length == 1 ? 'Reply' : 'Replies')}',
            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppColors.charcoal),
          ),
          const SizedBox(height: 10),
          ..._post.answers.map(_answerCard),
          if (_post.answers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No answers yet — be the first to respond as Team.',
                    style: GoogleFonts.poppins(color: AppColors.muted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? border, Gradient? gradient}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? const Color(0xFFE6E8EC)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }

  Widget _questionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_post.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.charcoal)),
              ),
              if (_post.isClosed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('CLOSED', style: GoogleFonts.poppins(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 9)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityVoteControl(
                score: _post.voteScore,
                myVote: _post.myVote,
                onUp: () => _onVotePost(1),
                onDown: () => _onVotePost(-1),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(_post.body, style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: AppColors.charcoal))),
            ],
          ),
          if (_post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: _post.tags.map((t) => CommunityTagChip(tag: t, small: true)).toList()),
          ],
          const Divider(height: 26),
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text('${_post.viewCount}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted)),
              const Spacer(),
              Flexible(child: CommunityAuthorBadge(author: _post.author, time: _post.createdAt, prefix: 'Asked by ')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerCard(CommunityAnswer a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        gradient: a.isAccepted
            ? const LinearGradient(colors: [Color(0xFFECFDF5), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        border: a.isAccepted ? AppColors.positive.withValues(alpha: 0.5) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.isAccepted)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.verified_rounded, size: 15, color: AppColors.positive),
                  const SizedBox(width: 5),
                  Text('Accepted solution', style: GoogleFonts.poppins(color: AppColors.positive, fontWeight: FontWeight.w800, fontSize: 11)),
                ]),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommunityVoteControl(
                  score: a.voteScore,
                  myVote: a.myVote,
                  onUp: () => _onVoteAnswer(a, 1),
                  onDown: () => _onVoteAnswer(a, -1),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(a.body, style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: AppColors.charcoal))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _confirmDeleteAnswer(a),
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text('Remove', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.danger.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Spacer(),
                Flexible(child: CommunityAuthorBadge(author: a.author, time: a.createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    if (_post.isClosed) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
        child: Text('This thread is closed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 12)),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E8EC))),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _answerCtrl,
                minLines: 1,
                maxLines: 5,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Answer as Team…',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _answerCtrl.text.trim().length >= 2 && !_posting ? _submitAnswer : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: _answerCtrl.text.trim().length >= 2 && !_posting ? CommunityTheme.gradient : null,
                color: _answerCtrl.text.trim().length >= 2 && !_posting ? null : AppColors.muted.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _posting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
