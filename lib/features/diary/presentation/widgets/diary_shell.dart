import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiaryShell extends StatelessWidget {
  const DiaryShell({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              centerTitle: false,
              backgroundColor: Colors.transparent,
            ),
            floatingActionButton: floatingActionButton,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _goToIndex(context, index),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.edit_note_outlined), label: 'Write'),
                NavigationDestination(
                    icon: Icon(Icons.timeline_outlined), label: 'Timeline'),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: false,
            backgroundColor: Colors.transparent,
          ),
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _goToIndex(context, index),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.edit_note_outlined),
                    selectedIcon: Icon(Icons.edit_note),
                    label: Text('Write'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.timeline_outlined),
                    selectedIcon: Icon(Icons.timeline),
                    label: Text('Timeline'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/editor')) return 1;
    if (location.startsWith('/timeline')) return 2;
    return 0;
  }

  void _goToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/editor');
        break;
      case 2:
        context.go('/timeline');
        break;
    }
  }
}
