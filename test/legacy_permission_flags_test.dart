import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FincoreGo/legacy_permission_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  group('applyPermissionFlags', () {
    test('a null permissions claim fails every mapped flag closed', () async {
      final prefs = await freshPrefs();

      await applyPermissionFlags(prefs, null);

      for (final flagKey in legacyFlagToPermission.keys) {
        expect(prefs.getString(flagKey), 'False',
            reason: '$flagKey should default to False when the claim is null');
      }
    });

    test('an empty permissions list fails every mapped flag closed', () async {
      final prefs = await freshPrefs();

      await applyPermissionFlags(prefs, const []);

      for (final flagKey in legacyFlagToPermission.keys) {
        expect(prefs.getString(flagKey), 'False');
      }
    });

    test('only grants the flags whose permission string is present', () async {
      final prefs = await freshPrefs();

      await applyPermissionFlags(prefs, const [
        'DASHBOARD_SALES:READ',
        'ENTRY_SALES:CREATE',
      ]);

      expect(prefs.getString('salesdash'), 'True');
      expect(prefs.getString('salesentry'), 'True');

      // Everything else stays closed.
      expect(prefs.getString('purchasedash'), 'False');
      expect(prefs.getString('receiptentry'), 'False');
      expect(prefs.getString('rate'), 'False');
    });

    test('does not touch secbtnaccess at all', () async {
      final prefs = await freshPrefs();
      await prefs.setString('secbtnaccess', 'True');

      await applyPermissionFlags(prefs, const []);

      // secbtnaccess is set separately (admin/non-admin role check, not a
      // permission string) - applyPermissionFlags must leave it alone.
      expect(prefs.getString('secbtnaccess'), 'True');
    });

    test('an irrelevant/unknown permission string grants nothing', () async {
      final prefs = await freshPrefs();

      await applyPermissionFlags(prefs, const ['SOME_UNKNOWN_RESOURCE:READ']);

      for (final flagKey in legacyFlagToPermission.keys) {
        expect(prefs.getString(flagKey), 'False');
      }
    });

    test('every mapped permission string is RESOURCE:ACTION shaped', () {
      // Regression guard for the exact bug this file's own doc-comment
      // describes: an earlier version used the catalog's dotted `name`
      // field (e.g. "dashboard.sales:read"), which never matched a real
      // decoded JWT claim and silently failed every check.
      final pattern = RegExp(r'^[A-Z_]+:[A-Z]+$');
      for (final entry in legacyFlagToPermission.entries) {
        expect(pattern.hasMatch(entry.value), isTrue,
            reason:
                '${entry.key} -> "${entry.value}" is not RESOURCE:ACTION shaped');
      }
    });
  });
}
