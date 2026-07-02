import 'package:FincoreGo/Dashboard.dart';
import 'package:flutter/material.dart';

class AppNavigation {
  const AppNavigation._();

  static void backOrDashboard(BuildContext context) {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Dashboard()),
      (route) => false,
    );
  }
}
