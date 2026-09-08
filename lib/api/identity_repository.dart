import 'dart:convert' show jsonEncode;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'api_exception.dart';
import 'base_api_client.dart';
import 'tally_oauth_client.dart';
import 'token_store.dart';

/// Wraps tally-oauth's company-scoped identity endpoints - roles,
/// permissions, and company-users - used by the AddRole/ModifyRole/
/// RolesView and CreateUser/ModifyUser/UserView screens. All calls use
/// [TokenScope.companyUser]: most of these endpoints derive their
/// `companyId` from that token server-side (see company-role.controller.ts/
/// company-user.controller.ts), so a company-user session (established via
/// [AuthRepository.selectCompany]/[AuthRepository.selectCompanyById]) must
/// already exist before calling anything here. [createCompanyUser] is the
/// one exception - its Zod body schema requires `companyId` explicitly
/// (confirmed live: omitting it 400s with "Invalid input: expected string,
/// received undefined" at `path: ["companyId"]"`), so it reads
/// [TokenStore.activeCompanyGuid] itself rather than relying on the token.
class IdentityRepository {
  IdentityRepository._();
  static final IdentityRepository instance = IdentityRepository._();

  final TallyOauthClient _oauth = TallyOauthClient();

  // -- Company roles (AddRole / ModifyRole / RolesView) ----------------

  /// Each item's `permissions` is `[{permission: {id, name, displayName,
  /// description, group, resource, action}}, ...]`. tally-admin-api's Zod
  /// response DTO (RoleResponseSchema) documents this nested key as the
  /// misspelled `permision` - that's wrong/stale on the backend's side,
  /// not what's actually on the wire: confirmed live against the real
  /// Prisma `select` that builds it (CompanyRoleSelect in
  /// company-role.service.ts explicitly projects `permission: {...}`).
  /// Parse this as `permission`, not `permision`.
  Future<ApiResult> listRoles({int page = 1, int limit = 20}) =>
      _oauth.get('/company-role?page=$page&limit=$limit', scope: TokenScope.companyUser);

  /// A handful of `success:true` responses from this backend have come
  /// back with `data` missing/null (seen live on `GET /company-role/:id` -
  /// crashed the caller with an unhandled "Null is not a subtype of
  /// Map(String, dynamic) in type cast" instead of a catchable error).
  /// Centralizes that cast so every call site throws a normal,
  /// catchable [ApiException] instead of crashing, and logs the raw
  /// payload in debug builds to help track down which endpoint/response
  /// is actually malformed.
  Map<String, dynamic> _asObject(ApiResult result, String context) {
    final data = result.data;
    if (data is Map<String, dynamic>) return data;
    if (kDebugMode) {
      debugPrint(
        '$context: expected an object, got ${data.runtimeType}: $data',
      );
    }
    throw ApiException(
      statusCode: 0,
      code: 'MALFORMED_RESPONSE',
      message: 'Unexpected response from the server. Please try again.',
    );
  }

  Future<Map<String, dynamic>> getRole(String id) async {
    final result = await _oauth.get('/company-role/$id', scope: TokenScope.companyUser);
    return _asObject(result, 'getRole($id)');
  }

  /// `permissionIds` are Permission uuids (from [listPermissions]), not
  /// permission name strings.
  Future<Map<String, dynamic>> createRole({
    required String name,
    required List<String> permissionIds,
  }) async {
    final result = await _oauth.post(
      '/company-role',
      body: {'name': name, 'permissions': permissionIds},
      scope: TokenScope.companyUser,
    );
    return _asObject(result, 'createRole($name)');
  }

  Future<Map<String, dynamic>> updateRole(
    String id, {
    String? name,
    List<String>? permissionIds,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (permissionIds != null) body['permissions'] = permissionIds;
    final result = await _oauth.patch('/company-role/$id', body: body, scope: TokenScope.companyUser);
    return _asObject(result, 'updateRole($id)');
  }

  Future<void> deleteRole(String id) =>
      _oauth.delete('/company-role/$id', scope: TokenScope.companyUser);

  // -- Permission catalog (read-only, for the role-builder UI) ----------

  Future<ApiResult> listPermissions({int page = 1, int limit = 100}) =>
      _oauth.get('/company-permission?page=$page&limit=$limit', scope: TokenScope.companyUser);

  // -- Company users (CreateUser / ModifyUser / UserView) ----------------

  Future<ApiResult> listCompanyUsers({int page = 1, int limit = 20}) =>
      _oauth.get('/company-user?page=$page&limit=$limit', scope: TokenScope.companyUser);

  Future<Map<String, dynamic>> getCompanyUser(String id) async {
    final result = await _oauth.get('/company-user/$id', scope: TokenScope.companyUser);
    return result.data as Map<String, dynamic>;
  }

  /// Creates (or, if a `User` with this `userName`/`email` already exists
  /// elsewhere, reuses) a `User` record and links it to the current
  /// company-user session's company with [roleId] - tally-oauth's
  /// `CompanyUserService.create` looks up by `userName` first, then
  /// `email`, before provisioning a new `User` (see company-user.service.ts).
  Future<Map<String, dynamic>> createCompanyUser({
    required String userName,
    required String firstName,
    required String lastName,
    required String password,
    required String roleId,
    String? phone,
    String? email,
  }) async {
    final companyGuid = await TokenStore.instance.activeCompanyGuid;
    if (companyGuid == null) {
      throw ApiException(
        statusCode: 0,
        code: 'NO_ACTIVE_COMPANY',
        message: 'No company selected - call selectCompany() first.',
      );
    }
    final body = <String, dynamic>{
      'companyId': companyGuid,
      'userName': userName,
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
      'roleId': roleId,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    };
    // Debug-only, password masked - never prints in a release build
    // (kDebugMode compiles to `false` there), same treatment as the
    // debug-only OTP print in Login.dart.
    if (kDebugMode) {
      debugPrint(
        'POST /company-user body: '
        '${jsonEncode({...body, 'password': '*' * password.length})}',
      );
    }
    final result = await _oauth.post('/company-user', body: body, scope: TokenScope.companyUser);
    return result.data as Map<String, dynamic>;
  }

  /// Only `roleId`/`isActive` can be changed on an existing company-user -
  /// name/password/etc. belong to the underlying `User` record, which this
  /// endpoint doesn't touch (no equivalent exposed to a company-user today).
  Future<Map<String, dynamic>> updateCompanyUser(
    String id, {
    String? roleId,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (roleId != null) body['roleId'] = roleId;
    if (isActive != null) body['isActive'] = isActive;
    final result = await _oauth.patch('/company-user/$id', body: body, scope: TokenScope.companyUser);
    return result.data as Map<String, dynamic>;
  }

  Future<void> deleteCompanyUser(String id) =>
      _oauth.delete('/company-user/$id', scope: TokenScope.companyUser);
}
