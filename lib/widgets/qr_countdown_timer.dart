import 'dart:async';
import 'package:flutter/material.dart';

class QrCountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback onExpired;

  const QrCountdownTimer({
    super.key,
    required this.expiresAt,
    required this.onExpired,
  });

  @override
  State<QrCountdownTimer> createState() => _QrCountdownTimerState();
}

class _QrCountdownTimerState extends State<QrCountdownTimer> {
  Timer? _timer;
  int _secondsLeft = 0;
  static const int totalSeconds = 300; // 5 minutos

  @override
  void initState() {
    super.initState();
    _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calcRemaining());
  }

  void _calcRemaining() {
    final now = DateTime.now();
    final diff = widget.expiresAt.difference(now).inSeconds;
    if (diff <= 0) {
      if (mounted) {
        setState(() => _secondsLeft = 0);
      }
      _timer?.cancel();
      widget.onExpired();
    } else {
      if (mounted) {
        setState(() => _secondsLeft = diff);
      }
    }
  }

  @override
  void didUpdateWidget(covariant QrCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _calcRemaining();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calcRemaining());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final progress = (_secondsLeft / totalSeconds).clamp(0.0, 1.0);
    final color = _secondsLeft > 60
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A))
        : (_secondsLeft > 20 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              'Tiempo restante: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
