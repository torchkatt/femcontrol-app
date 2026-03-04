import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../../../shared/widgets/name_input_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo electrónico válido')),
      );
      return;
    }
    final ok = await ref.read(authProvider.notifier).login(email, password);
    if (ok && mounted) context.go('/home');
  }

  Future<void> _googleSignIn() async {
    final ok = await ref.read(authProvider.notifier).signInWithGoogle();
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
        context.go('/home');
      }
    });

    final state = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.terracotta, size: 28),
              ),
              const SizedBox(height: 24),
              const Text('Bienvenida de nuevo',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text('Ingresa a tu espacio seguro', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 36),

              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(state.error!, style: const TextStyle(color: AppColors.terracottaDark, fontSize: 14)),
                ),

              // ── Google Button ──────────────────────────────────
              GoogleSignInButton(onTap: _googleSignIn, isLoading: state.isLoading),
              const SizedBox(height: 20),
              const GoogleDivider(),
              const SizedBox(height: 20),

              // ── Email/Password ────────────────────────────────
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(text: 'Iniciar sesión', onPressed: _submit, isLoading: state.isLoading),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta? ', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Regístrate', style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Divider(color: AppColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
                Expanded(child: Divider(color: AppColors.divider)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final name = await showNameInputSheet(context);
                    if (!context.mounted) return;
                    await ref.read(authProvider.notifier).continueAsGuest(name: name);
                    if (context.mounted) context.go('/home');
                  },
                  icon: const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.textSecondary),
                  label: const Text(
                    'Continuar sin cuenta',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
