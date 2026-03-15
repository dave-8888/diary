import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiaryShell extends ConsumerWidget {
  const DiaryShell({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final selectedLanguage = ref.watch(appLanguageProvider);
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final appBarActions = [
      ...actions,
      PopupMenuButton<AppLanguage>(
        tooltip: strings.language,
        initialValue: selectedLanguage,
        icon: const Icon(Icons.language),
        onSelected: (language) {
          ref.read(appLanguageProvider.notifier).setLanguage(language);
        },
        itemBuilder: (context) => AppLanguage.values
            .map(
              (language) => PopupMenuItem<AppLanguage>(
                value: language,
                child: Text(strings.titleForLanguage(language)),
              ),
            )
            .toList(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              centerTitle: false,
              backgroundColor: Colors.transparent,
              actions: appBarActions,
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
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  label: strings.homeNav,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.edit_note_outlined),
                  label: strings.writeNav,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.timeline_outlined),
                  label: strings.timelineNav,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            actions: appBarActions,
          ),
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _goToIndex(context, index),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: Text(strings.homeNav),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.edit_note_outlined),
                    selectedIcon: const Icon(Icons.edit_note),
                    label: Text(strings.writeNav),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.timeline_outlined),
                    selectedIcon: const Icon(Icons.timeline),
                    label: Text(strings.timelineNav),
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
