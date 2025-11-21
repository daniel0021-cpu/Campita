import 'package:flutter/material.dart';

/// Ultra-smooth page transitions optimized for 60fps
/// Uses GPU-accelerated Transform widgets and optimized timing curves
class PageTransitions {
  /// Smooth fade with subtle scale (default, fastest)
  static Route<T> fadeRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.25, 0.1, 0.25, 1.0),
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 225),
    );
  }

  /// Slide from right with fade overlay
  static Route<T> slideRightRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.25, 0.1, 0.25, 1.0),
        );
        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.7, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 225),
    );
  }

  /// Slide from bottom (for modals)
  static Route<T> slideUpRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.19, 1.0, 0.22, 1.0), // Bouncy
        );
        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 240),
    );
  }

  /// Scale transition with fade
  static Route<T> scaleRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.25, 0.1, 0.25, 1.0),
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 225),
    );
  }

  /// Combined slide and fade (shared axis)
  static Route<T> slideFadeRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.25, 0.1, 0.25, 1.0),
            )),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 260),
    );
  }

  /// Rotation + Fade transition (for special effects)
  static Route<T> rotationRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 375),
    );
  }

  /// No transition (instant - for performance)
  static Route<T> noTransitionRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      transitionDuration: Duration.zero,
    );
  }
}

