import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import '../booking_detail_screen.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<Auth>().currentUser!;
    return StreamBuilder<List<Booking>>(
      stream: Repo.instance.bookingsForCustomer(user.id),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_outlined, size: 80, color: AppColors.textMute.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No bookings yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Create one from Home → Quick service', style: TextStyle(color: AppColors.textMute, fontSize: 12)),
          ]));
        }
        return ListView(padding: const EdgeInsets.all(16), children: list.map((b) => Card(child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            backgroundColor: _color(b.status).withOpacity(0.15),
            child: Icon(_icon(b.status), color: _color(b.status)),
          ),
          title: Text(labelOf(b.serviceType), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${Fmt.dateTime(b.scheduledAt)}\n${b.description.isEmpty ? "No description" : b.description}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
          isThreeLine: true,
          trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _color(b.status).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(b.status.name.toUpperCase(), style: TextStyle(color: _color(b.status), fontWeight: FontWeight.w700, fontSize: 10))),
            const SizedBox(height: 4),
            Text(b.total > 0 ? Fmt.etb(b.total) : '—', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
        ))).toList());
      },
    );
  }

  Color _color(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending: return AppColors.warn;
      case BookingStatus.accepted: case BookingStatus.enroute: case BookingStatus.inprogress: return AppColors.orange;
      case BookingStatus.completed: return AppColors.success;
      case BookingStatus.cancelled: case BookingStatus.declined: return AppColors.danger;
    }
  }

  IconData _icon(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending: return Icons.hourglass_top_rounded;
      case BookingStatus.accepted: return Icons.check_circle_outline_rounded;
      case BookingStatus.enroute: return Icons.directions_car_rounded;
      case BookingStatus.inprogress: return Icons.build_rounded;
      case BookingStatus.completed: return Icons.task_alt_rounded;
      case BookingStatus.cancelled: case BookingStatus.declined: return Icons.cancel_outlined;
    }
  }
}
