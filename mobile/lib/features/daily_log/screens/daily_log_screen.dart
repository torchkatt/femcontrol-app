import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/local_db_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  double _flow = 0;
  double _pain = 0;
  final Set<String> _moods = {};
  final Set<String> _symptoms = {};
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  bool _hasPeriod = false;

  @override
  void initState() {
    super.initState();
    // Pre-rellena con el registro del día si ya existe
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingLog());
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Carga el registro del día actual y pre-rellena el formulario.
  Future<void> _loadExistingLog() async {
    final db = ref.read(localDbServiceProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final log = await db.getLogForDate(today);
    if (log == null || !mounted) return;
    setState(() {
      final flow = log['flowLevel'] as int?;
      if (flow != null && flow > 0) {
        _hasPeriod = true;
        _flow = flow.toDouble();
      }
      final pain = log['painLevel'] as int?;
      if (pain != null && pain > 0) _pain = pain.toDouble();
      _moods.addAll(List<String>.from(log['mood'] ?? []));
      _symptoms.addAll(List<String>.from(log['symptoms'] ?? []));
      final notes = log['notes'] as String?;
      if (notes != null && notes.isNotEmpty) _notesCtrl.text = notes;
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(localDbServiceProvider);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await db.upsertLog(
        logDate: today,
        flowLevel: _hasPeriod ? _flow.round() : 0,
        painLevel: _pain.round(),
        mood: _moods.toList(),
        symptoms: _symptoms.toList(),
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro guardado! 🌸'),
            backgroundColor: AppColors.sage,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de hoy'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta))
                : const Text('Guardar', style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Período toggle
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.terracotta.withOpacity(0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.terracotta, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('¿Tienes el período hoy?', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                    Text(_hasPeriod ? 'Sí, tengo el período' : 'No hoy', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                  const Spacer(),
                  Switch(value: _hasPeriod, onChanged: (v) => setState(() => _hasPeriod = v), activeColor: AppColors.terracotta),
                ],
              ),
            ),

            // Flow slider
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _hasPeriod ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _SectionTitle(icon: Icons.water_drop_rounded, title: 'Intensidad del flujo', value: _flowLabel(_flow)),
                  Slider(
                    value: _flow, min: 0, max: 4, divisions: 4,
                    activeColor: AppColors.terracotta,
                    onChanged: (v) => setState(() => _flow = v),
                  ),
                  _ScaleLabels(labels: const ['—', 'Leve', 'Moderado', 'Abundante', 'Muy abd.']),
                ],
              ) : const SizedBox(),
            ),

            const SizedBox(height: 20),
            // Pain slider
            _SectionTitle(icon: Icons.thermostat_rounded, title: 'Dolor o malestar', value: _painLabel(_pain)),
            Slider(
              value: _pain, min: 0, max: 4, divisions: 4,
              activeColor: const Color(0xFF9D85BE),
              onChanged: (v) => setState(() => _pain = v),
            ),
            _ScaleLabels(labels: const ['—', 'Leve', 'Moderado', 'Fuerte', 'Intenso']),

            const SizedBox(height: 24),
            // Moods
            _SectionTitle(icon: Icons.emoji_emotions_outlined, title: 'Estado de ánimo', value: '${_moods.length} seleccionados'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.moods.map((m) {
                final sel = _moods.contains(m);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => sel ? _moods.remove(m) : _moods.add(m)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.sage : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: sel ? AppColors.sage : AppColors.divider),
                    ),
                    child: Text(m, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            // Symptoms
            _SectionTitle(icon: Icons.medical_information_outlined, title: 'Síntomas', value: '${_symptoms.length} seleccionados'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.symptoms.map((s) {
                final sel = _symptoms.contains(s);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => sel ? _symptoms.remove(s) : _symptoms.add(s)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF9D85BE) : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: sel ? const Color(0xFF9D85BE) : AppColors.divider),
                    ),
                    child: Text(s, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            // Notes
            _SectionTitle(icon: Icons.notes_rounded, title: 'Notas libres', value: ''),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Escribe lo que sientes o quieres recordar...'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _flowLabel(double v) => ['—', 'Leve', 'Moderado', 'Abundante', 'Muy abundante'][v.round()];
  String _painLabel(double v) => ['—', 'Leve', 'Moderado', 'Fuerte', 'Intenso'][v.round()];
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _SectionTitle({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.terracotta),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)),
        const Spacer(),
        if (value.isNotEmpty)
          Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _ScaleLabels extends StatelessWidget {
  final List<String> labels;
  const _ScaleLabels({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((l) => Text(l, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))).toList(),
    );
  }
}
