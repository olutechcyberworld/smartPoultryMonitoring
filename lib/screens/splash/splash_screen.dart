import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poultri_sense/providers/device_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await ref.read(deviceProvider.notifier).initialize();

    if (!mounted) return;

    final deviceState = ref.read(deviceProvider);
    if (deviceState.isSetupComplete) {
      context.go('/shell/dashboard');
    } else {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, size: 64),
            SizedBox(height: screenHeight * 0.03),
            const Text(
              'PoultriSense',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: screenHeight * 0.06),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}