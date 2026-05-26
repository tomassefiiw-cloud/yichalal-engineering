import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import '../booking_detail_screen.dart';

class JobsTab extends StatelessWidget {
  const JobsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final me = context.watch<Auth>().currentUser!;
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Jobs'),
        bottom: const TabBar(
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          tabs: [Tab(text: 'Active'), Tab(text: 'History')],
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: Repo.instance.bookingsForMechanic(me.id),
        builder: (_, snap) {
          final list = snap.data ?? [];
          final active = list.where((b) => [BookingStatus.accepted, BookingStatus.enroute, BookingStatus.inprogress].contains(b.status)).toList();
          final hist = list.where((b) => [BookingStatus.completed, BookingStatus.cancelled, BookingStatus.declined].contains(b.status)).toList();
          return TabBarView(children: [_list(context, active), _list(context, hist)]);
        },
      ),
    ));
  }

  Widget _list(BuildContext c, List<Booking> bs) {
    if (bs.isEmpty) return const Center(child: Text('Nothing here'));
    return ListView(padding: const EdgeInsets.all(12), children: bs.map((b) => Card(child: ListTile(
      leading: const Icon(Icons.assignment_outlined, color: AppColors.orange),
      title: Text(labelOf(b.serviceType), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${Fmt.dateTime(b.scheduledAt)}\n${b.address}'),
      isThreeLine: true,
      trailing: Text(b.total > 0 ? Fmt.etb(b.total) : '—', style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
    ))).toList());
  }
}
