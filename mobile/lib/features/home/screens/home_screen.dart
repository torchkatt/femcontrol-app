import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/local_db_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:math' as math;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final cycleAsync = ref.watch(cycleProvider);
    final todayLogAsync = ref.watch(todayLogProvider);
    final userName = authState.user?['name']?.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                          userName != null ? 'Hola, $userName 👋' : '¡Bienvenida! 👋',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                      const Text('¿Cómo te sientes hoy?',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ]),
                    _ProfileButton(authState: authState),
                  ],
                ),
              ),
            ),

            // Banner de sincronización para invitados
            if (authState.isGuest)
              SliverToBoxAdapter(
                child: _SyncBanner(onTap: () => context.push('/login')),
              ),

            // Cycle Ring Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: cycleAsync.when(
                  loading: () => const _CycleRingCard(cycleData: null),
                  error: (_, __) => _NoCycleCard(onStart: () => _showStartCycleSheet(context, ref)),
                  data: (data) => data == null
                      ? _NoCycleCard(onStart: () => _showStartCycleSheet(context, ref))
                      : _CycleRingCard(cycleData: data),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.edit_note_rounded,
                        label: 'Registrar hoy',
                        color: AppColors.terracotta,
                        onTap: () => context.push('/log'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Mi historial',
                        color: AppColors.sage,
                        onTap: () => context.push('/history'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.favorite_border_rounded,
                        label: 'Mi pareja',
                        color: const Color(0xFF9D85BE),
                        onTap: () => context.push('/partner'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Today's summary 
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: const Text('Registro de hoy',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: todayLogAsync.when(
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(),
                  data: (log) => log == null
                      ? _EmptyLogCard(onTap: () => context.push('/log'))
                      : _TodayLogCard(log: log),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _showStartCycleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StartCycleSheet(onStarted: () => ref.invalidate(cycleProvider)),
    );
  }
}

class _CycleRingCard extends StatelessWidget {
  final Map<String, dynamic>? cycleData;
  const _CycleRingCard({this.cycleData});

  Color _phaseColor(String? phase) {
    switch (phase) {
      case 'menstrual': return AppColors.phaseMenstrual;
      case 'folicular': return AppColors.phaseFolicular;
      case 'ovulacion': return AppColors.phaseOvulacion;
      case 'lutea': return AppColors.phaseLutea;
      default: return AppColors.terracotta;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cycleData == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.terracotta.withOpacity(0.6), AppColors.terracottaLight.withOpacity(0.4)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final day = cycleData!['currentDay'] as int? ?? 1;
    final total = cycleData!['expectedLength'] as int? ?? 28;
    final phase = cycleData!['phase'] as String? ?? 'menstrual';
    final phaseName = AppConstants.phaseNames[phase] ?? phase;
    final phaseDesc = AppConstants.phaseDescriptions[phase] ?? '';
    final color = _phaseColor(phase);
    final progress = (day / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.9), color],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Fase $phaseName',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: 'Día $day', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    TextSpan(text: ' / $total', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18)),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(phaseDesc, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(painter: _RingPainter(progress: progress, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final bg = Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bg);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
    final tp = TextPainter(
      text: TextSpan(text: '${(progress * 100).round()}%', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _NoCycleCard extends StatelessWidget {
  final VoidCallback onStart;
  const _NoCycleCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.terracotta.withOpacity(0.7), AppColors.terracottaLight]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Sin ciclo activo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Toca aquí para registrar el inicio de tu ciclo', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ]),
            ),
            const Icon(Icons.add_circle_rounded, color: Colors.white, size: 44),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyLogCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyLogCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.terracotta.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: AppColors.terracotta, size: 24),
            ),
            const SizedBox(width: 16),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sin registro hoy', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
              Text('Toca para registrar cómo te sientes', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _TodayLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _TodayLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final flow = log['flowLevel'] as int?;
    final pain = log['painLevel'] as int?;
    final moods = List<String>.from(log['mood'] ?? []);
    return Container(
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
              Container(
                width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('Registrado hoy', style: TextStyle(color: AppColors.sage, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (flow != null) _MiniChip(label: 'Flujo: $flow/4', icon: Icons.water_drop_outlined),
              if (pain != null) ...[const SizedBox(width: 8), _MiniChip(label: 'Dolor: $pain/4', icon: Icons.thermostat)],
            ],
          ),
          if (moods.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: moods.take(3).map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.sageLight.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                child: Text(m, style: const TextStyle(fontSize: 11, color: AppColors.sageDark)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Banner de sincronización para invitados ───────────────────────────
class _SyncBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SyncBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF9D85BE).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9D85BE).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFF9D85BE)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Modo local · Toca para sincronizar con la nube',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9D85BE),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF9D85BE)),
          ],
        ),
      ),
    );
  }
}

// ── Botón de perfil / sesión ──────────────────────────────────────────
class _ProfileButton extends ConsumerWidget {
  final AuthState authState;
  const _ProfileButton({required this.authState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.bgCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _ProfileSheet(authState: authState),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: authState.isAuthenticated
              ? AppColors.sage.withOpacity(0.15)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          authState.isAuthenticated ? Icons.person_rounded : Icons.person_outline,
          color: authState.isAuthenticated ? AppColors.sage : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Hoja de perfil / sesión ───────────────────────────────────────────
class _ProfileSheet extends ConsumerWidget {
  final AuthState authState;
  const _ProfileSheet({required this.authState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Avatar
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: authState.isAuthenticated
                  ? AppColors.sage.withOpacity(0.15)
                  : AppColors.terracotta.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              authState.isAuthenticated ? Icons.person_rounded : Icons.phone_android_rounded,
              size: 30,
              color: authState.isAuthenticated ? AppColors.sage : AppColors.terracotta,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            authState.user?['name'] ?? 'Invitada',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authState.isAuthenticated
                ? (authState.user?['email'] ?? 'Cuenta activa')
                : 'Modo local — sin cuenta',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (authState.isGuest) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
                icon: const Icon(Icons.cloud_rounded, size: 18),
                label: const Text('Crear cuenta / Iniciar sesión'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Al crear cuenta, podrás sincronizar tus datos y vincular a tu pareja.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.terracottaDark,
                  side: const BorderSide(color: AppColors.terracottaDark),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MiniChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 12, color: AppColors.textSecondary), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))],
      ),
    );
  }
}

class _StartCycleSheet extends ConsumerStatefulWidget {
  final VoidCallback onStarted;
  const _StartCycleSheet({required this.onStarted});

  @override
  ConsumerState<_StartCycleSheet> createState() => _StartCycleSheetState();
}

class _StartCycleSheetState extends ConsumerState<_StartCycleSheet> {
  DateTime _selected = DateTime.now();
  int _length = 28;
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(localDbServiceProvider);
      // Normalizar fecha sin hora para evitar problemas de zona horaria
      final dateStr =
          '${_selected.year}-${_selected.month.toString().padLeft(2, '0')}-${_selected.day.toString().padLeft(2, '0')}';
      await db.startCycle(dateStr, expectedLength: _length);
      widget.onStarted();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Nuevo ciclo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          const Text('¿Cuándo comenzó tu periodo?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selected,
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selected = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.terracotta),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.terracotta, size: 18),
                  const SizedBox(width: 10),
                  Text('${_selected.day}/${_selected.month}/${_selected.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duración del ciclo', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              Text('$_length días', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          Slider(
            value: _length.toDouble(),
            min: 21, max: 35, divisions: 14,
            activeColor: AppColors.terracotta,
            onChanged: (v) => setState(() => _length = v.round()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Registrar ciclo'),
            ),
          ),
        ],
      ),
    );
  }
}
