import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../AddRole.dart';
import '../api/api_exception.dart';
import '../api/base_api_client.dart';
import '../constants.dart';
import 'repository_providers.dart';

class ModifyRoleState {
  final String name;
  final List<PermissionOption> permissions;
  final Set<String> selectedPermissionIds;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  // System roles (e.g. "Admin", auto-created per company - see
  // company-role.service.ts's `isSystem` flag) can't be edited by a
  // regular company-user at all - the backend rejects the PATCH outright
  // (401 "Company Role can't be deleted", an oddly-worded but deliberate
  // message reused from the delete-guard check). Rather than let the user
  // fill out the whole form and hit that confusing error on submit, the
  // screen disables editing up front once this is known.
  final bool isSystem;
  // Set when the role couldn't be loaded because it no longer belongs to
  // the currently active company (a stale role card from a previously
  // selected company, or the company was switched while this screen was
  // open) - the backend correctly 401s that as "Unauthorized" rather than
  // 404ing (see company-role.service.ts's findOne), but that raw message
  // is meaningless to a user staring at a blank edit screen. The widget
  // pops back to the roles list (which re-fetches on its own) instead of
  // leaving this screen open with nothing to edit.
  final bool shouldGoBack;

  const ModifyRoleState({
    this.name = '',
    this.permissions = const [],
    this.selectedPermissionIds = const {},
    this.isLoading = true,
    this.isSaving = false,
    this.loadError,
    this.shouldGoBack = false,
    this.isSystem = false,
  });

  ModifyRoleState copyWith({
    String? name,
    List<PermissionOption>? permissions,
    Set<String>? selectedPermissionIds,
    bool? isLoading,
    bool? isSaving,
    String? loadError,
    bool clearLoadError = false,
    bool? shouldGoBack,
    bool? isSystem,
  }) {
    return ModifyRoleState(
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      selectedPermissionIds:
          selectedPermissionIds ?? this.selectedPermissionIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      isSystem: isSystem ?? this.isSystem,
      shouldGoBack: shouldGoBack ?? this.shouldGoBack,
    );
  }

  Map<String, List<PermissionOption>> get groupedPermissions {
    return PermissionOption.groupByLegacyOrder(permissions);
  }
}

class ModifyRoleActionResult {
  final bool success;
  final String? message;

  const ModifyRoleActionResult(this.success, [this.message]);
}

class ModifyRoleNotifier extends StateNotifier<ModifyRoleState> {
  final Ref _ref;
  final String roleId;

