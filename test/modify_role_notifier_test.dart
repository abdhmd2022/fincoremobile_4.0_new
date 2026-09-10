import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:FincoreGo/api/identity_repository.dart';
import 'package:FincoreGo/api/base_api_client.dart';
import 'package:FincoreGo/providers/repository_providers.dart';
import 'package:FincoreGo/providers/modify_role_notifier.dart';

class MockIdentityRepository extends Mock implements IdentityRepository {}

/// The full 61-entry-ish catalog shape isn't needed - a representative mix
/// of meta-admin, Van Allocation, and ordinary business permissions is
/// enough to exercise every filter this notifier applies.
final _catalog = <Map<String, dynamic>>[
  {
    'id': 'perm-dash-sales',
    'displayName': 'Sales Dashboard Tile',
    'group': 'Dashboard',
    'resource': 'DASHBOARD_SALES',
    'action': 'READ',
  },
  {
    'id': 'perm-company-role-read',
    'displayName': 'Read Role',
    'group': 'Company User Management',
    'resource': 'COMPANY_ROLE',
    'action': 'READ',
  },
  {
    'id': 'perm-van-allocation',
    'displayName': 'View Van Allocation',
    'group': 'Van Allocation',
    'resource': 'VAN_ALLOCATION',
    'action': 'READ',
  },
  {
    'id': 'perm-delivery-note',
    'displayName': 'Create Delivery Note Entry',
    'group': 'Entries',
    'resource': 'ENTRY_DELIVERY_NOTE',
    'action': 'CREATE',
  },
];

Future<void> _waitUntilLoaded(
  ProviderContainer container,
  AutoDisposeStateNotifierProvider<ModifyRoleNotifier, ModifyRoleState> provider,
) async {
  // `.autoDispose` providers are torn down (and, worse here, silently
  // recreated - restarting `_load()` from scratch) the instant there's no
  // active listener. A bare `container.read` between poll iterations isn't
  // a listener, so without pinning it alive here the provider never
  // actually finishes loading - it just keeps restarting.
  final subscription = container.listen(provider, (_, __) {});
  addTearDown(subscription.close);

  for (var i = 0; i < 100; i++) {
    if (!container.read(provider).isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('ModifyRoleNotifier never finished loading');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockIdentityRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockIdentityRepository();
    container = ProviderContainer(
      overrides: [identityRepositoryProvider.overrideWithValue(repo)],
    );
    when(() => repo.listPermissions()).thenAnswer((_) async => ApiResult(_catalog, null));
  });

  tearDown(() => container.dispose());

  group('granted-permission parsing (selection-zero regression)', () {
    test('reads the correctly-spelled "permission" key', () async {
      SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});
      when(() => repo.getRole('role-1')).thenAnswer((_) async => {
            'id': 'role-1',
            'name': 'Driver',
            'isSystem': false,
            'permissions': [
              {
                'permission': {'id': 'perm-dash-sales'}
              },
            ],
          });

      final provider = modifyRoleNotifierProvider('role-1');
      container.read(provider.notifier);
      await _waitUntilLoaded(container, provider);

      final state = container.read(provider);
      expect(state.selectedPermissionIds, {'perm-dash-sales'});
    });

    test('falls back to the misspelled "permision" key defensively',
        () async {
      SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});
      when(() => repo.getRole('role-1')).thenAnswer((_) async => {
            'id': 'role-1',
            'name': 'Driver',
            'isSystem': false,
            'permissions': [
              {
                'permision': {'id': 'perm-dash-sales'}
              },
            ],
          });

      final provider = modifyRoleNotifierProvider('role-1');
      container.read(provider.notifier);
      await _waitUntilLoaded(container, provider);

      final state = container.read(provider);
      expect(state.selectedPermissionIds, {'perm-dash-sales'});
    });

    test('a malformed entry is skipped, not crashed on, and does not '
        'affect the valid entries around it', () async {
      SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});
      when(() => repo.getRole('role-1')).thenAnswer((_) async => {
            'id': 'role-1',
            'name': 'Driver',
            'isSystem': false,
            'permissions': [
              {
                'permission': {'id': 'perm-dash-sales'}
              },
              {'permission': null}, // malformed
              {'somethingElse': 'x'}, // malformed
              null, // malformed
            ],
          });

      final provider = modifyRoleNotifierProvider('role-1');
      container.read(provider.notifier);
      await _waitUntilLoaded(container, provider);

      final state = container.read(provider);
      expect(state.selectedPermissionIds, {'perm-dash-sales'});
      expect(state.loadError, isNull, reason: 'must not crash the load');
    });
  });

  group('catalog filtering', () {
    test('excludes meta-admin permissions from the pickable list', () async {
      SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});
      when(() => repo.getRole('role-1')).thenAnswer((_) async => {
            'id': 'role-1',
            'name': 'Driver',
            'isSystem': false,
            'permissions': [],
          });

      final provider = modifyRoleNotifierProvider('role-1');
      container.read(provider.notifier);
      await _waitUntilLoaded(container, provider);

      final ids = container.read(provider).permissions.map((p) => p.id);
      expect(ids, isNot(contains('perm-company-role-read')));
    });

    test('excludes Van Allocation and Delivery Note for a non-Spectra '
        'company', () async {
      SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});
      when(() => repo.getRole('role-1')).thenAnswer((_) async => {
            'id': 'role-1',
            'name': 'Driver',
            'isSystem': false,
            'permissions': [],
          });

      final provider = modifyRoleNotifierProvider('role-1');
      container.read(provider.notifier);
      await _waitUntilLoaded(container, provider);

      final ids = container.read(provider).permissions.map((p) => p.id);
      expect(ids, isNot(contains('perm-van-allocation')));
      expect(ids, isNot(contains('perm-delivery-note')));
      expect(ids, contains('perm-dash-sales'));
    });

    test('keeps a role\'s already-granted Van Allocation permission '
        'selected even when hidden from the pickable list (non-Spectra)',
        () async {
      SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});
      when(() => repo.getRole('role-1')).thenAnswer((_) async => {
            'id': 'role-1',
            'name': 'Driver',
            'isSystem': false,
            'permissions': [
              {
                'permission': {'id': 'perm-van-allocation'}
              },
            ],
          });

      final provider = modifyRoleNotifierProvider('role-1');
      container.read(provider.notifier);
      await _waitUntilLoaded(container, provider);

      final state = container.read(provider);
      expect(state.selectedPermissionIds, contains('perm-van-allocation'));
      expect(
        state.permissions.map((p) => p.id),
        isNot(contains('perm-van-allocation')),
        reason: 'still not offered as pickable',
      );
    });
  });

  test('isSystem reflects the role response, disabling edits for a system '
      'role', () async {
    SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});
    when(() => repo.getRole('role-1')).thenAnswer((_) async => {
          'id': 'role-1',
          'name': 'Admin',
          'isSystem': true,
          'permissions': [],
        });

    final provider = modifyRoleNotifierProvider('role-1');
    container.read(provider.notifier);
    await _waitUntilLoaded(container, provider);

    expect(container.read(provider).isSystem, isTrue);

    final result =
        await container.read(provider.notifier).saveRole('Admin renamed');
    expect(result.success, isFalse);
    expect(result.message, contains('System roles'));
  });
}
