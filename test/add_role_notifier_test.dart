import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:FincoreGo/api/identity_repository.dart';
import 'package:FincoreGo/api/base_api_client.dart';
import 'package:FincoreGo/constants.dart';
import 'package:FincoreGo/providers/repository_providers.dart';
import 'package:FincoreGo/providers/add_role_notifier.dart';

class MockIdentityRepository extends Mock implements IdentityRepository {}

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
  AutoDisposeStateNotifierProvider<AddRoleNotifier, AddRoleState> provider,
) async {
  final subscription = container.listen(provider, (_, __) {});
  addTearDown(subscription.close);

  for (var i = 0; i < 100; i++) {
    if (!container.read(provider).isLoadingPermissions) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('AddRoleNotifier never finished loading');
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
    // Reset the mutable global between tests so one test's Spectra serial
    // doesn't leak into the next.
    vanSalesSerialNo = {};
  });

  tearDown(() => container.dispose());

  test('excludes meta-admin permissions from the pickable catalog', () async {
    SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});

    final provider = addRoleNotifierProvider;
    container.read(provider.notifier);
    await _waitUntilLoaded(container, provider);

    final ids = container.read(provider).permissions.map((p) => p.id);
    expect(ids, isNot(contains('perm-company-role-read')));
    expect(ids, contains('perm-dash-sales'));
  });

  test('a non-Spectra company does not see Van Allocation or Delivery Note',
      () async {
    SharedPreferences.setMockInitialValues({'serial_no': 'generic-serial'});

    final provider = addRoleNotifierProvider;
    container.read(provider.notifier);
    await _waitUntilLoaded(container, provider);

    final ids = container.read(provider).permissions.map((p) => p.id);
    expect(ids, isNot(contains('perm-van-allocation')));
    expect(ids, isNot(contains('perm-delivery-note')));
  });

  test('a Spectra/van-sales company sees Van Allocation and Delivery Note',
      () async {
    vanSalesSerialNo = {'772976358'};
    SharedPreferences.setMockInitialValues({'serial_no': '772976358'});

    final provider = addRoleNotifierProvider;
    container.read(provider.notifier);
    await _waitUntilLoaded(container, provider);

    final ids = container.read(provider).permissions.map((p) => p.id);
    expect(ids, contains('perm-van-allocation'));
    expect(ids, contains('perm-delivery-note'));
  });

  test('togglePermission adds and removes ids from the selected set',
      () async {
    SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});

    final provider = addRoleNotifierProvider;
    final notifier = container.read(provider.notifier);
    await _waitUntilLoaded(container, provider);

    notifier.togglePermission('perm-dash-sales', true);
    expect(container.read(provider).selectedPermissionIds, {'perm-dash-sales'});

    notifier.togglePermission('perm-dash-sales', false);
    expect(container.read(provider).selectedPermissionIds, isEmpty);
  });

  test('createRole rejects an empty name without calling the repository',
      () async {
    SharedPreferences.setMockInitialValues({'serial_no': 'not-spectra'});

    final provider = addRoleNotifierProvider;
    final notifier = container.read(provider.notifier);
    await _waitUntilLoaded(container, provider);

    final result = await notifier.createRole('');

    expect(result.success, isFalse);
    verifyNever(() => repo.createRole(
          name: any(named: 'name'),
          permissionIds: any(named: 'permissionIds'),
        ));
  });
}
