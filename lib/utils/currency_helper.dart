import 'package:FincoreGo/Settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> checkCurrencyMismatch(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final userCurrency = prefs.getString('currencycode') ?? "AED";
  final baseCurrency = prefs.getString('base_currency') ?? "AED";

  if (userCurrency != baseCurrency) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "App currency ($userCurrency) doesn’t match your Tally company’s base currency ($baseCurrency). Please review or change your settings.",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Settings()));
              },
              child: const Text(
                "Change",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
