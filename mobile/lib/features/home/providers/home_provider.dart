import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/local_db_service.dart';

/// Estado del ciclo actual con fase y día calculados localmente.
/// Usa StreamProvider para actualizaciones reactivas en tiempo real.
final cycleProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final db = ref.read(localDbServiceProvider);
  return db.watchCurrentCycleStatus();
});

/// Registro del día de hoy.
/// Usa StreamProvider para actualizaciones reactivas en tiempo real.
final todayLogProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final db = ref.read(localDbServiceProvider);
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return db.watchLogForDate(dateStr);
});

/// Todos los registros diarios.
final logsProvider = StreamProvider.autoDispose<List>((ref) {
  final db = ref.read(localDbServiceProvider);
  return db.watchAllLogs();
});
