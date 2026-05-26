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
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load garage:\n${snap.error}',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
            ));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return ListView(padding: const EdgeInsets.all(20), children: [
              const SizedBox(height: 80),
              Icon(Icons.directions_car_outlined, size: 90,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Your garage is empty', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color)),
              const SizedBox(height: 6),
              Text('Tap + below to add your first vehicle.', textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
            ]);
          }
          return ListView(padding: const EdgeInsets.all(16), children: list.map((v) => Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.directions_car_rounded, color: AppColors.orangeDark, size: 32)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                        color: Theme.of(context).textTheme.titleMedium?.color)),
                const SizedBox(height: 4),
                Text('${v.plateNumber} • ${v.engineType.name.toUpperCase()}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                if (v.mileage != null) Text('${v.mileage} km',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
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
  String? _error;

  Future<void> _save() async {
    setState(() => _error = null);
    if (_make.text.trim().isEmpty || _model.text.trim().isEmpty) {
      setState(() => _error = 'Make & Model are required');
      return;
    }
    final yr = int.tryParse(_year.text.trim());
    if (yr == null || yr < 1950 || yr > DateTime.now().year + 1) {
      setState(() => _error = 'Year must be between 1950 and ${DateTime.now().year + 1}');
      return;
    }
    if (_plate.text.trim().isEmpty) {
      setState(() => _error = 'Plate number is required');
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<Auth>();
    final user = auth.currentUser!;
    Future<void> doInsert() async {
      await Repo.instance.upsertVehicle(Vehicle(
        id: const Uuid().v4(),
        ownerId: user.id,
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: yr!,
        plateNumber: _plate.text.trim(),
        engineType: _engine,
        color: _color.text.trim().isEmpty ? null : _color.text.trim(),
        mileage: int.tryParse(_mileage.text.trim()),
        vin: _vin.text.trim().isEmpty ? null : _vin.text.trim(),
      ));
    }
    try {
      try {
        await doInsert();
      } catch (e) {
        final msg = e.toString().toLowerCase();
        // If FK error (profile row missing for this id), upsert the profile
        // automatically and retry the vehicle insert once. Common after a
        // database wipe or for users who signed up before the schema ran.
        if (msg.contains('foreign key') || msg.contains('violates') || msg.contains('23503')) {
          await auth.ensureProfileExists();
          await doInsert();
        } else {
          rethrow;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle added'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Save failed: ${_humanError(e.toString())}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _humanError(String raw) {
    if (raw.contains('PGRST205')) return 'Server not ready. Run supabase/schema.sql once in Supabase.';
    if (raw.contains('foreign key') || raw.contains('23503')) return 'Profile sync issue. Try logging out and back in.';
    if (raw.length > 140) return '${raw.substring(0, 140)}…';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        if (_error != null) Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
          ]),
        ),
        TextField(controller: _make, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Make (e.g. Toyota)', prefixIcon: Icon(Icons.directions_car))),
        const SizedBox(height: 12),
        TextField(controller: _model, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Model (e.g. Corolla)', prefixIcon: Icon(Icons.label_outline))),
        const SizedBox(height: 12),
        TextField(controller: _year, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Year', prefixIcon: Icon(Icons.event))),
        const SizedBox(height: 12),
        TextField(controller: _plate, textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Plate number', prefixIcon: Icon(Icons.confirmation_number_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _color, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Color', prefixIcon: Icon(Icons.color_lens_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _mileage, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Mileage (km)', prefixIcon: Icon(Icons.speed))),
        const SizedBox(height: 12),
        TextField(controller: _vin,
            decoration: const InputDecoration(labelText: 'VIN (optional)', prefixIcon: Icon(Icons.qr_code))),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: Text('Engine type',
            style: TextStyle(fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleMedium?.color))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: EngineType.values.map((e) => ChoiceChip(
          label: Text(e.name.toUpperCase()),
          selected: _engine == e, onSelected: (_) => setState(() => _engine = e),
        )).toList()),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save vehicle'),
        )),
        const SizedBox(height: 12),
      ])),
    );
  }
}