  ModifyRoleNotifier(this._ref, this.roleId) : super(const ModifyRoleState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(identityRepositoryProvider);
      final results = await Future.wait([
        repo.listPermissions(),
        repo.getRole(roleId),
      ]);

      // `.whereType<Map>()` rather than a blind `.cast<Map<String,
      // dynamic>>()` - a malformed/null entry in this list should be
      // dropped, not crash the whole screen.
      final permissionItems = ((results[0] as ApiResult).data as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      // Meta-admin entries (Company/Company User/License Management) have
      // no legacy equivalent and aren't selectable for a custom role here
      // - see [PermissionOption.isMetaAdmin]. (The system Admin role can't
      // reach this screen at all - ModifyRole.dart disables editing it -
      // so this only ever affects custom roles.)
      final allPermissions = permissionItems
          .map(PermissionOption.fromJson)
          .where((p) => !PermissionOption.isMetaAdmin(p.resource))
          .toList();

      // Same Spectra/UniGas-only filter as AddRoleNotifier - the whole
      // "Van Allocation" group and "Create Delivery Note Entry" within
      // Entries are only real features for a van-sales-enabled company
      // (see isVanSalesAccess/app_bottom_nav.dart). Already-granted
      // permissions on this role stay selected/saved even if hidden here -
      // only the pickable list is filtered.
      final prefs = await SharedPreferences.getInstance();
      final serialNo = prefs.getString('serial_no');
      final isSpectra = isVanSalesAccess(serialNo);
      final permissions = isSpectra
          ? allPermissions
          : allPermissions
              .where((p) =>
                  p.group != 'Van Allocation' &&
                  p.resource != 'ENTRY_DELIVERY_NOTE')
              .toList();

      final role = results[1] as Map<String, dynamic>;
      final name = role['name'] as String;

      // Each item is `{permission: {id, ...}}`. The backend's Zod response
      // DTO (RoleResponseSchema) actually declares this nested key as the
      // misspelled `permision` - but that's a documentation/schema bug on
      // the backend's side, not what's really on the wire: the Prisma
      // `select` that builds this data (CompanyRoleSelect in
      // company-role.service.ts) explicitly projects the relation as
      // `permission: {select: companyPermissionSelect}`, and Prisma's
      // `select` always emits the exact field name given - confirmed live
      // (this was the actual cause of every role showing zero selected
      // permissions once malformed entries started being skipped instead
      // of crashing). Checks both spellings defensively in case that
      // backend inconsistency is ever "fixed" the other way.
      final rawGrantedPermissions = role['permissions'] as List? ?? const [];
      final selectedPermissionIds = <String>{};
      for (final entry in rawGrantedPermissions) {
        final permission = entry is Map
            ? (entry['permission'] ?? entry['permision'])
            : null;
        final id = permission is Map ? permission['id'] : null;
        if (id is String) {
          selectedPermissionIds.add(id);
        } else if (kDebugMode) {
          debugPrint(
            'ModifyRoleNotifier._load: skipping malformed granted-permission entry: $entry',
          );
        }
      }

      state = state.copyWith(
        name: name,
        permissions: permissions,
        selectedPermissionIds: selectedPermissionIds,
        isLoading: false,
        isSystem: role['isSystem'] == true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        state = state.copyWith(
          isLoading: false,
          loadError:
              'This role belongs to a different company. Refreshing the list...',
          shouldGoBack: true,
        );
      } else {
        state = state.copyWith(isLoading: false, loadError: e.message);
      }
    } on SessionExpiredException {
      // BaseApiClient already force-navigated to Login (see its 401 +
      // failed-refresh handling) before this was thrown - this screen is
      // being torn down underneath that redirect, so setting a "could not
      // reach the server" error here would be both wrong (it's a session
      // expiry, not a network failure) and pointless (nothing is left to
      // show it to). Just stop loading, no error surfaced.
      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      // Temporary diagnostic - see saveRole()'s matching catch-all for why.
      if (kDebugMode) {
        debugPrint('ModifyRoleNotifier._load failed: ${e.runtimeType}: $e');
        debugPrint(st.toString());
      }
      state = state.copyWith(
        isLoading: false,
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

  Future<ModifyRoleActionResult> saveRole(String name) async {
    if (name.isEmpty) {
      return const ModifyRoleActionResult(false, 'Please enter a role name');
    }
    if (state.isSystem) {
      return const ModifyRoleActionResult(
        false,
        'System roles like Admin cannot be modified.',
      );
    }

    state = state.copyWith(isSaving: true);
    try {
      await _ref.read(identityRepositoryProvider).updateRole(
        roleId,
        name: name,
        permissionIds: state.selectedPermissionIds.toList(),
      );
      state = state.copyWith(isSaving: false);
      return const ModifyRoleActionResult(true, 'Role updated successfully');
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false);
      return ModifyRoleActionResult(false, e.message);
    } on SessionExpiredException {
      // Already redirected to Login by BaseApiClient - no message to show.
      state = state.copyWith(isSaving: false);
      return const ModifyRoleActionResult(false);
    } catch (e) {
      // Temporary diagnostic - this catch-all is currently swallowing the
      // real exception type behind a generic "could not reach the server"
      // message, and it's firing for a save that never even shows up in
      // the backend's request logs. Logging the real type/message here
      // until the actual cause (client-side exception before the HTTP
      // call, vs. a genuine dropped connection) is identified.
      if (kDebugMode) {
        debugPrint('ModifyRoleNotifier.saveRole failed: ${e.runtimeType}: $e');
      }
      state = state.copyWith(isSaving: false);
      return const ModifyRoleActionResult(
        false,
        'Could not reach the server. Please try again.',
      );
    }
  }
}

final modifyRoleNotifierProvider = StateNotifierProvider.autoDispose
    .family<ModifyRoleNotifier, ModifyRoleState, String>(
  (ref, roleId) => ModifyRoleNotifier(ref, roleId),
);
