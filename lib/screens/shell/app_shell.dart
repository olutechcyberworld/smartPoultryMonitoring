import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({required this.child, super.key});

  static const _tabs = [
    '/shell/dashboard',
    '/shell/live',
    '/shell/sensors',
    '/shell/events',
    '/shell/history',
    '/shell/about',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => context.go(_tabs[index]),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined), label: 'Live'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Sensors'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined), label: 'Events'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.info_outline), label: 'About'),
        ],
      ),
    );
  }
}