import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:FincoreGo/AssistantChat.dart';

/// See assistant_support_form_test.dart's identical helper for why this
/// stub is needed.
void _stubSecureStorageChannel() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => null);
}

const _messagesKey = 'assistant_chat_messages';
const _lastInputKey = 'assistant_chat_last_input_at';

Future<void> _openAssistantChat(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AssistantChat()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_stubSecureStorageChannel);

  testWidgets(
    'leaving the screen and returning within 15 minutes of the last reply '
    'resumes the same conversation',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        _messagesKey:
            '[{"text":"hello","isUser":true,"isError":false,"timestamp":"${DateTime.now().toIso8601String()}"}]',
        // 10 minutes ago - inside the 15-minute window.
        _lastInputKey: DateTime.now()
            .subtract(const Duration(minutes: 10))
            .toIso8601String(),
      });

      await _openAssistantChat(tester);

      expect(find.text('hello'), findsOneWidget);

      Navigator.of(tester.element(find.text('hello'))).pop();
      await tester.pumpAndSettle();

      // Leaving the screen alone must not clear the session - the whole
      // point of the resume window is that it's still there to resume.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_messagesKey), isNotNull);
      expect(prefs.getString(_lastInputKey), isNotNull);
    },
  );

  testWidgets(
    'returning more than 15 minutes after the last reply starts a fresh '
    'chat instead of resuming the old one',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        _messagesKey:
            '[{"text":"hello","isUser":true,"isError":false,"timestamp":"${DateTime.now().toIso8601String()}"}]',
        // 16 minutes ago - past the 15-minute window.
        _lastInputKey: DateTime.now()
            .subtract(const Duration(minutes: 16))
            .toIso8601String(),
      });

      await _openAssistantChat(tester);

      expect(find.text('hello'), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_messagesKey), isNull);
      expect(prefs.getString(_lastInputKey), isNull);
    },
  );
}
