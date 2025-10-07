import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastActive = prefs.getInt('lastActive');

    if (lastActive != null) {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int sevenDaysInMillis = 15 * 60 * 1000;

      if (now - lastActive > sevenDaysInMillis) {
        // If more than 7 days inactive, show notification
        // NotificationService().showInactivityNotification();
      }
    }
    return Future.value(true);
  });
}
