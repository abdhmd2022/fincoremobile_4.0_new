import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../AddRole.dart';
import '../api/api_exception.dart';
import '../constants.dart';
import 'repository_providers.dart';

class AddRoleState {
  final List<PermissionOption> permissions;
  final Set<String> selectedPermissionIds;
  final bool isLoadingPermissions;
  final bool isSaving;
  // A load error to be surfaced once via `ref.listen` + [AddRoleNotifier.clearLoadError],
  // since the initial load runs before any widget can await it directly.
  final String? loadError;

  const AddRoleState({
    this.permissions = const [],
    this.selectedPermissionIds = const {},
    this.isLoadingPermissions = true,
    this.isSaving = false,
    this.loadError,
  });

  AddRoleState copyWith({
    List<PermissionOption>? permissions,
    Set<String>? selectedPermissionIds,
    bool? isLoadingPermissions,
    bool? isSaving,
    String? loadError,
    bool clearLoadError = false,
  }) {
    return AddRoleState(
      permissions: permissions ?? this.permissions,
      selectedPermissionIds:
          selectedPermissionIds ?? this.selectedPermissionIds,
      isLoadingPermissions: isLoadingPermissions ?? this.isLoadingPermissions,
      isSaving: isSaving ?? this.isSaving,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
    );
  }

  Map<String, List<PermissionOption>> get groupedPermissions {
    return PermissionOption.groupByLegacyOrder(permissions);
  }
}

/// Result of an action, so the widget can show a message/navigate without
/// the notifier reaching into `BuildContext`.
class AddRoleActionResult {
  final bool success;
  final String? message;

  const AddRoleActionResult(this.success, [this.message]);
}

class AddRoleNotifier extends StateNotifier<AddRoleState> {
  final Ref _ref;

  AddRoleNotifier(this._ref) : super(const AddRoleState()) {
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    state = state.copyWith(isLoadingPermissions: true);
    try {
      final result =
          await _ref.read(identityRepositoryProvider).listPermissions();
      // `.whereType<Map>()` rather than a blind `.cast<Map<String,
      // dynamic>>()` - a malformed/null entry in this list should be
      // dropped, not crash the whole screen (see the matching note in
      // modify_role_notifier.dart's _load()).
      final items = (result.data as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      // Meta-admin entries (Company/Company User/License Management) have
      // no legacy equivalent and aren't selectable for a custom role here
      // - see [PermissionOption.isMetaAdmin].
      final permissions = items
          .map(PermissionOption.fromJson)
          .where((p) => !PermissionOption.isMetaAdmin(p.resource))
          .toList();

      // The `/company-permission` catalog is global (not company/license
      // scoped on the backend), so it includes Spectra/UniGas-only entries
      // for every company: the whole "Van Allocation" group, and "Create
      // Delivery Note Entry" within Entries (legacy only showed both to a
      // van-sales-enabled company - see AddRole.dart's `entryPermissions`
      // getter in the legacy app). Filtered out here to match the same
      // `isVanSalesAccess` gate the Van Allocation screen itself uses (see
      // app_bottom_nav.dart) - a generic company (e.g. customer1demo)
      // shouldn't be able to grant a permission it has no matching feature
      // for.
      final prefs = await SharedPreferences.getInstance();
      final serialNo = prefs.getString('serial_no');
      final isSpectra = isVanSalesAccess(serialNo);
      final filtered = isSpectra
          ? permissions
          : permissions
              .where((p) =>
                  p.group != 'Van Allocation' &&
                  p.resource != 'ENTRY_DELIVERY_NOTE')
              .toList();

      state = state.copyWith(
        permissions: filtered,
        isLoadingPermissions: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingPermissions: false, loadError: e.message);
    } on SessionExpiredException {
      // BaseApiClient already force-navigated to Login on a dead refresh
      // token - this screen is being torn down underneath that redirect,
      // so there's nothing useful to show here.
      state = state.copyWith(isLoadingPermissions: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingPermissions: false,
        loadError: 'Could not reach the server. Please try again.',
      );
    }
  }

  void clearLoadError() {
    state = state.copyWith(clearLoadError: true);
  }

  void togglePermission(String permissionId, bool checked) {
    final updated = Set<String>.from(state.selectedPermissionIds);
    if (checked) {
      updated.add(permissionId);
    } else {
      updated.remove(permissionId);
    }
    state = state.copyWith(selectedPermissionIds: updated);
  }

  Future<AddRoleActionResult> createRole(String name) async {
    if (name.isEmpty) {
      return const AddRoleActionResult(false, 'Please enter a role name');
    }

    state = state.copyWith(isSaving: true);
    try {
      await _ref.read(identityRepositoryProvider).createRole(
        name: name,
        permissionIds: state.selectedPermissionIds.toList(),
      );
      state = state.copyWith(isSaving: false);
      return const AddRoleActionResult(true, 'Role created successfully');
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false);
      return AddRoleActionResult(false, e.message);
    } on SessionExpiredException {
      // Already redirected to Login by BaseApiClient - no message to show.
      state = state.copyWith(isSaving: false);
      return const AddRoleActionResult(false);
    } catch (e) {
      state = state.copyWith(isSaving: false);
      return const AddRoleActionResult(
        false,
        'Could not reach the server. Please try again.',
      );
    }
  }
}

final addRoleNotifierProvider =
    StateNotifierProvider.autoDispose<AddRoleNotifier, AddRoleState>(
  (ref) => AddRoleNotifier(ref),
);
