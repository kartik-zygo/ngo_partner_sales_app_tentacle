import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/community.dart';

class CommunityTheme {
  CommunityTheme._();
  static const Color accent = Color(0xFF6366F1);
  static const Color accent2 = Color(0xFFA855F7);
  static const LinearGradient gradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

String communityTimeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final l = dt.toLocal();
  return '${l.day} ${m[l.month]} ${l.year}';
}

String prettyTag(String slug) => slug
    .split('-')
    .map((w) => w.isEmpty ? w : (w.length <= 3 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}'))
    .join(' ');

class CommunityTagChip extends StatelessWidget {
  const CommunityTagChip({
    super.key,
    required this.tag,
    this.count,
    this.selected = false,
    this.onTap,
    this.small = false,
  });

  final String tag;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 11, vertical: small ? 4 : 7),
        decoration: BoxDecoration(
          color: selected ? CommunityTheme.accent : CommunityTheme.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? CommunityTheme.accent : CommunityTheme.accent.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          count != null ? '${prettyTag(tag)} · $count' : prettyTag(tag),
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : CommunityTheme.accent,
            fontWeight: FontWeight.w700,
            fontSize: small ? 9 : 11,
          ),
        ),
      ),
    );
  }
}

class CommunityAuthorBadge extends StatelessWidget {
  const CommunityAuthorBadge({super.key, required this.author, this.time, this.prefix});
  final CommunityAuthor author;
  final DateTime? time;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: author.isTeam
                ? const LinearGradient(colors: [AppColors.positive, Color(0xFF34D399)])
                : CommunityTheme.gradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(author.initial,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text('${prefix ?? ''}${author.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
        if (author.isTeam) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('TEAM',
                style: GoogleFonts.poppins(
                    color: AppColors.positive, fontWeight: FontWeight.w800, fontSize: 8)),
          ),
        ] else if (author.reputation > 0) ...[
          const SizedBox(width: 4),
          const Icon(Icons.bolt_rounded, size: 11, color: AppColors.warning),
          Text('${author.reputation}',
              style: GoogleFonts.poppins(
                  color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 9)),
        ],
        if (time != null) ...[
          const SizedBox(width: 6),
          Text('· ${communityTimeAgo(time)}',
              style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 9)),
        ],
      ],
    );
  }
}

class CommunityVoteControl extends StatelessWidget {
  const CommunityVoteControl({
    super.key,
    required this.score,
    required this.myVote,
    required this.onUp,
    required this.onDown,
  });

  final int score;
  final int myVote;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(Icons.keyboard_arrow_up_rounded, myVote == 1, onUp, CommunityTheme.accent),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('$score',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: myVote == 1
                    ? CommunityTheme.accent
                    : myVote == -1
                        ? AppColors.danger
                        : AppColors.charcoal,
              )),
        ),
        _arrow(Icons.keyboard_arrow_down_rounded, myVote == -1, onDown, AppColors.danger),
      ],
    );
  }

  Widget _arrow(IconData icon, bool active, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 20, color: active ? color : AppColors.muted),
      ),
    );
  }
}
