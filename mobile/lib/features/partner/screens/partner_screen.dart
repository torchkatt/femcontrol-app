import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

final _partnerProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final res = await api.getPartnerInfo();
    return res['data'];
  } catch (_) {
    return null;
  }
});

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
      ref.invalidate(_partnerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pareja vinculada exitosamente! 💕'), backgroundColor: AppColors.sage),
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
        ref.invalidate(_partnerProvider);
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
            child: const Icon(
              Icons.favorite_rounded,
              size: 50,
              color: Color(0xFF9D85BE),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Vincula a tu pareja',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Para vincular a tu pareja y que pueda ver tu estado de ciclo, necesitas crear una cuenta gratuita.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
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
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Vista para usuarios autenticados ─────────────────────────────────
class _AuthenticatedPartnerView extends ConsumerStatefulWidget {
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
  ConsumerState<_AuthenticatedPartnerView> createState() =>
      _AuthenticatedPartnerViewState();
}

class _AuthenticatedPartnerViewState
    extends ConsumerState<_AuthenticatedPartnerView> {
  @override
  Widget build(BuildContext context) {
    final partnerAsync = ref.watch(_partnerProvider);
    final myCode = widget.authState.user?['pairingCode'] ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Código de vinculación
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
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
                          if (mounted) {
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
                const SizedBox(height: 8),
                Text(
                  'Comparte este código con tu pareja para vincularse',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          partnerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _NoPairedCard(
              codeCtrl: widget.codeCtrl,
              onPair: widget.onPair,
              linking: widget.linking,
            ),
            data: (partner) => partner == null
                ? _NoPairedCard(
                    codeCtrl: widget.codeCtrl,
                    onPair: widget.onPair,
                    linking: widget.linking,
                  )
                : _PairedCard(
                    partner: partner,
                    onUnlink: widget.onUnlink,
                  ),
          ),
        ],
      ),
    );
  }
}

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
            const Text('Sin pareja vinculada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text(
              'Vincula a tu pareja para que pueda ver tu estado de ciclo y apoyarte mejor.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Ingresar código de pareja', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
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
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Vincular pareja'),
          ),
        ),
      ],
    );
  }
}

class _PairedCard extends StatelessWidget {
  final Map<String, dynamic> partner;
  final VoidCallback onUnlink;
  const _PairedCard({required this.partner, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    final cycles = partner['cycles'] as List?;
    final lastCycle = cycles != null && cycles.isNotEmpty ? cycles.first as Map<String, dynamic> : null;
    final name = partner['name'] ?? 'Pareja';

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
                width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFF9D85BE).withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, color: Color(0xFF9D85BE), size: 26),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Text('Pareja vinculada', style: TextStyle(fontSize: 13, color: AppColors.sage)),
              ]),
              const Spacer(),
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
              ),
            ],
          ),
          if (lastCycle != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            const Text('Último ciclo registrado', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.terracotta),
              const SizedBox(width: 6),
              Text(
                'Inicio: ${(lastCycle['startDate'] as String).substring(0, 10)}',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUnlink,
              icon: const Icon(Icons.link_off_rounded, size: 16),
              label: const Text('Desvincular pareja'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
