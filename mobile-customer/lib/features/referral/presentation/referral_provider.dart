import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/referral_repository.dart';
import '../domain/referral_info.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class ReferralState {
  final ReferralInfo? info;
  final bool isApplyingCode;
  final String? applyError;
  final String? applySuccessMessage;

  const ReferralState({
    this.info,
    this.isApplyingCode = false,
    this.applyError,
    this.applySuccessMessage,
  });

  ReferralState copyWith({
    ReferralInfo? info,
    bool? isApplyingCode,
    String? applyError,
    String? applySuccessMessage,
    bool clearApplyError = false,
    bool clearApplySuccess = false,
  }) =>
      ReferralState(
        info: info ?? this.info,
        isApplyingCode: isApplyingCode ?? this.isApplyingCode,
        applyError: clearApplyError ? null : (applyError ?? this.applyError),
        applySuccessMessage: clearApplySuccess
            ? null
            : (applySuccessMessage ?? this.applySuccessMessage),
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class ReferralNotifier extends AsyncNotifier<ReferralState> {
  @override
  Future<ReferralState> build() async => _load();

  Future<ReferralState> _load() async {
    final repo = ref.read(referralRepositoryProvider);
    final info = await repo.getReferralInfo();
    return ReferralState(info: info);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> applyCode(String code) async {
    final current = state.valueOrNull ?? const ReferralState();
    state = AsyncValue.data(current.copyWith(
      isApplyingCode: true,
      clearApplyError: true,
      clearApplySuccess: true,
    ));

    try {
      final repo = ref.read(referralRepositoryProvider);
      final result = await repo.applyReferralCode(code);
      final discountPct = (result['discountPct'] as num?)?.toInt() ?? 15;
      final updated = await _load();
      state = AsyncValue.data(updated.copyWith(
        isApplyingCode: false,
        applySuccessMessage: 'تم تطبيق الخصم! ستحصل على $discountPct% خصم في حجزك الأول',
      ));
    } on DioException catch (e) {
      final errorCode = _extractErrorCode(e);
      final message = switch (errorCode) {
        'REFERRAL_CODE_NOT_FOUND' => 'الكود غير صحيح أو غير موجود',
        'REFERRAL_ALREADY_USED'   => 'لقد طبّقت كود دعوة مسبقاً',
        'REFERRAL_SELF_REFERRAL'  => 'لا يمكنك استخدام كودك الخاص',
        'REFERRAL_CODE_EXPIRED'   => 'انتهت صلاحية الكود',
        _                         => 'حدث خطأ. حاول مرة أخرى',
      };
      final cur = state.valueOrNull ?? const ReferralState();
      state = AsyncValue.data(cur.copyWith(
        isApplyingCode: false,
        applyError: message,
      ));
    } catch (_) {
      final cur = state.valueOrNull ?? const ReferralState();
      state = AsyncValue.data(cur.copyWith(
        isApplyingCode: false,
        applyError: 'حدث خطأ. حاول مرة أخرى',
      ));
    }
  }

  String _extractErrorCode(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) return (data['error'] as String?) ?? '';
    } catch (_) {}
    return '';
  }
}

final referralNotifierProvider =
    AsyncNotifierProvider<ReferralNotifier, ReferralState>(ReferralNotifier.new);
