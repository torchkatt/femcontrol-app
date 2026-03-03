import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/local_db_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

final _historyProvider = FutureProvider.autoDispose<List>((ref) async {
  final db = ref.read(localDbServiceProvider);
  return db.getAllLogs();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi historial'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_month_outlined, size: 64, color: AppColors.divider),
                SizedBox(height: 16),
                Text('No hay registros aún', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                SizedBox(height: 8),
                Text('Empieza registrando tu primer día', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            );
          }

          // Build calendar grid
          final now = DateTime.now();
          final logMap = <String, Map<String, dynamic>>{};
          for (final log in logs) {
            final dateStr = (log['logDate'] as String).substring(0, 10);
            logMap[dateStr] = log as Map<String, dynamic>;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _CalendarLegend(),
                _MonthCalendar(year: now.year, month: now.month, logMap: logMap),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: logs.length,
                  itemBuilder: (_, i) => _LogTile(log: logs[i] as Map<String, dynamic>),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(color: AppColors.phaseMenstrual, label: 'Período'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.sage, label: 'Registrado'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.divider, label: 'Sin datos'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final int year, month;
  final Map<String, Map<String, dynamic>> logMap;
  const _MonthCalendar({required this.year, required this.month, required this.logMap});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(DateFormat.yMMMM('es').format(firstDay),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
                .map((d) => Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final log = logMap[dateStr];
              final now2 = DateTime.now();
              final isToday = now2.year == year && now2.month == month && now2.day == day;

              Color dotColor = AppColors.divider;
              if (log != null) {
                dotColor = (log['flowLevel'] != null && (log['flowLevel'] as int) > 0) ? AppColors.phaseMenstrual : AppColors.sage;
              }

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.terracotta : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Text('$day', style: TextStyle(fontSize: 13, color: isToday ? Colors.white : AppColors.textPrimary, fontWeight: isToday ? FontWeight.w700 : FontWeight.normal)),
                  if (log != null)
                    Positioned(bottom: 4, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: isToday ? Colors.white : dotColor, shape: BoxShape.circle))),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = log['logDate'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final moods = List<String>.from(log['mood'] ?? []);
    final hasFlow = (log['flowLevel'] as int?) != null && (log['flowLevel'] as int) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: hasFlow ? AppColors.phaseMenstrual.withOpacity(0.12) : AppColors.sage.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFlow ? Icons.water_drop_rounded : Icons.check_circle_outline_rounded,
              color: hasFlow ? AppColors.phaseMenstrual : AppColors.sage,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('EEE, d MMM', 'es').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
              if (moods.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(moods.take(2).join(' · '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ]),
          ),
          if (log['painLevel'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
              child: Text('Dolor ${log['painLevel']}/4', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}
