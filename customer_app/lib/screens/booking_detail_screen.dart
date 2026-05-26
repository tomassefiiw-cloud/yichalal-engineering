import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'chat_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Timer? _sim;
  LatLng? _mechPos;

  @override
  void dispose() { _sim?.cancel(); super.dispose(); }

  void _ensureSim(Booking b, AppUser? mech) {
    if (mech == null) return;
    if (![BookingStatus.accepted, BookingStatus.enroute, BookingStatus.inprogress].contains(b.status)) {
      _sim?.cancel(); _sim = null; return;
    }
    if (_sim != null) return;
    _mechPos = LatLng(mech.lat ?? 9.02, mech.lng ?? 38.78);
    final dest = LatLng(b.lat, b.lng);
    _sim = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted || _mechPos == null) return;
      final c = _mechPos!;
      final dx = dest.latitude - c.latitude;
      final dy = dest.longitude - c.longitude;
      if (dx.abs() < 0.0001 && dy.abs() < 0.0001) { t.cancel(); return; }
      setState(() => _mechPos = LatLng(c.latitude + dx * 0.10, c.longitude + dy * 0.10));
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Auth>().currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: StreamBuilder<Booking?>(
        stream: Repo.instance.bookingStream(widget.bookingId),
        builder: (_, snap) {
          if (!snap.hasData && snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final b = snap.data;
          if (b == null) return const Center(child: Text('Booking not found'));
          return FutureBuilder<_Aux>(
            future: _loadAux(b),
            builder: (_, aux) {
              if (!aux.hasData) return const Center(child: CircularProgressIndicator());
              _ensureSim(b, aux.data!.mechanic);
              return _body(b, aux.data!, me);
            },
          );
        },
      ),
    );
  }

  Future<_Aux> _loadAux(Booking b) async {
    final mech = b.mechanicId == null ? null : await Repo.instance.findUserById(b.mechanicId!);
    final v = await Repo.instance.vehicle(b.vehicleId);
    return _Aux(mech, v);
  }

  Widget _body(Booking b, _Aux aux, AppUser me) {
    final mech = aux.mechanic;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: _statusBg(b.status), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        CircleAvatar(backgroundColor: Colors.white.withOpacity(0.95), child: Icon(_statusIcon(b.status), color: _statusColor(b.status))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.status.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          Text('Booking #${b.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ])),
      ]))),
      const SizedBox(height: 12),
      if (mech != null) Card(child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppColors.orangeLight, child: Icon(Icons.handyman_rounded, color: AppColors.orangeDark)),
        title: Text(mech.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Your mechanic • ${mech.phone}'),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(bookingId: b.id, peerId: mech.id))),
      )),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _kv('Service', labelOf(b.serviceType)),
        _kv('Vehicle', aux.vehicle?.title ?? '—'),
        _kv('Plate', aux.vehicle?.plateNumber ?? '—'),
        _kv('Scheduled', Fmt.dateTime(b.scheduledAt)),
        _kv('Address', b.address),
        if (b.description.isNotEmpty) ...[
          const Divider(height: 20),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SelectableText(b.description),
        ],
      ]))),
      if (mech != null && [BookingStatus.accepted, BookingStatus.enroute, BookingStatus.inprogress].contains(b.status)) ...[
        const SizedBox(height: 12),
        _mapCard(b, mech),
      ],
      if (b.status == BookingStatus.completed) ...[
        const SizedBox(height: 12),
        _invoice(b, aux),
        const SizedBox(height: 12),
        _ratingCard(b),
      ],
      const SizedBox(height: 12),
      if (b.status == BookingStatus.pending || b.status == BookingStatus.accepted)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), minimumSize: const Size.fromHeight(48)),
          onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: const Text('Cancel booking?'),
              content: const Text('This will notify the mechanic.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Cancel'))],
            ));
            if (ok == true) {
              await Repo.instance.upsertBooking(b.copyWith(status: BookingStatus.cancelled));
              if (b.mechanicId != null) await Repo.instance.notify(b.mechanicId!, 'Booking cancelled', 'Customer cancelled the booking', bookingId: b.id);
            }
          },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel booking'),
        ),
      const SizedBox(height: 30),
    ]);
  }

  Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
    SizedBox(width: 100, child: Text(k, style: const TextStyle(color: AppColors.textMute, fontSize: 13))),
    Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
  ]));

  Widget _mapCard(Booking b, AppUser mech) {
    final dest = LatLng(b.lat, b.lng);
    final pos = _mechPos ?? LatLng(mech.lat ?? 9.02, mech.lng ?? 38.78);
    final dist = Fmt.haversine(pos.latitude, pos.longitude, dest.latitude, dest.longitude);
    final eta = (dist / 1000 / 25 * 60).round();
    return Card(clipBehavior: Clip.antiAlias, child: Column(children: [
      SizedBox(height: 240, child: FlutterMap(
        options: MapOptions(initialCenter: LatLng((pos.latitude + dest.latitude) / 2, (pos.longitude + dest.longitude) / 2), initialZoom: 13),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.yichalal.customer'),
          PolylineLayer(polylines: [Polyline(points: [pos, dest], strokeWidth: 4, color: AppColors.orange)]),
          MarkerLayer(markers: [
            Marker(point: dest, width: 40, height: 40, child: const Icon(Icons.location_pin, color: AppColors.danger, size: 38)),
            Marker(point: pos, width: 40, height: 40, child: const Icon(Icons.directions_car_rounded, color: AppColors.orangeDark, size: 32)),
          ]),
        ],
      )),
      Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        const Icon(Icons.timer_outlined, color: AppColors.orange),
        const SizedBox(width: 6),
        Text(eta <= 0 ? 'Arrived' : 'ETA: $eta min', style: const TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(Fmt.dist(dist), style: const TextStyle(color: AppColors.textMute)),
      ])),
    ]));
  }

  Widget _invoice(Booking b, _Aux aux) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Invoice', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 10),
      _row('Labor', Fmt.etb(b.laborCost)),
      _row('Parts', Fmt.etb(b.partsCost)),
      _row('Service fee', Fmt.etb(b.serviceFee)),
      const Divider(),
      _row('Total', Fmt.etb(b.total), bold: true),
      _row('Payment', '${b.paymentMethod?.name.toUpperCase() ?? '—'} (${b.paymentStatus.name})'),
      const SizedBox(height: 12),
      if (b.paymentStatus != PaymentStatus.paid)
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => _pay(b), icon: const Icon(Icons.payments_rounded), label: Text('Pay ${Fmt.etb(b.total)}'),
        )),
    ])));
  }

  Widget _row(String k, String v, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
    Expanded(child: Text(k, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400))),
    Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
  ]));

  Future<void> _pay(Booking b) async {
    final method = await showModalBottomSheet<PaymentMethod>(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Choose payment method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      _payOpt(PaymentMethod.telebirr, 'Telebirr', Icons.phone_android),
      _payOpt(PaymentMethod.cbe_birr, 'CBE Birr', Icons.account_balance),
      _payOpt(PaymentMethod.amole, 'Amole', Icons.account_balance_wallet),
      _payOpt(PaymentMethod.wallet, 'Wallet', Icons.savings_outlined),
      _payOpt(PaymentMethod.cash, 'Cash', Icons.payments_outlined),
      const SizedBox(height: 8),
    ])));
    if (method == null || !mounted) return;
    final me = context.read<Auth>().currentUser!;
    if (method == PaymentMethod.wallet && me.walletBalance < b.total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient wallet balance'))); return;
    }
    if (method == PaymentMethod.cash) {
      await Repo.instance.upsertBooking(b.copyWith(paymentMethod: method, paymentStatus: PaymentStatus.held_in_escrow));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cash selected — pay mechanic on completion')));
      return;
    }
    if (method == PaymentMethod.wallet) {
      await Repo.instance.creditWallet(me.id, -b.total, 'Paid booking ${b.id.substring(0, 6)}');
    }
    await Repo.instance.upsertBooking(b.copyWith(paymentMethod: method, paymentStatus: PaymentStatus.paid));
    if (b.mechanicId != null) {
      await Repo.instance.creditWallet(b.mechanicId!, b.total * 0.9, 'Earnings ${b.id.substring(0, 6)} (10% commission)');
      await Repo.instance.notify(b.mechanicId!, 'Payment received', '${Fmt.etb(b.total)} for booking', bookingId: b.id);
    }
    await context.read<Auth>().refresh();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful')));
  }

  Widget _payOpt(PaymentMethod m, String label, IconData ic) => ListTile(
    leading: Icon(ic, color: AppColors.orange),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    onTap: () => Navigator.pop(context, m),
  );

  Widget _ratingCard(Booking b) {
    int stars = b.rating.toInt();
    final reviewC = TextEditingController(text: b.review ?? '');
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Rate this service', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      StatefulBuilder(builder: (_, setLocal) => Row(children: List.generate(5, (i) => IconButton(
        onPressed: () => setLocal(() => stars = i + 1),
        icon: Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.warn, size: 30),
      )))),
      TextField(controller: reviewC, maxLines: 3, decoration: const InputDecoration(labelText: 'Write a review (optional)')),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: () async {
        await Repo.instance.upsertBooking(b.copyWith(rating: stars.toDouble(), review: reviewC.text.trim()));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
      }, child: const Text('Submit review')),
    ])));
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending: return AppColors.warn;
      case BookingStatus.accepted: case BookingStatus.enroute: case BookingStatus.inprogress: return AppColors.orange;
      case BookingStatus.completed: return AppColors.success;
      case BookingStatus.cancelled: case BookingStatus.declined: return AppColors.danger;
    }
  }

  Color _statusBg(BookingStatus s) => _statusColor(s);

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
  final AppUser? mechanic;
  final Vehicle? vehicle;
  _Aux(this.mechanic, this.vehicle);
}
