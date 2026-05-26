import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import '../booking_detail_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<Auth>().currentUser!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (!user.kycVerified)
        Card(color: AppColors.warn.withOpacity(0.14), child: const ListTile(
          leading: Icon(Icons.warning_amber_outlined, color: AppColors.warn),
          title: Text('KYC verification pending', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('You will start receiving jobs once admin verifies your documents.'),
        )),
      if (!user.kycVerified) const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.mintDark, AppColors.mint], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.handyman_rounded, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user.fullName.split(' ').first}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Wallet: ${Fmt.etb(user.walletBalance)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Column(children: [
            Switch(value: user.isOnline, activeColor: Colors.white, activeTrackColor: AppColors.success,
              onChanged: (v) async {
                await Repo.instance.updateUserOnline(user.id, v);
                await context.read<Auth>().refresh();
              }),
            Text(user.isOnline ? 'ONLINE' : 'OFFLINE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      StreamBuilder<List<Booking>>(
        stream: Repo.instance.bookingsForMechanic(user.id),
        builder: (_, snap) {
          final list = snap.data ?? [];
          final pending = list.where((b) => b.status == BookingStatus.pending).length;
          final today = list.where((b) => b.scheduledAt.day == DateTime.now().day && b.status != BookingStatus.cancelled).length;
          final done = list.where((b) => b.status == BookingStatus.completed && b.updatedAt.day == DateTime.now().day).length;
          return Column(children: [
            Row(children: [
              _stat('Pending', pending.toString(), Icons.hourglass_top_rounded, AppColors.warn),
              const SizedBox(width: 8),
              _stat('Today', today.toString(), Icons.event, AppColors.mint),
              const SizedBox(width: 8),
              _stat('Done', done.toString(), Icons.task_alt_rounded, AppColors.success),
            ]),
            const SizedBox(height: 18),
            const Align(alignment: Alignment.centerLeft, child: Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            const SizedBox(height: 6),
            if (list.isEmpty) const Card(child: ListTile(title: Text('No jobs yet — incoming requests will appear in the Requests tab.')))
            else ...list.take(5).map((b) => Card(child: ListTile(
              leading: const Icon(Icons.assignment_outlined, color: AppColors.mintDark),
              title: Text(labelOf(b.serviceType), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${Fmt.dateTime(b.scheduledAt)} • ${b.status.name.toUpperCase()}'),
              trailing: Text(b.total > 0 ? Fmt.etb(b.total) : '—', style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
            ))),
          ]);
        },
      ),
    ]);
  }

  Widget _stat(String label, String value, IconData ic, Color color) => Expanded(child: Card(child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(ic, color: color, size: 22)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
      Text(label, style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
    ]),
  )));
}
