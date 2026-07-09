import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _checkFirstLaunchAndNavigate();
  }

  Future<void> _checkFirstLaunchAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(AppConstants.firstLaunchKey) ?? true;
    final selectedLanguage = prefs.getString(AppConstants.languageKey);

    // Check if user is already logged in
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'user_token');

      if (token != null && token.isNotEmpty) {
        // User is logged in, go to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.dashboard);
        }
        return;
      }
    } catch (e) {
      // Continue to login if there's an error
    }

    if (isFirstLaunch || selectedLanguage == null) {
      // First launch - go to language selection
      Navigator.of(context).pushReplacementNamed(Routes.languageSelection);
    } else {
      // Go to simple login screen
      Navigator.of(context).pushReplacementNamed(Routes.simpleLogin);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.secondary,
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.agriculture,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // App Name
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 10),

                  // Tagline
                  Text(
                    'Smart Farming Assistant',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 50),

                  // AI Generated Logo Text
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.textOnPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Welcome',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1200.ms).scale(),

                  const SizedBox(height: 100),

                  // Loading Indicator
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                  ).animate().fadeIn(delay: 1500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
