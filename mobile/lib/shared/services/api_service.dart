import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
    },
  ))..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        return handler.next(e);
      },
    ),
  );

  Future<void> saveToken(String token) => _storage.write(key: 'token', value: token);
  Future<String?> getToken() => _storage.read(key: 'token');
  Future<void> deleteToken() => _storage.delete(key: 'token');

  Future<void> warmup() async {
    try {
      await _dio.get('/health',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 90),
          ));
    } catch (_) {}
  }

  // Auth
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final res = await _dio.post('/auth/register', data: {'email': email, 'password': password, 'name': name});
    return res.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return res.data;
  }

  Future<Map<String, dynamic>> googleAuth({String? idToken, String? serverAuthCode}) async {
    final res = await _dio.post('/auth/google', data: {
      if (idToken != null) 'idToken': idToken,
      if (serverAuthCode != null) 'serverAuthCode': serverAuthCode,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/auth/profile');
    return res.data;
  }

  // Cycles
  Future<Map<String, dynamic>> getCurrentCycle() async {
    final res = await _dio.get('/cycles/current');
    return res.data;
  }

  Future<Map<String, dynamic>> startCycle(String startDate, {int expectedLength = 28}) async {
    final res = await _dio.post('/cycles', data: {'startDate': startDate, 'expectedLength': expectedLength});
    return res.data;
  }

  Future<List> getCycleHistory() async {
    final res = await _dio.get('/cycles/history');
    return res.data['data'] as List;
  }

  // Daily logs
  Future<List> getLogs() async {
    final res = await _dio.get('/logs');
    return res.data['data'] as List;
  }

  Future<Map<String, dynamic>> upsertLog({
    required String logDate,
    int? flowLevel,
    int? painLevel,
    List<String>? mood,
    List<String>? symptoms,
    String? notes,
  }) async {
    final res = await _dio.post('/logs', data: {
      'logDate': logDate,
      if (flowLevel != null) 'flowLevel': flowLevel,
      if (painLevel != null) 'painLevel': painLevel,
      if (mood != null) 'mood': mood,
      if (symptoms != null) 'symptoms': symptoms,
      if (notes != null) 'notes': notes,
    });
    return res.data;
  }

  Future<Map<String, dynamic>?> getLogForDate(String date) async {
    try {
      final res = await _dio.get('/logs/$date');
      return res.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // Couple
  Future<Map<String, dynamic>> pairPartner(String code) async {
    final res = await _dio.post('/couple/pair', data: {'pairingCode': code});
    return res.data;
  }

  Future<Map<String, dynamic>> getPartnerInfo() async {
    final res = await _dio.get('/couple/partner');
    return res.data;
  }

  Future<void> unlinkPartner() async {
    await _dio.delete('/couple/unlink');
  }

  Future<Map<String, dynamic>> getPartnerCycleStatus() async {
    final res = await _dio.get('/couple/partner/cycle');
    return res.data;
  }

  Future<Map<String, dynamic>> createLogForPartner({
    required String logDate,
    int? flowLevel,
    int? painLevel,
    List<String>? mood,
    List<String>? symptoms,
    String? notes,
  }) async {
    final res = await _dio.post('/couple/partner/log', data: {
      'logDate': logDate,
      if (flowLevel != null) 'flowLevel': flowLevel,
      if (painLevel != null) 'painLevel': painLevel,
      if (mood != null) 'mood': mood,
      if (symptoms != null) 'symptoms': symptoms,
      if (notes != null) 'notes': notes,
    });
    return res.data;
  }
}
