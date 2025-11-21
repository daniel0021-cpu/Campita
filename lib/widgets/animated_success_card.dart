import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';

/// Shows an animated success card with custom curved background
void showAnimatedSuccess(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle,
  Duration duration = const Duration(seconds: 3),
  Color? iconColor,
  Color? backgroundColor,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _AnimatedSuccessCard(
      message: message,
      icon: icon,
      duration: duration,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      onDismiss: () => overlayEntry.remove(),
    ),
  );

  overlay.insert(overlayEntry);
}

class _AnimatedSuccessCard extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback onDismiss;

  const _AnimatedSuccessCard({
    required this.message,
    required this.icon,
    required this.duration,
    this.iconColor,
    this.backgroundColor,
    required this.onDismiss,
  });

  @override
  State<_AnimatedSuccessCard> createState() => _AnimatedSuccessCardState();
}

class _AnimatedSuccessCardState extends State<_AnimatedSuccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Slide up from bottom with elastic bounce
    _slideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Scale with bounce effect
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    // Fade in smoothly
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Start animation
    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final defaultIconColor = AppColors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          bottom: 80 + _slideAnimation.value,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: CustomPaint(
              painter: _CurvedBackgroundPainter(
                color: widget.backgroundColor ?? defaultBgColor,
                isDark: isDark,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icon with gradient background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.iconColor ?? defaultIconColor,
                            (widget.iconColor ?? defaultIconColor)
                                .withAlpha(179),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (widget.iconColor ?? defaultIconColor)
                                .withAlpha(77),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Message text
                    Expanded(
                      child: Text(
                        widget.message,
                        style: AppTextStyles.notification.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for curved background with shadow
class _CurvedBackgroundPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _CurvedBackgroundPainter({
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(isDark ? 242 : 250)
      ..style = PaintingStyle.fill;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final shadowPath = Path()
      ..moveTo(0, 8)
      ..lineTo(0, size.height - 8)
      ..quadraticBezierTo(0, size.height, 8, size.height)
      ..lineTo(size.width - 8, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - 8)
      ..lineTo(size.width, 8)
      ..quadraticBezierTo(size.width, 0, size.width - 8, 0)
      ..lineTo(8, 0)
      ..quadraticBezierTo(0, 0, 0, 8)
      ..close();

    canvas.drawPath(shadowPath.shift(const Offset(0, 2)), shadowPaint);

    // Draw main curved background
    final path = Path()
      ..moveTo(0, 8)
      ..lineTo(0, size.height - 8)
      ..quadraticBezierTo(0, size.height, 8, size.height)
      ..lineTo(size.width - 8, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - 8)
      ..lineTo(size.width, 8)
      ..quadraticBezierTo(size.width, 0, size.width - 8, 0)
      ..lineTo(8, 0)
      ..quadraticBezierTo(0, 0, 0, 8)
      ..close();

    canvas.drawPath(path, paint);

    // Add subtle border
    final borderPaint = Paint()
      ..color = isDark
          ? Colors.white.withAlpha(26)
          : Colors.black.withAlpha(13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_CurvedBackgroundPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
