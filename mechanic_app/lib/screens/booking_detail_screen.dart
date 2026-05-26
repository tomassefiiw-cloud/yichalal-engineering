import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'chat_screen.dart';

/// Mechanic-side booking detail. Shows customer contact, address, status
/// controls (Start trip / Mark in-progress / Finish & invoice). No payment
/// controls — those belong to the customer app.
class BookingDetailScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Auth>().currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: StreamBuilder<Booking?>(
        stream: Repo.instance.bookingStream(bookingId),
        builder: (_, snap) {
          if (!snap.hasData && snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final b = snap.data;
          if (b == null) return const Center(child: Text('Booking not found'));
          return FutureBuilder<_Aux>(
            future: _loadAux(b),
            builder: (_, aux) {
              if (!aux.hasData) return const Center(child: CircularProgressIndicator());
              return _body(context, b, aux.data!, me);
            },
          );
        },
      ),
    );
  }

  Future<_Aux> _loadAux(Booking b) async {
    final c = await Repo.instance.findUserById(b.customerId);
    final v = await Repo.instance.vehicle(b.vehicleId);
    return _Aux(c, v);
  }

  Widget _body(BuildContext context, Booking b, _Aux aux, AppUser me) {
    final customer = aux.customer;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: _statusColor(b.status), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        CircleAvatar(backgroundColor: Colors.white.withOpacity(0.95), child: Icon(_statusIcon(b.status), color: _statusColor(b.status))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          Text('Booking #${b.id.substring(0, 8).toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        if (b.total > 0) Text(Fmt.etb(b.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ]))),
      const SizedBox(height: 12),
      if (customer != null) Card(child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppColors.orangeLight, child: Icon(Icons.person, color: AppColors.orangeDark)),
        title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Customer • ${customer.phone}'),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(bookingId: b.id, peerId: customer.id))),
      )),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _kv('Service', labelOf(b.serviceType)),
        _kv('Vehicle', aux.vehicle?.title ?? '—'),
        _kv('Plate', aux.vehicle?.plateNumber ?? '—'),
        _kv('Engine', aux.vehicle?.engineType.name.toUpperCase() ?? '—'),
        _kv('Scheduled', Fmt.dateTime(b.scheduledAt)),
        _kv('Address', b.address),
        if (b.description.isNotEmpty) ...[
          const Divider(height: 20),
          const Text('Customer description', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SelectableText(b.description),
        ],
      ]))),
      if (customer != null && [BookingStatus.accepted, BookingStatus.enroute, BookingStatus.inprogress].contains(b.status)) ...[
        const SizedBox(height: 12),
        _mapCard(b, me, customer),
      ],
      const SizedBox(height: 16),
      ..._actions(context, b, me),
      const SizedBox(height: 30),
    ]);
  }

  Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
    SizedBox(width: 100, child: Text(k, style: const TextStyle(color: AppColors.textMute, fontSize: 13))),
    Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
  ]));

  Widget _mapCard(Booking b, AppUser me, AppUser customer) {
    final pos = LatLng(me.lat ?? 9.02, me.lng ?? 38.78);
    final dest = LatLng(b.lat, b.lng);
    final dist = Fmt.haversine(pos.latitude, pos.longitude, dest.latitude, dest.longitude);
    return Card(clipBehavior: Clip.antiAlias, child: Column(children: [
      SizedBox(height: 240, child: FlutterMap(
        options: MapOptions(initialCenter: LatLng((pos.latitude + dest.latitude) / 2, (pos.longitude + dest.longitude) / 2), initialZoom: 13),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.yichalal.mechanic'),
          PolylineLayer(polylines: [Polyline(points: [pos, dest], strokeWidth: 4, color: AppColors.orange)]),
          MarkerLayer(markers: [
            Marker(point: pos, width: 40, height: 40, child: const Icon(Icons.handyman_rounded, color: AppColors.orange, size: 32)),
            Marker(point: dest, width: 40, height: 40, child: const Icon(Icons.location_pin, color: AppColors.danger, size: 38)),
          ]),
        ],
      )),
      Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        const Icon(Icons.route_outlined, color: AppColors.orange),
        const SizedBox(width: 6),
        Text('Distance: ${Fmt.dist(dist)}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('To: ${customer.fullName}', style: const TextStyle(color: AppColors.textMute, fontSize: 12)),
      ])),
    ]));
  }

  List<Widget> _actions(BuildContext c, Booking b, AppUser me) {
    Widget big(String label, IconData ic, Color color, VoidCallback onTap) => ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size.fromHeight(54)),
      onPressed: onTap, icon: Icon(ic), label: Text(label),
    );

    Future<void> update(BookingStatus s, String custTitle, String custBody) async {
      await Repo.instance.upsertBooking(b.copyWith(status: s, mechanicId: me.id));
      await Repo.instance.notify(b.customerId, custTitle, custBody, bookingId: b.id);
    }

    if (b.status == BookingStatus.pending) {
      return [
        big('Accept job', Icons.check, AppColors.success, () => update(BookingStatus.accepted, 'Booking accepted', '${me.fullName} accepted your job')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), minimumSize: const Size.fromHeight(48)),
          onPressed: () async {
            await Repo.instance.upsertBooking(b.copyWith(status: BookingStatus.declined));
            await Repo.instance.notify(b.customerId, 'Booking declined', 'Mechanic unavailable', bookingId: b.id);
          },
          icon: const Icon(Icons.close), label: const Text('Decline'),
        ),
      ];
    }
    if (b.status == BookingStatus.accepted) {
      return [big('Start trip / En route', Icons.directions_car_rounded, AppColors.orange,
        () => update(BookingStatus.enroute, 'Mechanic en route', 'Track in the app'))];
    }
    if (b.status == BookingStatus.enroute) {
      return [big('Arrived — Start service', Icons.build_rounded, AppColors.orange,
        () => update(BookingStatus.inprogress, 'Service started', 'Your mechanic is working on it'))];
    }
    if (b.status == BookingStatus.inprogress) {
      return [big('Finish & invoice', Icons.receipt_long_rounded, AppColors.success, () => _complete(c, b))];
    }
    return [];
  }

  Future<void> _complete(BuildContext context, Booking b) async {
    final laborC = TextEditingController(text: '1500');
    final partsC = TextEditingController(text: '0');
    final feeC = TextEditingController(text: '200');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Complete & invoice'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: laborC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Labor (ETB)')),
        TextField(controller: partsC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Parts (ETB)')),
        TextField(controller: feeC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Service fee (ETB)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Complete'))],
    ));
    if (ok != true) return;
    final l = double.tryParse(laborC.text) ?? 0;
    final p = double.tryParse(partsC.text) ?? 0;
    final f = double.tryParse(feeC.text) ?? 0;
    final total = l + p + f;
    await Repo.instance.upsertBooking(b.copyWith(status: BookingStatus.completed,
      laborCost: l, partsCost: p, serviceFee: f, total: total));
    await Repo.instance.notify(b.customerId, 'Service completed', 'Total: ${Fmt.etb(total)} — please rate & pay', bookingId: b.id);
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending: return AppColors.warn;
      case BookingStatus.accepted: case BookingStatus.enroute: case BookingStatus.inprogress: return AppColors.orange;
      case BookingStatus.completed: return AppColors.success;
      case BookingStatus.cancelled: case BookingStatus.declined: return AppColors.danger;
    }
  }

  IconData _statusIcon(BookingStatus s) {
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

class _Aux {
  final AppUser? customer;
  final Vehicle? vehicle;
  _Aux(this.customer, this.vehicle);
}
