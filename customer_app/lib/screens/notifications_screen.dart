import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'booking_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final me = context.watch<Auth>().currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<AppNotification>>(
        stream: Repo.instance.notificationsStream(me.id),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('No notifications'));
          return ListView(children: list.map((n) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: n.read ? null : AppColors.orangeLight,
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined, color: AppColors.orange),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${n.body}\n${Fmt.dateTime(n.ts)}'),
              isThreeLine: true,
              onTap: () async {
                if (!n.read) await Repo.instance.markNotificationRead(n.id);
                if (n.bookingId != null && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: n.bookingId!)));
                }
              },
            ),
          )).toList());
        },
      ),
    );
  }
}
