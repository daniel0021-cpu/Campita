import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/enhanced_campus_map.dart';
import '../screens/favorites_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/profile_screen_redesigned.dart';

class ModernNavBar extends StatelessWidget {
  final int currentIndex;

  const ModernNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.grey[900]?.withAlpha(242) 
                : Colors.white.withAlpha(242),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withAlpha(26) 
                  : Colors.black.withAlpha(20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 128 : 31),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 77 : 13),
                blurRadius: 40,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navItem(context, Icons.explore_rounded, 0),
              _navItem(context, Icons.favorite_rounded, 1),
              _navItem(context, Icons.workspace_premium_rounded, 2),
              _navItem(context, Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, int index) {
    final selected = currentIndex == index;
    final labels = ['Home', 'Saved', 'Pro', 'Me'];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: selected ? 95 : 50,
      child: _AnimatedNavButton(
        selected: selected,
        onTap: () {
          if (index == currentIndex) return;
          
          Widget destination;
          switch (index) {
            case 0:
              destination = const EnhancedCampusMap();
              break;
            case 1:
              destination = const FavoritesScreen();
              break;
            case 2:
              destination = const SubscriptionScreen();
              break;
            case 3:
              destination = const ProfileScreenRedesigned();
              break;
            default:
              return;
          }
          
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => destination,
              transitionDuration: const Duration(milliseconds: 450),
              reverseTransitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                  reverseCurve: Curves.easeInQuart,
                );
                
                final secondaryCurve = CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeOutQuart,
                );

                return Stack(
                  children: [
                    // Exiting screen with depth
                    if (secondaryAnimation.status != AnimationStatus.dismissed)
                      Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..scale(1.0 - (0.05 * secondaryCurve.value), 1.0 - (0.05 * secondaryCurve.value), 1.0),
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: 1.0 - (0.3 * secondaryCurve.value),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    // Entering screen with spring
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..scale(0.94 + (0.06 * curvedAnimation.value), 0.94 + (0.06 * curvedAnimation.value), 1.0),
                      alignment: Alignment.center,
                      child: FadeTransition(
                        opacity: curvedAnimation,
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.grey.withAlpha(153),
                  size: selected ? 23 : 20,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                clipBehavior: Clip.hardEdge,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  const _AnimatedNavButton({
    required this.child,
    required this.onTap,
    required this.selected,
  });

  @override
  State<_AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<_AnimatedNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        setState(() => _scale = 0.92);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _scale = 1.0);
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: widget.selected ? 3 : 1),
          padding: EdgeInsets.only(
            top: 9,
            bottom: 9,
            left: widget.selected ? 12 : 8,
            right: widget.selected ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primary.withAlpha(36)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: widget.selected
                ? Border.all(
                    color: AppColors.primary.withAlpha(89),
                    width: 1.2,
                  )
                : null,
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(46),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withAlpha(26),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

