import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import '../booking_create_screen.dart';
import '../booking_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<Auth>().currentUser!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.orange, AppColors.orangeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user.fullName.split(' ').first} 👋', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(user.address.isEmpty ? 'Add your address in profile' : user.address,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      const Text('Quick service', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _action(context, Icons.flash_on_rounded, 'Emergency', AppColors.danger, ServiceType.emergency_roadside)),
        const SizedBox(width: 10),
        Expanded(child: _action(context, Icons.home_repair_service_rounded, 'At Home', AppColors.mint, ServiceType.at_home)),
        const SizedBox(width: 10),
        Expanded(child: _action(context, Icons.build_rounded, 'Workshop', AppColors.orange, ServiceType.workshop)),
      ]),
      const SizedBox(height: 22),
      const Text('Verified mechanics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 8),
      FutureBuilder<List<AppUser>>(
        future: Repo.instance.mechanics(onlyVerified: true),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
          final list = snap.data!;
          if (list.isEmpty) return _empty('No verified mechanics nearby yet.');
          list.sort((a, b) => Fmt.haversine(user.lat ?? 9.01, user.lng ?? 38.76, a.lat ?? 9.01, a.lng ?? 38.76)
              .compareTo(Fmt.haversine(user.lat ?? 9.01, user.lng ?? 38.76, b.lat ?? 9.01, b.lng ?? 38.76)));
          return Column(children: list.take(5).map((m) {
            final dist = Fmt.haversine(user.lat ?? 9.01, user.lng ?? 38.76, m.lat ?? 9.01, m.lng ?? 38.76);
            return Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: const CircleAvatar(backgroundColor: AppColors.orangeLight, child: Icon(Icons.handyman, color: AppColors.orangeDark)),
              title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${m.specialties.isEmpty ? "General mechanic" : m.specialties.join(' • ')}\n${Fmt.dist(dist)} away',
                style: const TextStyle(fontSize: 12)),
              isThreeLine: true,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded, color: AppColors.warn, size: 14),
                  SizedBox(width: 2),
                  Text('4.7', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ));
          }).toList());
        },
      ),
      const SizedBox(height: 18),
      const Text('Recent bookings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 8),
      StreamBuilder<List<Booking>>(
        stream: Repo.instance.bookingsForCustomer(user.id),
        builder: (_, snap) {
          if (!snap.hasData) return _empty('Loading…');
          final list = snap.data!;
          if (list.isEmpty) return _empty('No bookings yet. Tap a quick action above.');
          return Column(children: list.take(3).map((b) => Card(child: ListTile(
            leading: Icon(_iconFor(b.serviceType), color: AppColors.orange),
            title: Text(labelOf(b.serviceType), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${Fmt.dateTime(b.scheduledAt)} • ${b.status.name.toUpperCase()}'),
            trailing: Text(b.total > 0 ? Fmt.etb(b.total) : '—', style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
          ))).toList());
        },
      ),
    ]);
  }

  Widget _action(BuildContext c, IconData ic, String label, Color color, ServiceType type) {
    return InkWell(
      onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => BookingCreateScreen(initial: type))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.25))),
        child: Column(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(ic, color: Colors.white, size: 22)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _empty(String t) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(t, style: const TextStyle(color: AppColors.textMute)))));

  IconData _iconFor(ServiceType t) {
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
