import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabSwitchDelay = Duration(milliseconds: 180);

  Timer? _navigationTimer;
  int? _pendingIndex;

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _switchTab(int index, int selectedIndex) {
    if (index == selectedIndex) {
      return;
    }

    _navigationTimer?.cancel();
    setState(() {
      _pendingIndex = index;
    });

    _navigationTimer = Timer(_tabSwitchDelay, () {
      if (!mounted) {
        return;
      }

      context.go(_pathForIndex(index));
      setState(() {
        _pendingIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location);
    final pendingIndex = _pendingIndex;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: pendingIndex == null
            ? widget.child
            : _TabSwitchingView(label: _labelForIndex(pendingIndex)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pendingIndex ?? selectedIndex,
        onDestinationSelected: (index) {
          _switchTab(index, selectedIndex);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard_rounded),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location == '/leaderboard' || location == '/channel-trades') {
      return 1;
    }

    if (location == '/history') {
      return 2;
    }

    return 0;
  }

  String _pathForIndex(int index) {
    switch (index) {
      case 1:
        return '/leaderboard';
      case 2:
        return '/history';
      default:
        return '/home';
    }
  }

  String _labelForIndex(int index) {
    switch (index) {
      case 1:
        return 'Leaderboard';
      case 2:
        return 'History';
      default:
        return 'Dashboard';
    }
  }
}

class _TabSwitchingView extends StatelessWidget {
  final String label;

  const _TabSwitchingView({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Opening $label...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
