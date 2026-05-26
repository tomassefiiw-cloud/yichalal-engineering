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
          return completed.where((b) =>
              b.updatedAt.year == day.year &&
              b.updatedAt.month == day.month &&
              b.updatedAt.day == day.day)
              .fold<double>(0, (s, b) => s + b.total * 0.9);
        });
        final maxY = last7.fold<double>(1000, (m, v) => v > m ? v : m) * 1.2;

        // last 30 days line chart
        final last30 = List.generate(30, (i) {
          final day = DateTime.now().subtract(Duration(days: 29 - i));
          return completed.where((b) =>
              b.updatedAt.year == day.year &&
              b.updatedAt.month == day.month &&
              b.updatedAt.day == day.day)
              .fold<double>(0, (s, b) => s + b.total * 0.9);
        });
        final max30 = last30.fold<double>(1000, (m, v) => v > m ? v : m) * 1.2;

        // totals
        final total7 = last7.fold<double>(0, (s, v) => s + v);
        final total30 = last30.fold<double>(0, (s, v) => s + v);
        final totalAll = completed.fold<double>(0, (s, b) => s + b.total * 0.9);
        final avg = completed.isEmpty ? 0.0 : totalAll / completed.length;
        final commission = completed.fold<double>(0, (s, b) => s + b.total * 0.1);
        final pendingCount = list.where((b) => b.status == BookingStatus.pending).length;
        final activeCount = list.where((b) =>
            b.status == BookingStatus.accepted ||
            b.status == BookingStatus.enroute ||
            b.status == BookingStatus.inprogress).length;
        final cancelRate = list.isEmpty
            ? 0.0
            : list.where((b) => b.status == BookingStatus.cancelled || b.status == BookingStatus.declined).length /
                list.length;

        // by service type
        final byType = <ServiceType, double>{};
        for (final b in completed) {
          byType[b.serviceType] = (byType[b.serviceType] ?? 0) + b.total * 0.9;
        }
        final byTypeTotal = byType.values.fold<double>(0, (s, v) => s + v);

        // top 5 days last 30
        final dayMap = <DateTime, double>{};
        for (final b in completed) {
          final d = DateTime(b.updatedAt.year, b.updatedAt.month, b.updatedAt.day);
          if (DateTime.now().difference(d).inDays > 30) continue;
          dayMap[d] = (dayMap[d] ?? 0) + b.total * 0.9;
        }
        final topDays = dayMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final axisColor = isDark ? AppColors.darkTextMute : AppColors.textMute;

        return ListView(padding: const EdgeInsets.all(14), children: [
          // hero balance
          Container(padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.orange, AppColors.orangeDark]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Available balance', style: TextStyle(color: Colors.white70)),
              Text(Fmt.etb(me.walletBalance), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.info_outline, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text('After 10% platform commission (paid: ${Fmt.etb(commission)})',
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ])),
          const SizedBox(height: 12),

          // 6 stat cards in 3x2 grid
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              _stat(context, 'This week', Fmt.etb(total7), Icons.calendar_today_outlined, AppColors.orange),
              _stat(context, '30 days', Fmt.etb(total30), Icons.date_range_outlined, AppColors.orangeDark),
              _stat(context, 'All time', Fmt.etb(totalAll), Icons.account_balance_wallet_outlined, AppColors.success),
              _stat(context, 'Avg / job', Fmt.etb(avg.round()), Icons.show_chart_rounded, AppColors.mint),
              _stat(context, 'Jobs done', completed.length.toString(), Icons.task_alt_rounded, AppColors.warn),
              _stat(context, 'Cancel %', '${(cancelRate * 100).toStringAsFixed(0)}%',
                  Icons.cancel_outlined, AppColors.danger),
            ],
          ),
          const SizedBox(height: 14),

          // Pipeline strip
          Card(child: Padding(padding: const EdgeInsets.all(14),
            child: Row(children: [
              _pipeBox(context, 'Pending', pendingCount, AppColors.warn),
              _pipeBox(context, 'Active', activeCount, AppColors.orange),
              _pipeBox(context, 'Completed', completed.length, AppColors.success),
            ]))),

          const SizedBox(height: 14),

          // 7-day bar
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Last 7 days', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: BarChart(BarChartData(
              maxY: maxY,
              gridData: FlGridData(show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: axisColor.withOpacity(0.15), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44,
                  getTitlesWidget: (v, _) => Text(
                      v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(),
                      style: TextStyle(fontSize: 10, color: axisColor)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, _) {
                    final day = DateTime.now().subtract(Duration(days: 6 - v.toInt()));
                    return Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][(day.weekday - 1) % 7],
                        style: TextStyle(fontSize: 10, color: axisColor)));
                  })),
              ),
              barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: last7[i], color: AppColors.orange, width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
              ])),
            ))),
          ]))),

          const SizedBox(height: 14),

          // 30-day line
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('30-day earnings trend', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: LineChart(LineChartData(
              minX: 0, maxX: 29, minY: 0, maxY: max30,
              gridData: FlGridData(show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: axisColor.withOpacity(0.12), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42,
                    getTitlesWidget: (v, _) => Text(
                        v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(),
                        style: TextStyle(fontSize: 9, color: axisColor)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 6,
                    getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4),
                        child: Text('${30 - v.toInt()}d', style: TextStyle(fontSize: 9, color: axisColor))))),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(30, (i) => FlSpot(i.toDouble(), last30[i])),
                  isCurved: true, curveSmoothness: 0.25,
                  color: AppColors.orange,
                  barWidth: 3, isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true,
                      gradient: LinearGradient(colors: [
                        AppColors.orange.withOpacity(0.30), AppColors.orange.withOpacity(0.02),
                      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                ),
              ],
            ))),
          ]))),

          if (byType.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Earnings by service type', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: PieChart(PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 36,
                sections: byType.entries.map((e) => PieChartSectionData(
                  value: e.value, color: _color(e.key),
                  title: '${(e.value / byTypeTotal * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  radius: 60,
                )).toList(),
              ))),
              const SizedBox(height: 12),
              ...byType.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _color(e.key), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(labelOf(e.key), style: const TextStyle(fontSize: 13))),
                Text(Fmt.etb(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]))),
            ]))),
          ],

          if (topDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Top earning days', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...topDays.take(5).map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.event_rounded, size: 16, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(Fmt.date(e.key), style: const TextStyle(fontSize: 13))),
                    Text(Fmt.etb(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]))),
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
                  child: Icon(t.amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      color: t.amount >= 0 ? AppColors.success : AppColors.danger)),
                title: Text(t.description),
                subtitle: Text(Fmt.dateTime(t.ts)),
                trailing: Text((t.amount >= 0 ? '+' : '') + Fmt.etb(t.amount.abs()),
                  style: TextStyle(fontWeight: FontWeight.w800, color: t.amount >= 0 ? AppColors.success : AppColors.danger)),
              ))).toList());
            },
          ),
          const SizedBox(height: 24),
        ]);
      },
    );
  }

  Widget _stat(BuildContext context, String label, String value, IconData ic, Color color) =>
      Card(child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(ic, color: color, size: 18)),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
        ]),
      ));

  Widget _pipeBox(BuildContext c, String label, int n, Color color) => Expanded(child: Column(children: [
    Text(n.toString(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 11, color: Theme.of(c).textTheme.bodySmall?.color)),
  ]));

  Color _color(ServiceType t) {
    switch (t) {
      case ServiceType.emergency_roadside: return AppColors.danger;
      case ServiceType.at_home: return AppColors.mint;
      case ServiceType.workshop: return AppColors.orange;
      case ServiceType.scheduled_maintenance: return AppColors.orangeDark;
      case ServiceType.detailing: return Colors.deepPurple;
      case ServiceType.custom: return Colors.teal;
    }
  }
}
