import 'package:flutter/material.dart';

class ExpandingDotsIndicator extends StatelessWidget {
  final int currentPage;
  final int count;
  final Color activeColor;
  final Color inactiveColor;
  final double dotHeight;
  final double dotWidth;
  final double expandedWidth;
  final Duration duration;
  final Curve curve;

  const ExpandingDotsIndicator({
    super.key,
    required this.currentPage,
    required this.count,
    this.activeColor = Colors.black,
    this.inactiveColor = const Color(0xFFBDBDBD),
    this.dotHeight = 10,
    this.dotWidth = 10,
    this.expandedWidth = 32,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: dotHeight + 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == currentPage;
          return AnimatedContainer(
            duration: duration,
            curve: curve,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? expandedWidth : dotWidth,
            height: dotHeight,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(dotHeight),
            ),
          );
        }),
      ),
    );
  }
}
