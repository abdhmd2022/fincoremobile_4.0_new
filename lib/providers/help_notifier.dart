import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod migration of `Help.dart`'s `_HelpPageState`. Only the two
/// SharedPreferences-backed fields (`name`/`email`, used to prefill the
/// support email body) are real state - `_textEditingController` and
/// `_scaffoldKey` stay on the widget per the migration plan, and the dead
/// `isDashEnable`/`isRolesVisible`/etc. fields from the legacy state class
/// (never read anywhere in the original widget) were dropped rather than
/// carried over.
class HelpState {
  final String name;
  final String email;
  final bool isLengthErrorVisible;

  const HelpState({
    this.name = '',
    this.email = '',
    this.isLengthErrorVisible = false,
  });

  HelpState copyWith({
    String? name,
    String? email,
    bool? isLengthErrorVisible,
  }) {
    return HelpState(
      name: name ?? this.name,
      email: email ?? this.email,
      isLengthErrorVisible:
          isLengthErrorVisible ?? this.isLengthErrorVisible,
    );
  }
}

class HelpNotifier extends StateNotifier<HelpState> {
  HelpNotifier() : super(const HelpState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final emailNav = prefs.getString('email_nav');
    final nameNav = prefs.getString('name_nav');
    if (emailNav != null && nameNav != null) {
      state = state.copyWith(name: nameNav, email: emailNav);
    }
  }

  void setLengthErrorVisible(bool visible) {
    state = state.copyWith(isLengthErrorVisible: visible);
  }
}

final helpNotifierProvider =
    StateNotifierProvider.autoDispose<HelpNotifier, HelpState>(
  (ref) => HelpNotifier(),
);
