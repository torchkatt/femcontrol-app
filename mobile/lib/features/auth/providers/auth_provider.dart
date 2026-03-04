import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/local_db_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final _googleSignIn = GoogleSignIn(
  clientId:
      '461405054411-qkeock8ojquvkf4aoqkoo279pietusvl.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

// ── Estado de autenticación ───────────────────────────────────────────
class AuthState {
  final bool isAuthenticated; // Tiene cuenta + token válido
  final bool isGuest; // Usa la app sin cuenta (datos locales)
  final bool isInitializing; // Verificando estado al arrancar
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isGuest = false,
    this.isInitializing = true,
    this.user,
    this.isLoading = false,
    this.error,
  });

  /// Puede acceder a la app (sea invitado o autenticado)
  bool get canUseApp => isAuthenticated || isGuest;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isGuest,
    bool? isInitializing,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      isInitializing: isInitializing ?? this.isInitializing,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final LocalDbService _db;

  AuthNotifier(this._api, this._db) : super(const AuthState()) {
    _initialize();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (account != null && kIsWeb) {
        _handleGoogleAccount(account);
      }
    });
  }

  // ── Inicialización ─────────────────────────────────────────────────

  Future<void> _initialize() async {
    // 1. Intentar validar token de nube
    final token = await _api.getToken();
    if (token != null) {
      // Despertar el servidor en paralelo con la validación del token
      unawaited(_api.warmup());
      try {
        final profile = await _api.getProfile();
        state = state.copyWith(
          isAuthenticated: true,
          isGuest: false,
          isInitializing: false,
          user: profile['data'],
        );
        return;
      } catch (_) {
        // Token inválido → eliminar
        await _api.deleteToken();
      }
    }

    // 2. Verificar si venía usando la app como invitado
    final isGuest = await _db.isGuestMode();
    if (isGuest) {
      final name = await _db.getUserName();
      state = state.copyWith(
        isGuest: true,
        isInitializing: false,
        user: name != null ? {'name': name} : null,
        clearError: true,
      );
      return;
    }

    // 3. Ni token ni invitado → despertar servidor en background y mostrar login
    unawaited(_api.warmup());
    state = state.copyWith(isInitializing: false, clearError: true);
  }

  // ── Modo invitado ──────────────────────────────────────────────────

  /// Activa el modo invitado: todos los datos se guardan localmente.
  Future<void> continueAsGuest({String? name}) async {
    await _db.setGuestMode(true);
    if (name != null && name.isNotEmpty) await _db.setUserName(name);
    final savedName = name ?? await _db.getUserName();
    state = state.copyWith(
      isGuest: true,
      isAuthenticated: false,
      isInitializing: false,
      clearUser: savedName == null,
      user: savedName != null ? {'name': savedName} : null,
      clearError: true,
    );
  }

  // ── Google ─────────────────────────────────────────────────────────

  Future<void> _handleGoogleAccount(GoogleSignInAccount googleUser) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('No se pudo obtener el token de Google');

      final res = await _api.googleAuth(idToken: idToken);
      await _api.saveToken(res['data']['token']);
      await _db.setGuestMode(false);
      state = state.copyWith(
        isAuthenticated: true,
        isGuest: false,
        user: res['data']['user'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final googleUser = await _googleSignIn.signIn();

      // En web, el resultado llega por onCurrentUserChanged.
      // Si signIn() devuelve null, el listener se encarga cuando el OAuth complete.
      // Si devuelve non-null, el listener ya disparó _handleGoogleAccount → evitar duplicado.
      if (kIsWeb) {
        if (googleUser == null) state = state.copyWith(isLoading: false);
        return false;
      }

      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('No se pudo obtener el token de Google');

      final res = await _api.googleAuth(idToken: idToken);
      await _api.saveToken(res['data']['token']);
      await _db.setGuestMode(false);
      state = state.copyWith(
        isAuthenticated: true,
        isGuest: false,
        user: res['data']['user'],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  // ── Email / Contraseña ─────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.login(email, password);
      await _api.saveToken(res['data']['token']);
      await _db.setGuestMode(false);
      state = state.copyWith(
        isAuthenticated: true,
        isGuest: false,
        user: res['data']['user'],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, {String role = 'PRIMARY'}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.register(email, password, name, role: role);
      await _api.saveToken(res['data']['token']);
      await _db.setGuestMode(false);
      state = state.copyWith(
        isAuthenticated: true,
        isGuest: false,
        user: res['data']['user'],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  // ── Cerrar sesión ─────────────────────────────────────────────────

  /// Cierra la sesión en la nube pero mantiene los datos locales
  /// y activa el modo invitado automáticamente.
  Future<void> logout() async {
    await _api.deleteToken();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _db.setGuestMode(true);
    final name = await _db.getUserName();
    state = AuthState(
      isGuest: true,
      isInitializing: false,
      user: name != null ? {'name': name} : null,
    );
  }

  // ── Utilidades ────────────────────────────────────────────────────

  String _parseError(dynamic e) {
    final str = e.toString();
    // Errores de red / servidor no disponible
    if (str.contains('SocketException') ||
        str.contains('Connection refused') ||
        str.contains('failed host lookup') ||
        str.contains('Network is unreachable') ||
        str.contains('errno = 111')) {
      return 'Servidor no disponible. La sincronización en la nube no está activa.';
    }
    if (str.contains('DioException')) {
      if (str.contains('timed out') || str.contains('connection timeout')) {
        return 'El servidor está iniciando, puede tardar hasta un minuto. Intenta de nuevo.';
      }
      if (str.contains('connection') || str.contains('refused') ||
          str.contains('No route to host')) {
        return 'Servidor no disponible. La sincronización en la nube no está activa.';
      }
      try {
        final data = (e as dynamic).response?.data;
        return data?['message'] ?? 'Error de conexión con el servidor';
      } catch (_) {}
      return 'Error de conexión con el servidor';
    }
    return str.replaceAll('Exception: ', '');
  }
}

// ── Provider global ───────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiServiceProvider),
    LocalDbService.instance,
  );
});
