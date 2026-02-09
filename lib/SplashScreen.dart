import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Constants.dart';
import 'Login.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();

    String? username = prefs.getString('username_remember');
    String? password = prefs.getString('password_remember');

    Timer(const Duration(seconds: 2), () {
      _checkUpdates(username, password);
    });
  }

  // -------------------------------
  // MANDATORY UPDATE CHECK
  // -------------------------------
  Future<void> _checkUpdates(String? username, String? password) async {
    if (Platform.isAndroid) {
      await _mandatoryAndroidUpdate(username, password);
    } else if (Platform.isIOS) {
      await _mandatoryIOSUpdate(username, password);
    } else {
      _goToLogin(username, password);
    }
  }

  // -------------------------------
  // ANDROID — FORCED UPDATE
  // -------------------------------
  Future<void> _mandatoryAndroidUpdate(
      String? username, String? password) async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();

          if (result == AppUpdateResult.success) {
            _goToLogin(username, password);
          } else {
            SystemNavigator.pop(); // user cannot skip
          }
        } else {
          _goToLogin(username, password);
        }
      } else {
        _goToLogin(username, password);
      }
    } catch (e) {
      _goToLogin(username, password);
    }
  }

  // -------------------------------
  // iOS — FORCED UPDATE
  // -------------------------------
  Future<void> _mandatoryIOSUpdate(
      String? username, String? password) async {
    bool updateAvailable = await AppUpdateService.isIOSUpdateAvailable();

    if (updateAvailable) {
      _showForcedIOSDialog();
    } else {
      _goToLogin(username, password);
    }
  }

  // -------------------------------
  // iOS — FORCE UPDATE POPUP
  // -------------------------------
  void _showForcedIOSDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // App Icon Circle
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [app_color, app_color.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 18),

                // Title
                Text(
                  "Update Required",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // Message
                Text(
                  "A new version of FINCORE GO is available.\nYou must update to continue using the app.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 25),

                // Update Button (Gradient)
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(
                        "https://apps.apple.com/app/id${AppUpdateService.iosAppId}");

                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [app_color, app_color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Update Now",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------
  // NAVIGATE TO LOGIN
  // -------------------------------
  void _goToLogin(String? username, String? password) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Login(
          username: username ?? '',
          password: password ?? '',
        ),
      ),
    );
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/fincorego_logo_png.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                SpinKitWave(
                  color: app_color,
                  size: 40.0,
                  itemCount: 5,
                )
              ],
            )),

        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "© 2023-2026 CSH LLC. All Rights Reserved.",
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
        )
      ]),
    );
  }
}


class AppUpdateService {
  // CHANGE THIS to your real iOS App ID
  static const String iosAppId = "6451186057";

  // Check if an update is available on the App Store
  static Future<bool> isIOSUpdateAvailable() async {
    try {
      if (!Platform.isIOS) return false;

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final url = Uri.parse("https://itunes.apple.com/lookup?id=$iosAppId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData["resultCount"] > 0) {
          final storeVersion = jsonData["results"][0]["version"];
          return _isVersionGreater(storeVersion, currentVersion);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Compare store version with installed version
  static bool _isVersionGreater(String store, String current) {
    final s = store.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();

    for (int i = 0; i < s.length; i++) {
      if (s[i] > c[i]) return true;
      if (s[i] < c[i]) return false;
    }
    return false;
  }
}
