import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'booking_detail_screen.dart';

class BookingCreateScreen extends StatefulWidget {
  final String? vehicleId;
  final ServiceType? initial;
  final String? prefillDescription;
  const BookingCreateScreen({super.key, this.vehicleId, this.initial, this.prefillDescription});
  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  ServiceType _type = ServiceType.workshop;
  Vehicle? _vehicle;
  List<Vehicle> _vehicles = [];
  DateTime _scheduled = DateTime.now().add(const Duration(hours: 2));
  final _addr = TextEditingController();
  late final _desc = TextEditingController(text: widget.prefillDescription ?? '');
  bool _saving = false;

  @override
  void initState() { super.initState(); _type = widget.initial ?? ServiceType.workshop; _load(); }

  Future<void> _load() async {
    final user = context.read<Auth>().currentUser!;
    final v = await Repo.instance.vehiclesOf(user.id);
    if (!mounted) return;
    setState(() {
      _vehicles = v;
      _vehicle = widget.vehicleId != null
        ? (v.where((x) => x.id == widget.vehicleId).isNotEmpty ? v.firstWhere((x) => x.id == widget.vehicleId) : (v.isNotEmpty ? v.first : null))
        : (v.isNotEmpty ? v.first : null);
      _addr.text = user.address;
    });
  }

  Future<void> _submit() async {
    if (_vehicle == null) { _toast('Add a vehicle in Garage first'); return; }
    if (_addr.text.trim().isEmpty) { _toast('Enter your address'); return; }
    setState(() => _saving = true);
    try {
      final user = context.read<Auth>().currentUser!;
      final mechs = await Repo.instance.mechanics(onlyVerified: true);
      AppUser? assigned;
      double bestDist = double.infinity;
      for (final m in mechs) {
        if (m.lat == null || m.lng == null) continue;
        final d = Fmt.haversine(user.lat ?? 9.01, user.lng ?? 38.76, m.lat!, m.lng!);
        if (d < bestDist) { bestDist = d; assigned = m; }
      }
      final booking = Booking(
        id: const Uuid().v4(), customerId: user.id, mechanicId: assigned?.id,
        vehicleId: _vehicle!.id, serviceType: _type,
        description: _desc.text.trim(),
        scheduledAt: _scheduled, address: _addr.text.trim(),
        lat: user.lat ?? 9.0108, lng: user.lng ?? 38.7613,
        status: BookingStatus.pending, serviceFee: 100,
      );
      await Repo.instance.upsertBooking(booking);
      if (assigned != null) {
        await Repo.instance.notify(assigned.id, 'New service request',
          '${user.fullName} — ${labelOf(_type)}', bookingId: booking.id);
      }
      await Repo.instance.notify(user.id, 'Booking created',
        assigned != null ? 'Sent to ${assigned.fullName}' : 'Awaiting mechanic assignment',
        bookingId: booking.id);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: booking.id)));
      }
    } catch (e) {
      if (mounted) _toast('Failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(context: context, initialDate: _scheduled, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduled));
    if (t == null) return;
    setState(() => _scheduled = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Booking')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Service Type', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ServiceType.values.where((t) => t != ServiceType.custom).map((t) =>
          ChoiceChip(label: Text(_short(t)), selected: _type == t, onSelected: (_) => setState(() => _type = t))).toList()),
        const SizedBox(height: 16),
        if (_vehicles.isNotEmpty)
          Card(child: ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('Vehicle'),
            subtitle: Text(_vehicle?.title ?? '—'),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () async {
              final v = await showModalBottomSheet<Vehicle>(context: context, builder: (_) => SafeArea(child: ListView(shrinkWrap: true,
                children: _vehicles.map((v) => ListTile(title: Text(v.title), subtitle: Text(v.plateNumber), onTap: () => Navigator.pop(context, v))).toList())));
              if (v != null) setState(() => _vehicle = v);
            },
          ))
        else
          Card(color: AppColors.warn.withOpacity(0.12), child: const ListTile(
            leading: Icon(Icons.warning_amber_outlined, color: AppColors.warn),
            title: Text('No vehicles in your garage'),
            subtitle: Text('Tap Garage tab → + to add one before booking.'),
          )),
        const SizedBox(height: 8),
        Card(child: ListTile(
          leading: const Icon(Icons.event_outlined),
          title: const Text('Pick date & time'),
          subtitle: Text(Fmt.dateTime(_scheduled)),
          onTap: _pickDateTime,
        )),
        const SizedBox(height: 8),
        TextField(controller: _addr, maxLines: 2, decoration: const InputDecoration(labelText: 'Address / landmark', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 5, decoration: const InputDecoration(labelText: 'Describe the problem', prefixIcon: Icon(Icons.description_outlined))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _saving || _vehicle == null ? null : _submit,
          icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
          label: const Text('Create Booking'),
        ),
      ]),
    );
  }

  String _short(ServiceType t) {
    switch (t) {
      case ServiceType.emergency_roadside: return 'Emergency';
      case ServiceType.at_home: return 'At Home';
      case ServiceType.workshop: return 'Workshop';
      case ServiceType.scheduled_maintenance: return 'Maintenance';
      case ServiceType.detailing: return 'Detailing';
      case ServiceType.custom: return 'Custom';
    }
  }
}
