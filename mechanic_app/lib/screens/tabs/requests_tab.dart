import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import '../booking_detail_screen.dart';

/// Shows BOTH:
/// - Open requests assigned to this mechanic (status=pending, mechanic_id=me)
/// - Unassigned pending bookings nearby (so mechanics can claim)
class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final me = context.watch<Auth>().currentUser!;
    return StreamBuilder<List<Booking>>(
      stream: Repo.instance.bookingsForMechanic(me.id),
      builder: (_, mineSnap) {
        return StreamBuilder<List<Booking>>(
          stream: Repo.instance.pendingBookingsUnassigned(),
          builder: (_, openSnap) {
            final mine = (mineSnap.data ?? []).where((b) => b.status == BookingStatus.pending).toList();
            final unassigned = (openSnap.data ?? []);
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (mine.isEmpty && unassigned.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
                  Icon(Icons.inbox_outlined, size: 80, color: AppColors.textMute.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No requests right now', style: TextStyle(fontWeight: FontWeight.w600)),
                ]))),
              if (mine.isNotEmpty) ...[
                const Text('Assigned to you', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                ...mine.map((b) => _card(context, b, me, assigned: true)),
                const SizedBox(height: 18),
              ],
              if (unassigned.isNotEmpty) ...[
                const Text('Open requests in your area', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                ...unassigned.map((b) => _card(context, b, me, assigned: false)),
              ],
            ]);
          },
        );
      },
    );
  }

  Widget _card(BuildContext context, Booking b, AppUser me, {required bool assigned}) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        CircleAvatar(backgroundColor: AppColors.orangeLight, child: Icon(_icon(b.serviceType), color: AppColors.orangeDark)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(labelOf(b.serviceType), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(Fmt.dateTime(b.scheduledAt), style: const TextStyle(color: AppColors.textMute, fontSize: 12)),
        ])),
        Text(Fmt.dist(Fmt.haversine(me.lat ?? 9.01, me.lng ?? 38.76, b.lat, b.lng)),
          style: const TextStyle(fontSize: 12, color: AppColors.textMute)),
      ]),
      if (b.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(b.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
      ],
      const SizedBox(height: 4),
      Text(b.address, style: const TextStyle(color: AppColors.textMute, fontSize: 12)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: () async {
            await Repo.instance.upsertBooking(b.copyWith(mechanicId: me.id, status: BookingStatus.accepted));
            await Repo.instance.notify(b.customerId, 'Booking accepted', '${me.fullName} accepted your job', bookingId: b.id);
          },
          icon: const Icon(Icons.check), label: const Text('Accept'),
        )),
        const SizedBox(width: 8),
        if (assigned) Expanded(child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
          onPressed: () async {
            await Repo.instance.upsertBooking(b.copyWith(status: BookingStatus.declined));
            await Repo.instance.notify(b.customerId, 'Booking declined', 'Mechanic declined — finding another', bookingId: b.id);
          },
          icon: const Icon(Icons.close), label: const Text('Decline'),
        )) else Expanded(child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
          icon: const Icon(Icons.info_outline), label: const Text('Details'),
        )),
      ]),
    ])));
  }

  IconData _icon(ServiceType t) {
    switch (t) {
      case ServiceType.emergency_roadside: return Icons.flash_on_rounded;
      case ServiceType.at_home: return Icons.home_rounded;
      case ServiceType.workshop: return Icons.build_rounded;
      case ServiceType.scheduled_maintenance: return Icons.event_note_rounded;
      case ServiceType.detailing: return Icons.local_car_wash_rounded;
      case ServiceType.custom: return Icons.handyman_rounded;
    }
  }
}
