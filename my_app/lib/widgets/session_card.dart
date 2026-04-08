import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../theme/app_theme.dart';

/// Summary card shown in the history list and the dashboard.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.showDate = true,
  });

  final Session session;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final score = session.score;
    final color = score != null ? AppTheme.scoreColor(score.total) : AppTheme.textMuted;
    final timeStr = DateFormat('HH:mm').format(session.startTime);
    final dateStr = DateFormat('EEE d MMM').format(session.startTime);
    final dur = session.actualDuration;
    final durStr = '${dur.inMinutes} min';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            // Score badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(80), width: 1.5),
              ),
              child: Center(
                child: Text(
                  score != null ? score.total.toStringAsFixed(0) : '—',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.name,
                      style: AppTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(session.location,
                            style: AppTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (showDate) ...[
                        Text(dateStr, style: AppTheme.labelSmall),
                        const SizedBox(width: 6),
                        Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                                color: AppTheme.textMuted,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                      ],
                      Text(timeStr, style: AppTheme.labelSmall),
                      const SizedBox(width: 6),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                              color: AppTheme.textMuted, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(durStr, style: AppTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            // Grade chip
            if (score != null) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      score.grade,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(score.label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
