import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/partner_provider.dart';
import '../../../core/theme/app_theme.dart';

// ── Consejos por fase ─────────────────────────────────────────────────
const _phaseAdvice = <String, List<(String, IconData)>>{
  'menstrual': [
    ('Dale calor y mucho descanso', Icons.local_fire_department_rounded),
    ('Evita planear actividades exigentes', Icons.block_rounded),
    ('Una bolsa de agua caliente ayuda', Icons.water_drop_rounded),
  ],
  'folicular': [
    ('Buen momento para planes juntos', Icons.event_rounded),
    ('Está con más energía, aprovéchenlo', Icons.bolt_rounded),
    ('Apoya sus proyectos e ideas nuevas', Icons.star_rounded),
  ],
  'ovulacion': [
    ('Es su momento de mayor vitalidad', Icons.favorite_rounded),
    ('Disfruten tiempo de calidad juntos', Icons.people_rounded),
    ('Está comunicativa y muy abierta', Icons.chat_bubble_rounded),
  ],
  'lutea': [
    ('Puede estar más sensible de lo normal', Icons.sentiment_satisfied_rounded),
    ('Sé paciente y comprensivo con ella', Icons.volunteer_activism_rounded),
    ('Los antojos son normales en esta fase', Icons.local_dining_rounded),
  ],
};

Color _phaseColor(String phase) => switch (phase) {
      'menstrual' => AppColors.terracotta,
      'folicular' => const Color(0xFFD4875E),
      'ovulacion' => AppColors.sage,
      _ => const Color(0xFF9D85BE),
    };

String _phaseName(String phase) => switch (phase) {
      'menstrual' => 'Menstrual',
      'folicular' => 'Folicular',
      'ovulacion' => 'Ovulación',
      _ => 'Lútea',
    };

// ══════════════════════════════════════════════════════════════════════
// PartnerScreen
// ══════════════════════════════════════════════════════════════════════
class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  final _codeCtrl = TextEditingController();
  bool _linking = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _linking = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.pairPartner(code);
      ref.invalidate(partnerInfoProvider);
      ref.invalidate(partnerCycleStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pareja vinculada exitosamente! 💕'),
            backgroundColor: AppColors.sage,
          ),
        );
        _codeCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _unlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desvincular pareja'),
        content: const Text('¿Estás segura de que quieres desvincularte de tu pareja?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(apiServiceProvider).unlinkPartner();
        ref.invalidate(partnerInfoProvider);
        ref.invalidate(partnerCycleStatusProvider);
        ref.invalidate(sharingSettingsProvider);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi pareja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: authState.isGuest
          ? _GuestPartnerView(onCreateAccount: () => context.push('/login'))
          : _AuthenticatedPartnerView(
              codeCtrl: _codeCtrl,
              onPair: _pair,
              onUnlink: _unlink,
              linking: _linking,
              authState: authState,
            ),
    );
  }
}

// ── Vista para invitados ──────────────────────────────────────────────
class _GuestPartnerView extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const _GuestPartnerView({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF9D85BE).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, size: 50, color: Color(0xFF9D85BE)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Vincula a tu pareja',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Para vincular a tu pareja y que pueda ver tu estado de ciclo, necesitas crear una cuenta gratuita.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          _FeatureRow(icon: Icons.code_rounded, text: 'Código único de vinculación'),
          const SizedBox(height: 12),
          _FeatureRow(icon: Icons.visibility_rounded, text: 'Tu pareja ve tu fase actual'),
          const SizedBox(height: 12),
          _FeatureRow(icon: Icons.cloud_done_rounded, text: 'Respaldo seguro en la nube'),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateAccount,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Crear cuenta gratuita'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCreateAccount,
              child: const Text('Ya tengo cuenta — Iniciar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF9D85BE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF9D85BE)),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Vista para usuarios autenticados ─────────────────────────────────
class _AuthenticatedPartnerView extends ConsumerWidget {
  final TextEditingController codeCtrl;
  final VoidCallback onPair;
  final VoidCallback onUnlink;
  final bool linking;
  final AuthState authState;

  const _AuthenticatedPartnerView({
    required this.codeCtrl,
    required this.onPair,
    required this.onUnlink,
    required this.linking,
    required this.authState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(partnerInfoProvider);
    final myCode = authState.user?['pairingCode'] ?? '—';
    final userRole = authState.user?['role'] as String? ?? 'PRIMARY';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Código de vinculación — solo relevante para PRIMARY
          if (userRole == 'PRIMARY')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9D85BE), Color(0xFFB59FD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu código de vinculación',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          myCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                        tooltip: 'Copiar código',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: myCode)).then((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Código copiado al portapapeles! 📋'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Comparte este código con tu pareja para vincularse',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                  ),
                ],
              ),
            ),
          partnerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _NoPairedCard(codeCtrl: codeCtrl, onPair: onPair, linking: linking),
            data: (partner) => partner == null
                ? _NoPairedCard(codeCtrl: codeCtrl, onPair: onPair, linking: linking)
                : _PairedPartnerView(partner: partner, onUnlink: onUnlink, userRole: userRole),
          ),
        ],
      ),
    );
  }
}

