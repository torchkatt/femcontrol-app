import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/local_db_service.dart';

/// Estado del ciclo actual con fase y día calculados localmente
final cycleProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final db = ref.read(localDbServiceProvider);
  return db.getCurrentCycleStatus();
});

/// Todos los registros diarios
final logsProvider = FutureProvider.autoDispose<List>((ref) async {
  final db = ref.read(localDbServiceProvider);
  return db.getAllLogs();
});

/// Registro del día de hoy
final todayLogProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final db = ref.read(localDbServiceProvider);
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return db.getLogForDate(dateStr);
});
