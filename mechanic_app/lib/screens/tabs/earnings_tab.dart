import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final me = context.watch<Auth>().currentUser!;
    return StreamBuilder<List<Booking>>(
      stream: Repo.instance.bookingsForMechanic(me.id),
      builder: (_, snap) {
        final list = snap.data ?? [];
        final completed = list.where((b) => b.status == BookingStatus.completed).toList();

        // last 7 days
        final last7 = List.generate(7, (i) {
          final day = DateTime.now().subtract(Duration(days: 6 - i));
          return completed.where((b) => b.updatedAt.year == day.year && b.updatedAt.month == day.month && b.updatedAt.day == day.day)
              .fold<double>(0, (s, b) => s + b.total * 0.9);
        });
        final maxY = last7.fold<double>(1000, (m, v) => v > m ? v : m) * 1.2;

        // totals
        final total7 = last7.fold<double>(0, (s, v) => s + v);
        final totalAll = completed.fold<double>(0, (s, b) => s + b.total * 0.9);
        final avg = completed.isEmpty ? 0.0 : totalAll / completed.length;

        // by service type
        final byType = <ServiceType, double>{};
        for (final b in completed) {
          byType[b.serviceType] = (byType[b.serviceType] ?? 0) + b.total * 0.9;
        }

        return ListView(padding: const EdgeInsets.all(16), children: [
          // hero balance
          Container(padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.mintDark, AppColors.mint]), borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Available balance', style: TextStyle(color: Colors.white70)),
              Text(Fmt.etb(me.walletBalance), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('After 10% platform commission', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ])),
          const SizedBox(height: 14),

          // top stats grid
          Row(children: [
            _stat('This week', Fmt.etb(total7), Icons.calendar_today_outlined, AppColors.orange),
            const SizedBox(width: 8),
            _stat('All-time', Fmt.etb(totalAll), Icons.account_balance_wallet_outlined, AppColors.mintDark),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _stat('Avg/job', Fmt.etb(avg.round()), Icons.show_chart, AppColors.success),
            const SizedBox(width: 8),
            _stat('Jobs done', completed.length.toString(), Icons.task_alt_rounded, AppColors.warn),
          ]),

          const SizedBox(height: 14),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Last 7 days', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: BarChart(BarChartData(
              maxY: maxY,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                  getTitlesWidget: (v, _) => Text(v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  final day = DateTime.now().subtract(Duration(days: 6 - v.toInt()));
                  return Padding(padding: const EdgeInsets.only(top: 4), child: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][(day.weekday - 1) % 7], style: const TextStyle(fontSize: 10)));
                })),
              ),
              barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: last7[i], color: AppColors.mintDark, width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
              ])),
            ))),
          ]))),

          if (byType.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Earnings by service', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: PieChart(PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 36,
                sections: byType.entries.map((e) => PieChartSectionData(
                  value: e.value, color: _color(e.key),
                  title: '${(e.value / byType.values.fold<double>(0, (s, v) => s + v) * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  radius: 60,
                )).toList(),
              ))),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: byType.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _color(e.key).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _color(e.key), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${labelOf(e.key)} ${Fmt.etb(e.value)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              )).toList()),
            ]))),
          ],

          const SizedBox(height: 14),
          const Text('Recent transactions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          StreamBuilder<List<WalletTxn>>(
            stream: Repo.instance.txnsStream(me.id),
            builder: (_, ts) {
              final list = ts.data ?? [];
              if (list.isEmpty) return const Card(child: ListTile(title: Text('No transactions yet')));
              return Column(children: list.take(20).map((t) => Card(child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.amount >= 0 ? AppColors.success.withOpacity(0.15) : AppColors.danger.withOpacity(0.15),
                  child: Icon(t.amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward, color: t.amount >= 0 ? AppColors.success : AppColors.danger)),
                title: Text(t.description),
                subtitle: Text(Fmt.dateTime(t.ts)),
                trailing: Text((t.amount >= 0 ? '+' : '') + Fmt.etb(t.amount.abs()),
                  style: TextStyle(fontWeight: FontWeight.w800, color: t.amount >= 0 ? AppColors.success : AppColors.danger)),
              ))).toList());
            },
          ),
        ]);
      },
    );
  }

  Widget _stat(String label, String value, IconData ic, Color color) => Expanded(child: Card(child: Padding(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(ic, color: color, size: 22)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMute)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  )));

  Color _color(ServiceType t) {
    switch (t) {
      case ServiceType.emergency_roadside: return AppColors.danger;
      case ServiceType.at_home: return AppColors.mint;
      case ServiceType.workshop: return AppColors.orange;
      case ServiceType.scheduled_maintenance: return AppColors.steel;
      case ServiceType.detailing: return Colors.deepPurple;
      case ServiceType.custom: return Colors.teal;
    }
  }
}
