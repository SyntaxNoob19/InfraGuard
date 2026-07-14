import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

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
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _startSequence();
  }

  Future<void> _startSequence() async {
    final startTime = DateTime.now();

    // Perform API check
    await _checkBackend();

    // Ensure minimum 4.5 seconds duration to enjoy the splash
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 4500) {
      await Future.delayed(Duration(milliseconds: 4500 - elapsed.inMilliseconds));
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  Future<bool> _checkBackend() async {
    final apiService = ApiService();
    try {
      final state = await apiService.fetchStatus();
      return state != null;
    } catch (_) {
      return false;
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
      backgroundColor: const Color(0xFF030A14), // Deep dark tech background
      body: Stack(
        children: [
          // Optional Background image (cityscape/globe) if the user provides it
          // Otherwise, we just use the dark background color.
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/splash screen.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(), // Fallback if no bg image
              ),
            ),
          ),

          // Main Content
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    
                    // Logo Image
                    Image.asset(
                      'assets/logo.png',
                      height: 160,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.security_rounded,
                          size: 100,
                          color: AppTheme.blue,
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // InfraGuard Title
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Infra',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              fontFamily: 'Inter',
                            ),
                          ),
                          TextSpan(
                            text: 'Guard',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007BFF), // Vibrant Blue
                              letterSpacing: 1.2,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Subtitle 1
                    const Text(
                      'ZERO TRUST. REAL-TIME PROTECTION.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8896AB),
                        letterSpacing: 2.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Divider with glowing shield
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.blue.withAlpha(150),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.blue.withAlpha(100),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.blue.withAlpha(50),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: AppTheme.blue,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.blue.withAlpha(150),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Subtitle 2
                    const Text(
                      'RUNTIME SECURITY PROXY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8896AB),
                        letterSpacing: 4.0,
                      ),
                    ),
                    
                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfraGuardLogo extends StatelessWidget {
  final double size;
  const InfraGuardLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.3,
      height: size,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Main Shield
          Icon(
            Icons.security_rounded,
            size: size,
            color: const Color(0xFF007BFF), // Vibrant Blue
          ),
          
          // Pixels dissolving to the right
          ..._buildPixels(size),
        ],
      ),
    );
  }

  List<Widget> _buildPixels(double size) {
    final List<Widget> pixels = [];
    final double pxSize = size * 0.08;
    final double startX = size * 0.7; // Start on the right side of the shield
    
    // Pattern of dissolving pixels
    final points = [
      const Offset(0, -0.3),
      const Offset(0.1, -0.1),
      const Offset(0.2, 0.2),
      const Offset(0.3, -0.4),
      const Offset(0.15, 0.4),
      const Offset(0.35, 0.05),
      const Offset(0.45, 0.3),
      const Offset(0.25, -0.2),
      const Offset(0.4, -0.15),
    ];

    for (int i = 0; i < points.length; i++) {
      pixels.add(
        Positioned(
          left: startX + (points[i].dx * size),
          top: (size / 2) + (points[i].dy * size) - (pxSize / 2),
          child: Container(
            width: pxSize * (0.5 + (i % 3) * 0.3),
            height: pxSize * (0.5 + (i % 3) * 0.3),
            decoration: BoxDecoration(
              color: const Color(0xFF007BFF).withAlpha(255 - (i * 20)),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    }
    return pixels;
  }
}

