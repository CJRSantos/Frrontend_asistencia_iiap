import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceModel record;
  final bool showUserName;

  const AttendanceCard({
    super.key,
    required this.record,
    this.showUserName = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isCheckIn = record.type == AttendanceType.CHECK_IN;
    final typeColor = isCheckIn
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));
    final typeBg = isCheckIn
        ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.35) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7));

    // Formateo de fecha y hora
    final timeStr = _formatTime(record.timestamp);
    final dateStr = _formatDate(record.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono representativo
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: typeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
              color: typeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Detalles de la marca
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showUserName && record.userName != null) ...[
                  Text(
                    record.userName!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.type.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    if (record.markedByName != null) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.verified_user_outlined,
                        size: 12,
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF2D5E2A),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          record.markedByName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF2D5E2A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Badge de puntualidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 12,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                ),
                const SizedBox(width: 4),
                Text(
                  record.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $ampm';
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }
}
