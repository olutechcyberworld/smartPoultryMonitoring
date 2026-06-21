import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Branded splash stays visible for at least this long, independent of
  // how fast SharedPreferences read completes. Native splash (main.dart)
  // already covers the "instant open" requirement — this covers the hold.
  static const _minDisplayDuration = Duration(seconds: 9);

  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _brandFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
          ),
        );
    _brandFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );
    _controller.forward();

    _initialize();
  }

  Future<void> _initialize() async {
    final initFuture = ref.read(deviceProvider.notifier).initialize();
    final holdFuture = Future.delayed(_minDisplayDuration);

    // Navigation waits for whichever finishes last — init or the hold timer.
    await Future.wait([initFuture, holdFuture]);

    if (!mounted) return;

    final deviceState = ref.read(deviceProvider);
    if (deviceState.isSetupComplete) {
      context.go('/shell/dashboard');
    } else {
      context.go('/setup');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icon/icon_foreground.png',
                        width: screenWidth * 0.32,
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      SlideTransition(
                        position: _textSlide,
                        child: Text(
                          'PoultriSense',
                          style: TextStyle(
                            fontSize: screenWidth * 0.075,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      SlideTransition(
                        position: _textSlide,
                        child: Text(
                          'Smart Poultry Environmental Monitoring',
                          style: TextStyle(
                            fontSize: screenWidth * 0.032,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Brand credit — fades in last ─────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.045),
              child: FadeTransition(
                opacity: _brandFade,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/brand_logo.png',
                      height: screenHeight * 0.038,
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Developed by',
                          style: TextStyle(
                            fontSize: screenWidth * 0.026,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Olutech Cyberworld',
                          style: TextStyle(
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
