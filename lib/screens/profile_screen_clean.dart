import 'package:flutter/material.dart';
import 'profile_screen_redesigned.dart';

/// Profile Screen Redirect
/// This file now redirects to the completely redesigned ProfileScreenRedesigned
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically navigate to redesigned profile screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreenRedesigned()),
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
