// Performance optimization utilities for ultra-smooth app experience
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PerformanceConfig {
  // Animation durations optimized for smoothness
  static const Duration ultraFast = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Premium curves for butter-smooth animations
  static const Curve premiumCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve smoothCurve = Cubic(0.25, 0.8, 0.25, 1);
  static const Curve elasticCurve = Cubic(0.68, -0.6, 0.32, 1.6);
  
  // Repaint boundaries for widgets that don't change often
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }
  
  // Force immediate frame scheduling for instant response
  static void scheduleFrame() {
    SchedulerBinding.instance.scheduleFrame();
  }
  
  // Reduce rebuild scope with const constructors where possible
  static bool get isReleaseMode => const bool.fromEnvironment('dart.vm.product');
}

// Mixin for adding advanced animations to any widget
mixin AdvancedAnimations<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController smoothController;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  
  void initSmoothAnimations({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    smoothController = AnimationController(
      duration: duration,
      vsync: this,
    );
    
    scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: smoothController,
      curve: curve,
    ));
    
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: smoothController,
      curve: curve,
    ));
    
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: smoothController,
      curve: curve,
    ));
    
    smoothController.forward();
  }
  
  void disposeSmoothAnimations() {
    smoothController.dispose();
  }
}

// Premium button with advanced animations
class PremiumButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  
  const PremiumButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.borderRadius,
  });
  
  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PerformanceConfig.ultraFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: PerformanceConfig.premiumCurve),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
  
  void _onTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (widget.backgroundColor ?? Colors.blue).withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Smooth list item with staggered animation
class SmoothListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  
  const SmoothListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
  });
  
  @override
  State<SmoothListItem> createState() => _SmoothListItemState();
}

class _SmoothListItemState extends State<SmoothListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PerformanceConfig.fast,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: PerformanceConfig.premiumCurve),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: PerformanceConfig.smoothCurve),
    );
    
    // Staggered animation
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

