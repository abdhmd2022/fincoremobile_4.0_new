import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../api/auth_repository.dart';

class VerifyEmailState {
  final bool isSending;
  final bool isVerifying;

  const VerifyEmailState({this.isSending = false, this.isVerifying = false});

  VerifyEmailState copyWith({bool? isSending, bool? isVerifying}) {
    return VerifyEmailState(
      isSending: isSending ?? this.isSending,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }
}

/// Drives the "your email isn't verified yet" prompt shown right after an
/// email-style login (see Login.dart) - shown again on every subsequent
/// login until the account's email is actually verified, per how this
/// feature was asked for; a username-style login never triggers it at
/// all, checked by the caller before this notifier is ever touched.
class VerifyEmailNotifier extends StateNotifier<VerifyEmailState> {
  VerifyEmailNotifier() : super(const VerifyEmailState());

  String? _verifyToken;

  /// `POST /auth/user/send-verification-email` - returns null on success,
  /// or a message to show the user on failure. Called once automatically
  /// when the prompt screen opens, and again on "Resend".
  Future<String?> sendCode() async {
    state = state.copyWith(isSending: true);
    try {
      _verifyToken = await AuthRepository.instance.sendVerificationEmail();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not reach the server. Please try again.';
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  /// `POST /auth/user/verify-email` - returns null on success, or a
  /// message to show the user on failure (e.g. wrong/expired code).
  Future<String?> verify(String otp) async {
    if (_verifyToken == null) {
      return 'Please request a code first.';
    }
    state = state.copyWith(isVerifying: true);
    try {
      await AuthRepository.instance.verifyEmail(
        verifyToken: _verifyToken!,
        otp: otp,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not reach the server. Please try again.';
    } finally {
      state = state.copyWith(isVerifying: false);
    }
  }
}

final verifyEmailNotifierProvider =
    StateNotifierProvider.autoDispose<VerifyEmailNotifier, VerifyEmailState>(
  (ref) => VerifyEmailNotifier(),
);
