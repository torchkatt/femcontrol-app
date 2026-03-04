import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/local_db_service.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

// ── Ciclo actual ──────────────────────────────────────────────────────
/// Si el usuario está autenticado, obtiene el ciclo desde el backend.
/// Si es invitado, usa Hive (local).
final cycleProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authProvider);

  if (authState.isAuthenticated) {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCurrentCycle();
      return res['data'] as Map<String, dynamic>?;
    } on Object catch (e) {
      // Si el backend falla (cold start, red), intentar con Hive
      if (kDebugMode) debugPrint('[cycleProvider] Backend error: $e – falling back to Hive');
      return ref.read(localDbServiceProvider).getCurrentCycleStatus();
    }
  }

  // Modo invitado → Hive
  return ref.read(localDbServiceProvider).getCurrentCycleStatus();
});

// ── Registro de hoy ────────────────────────────────────────────────────
/// Si autenticado: backend. Si invitado: Hive.
final todayLogProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authProvider);
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  if (authState.isAuthenticated) {
    try {
      final api = ref.read(apiServiceProvider);
      return await api.getLogForDate(dateStr);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[todayLogProvider] Backend error: $e – falling back to Hive');
      return ref.read(localDbServiceProvider).getLogForDate(dateStr);
    }
  }

  return ref.read(localDbServiceProvider).getLogForDate(dateStr);
});

/// Todos los registros diarios (para historial).
final logsProvider = FutureProvider.autoDispose<List>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated) {
    try {
      final api = ref.read(apiServiceProvider);
      return await api.getLogs();
    } on Object catch (_) {
      return ref.read(localDbServiceProvider).getAllLogs();
    }
  }
  return ref.read(localDbServiceProvider).getAllLogs();
});