// ── Sin pareja ────────────────────────────────────────────────────────
class _NoPairedCard extends StatelessWidget {
  final TextEditingController codeCtrl;
  final VoidCallback onPair;
  final bool linking;
  const _NoPairedCard({required this.codeCtrl, required this.onPair, required this.linking});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.favorite_border_rounded, size: 40, color: AppColors.terracotta),
            const SizedBox(height: 12),
            const Text(
              'Sin pareja vinculada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vincula a tu pareja para que pueda ver tu estado de ciclo y apoyarte mejor.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text(
          'Ingresar código de pareja',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            hintText: 'Pega o escribe el código aquí',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: linking ? null : onPair,
            icon: linking ? const SizedBox.shrink() : const Icon(Icons.favorite_rounded, size: 18),
            label: linking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Vincular pareja'),
          ),
        ),
      ],
    );
  }
}

// ── Con pareja vinculada ──────────────────────────────────────────────
class _PairedPartnerView extends ConsumerWidget {
  final Map<String, dynamic> partner;
  final VoidCallback onUnlink;
  final String userRole;
  const _PairedPartnerView({required this.partner, required this.onUnlink, required this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(partnerCycleStatusProvider);

    return Column(
      children: [
        cycleAsync.when(
          loading: () => _CycleLoadingCard(partnerName: partner['name'] ?? 'Pareja'),
          error: (_, __) => _CycleErrorCard(partnerName: partner['name'] ?? 'Pareja'),
          data: (cycle) {
            if (cycle == null || cycle['hasActiveCycle'] == false) {
              return _CycleErrorCard(partnerName: partner['name'] ?? 'Pareja', noData: true);
            }
            return _PartnerCycleCard(cycle: cycle);
          },
        ),
        const SizedBox(height: 16),
        cycleAsync.maybeWhen(
          data: (cycle) {
            if (cycle != null && cycle['hasActiveCycle'] == true) {
              return _PartnerLogCard(partnerName: partner['name'] ?? 'Pareja');
            }
            return const SizedBox.shrink();
          },
          orElse: () => const SizedBox.shrink(),
        ),
        // Configuración de privacidad — solo para PRIMARY
        if (userRole == 'PRIMARY') ...[
          const SizedBox(height: 16),
          const _SharingSettingsCard(),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onUnlink,
            icon: const Icon(Icons.link_off_rounded, size: 16),
            label: const Text('Desvincular pareja'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Card de ciclo de pareja ───────────────────────────────────────────
class _PartnerCycleCard extends StatelessWidget {
  final Map<String, dynamic> cycle;
  const _PartnerCycleCard({required this.cycle});

  @override
  Widget build(BuildContext context) {
    final phase = cycle['phase'] as String? ?? 'lutea';
    final phaseColor = _phaseColor(phase);
    final name = cycle['partnerName'] as String? ?? 'Pareja';
    final currentDay = cycle['currentDay'] as int? ?? 1;
    final expectedLength = cycle['expectedLength'] as int? ?? 28;
    final daysUntilPeriod = cycle['daysUntilPeriod'] as int? ?? 0;
    final advice = _phaseAdvice[phase] ?? _phaseAdvice['lutea']!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [phaseColor, phaseColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Fase ${_phaseName(phase)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CycleStat(label: 'Día del ciclo', value: '$currentDay de $expectedLength'),
                Container(width: 1, height: 36, color: Colors.white.withOpacity(0.3)),
                _CycleStat(label: 'Próximo período', value: 'En $daysUntilPeriod días'),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withOpacity(0.25)),
            const SizedBox(height: 16),
            // Consejos
            Text(
              'Cómo cuidarla hoy',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...advice.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(tip.$2, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _CycleStat extends StatelessWidget {
  final String label;
  final String value;
  const _CycleStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }
}

// ── Configuración de privacidad ───────────────────────────────────────
class _SharingSettingsCard extends ConsumerStatefulWidget {
  const _SharingSettingsCard();

  @override
  ConsumerState<_SharingSettingsCard> createState() => _SharingSettingsCardState();
}

class _SharingSettingsCardState extends ConsumerState<_SharingSettingsCard> {
  bool _savingFw = false;
  bool _savingSy = false;

  Future<void> _toggle(String field, bool value) async {
    setState(() => field == 'fertileWindow' ? _savingFw = true : _savingSy = true);
    try {
      await ref.read(apiServiceProvider).updateSharingSettings(
        fertileWindow: field == 'fertileWindow' ? value : null,
        symptoms: field == 'symptoms' ? value : null,
      );
      ref.invalidate(sharingSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: AppColors.sage,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => field == 'fertileWindow' ? _savingFw = false : _savingSy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(sharingSettingsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Privacidad',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '¿Qué puede ver tu pareja de tu ciclo?',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('No se pudo cargar la configuración',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            data: (settings) {
              final fw = settings['fertileWindow'] as bool? ?? true;
              final sy = settings['symptoms'] as bool? ?? false;
              return Column(
                children: [
                  _SettingRow(
                    icon: Icons.calendar_month_rounded,
                    title: 'Ventana fértil',
                    subtitle: 'Tu pareja verá cuándo eres más fértil',
                    value: fw,
                    loading: _savingFw,
                    onChanged: (v) => _toggle('fertileWindow', v),
                  ),
                  const SizedBox(height: 12),
                  _SettingRow(
                    icon: Icons.medication_liquid_rounded,
                    title: 'Síntomas del día',
                    subtitle: 'Tu pareja verá tu registro diario',
                    value: sy,
                    loading: _savingSy,
                    onChanged: (v) => _toggle('symptoms', v),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.terracotta.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.terracotta),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.terracotta,
              ),
      ],
    );
  }
}

// ── Card para registrar síntomas ──────────────────────────────────────
const _moods = [
  ('😊', 'Bien'),
  ('😔', 'Triste'),
  ('😤', 'Irritable'),
  ('😴', 'Cansada'),
  ('😰', 'Ansiosa'),
];

class _PartnerLogCard extends ConsumerStatefulWidget {
  final String partnerName;
  const _PartnerLogCard({required this.partnerName});

  @override
  ConsumerState<_PartnerLogCard> createState() => _PartnerLogCardState();
}

class _PartnerLogCardState extends ConsumerState<_PartnerLogCard> {
  int? _flow;
  int? _pain;
  final Set<String> _mood = {};
  bool _saving = false;

  Future<void> _save() async {
    if (_flow == null && _pain == null && _mood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un dato para guardar')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final today = DateTime.now();
      final logDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await ref.read(apiServiceProvider).createLogForPartner(
            logDate: logDate,
            flowLevel: _flow,
            painLevel: _pain,
            mood: _mood.isEmpty ? null : _mood.toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registro guardado para ${widget.partnerName} 💕'),
            backgroundColor: AppColors.sage,
          ),
        );
        setState(() {
          _flow = null;
          _pain = null;
          _mood.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registrar síntomas de hoy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Ayúdala llevando el registro',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          // Flujo
          const Text(
            'Flujo',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LevelButton(
                label: 'Sin flujo',
                level: 0,
                selected: _flow == 0,
                onTap: () => setState(() => _flow = _flow == 0 ? null : 0),
                colors: const [Color(0xFFBDBDBD), Color(0xFFFFB74D), Color(0xFFEF9A9A), AppColors.terracotta],
              ),
              const SizedBox(width: 6),
              _LevelButton(
                label: 'Leve',
                level: 1,
                selected: _flow == 1,
                onTap: () => setState(() => _flow = _flow == 1 ? null : 1),
                colors: const [Color(0xFFBDBDBD), Color(0xFFFFB74D), Color(0xFFEF9A9A), AppColors.terracotta],
              ),
              const SizedBox(width: 6),
              _LevelButton(
                label: 'Moderado',
                level: 2,
                selected: _flow == 2,
                onTap: () => setState(() => _flow = _flow == 2 ? null : 2),
                colors: const [Color(0xFFBDBDBD), Color(0xFFFFB74D), Color(0xFFEF9A9A), AppColors.terracotta],
              ),
              const SizedBox(width: 6),
              _LevelButton(
                label: 'Abundante',
                level: 3,
                selected: _flow == 3,
                onTap: () => setState(() => _flow = _flow == 3 ? null : 3),
                colors: const [Color(0xFFBDBDBD), Color(0xFFFFB74D), Color(0xFFEF9A9A), AppColors.terracotta],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dolor
          const Text(
            'Dolor',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LevelButton(
                label: 'Sin dolor',
                level: 0,
                selected: _pain == 0,
                onTap: () => setState(() => _pain = _pain == 0 ? null : 0),
                colors: const [Color(0xFFBDBDBD), Color(0xFF81C784), Color(0xFFFFB74D), Color(0xFFE57373)],
              ),
              const SizedBox(width: 6),
              _LevelButton(
                label: 'Leve',
                level: 1,
                selected: _pain == 1,
                onTap: () => setState(() => _pain = _pain == 1 ? null : 1),
                colors: const [Color(0xFFBDBDBD), Color(0xFF81C784), Color(0xFFFFB74D), Color(0xFFE57373)],
              ),
              const SizedBox(width: 6),
              _LevelButton(
                label: 'Moderado',
                level: 2,
                selected: _pain == 2,
                onTap: () => setState(() => _pain = _pain == 2 ? null : 2),
                colors: const [Color(0xFFBDBDBD), Color(0xFF81C784), Color(0xFFFFB74D), Color(0xFFE57373)],
              ),
              const SizedBox(width: 6),
              _LevelButton(
                label: 'Fuerte',
                level: 3,
                selected: _pain == 3,
                onTap: () => setState(() => _pain = _pain == 3 ? null : 3),
                colors: const [Color(0xFFBDBDBD), Color(0xFF81C784), Color(0xFFFFB74D), Color(0xFFE57373)],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Estado de ánimo
          const Text(
            'Estado de ánimo',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moods.map((m) {
              final isSelected = _mood.contains(m.$2);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _mood.remove(m.$2);
                  } else {
                    _mood.add(m.$2);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.terracotta.withOpacity(0.12) : AppColors.bgCream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.terracotta : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '${m.$1} ${m.$2}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.terracottaDark : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar registro'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String label;
  final int level;
  final bool selected;
  final VoidCallback onTap;
  final List<Color> colors;
  const _LevelButton({
    required this.label,
    required this.level,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final color = colors[level];
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : AppColors.bgCream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: selected ? color : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Loading / Error ───────────────────────────────────────────────────
class _CycleLoadingCard extends StatelessWidget {
  final String partnerName;
  const _CycleLoadingCard({required this.partnerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text('Cargando ciclo de $partnerName…', style: const TextStyle(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _CycleErrorCard extends StatelessWidget {
  final String partnerName;
  final bool noData;
  const _CycleErrorCard({required this.partnerName, this.noData = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF9D85BE).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFF9D85BE), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                partnerName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                noData
                    ? 'Aún no tiene un ciclo activo registrado'
                    : 'No se pudo cargar el ciclo',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
