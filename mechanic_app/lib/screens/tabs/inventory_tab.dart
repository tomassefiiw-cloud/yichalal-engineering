import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:yichalal_core/yichalal_core.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});
  @override
  Widget build(BuildContext context) {
    final me = context.watch<Auth>().currentUser!;
    return Scaffold(
      body: StreamBuilder<List<InventoryItem>>(
        stream: Repo.instance.inventoryStream(me.id),
        builder: (_, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('Tap + to add your first part'));
          return ListView(padding: const EdgeInsets.all(12), children: list.map((i) => Card(child: ListTile(
            leading: const Icon(Icons.settings_input_component_rounded, color: AppColors.orange),
            title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Qty: ${i.quantity}'),
            trailing: Text(Fmt.etb(i.price), style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => _edit(context, me.id, item: i),
          ))).toList());
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(context, me.id), child: const Icon(Icons.add)),
    );
  }

  Future<void> _edit(BuildContext c, String mid, {InventoryItem? item}) async {
    final n = TextEditingController(text: item?.name ?? '');
    final q = TextEditingController(text: (item?.quantity ?? 1).toString());
    final p = TextEditingController(text: (item?.price ?? 0).toString());
    final ok = await showDialog<bool>(context: c, builder: (_) => AlertDialog(
      title: Text(item == null ? 'Add part' : 'Edit part'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: q, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
        TextField(controller: p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (ETB)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
    ));
    if (ok != true) return;
    await Repo.instance.upsertInventory(InventoryItem(
      id: item?.id ?? const Uuid().v4(), mechanicId: mid,
      name: n.text.trim(), quantity: int.tryParse(q.text) ?? 0, price: double.tryParse(p.text) ?? 0,
    ));
  }
}
