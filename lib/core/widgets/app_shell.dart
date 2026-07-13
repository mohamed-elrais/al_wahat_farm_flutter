import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: <Widget>[
            const WahatTopBar(),
            const WahatConnectivityBanner(),
            Expanded(child: navigationShell),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: WahatNavigation(
          index: navigationShell.currentIndex,
          onSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      );
}

/// A live-region strip shown across the shell whenever the device is offline,
/// so every workflow makes its cached/offline state visible.
class WahatConnectivityBanner extends StatelessWidget {
  const WahatConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = AppServicesScope.maybeOf(context)?.connectivity;
    if (connectivity == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) {
        if (!connectivity.isOffline) return const SizedBox.shrink();
        return Semantics(
          liveRegion: true,
          label: 'You are offline. Showing cached farm and task data.',
          child: Container(
            key: const Key('offline-banner'),
            width: double.infinity,
            color: AppColors.issue.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: <Widget>[
                Icon(Icons.cloud_off_outlined,
                    size: 18, color: AppColors.issue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline · showing cached farm and task data',
                    style: TextStyle(
                      color: AppColors.issue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WahatTopBar extends StatelessWidget {
  const WahatTopBar({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.92),
          border: const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.park_outlined,
                      size: 30, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Text('Al Wahat',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () {},
                    icon: const Badge(child: Icon(Icons.notifications_none)),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    child: Text('A'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class WahatNavigation extends StatelessWidget {
  const WahatNavigation({
    required this.index,
    required this.onSelected,
    super.key,
  });

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.home_outlined, 'Home'),
      (Icons.map_outlined, 'Map'),
      (Icons.qr_code_scanner, 'Scan'),
      (Icons.assignment_outlined, 'Tasks'),
      (Icons.more_horiz, 'More'),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x47263D2B),
              blurRadius: 35,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List<Widget>.generate(items.length, (int itemIndex) {
            final item = items[itemIndex];
            final active = itemIndex == index;
            final scan = itemIndex == 2;
            return Semantics(
              key: Key('nav-${item.$2.toLowerCase()}'),
              excludeSemantics: true,
              selected: active,
              button: true,
              label: item.$2,
              child: InkResponse(
                onTap: () => onSelected(itemIndex),
                radius: 30,
                child: Container(
                  width: 58,
                  height: scan ? 58 : 52,
                  transform: scan ? Matrix4.translationValues(0, -15, 0) : null,
                  decoration: scan
                      ? const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        item.$1,
                        color: scan || active
                            ? Colors.white
                            : const Color(0xFFB6C6B9),
                        size: scan ? 27 : 23,
                      ),
                      if (!scan) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          item.$2,
                          style: TextStyle(
                            color:
                                active ? Colors.white : const Color(0xFFB6C6B9),
                            fontFamily: 'Inter',
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
