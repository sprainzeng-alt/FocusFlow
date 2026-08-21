import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentIndex,
    required this.child,
    super.key,
    this.floatingActionButton,
    this.navigationLocked = false,
    this.onLockedNavigationAttempt,
  });

  final int currentIndex;
  final Widget child;
  final Widget? floatingActionButton;
  final bool navigationLocked;
  final VoidCallback? onLockedNavigationAttempt;

  static const _routes = ['/', '/tasks', '/focus', '/statistics', '/search'];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !navigationLocked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationLocked) {
          onLockedNavigationAttempt?.call();
        }
      },
      child: Scaffold(
        body: SafeArea(child: child),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (navigationLocked && index != currentIndex) {
              onLockedNavigationAttempt?.call();
              return;
            }
            context.go(_routes[index]);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
            NavigationDestination(icon: Icon(Icons.checklist), label: '任务'),
            NavigationDestination(
                icon: Icon(Icons.timer_outlined), label: '专注'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: '统计'),
            NavigationDestination(icon: Icon(Icons.search), label: '搜索'),
          ],
        ),
      ),
    );
  }
}
