import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

enum NodeStatus {
  completed,
  active,
  locked,
}

class TactileLessonNode extends StatefulWidget {
  final int lessonNumber;
  final String title;
  final NodeStatus status;
  final VoidCallback onTap;
  final String? speechBubbleText;
  final double size;

  const TactileLessonNode({
    super.key,
    required this.lessonNumber,
    required this.title,
    required this.status,
    required this.onTap,
    this.speechBubbleText,
    this.size = 76.0,
  });

  @override
  State<TactileLessonNode> createState() => _TactileLessonNodeState();
}

class _TactileLessonNodeState extends State<TactileLessonNode> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == NodeStatus.active) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TactileLessonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == NodeStatus.active && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.status != NodeStatus.active && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  (Color bg, Color dark, IconData icon, Color iconColor) _getNodeVisuals(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (widget.status) {
      case NodeStatus.completed:
        return (
          AppColors.duoGold,
          AppColors.duoGoldDark,
          Icons.check_rounded,
          Colors.white,
        );
      case NodeStatus.active:
        return (
          AppColors.duoGreen,
          AppColors.duoGreenDark,
          Icons.star_rounded,
          Colors.white,
        );
      case NodeStatus.locked:
        return isDark
            ? (
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
                Icons.lock_rounded,
                const Color(0xFF64748B),
              )
            : (
                AppColors.duoGreyLight,
                AppColors.duoGrey,
                Icons.lock_rounded,
                AppColors.duoGreyDark,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, darkColor, iconData, iconColor) = _getNodeVisuals(context);
    const elevation = 6.0;
    final currentElevation = _isPressed ? 0.0 : elevation;
    final topMargin = _isPressed ? elevation : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bulle de dialogue animée Coach Sarah au-dessus du nœud actif
        if (widget.status == NodeStatus.active) ...[
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.duoGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.duoGreen.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    widget.speechBubbleText ?? 'COMMENCER !',
                    style: const TextStyle(
                      color: AppColors.duoGreenDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Nœud 3D tactile circulaire
        GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            margin: EdgeInsets.only(top: topMargin),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: widget.status == NodeStatus.locked
                  ? Border.all(color: AppColors.duoGreyDark, width: 2)
                  : null,
              boxShadow: currentElevation > 0
                  ? [
                      BoxShadow(
                        color: darkColor,
                        offset: Offset(0, currentElevation),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                      if (widget.status == NodeStatus.active)
                        BoxShadow(
                          color: AppColors.duoGreen.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Reflet intérieur Duolingo
                Positioned(
                  top: 6,
                  child: Container(
                    width: widget.size * 0.55,
                    height: widget.size * 0.22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Icon(
                  iconData,
                  size: widget.size * 0.48,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Étoiles de complétion si terminé
        if (widget.status == NodeStatus.completed) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.star_rounded, size: 16, color: AppColors.duoGold),
              Icon(Icons.star_rounded, size: 20, color: AppColors.duoGold),
              Icon(Icons.star_rounded, size: 16, color: AppColors.duoGold),
            ],
          ),
        ] else ...[
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}
