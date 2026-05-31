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

      context.go(index == 0 ? '/home' : '/history');
      setState(() {
        _pendingIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = location == '/history' ? 1 : 0;
    final pendingIndex = _pendingIndex;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: pendingIndex == null
              ? KeyedSubtree(key: ValueKey(location), child: widget.child)
              : _TabSwitchingView(
                  key: ValueKey('switching-$pendingIndex'),
                  label: pendingIndex == 0 ? 'Dashboard' : 'Trade History',
                ),
        ),
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Trade History',
          ),
        ],
      ),
    );
  }
}

class _TabSwitchingView extends StatelessWidget {
  final String label;

  const _TabSwitchingView({super.key, required this.label});

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
