import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'tabs/home_tab.dart';
import 'tabs/garage_tab.dart';
import 'tabs/diagnose_tab.dart';
import 'tabs/bookings_tab.dart';
import 'tabs/wallet_tab.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _idx = 0;
  bool _gpsAsked = false;

  @override
  void initState() {
    super.initState();
    // Request GPS once on first build → save to profile so distance is real.
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
    final s = S.of(context);
    final user = context.watch<Auth>().currentUser;
    if (user == null) return const SizedBox();
    const tabs = [HomeTab(), GarageTab(), DiagnoseTab(), BookingsTab(), WalletTab()];
    final titleColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Container(width: 32, height: 32,
            decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: AppColors.orangeDark, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Yichalal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: titleColor)),
            const Text('Customer', style: TextStyle(fontSize: 10, color: AppColors.orangeDark, letterSpacing: 1.2)),
          ])),
        ]),
        actions: [
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
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded), label: s.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.directions_car_outlined),
              activeIcon: const Icon(Icons.directions_car_filled), label: s.t('garage')),
          BottomNavigationBarItem(icon: const Icon(Icons.auto_awesome_outlined),
              activeIcon: const Icon(Icons.auto_awesome), label: s.t('diagnose')),
          BottomNavigationBarItem(icon: const Icon(Icons.event_note_outlined),
              activeIcon: const Icon(Icons.event_note), label: s.t('bookings')),
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet), label: s.t('wallet')),
        ],
      ),
    );
  }
}
