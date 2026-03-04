import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/daily_log/screens/daily_log_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/partner/screens/partner_screen.dart';
import '../../features/pet/screens/pet_selection_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // Mientras se verifica el estado inicial, no redirigir
      if (authState.isInitializing) return null;

      final canAccess = authState.canUseApp;
      final loc = state.matchedLocation;

      final onPublicPage = loc == '/splash' ||
          loc == '/onboarding' ||
          loc == '/login' ||
          loc == '/register';

      // Sin acceso en página protegida → login
      if (!canAccess && !onPublicPage) return '/login';

      // Solo usuarios completamente autenticados se redirigen desde auth pages → home
      // Invitados pueden navegar a /login o /register para crear cuenta
      if (authState.isAuthenticated && onPublicPage && loc != '/splash') return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/log', builder: (c, s) => const DailyLogScreen()),
      GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
      GoRoute(path: '/partner', builder: (c, s) => const PartnerScreen()),
      GoRoute(path: '/pet-selection', builder: (c, s) => const PetSelectionScreen()),
    ],
  );
});
