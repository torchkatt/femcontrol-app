import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/name_input_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<_Slide> _slides = [
    _Slide(
      icon: Icons.lock_rounded,
      color: AppColors.terracotta,
      title: 'Tu privacidad, primero',
      body:
          'Tus datos de salud son tuyos. Todo se almacena en tu dispositivo — sin servidores, sin sorpresas.',
    ),
    _Slide(
      icon: Icons.auto_graph_rounded,
      color: AppColors.sage,
      title: 'Conoce tu ciclo',
      body:
          'Registra tu flujo, dolor, estado de ánimo y síntomas. FemControl aprende contigo cada mes.',
    ),
    _Slide(
      icon: Icons.cloud_sync_rounded,
      color: const Color(0xFF9D85BE),
      title: 'Sincroniza cuando quieras',
      body:
          'Usa la app sin cuenta. Cuando desees, crea tu cuenta para hacer respaldo en la nube y vincular a tu pareja.',
    ),
  ];

  Future<void> _markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
  }

  Future<void> _goToLogin() async {
    await _markOnboarded();
    if (mounted) context.go('/login');
  }

  Future<void> _continueAsGuest() async {
    // Mostrar BottomSheet para solicitar nombre antes de continuar
    final name = await showNameInputSheet(context);
    if (!mounted) return;
    await _markOnboarded();
    await ref.read(authProvider.notifier).continueAsGuest(name: name);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _current == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Indicadores de página
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _current == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _current == i
                              ? AppColors.terracotta
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!isLastSlide) ...[
                    // Slides 1 y 2: solo botón siguiente
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Siguiente'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _controller.animateToPage(
                        _slides.length - 1,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('Omitir'),
                    ),
                  ] else ...[
                    // Último slide: opciones de acceso
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _continueAsGuest,
                        icon: const Icon(Icons.phone_android_rounded, size: 18),
                        label: const Text('Continuar sin cuenta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _goToLogin,
                        icon: const Icon(Icons.cloud_rounded, size: 18),
                        label: const Text('Iniciar sesión / Crear cuenta'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin cuenta, tus datos solo están en este dispositivo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 60, color: slide.color),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

