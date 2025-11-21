import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/enhanced_campus_map.dart';
import 'screens/onboarding_screen.dart';
import 'screens/events_screen.dart';
import 'screens/developer_login_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'theme/app_theme.dart';
import 'utils/app_settings.dart';
import 'screens/live_navigation_screen.dart';
import 'package:latlong2/latlong.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimize system UI for performance
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Enable smooth animations on all platforms
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  runApp(const CampusNavigationApp());
}

class CampusNavigationApp extends StatelessWidget {
  const CampusNavigationApp({super.key});

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.darkMode,
      builder: (_, isDark, __) {
        return MaterialApp(
          title: 'Igbinedion University Campus Navigation',
          debugShowCheckedModeBanner: false,
          routes: {
            '/developer_login': (ctx) => const DeveloperLoginScreen(),
            '/admin_panel': (ctx) => const AdminPanelScreen(),
            '/events': (ctx) => const EventsScreen(),
            '/live-navigation': (ctx) {
              final args = ModalRoute.of(ctx)!.settings.arguments as Map?;
              if (args == null) return const Scaffold(body: Center(child: Text('Missing route data')));
              return LiveNavigationScreen(
                routePoints: (args['points'] as List).cast<LatLng>(),
                destination: args['end'] as LatLng,
                transportMode: args['mode'] as String,
              );
            },
          },
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: FutureBuilder<bool>(
            future: _checkOnboarding(),
            builder: (context, snapshot) {
              // Don't show loading - HTML splash handles it
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              return snapshot.data == true 
                ? const EnhancedCampusMap() 
                : const OnboardingScreen();
            },
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);
    _controller.forward();

    // Show splash for 2 seconds total
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        // Check if onboarding completed
        final prefs = await SharedPreferences.getInstance();
        final onboardingComplete = prefs.getBool('onboarding_completed') ?? false;
        
        final nextScreen = onboardingComplete ? const EnhancedCampusMap() : const OnboardingScreen();
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Instant transition - no fade to prevent blue screen
              return child;
            },
          ),
        );
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
    return Container(
      color: AppColors.primary,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on, size: 72, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Igbinedion University',
                      style: AppTextStyles.heading1.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Campus Navigation',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
