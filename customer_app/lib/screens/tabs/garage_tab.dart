import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:yichalal_core/yichalal_core.dart';

class GarageTab extends StatelessWidget {
  const GarageTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<Auth>().currentUser!;
    return Scaffold(
      body: StreamBuilder<List<Vehicle>>(
        stream: Repo.instance.vehiclesStreamOf(user.id),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return ListView(padding: const EdgeInsets.all(20), children: [
              const SizedBox(height: 80),
              Icon(Icons.directions_car_outlined, size: 90, color: AppColors.textMute.withOpacity(0.4)),
              const SizedBox(height: 16),
              const Text('Your garage is empty', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Tap + below to add your first vehicle.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMute, fontSize: 13)),
            ]);
          }
          return ListView(padding: const EdgeInsets.all(16), children: list.map((v) => Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.directions_car_rounded, color: AppColors.orangeDark, size: 32)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${v.plateNumber} • ${v.engineType.name.toUpperCase()}', style: const TextStyle(color: AppColors.textMute, fontSize: 12)),
                if (v.mileage != null) Text('${v.mileage} km', style: const TextStyle(color: AppColors.textMute, fontSize: 12)),
              ])),
            ]),
          ))).toList());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange, foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: const Text('Add Vehicle'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _VehicleForm())),
      ),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm();
  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: DateTime.now().year.toString());
  final _plate = TextEditingController(text: 'AA ');
  final _color = TextEditingController();
  final _mileage = TextEditingController();
  final _vin = TextEditingController();
  EngineType _engine = EngineType.gasoline;
  bool _saving = false;

  Future<void> _save() async {
    if (_make.text.trim().isEmpty || _model.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Make & Model required'))); return;
    }
    setState(() => _saving = true);
    try {
      final user = context.read<Auth>().currentUser!;
      await Repo.instance.upsertVehicle(Vehicle(
        id: const Uuid().v4(), ownerId: user.id,
        make: _make.text.trim(), model: _model.text.trim(),
        year: int.tryParse(_year.text) ?? DateTime.now().year,
        plateNumber: _plate.text.trim(), engineType: _engine,
        color: _color.text.trim().isEmpty ? null : _color.text.trim(),
        mileage: int.tryParse(_mileage.text),
        vin: _vin.text.trim().isEmpty ? null : _vin.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _make, decoration: const InputDecoration(labelText: 'Make (e.g. Toyota)', prefixIcon: Icon(Icons.directions_car))),
        const SizedBox(height: 12),
        TextField(controller: _model, decoration: const InputDecoration(labelText: 'Model (e.g. Corolla)', prefixIcon: Icon(Icons.label_outline))),
        const SizedBox(height: 12),
        TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year', prefixIcon: Icon(Icons.event))),
        const SizedBox(height: 12),
        TextField(controller: _plate, decoration: const InputDecoration(labelText: 'Plate number', prefixIcon: Icon(Icons.confirmation_number_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _color, decoration: const InputDecoration(labelText: 'Color', prefixIcon: Icon(Icons.color_lens_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _mileage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mileage (km)', prefixIcon: Icon(Icons.speed))),
        const SizedBox(height: 12),
        TextField(controller: _vin, decoration: const InputDecoration(labelText: 'VIN (optional)', prefixIcon: Icon(Icons.qr_code))),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text('Engine type', style: TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: EngineType.values.map((e) => ChoiceChip(
          label: Text(e.name.toUpperCase()),
          selected: _engine == e, onSelected: (_) => setState(() => _engine = e),
        )).toList()),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save vehicle'),
        )),
      ])),
    );
  }
}
