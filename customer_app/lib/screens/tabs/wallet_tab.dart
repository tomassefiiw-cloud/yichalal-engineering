import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<Auth>().currentUser!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.orangeDark, AppColors.orange]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wallet Balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(Fmt.etb(user.walletBalance), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.orangeDark),
              onPressed: () async {
                final c = TextEditingController(text: '500');
                final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                  title: const Text('Top up'),
                  content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (ETB)')),
                  actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))],
                ));
                if (ok == true) {
                  final amt = double.tryParse(c.text) ?? 0;
                  if (amt > 0) {
                    await Repo.instance.creditWallet(user.id, amt, 'Top-up via Telebirr');
                    await context.read<Auth>().refresh();
                  }
                }
              },
              icon: const Icon(Icons.add), label: const Text('Top Up'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
              onPressed: () async {
                if (user.walletBalance <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to withdraw'))); return;
                }
                await Repo.instance.creditWallet(user.id, -user.walletBalance, 'Withdrawal to Telebirr');
                await context.read<Auth>().refresh();
              },
              icon: const Icon(Icons.upload), label: const Text('Withdraw'))),
          ]),
        ]),
      ),
      const SizedBox(height: 18),
      const Text('Transactions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 8),
      StreamBuilder<List<WalletTxn>>(
        stream: Repo.instance.txnsStream(user.id),
        builder: (_, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) return const Card(child: ListTile(title: Text('No transactions yet')));
          return Column(children: list.map((t) => Card(child: ListTile(
            leading: CircleAvatar(
              backgroundColor: t.amount >= 0 ? AppColors.success.withOpacity(0.15) : AppColors.danger.withOpacity(0.15),
              child: Icon(t.amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward, color: t.amount >= 0 ? AppColors.success : AppColors.danger),
            ),
            title: Text(t.description),
            subtitle: Text(Fmt.dateTime(t.ts)),
            trailing: Text((t.amount >= 0 ? '+' : '') + Fmt.etb(t.amount.abs()),
              style: TextStyle(fontWeight: FontWeight.w700, color: t.amount >= 0 ? AppColors.success : AppColors.danger)),
          ))).toList());
        },
      ),
    ]);
  }
}
