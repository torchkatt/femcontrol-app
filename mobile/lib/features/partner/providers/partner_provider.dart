import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

final partnerInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final res = await api.getPartnerInfo();
    return res['data'];
  } catch (_) {
    return null;
  }
});

final partnerCycleStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final res = await api.getPartnerCycleStatus();
    return res['data'] as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
});

final sharingSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final res = await api.getSharingSettings();
    return (res['data'] as Map<String, dynamic>?) ?? {'fertileWindow': true, 'symptoms': false};
  } catch (_) {
    return {'fertileWindow': true, 'symptoms': false};
  }
});
