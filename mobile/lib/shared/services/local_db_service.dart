import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Claves de las cajas Hive
const _kCyclesBox = 'femcontrol_cycles';
const _kLogsBox = 'femcontrol_logs';
const _kSettingsBox = 'femcontrol_settings';

/// Claves de configuración
const _kUserName = 'userName';
const _kIsGuest = 'isGuest';

/// Servicio singleton de base de datos local (Hive).
/// Todos los datos se almacenan localmente en el dispositivo.
/// No requiere conexión a internet.
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  // ── Inicialización ────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_kCyclesBox);
    await Hive.openBox(_kLogsBox);
    await Hive.openBox(_kSettingsBox);
  }

  Box get _cycles => Hive.box(_kCyclesBox);
  Box get _logs => Hive.box(_kLogsBox);
  Box get _settings => Hive.box(_kSettingsBox);

  // ══════════════════════════════════════════════════════════════════
  // CICLOS
  // ══════════════════════════════════════════════════════════════════

  /// Guarda (o actualiza) un ciclo identificado por su 'id'.
  Future<void> _saveCycle(Map<String, dynamic> cycle) async {
    await _cycles.put(cycle['id'] as String, jsonEncode(cycle));
  }

  /// Devuelve el ciclo activo (sin endDate) más reciente, o null.
  Future<Map<String, dynamic>?> getActiveCycle() async {
    Map<String, dynamic>? active;
    DateTime? latestStart;

    for (final key in _cycles.keys) {
      final raw = _cycles.get(key) as String?;
      if (raw == null) continue;
      final cycle = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (cycle['endDate'] != null) continue; // Ya terminó
      final start = DateTime.parse(cycle['startDate'] as String);
      if (latestStart == null || start.isAfter(latestStart)) {
        latestStart = start;
        active = cycle;
      }
    }
    return active;
  }

  /// Devuelve el estado actual del ciclo con fase y día calculados.
  Future<Map<String, dynamic>?> getCurrentCycleStatus() async {
    final cycle = await getActiveCycle();
    if (cycle == null) return null;

    final startDate = DateTime.parse(cycle['startDate'] as String);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final currentDay = today.difference(start).inDays + 1;
    final expectedLength = cycle['expectedLength'] as int? ?? 28;
    final phase = _calculatePhase(currentDay);

    return {
      ...cycle,
      'currentDay': currentDay,
      'expectedLength': expectedLength,
      'phase': phase,
    };
  }

  /// Calcula la fase del ciclo según el día actual.
  String _calculatePhase(int day) {
    if (day <= 5) return 'menstrual';
    if (day <= 13) return 'folicular';
    if (day <= 16) return 'ovulacion';
    return 'lutea';
  }

  /// Inicia un nuevo ciclo. Cierra el activo anterior si existe.
  Future<void> startCycle(String startDate, {int expectedLength = 28}) async {
    // Cerrar el ciclo activo anterior
    final active = await getActiveCycle();
    if (active != null) {
      final updated = {...active, 'endDate': startDate};
      await _saveCycle(updated);
    }

    // Crear nuevo ciclo
    final id = 'cycle_${DateTime.now().millisecondsSinceEpoch}';
    await _saveCycle({
      'id': id,
      'startDate': startDate,
      'endDate': null,
      'expectedLength': expectedLength,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Devuelve el historial completo de ciclos, más reciente primero.
  Future<List<Map<String, dynamic>>> getCycleHistory() async {
    final cycles = <Map<String, dynamic>>[];
    for (final key in _cycles.keys) {
      final raw = _cycles.get(key) as String?;
      if (raw != null) {
        cycles.add(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
    }
    cycles.sort(
      (a, b) => (b['startDate'] as String).compareTo(a['startDate'] as String),
    );
    return cycles;
  }

  // ══════════════════════════════════════════════════════════════════
  // REGISTROS DIARIOS
  // ══════════════════════════════════════════════════════════════════

  /// Crea o actualiza el registro del día indicado.
  Future<void> upsertLog({
    required String logDate,
    int? flowLevel,
    int? painLevel,
    List<String>? mood,
    List<String>? symptoms,
    String? notes,
  }) async {
    final existing = _logs.get(logDate) as String?;
    final existingMap =
        existing != null
            ? Map<String, dynamic>.from(jsonDecode(existing) as Map)
            : <String, dynamic>{};

    final updated = {
      ...existingMap,
      'logDate': logDate,
      if (flowLevel != null) 'flowLevel': flowLevel,
      if (painLevel != null) 'painLevel': painLevel,
      if (mood != null) 'mood': mood,
      if (symptoms != null) 'symptoms': symptoms,
      if (notes != null) 'notes': notes,
      'updatedAt': DateTime.now().toIso8601String(),
      if (!existingMap.containsKey('createdAt'))
        'createdAt': DateTime.now().toIso8601String(),
    };

    await _logs.put(logDate, jsonEncode(updated));
  }

  /// Devuelve el registro de una fecha específica o null.
  Future<Map<String, dynamic>?> getLogForDate(String date) async {
    final raw = _logs.get(date) as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  /// Devuelve todos los registros (más reciente primero) con límite.
  Future<List<Map<String, dynamic>>> getAllLogs({int limit = 90}) async {
    final logs = <Map<String, dynamic>>[];
    for (final key in _logs.keys) {
      final raw = _logs.get(key) as String?;
      if (raw != null) {
        logs.add(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
    }
    logs.sort(
      (a, b) => (b['logDate'] as String).compareTo(a['logDate'] as String),
    );
    return logs.take(limit).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  // STREAMS REACTIVOS (actualizaciones en tiempo real via Hive.watch)
  // ══════════════════════════════════════════════════════════════════

  /// Stream del estado del ciclo: emite inmediatamente y cada vez que
  /// cambia la caja de ciclos.
  Stream<Map<String, dynamic>?> watchCurrentCycleStatus() async* {
    yield await getCurrentCycleStatus();
    await for (final _ in _cycles.watch()) {
      yield await getCurrentCycleStatus();
    }
  }

  /// Stream del registro de una fecha: emite inmediatamente y cada vez
  /// que cambia esa clave en la caja de logs.
  Stream<Map<String, dynamic>?> watchLogForDate(String date) async* {
    yield await getLogForDate(date);
    await for (final event in _logs.watch(key: date)) {
      final raw = event.value as String?;
      yield raw == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }
  }

  /// Stream de todos los registros: emite inmediatamente y cada vez que
  /// cambia cualquier clave en la caja de logs.
  Stream<List<Map<String, dynamic>>> watchAllLogs({int limit = 90}) async* {
    yield await getAllLogs(limit: limit);
    await for (final _ in _logs.watch()) {
      yield await getAllLogs(limit: limit);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN / USUARIO LOCAL
  // ══════════════════════════════════════════════════════════════════

  Future<void> setUserName(String name) =>
      _settings.put(_kUserName, name);

  Future<String?> getUserName() async =>
      _settings.get(_kUserName) as String?;

  Future<void> setGuestMode(bool value) =>
      _settings.put(_kIsGuest, value);

  Future<bool> isGuestMode() async =>
      (_settings.get(_kIsGuest) as bool?) ?? false;

  /// Limpia la sesión (sale de cuenta) pero conserva los datos locales.
  Future<void> clearSession() async {
    await _settings.delete(_kIsGuest);
  }

  // ── Mascota ────────────────────────────────────────────────────────

  Future<void> setSelectedPet(String petId) =>
      _settings.put('selectedPet', petId);

  String getSelectedPet() =>
      (_settings.get('selectedPet') as String?) ?? 'llama';
}

// ── Provider ──────────────────────────────────────────────────────────
final localDbServiceProvider = Provider<LocalDbService>(
  (_) => LocalDbService.instance,
);
