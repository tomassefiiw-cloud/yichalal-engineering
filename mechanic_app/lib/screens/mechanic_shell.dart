import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'tabs/dashboard_tab.dart';
import 'tabs/requests_tab.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/earnings_tab.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MechanicShell extends StatefulWidget {
  const MechanicShell({super.key});
  @override
  State<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends State<MechanicShell> {
  int _idx = 0;
  bool _gpsAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureLocationOnce());
  }

  Future<void> _captureLocationOnce() async {
    if (_gpsAsked) return;
    _gpsAsked = true;
    final user = context.read<Auth>().currentUser;
    if (user == null) return;
    final pos = await Geo.current();
    if (pos == null) return;
    try {
      await Repo.instance.updateUserLocation(user.id, pos.latitude, pos.longitude);
      await context.read<Auth>().refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Auth>().currentUser;
    final s = S.of(context);
    if (user == null) return const SizedBox();
    const tabs = [DashboardTab(), RequestsTab(), JobsTab(), InventoryTab(), EarningsTab()];
    final titleColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(children: [
          Container(width: 32, height: 32,
            decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.handyman_rounded, color: AppColors.orangeDark, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Yichalal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: titleColor)),
              const Text('MECHANIC',
                  style: TextStyle(fontSize: 9, color: AppColors.orangeDark, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
            ]),
          )),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined),
              tooltip: s.t('settings'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(primary: AppColors.orange)))),
          IconButton(icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          IconButton(icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
        ],
      ),
      body: IndexedStack(index: _idx, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard_rounded), label: s.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_active_outlined),
              activeIcon: const Icon(Icons.notifications_active), label: s.t('requests')),
          BottomNavigationBarItem(icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment_rounded), label: s.t('jobs')),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: const Icon(Icons.inventory_2_rounded), label: s.t('inventory')),
          BottomNavigationBarItem(icon: const Icon(Icons.payments_outlined),
              activeIcon: const Icon(Icons.payments_rounded), label: s.t('earnings')),
        ],
      ),
    );
  }
}
