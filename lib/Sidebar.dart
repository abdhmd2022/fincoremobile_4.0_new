import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'Dashboard.dart';
import 'Login.dart';
import 'Settings.dart';
import 'Help.dart';
import 'RolesView.dart';
import 'SerialSelect.dart';
import 'UserView.dart';
import 'constants.dart';

class Sidebar extends StatelessWidget {
  final bool isDashEnable, isRolesVisible, isUserEnable, isRolesEnable, isUserVisible;
  final String? Username, Email;
  final TickerProvider tickerProvider;

  bool isSalesEntryVisible = false, isSalesEntryEnable = true;
  bool isReceiptEntryVisible = false, isReceiptEntryEnable = true;
  String SalesEntryHolder = '', username_prefs = '', password_prefs = '', ReceiptEntryHolder = '';
  String? socketId = '', deviceIdentifier = '';
  late IO.Socket socket;

  Sidebar({
    Key? key,
    required this.isDashEnable,
    required this.isRolesVisible,
    required this.isRolesEnable,
    required this.isUserEnable,
    required this.Username,
    required this.Email,
    required this.tickerProvider,
    required this.isUserVisible,
  }) : super(key: key) {
    _loadSharedPreferences();
    _getDeviceIdentifier();

    socket = IO.io('$BASE_URL_config', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': '$authTokenBase'}
    });

    socket.on('connect', (_) {
      socketId = socket.id!;
    });
    socket.connect();
  }

  Future<void> _getDeviceIdentifier() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceIdentifier = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceIdentifier = iosInfo.identifierForVendor;
      }
    } catch (e) {
      print('Error getting device identifier: $e');
    }
  }

  void _loadSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    SalesEntryHolder = prefs.getString('salesentry') ?? "False";
    ReceiptEntryHolder = prefs.getString('receiptentry') ?? "False";
    username_prefs = prefs.getString('username') ?? '';
    password_prefs = prefs.getString('password') ?? '';
    isSalesEntryVisible = SalesEntryHolder == 'True';
    isReceiptEntryVisible = ReceiptEntryHolder == 'True';
  }

  Widget _buildTile({required IconData icon, required String title, required VoidCallback onTap, bool enabled = true}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade600),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 15, color: Colors.black),
      ),
      enabled: enabled,
      onTap: onTap,
      horizontalTitleGap: 10,
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white, // Very light purple-pink like in your screenshot

      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 120,bottom:30,left:20,right:20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: app_color,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: app_color,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Username ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        Email ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,

                          color: Colors.white70,

                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: ListView(
              children: [
                _buildTile(title: 'Dashboard', icon: Icons.dashboard, enabled: isDashEnable, onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard()));
                }),
                _buildTile(title: 'Companies', icon: Icons.business, onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SerialSelect()));
                }),
                if (isRolesVisible)
                  _buildTile(title: 'Roles', icon: Icons.group, enabled: isRolesEnable, onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RolesView()));
                  }),
                if (isUserVisible)
                  _buildTile(title: 'Users', icon: Icons.person, enabled: isUserEnable, onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserView()));
                  }),
                _buildTile(title: 'Settings', icon: Icons.settings, onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Settings()));
                }),
                Divider(),
                _buildTile(title: 'Help', icon: Icons.help_outline, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => Help()));
                }),
                _buildTile(title: 'Logout', icon: Icons.logout, onTap: () {
                  _showConfirmationDialogAndNavigate(context);
                }),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '© CSH LLC 2023-2025 • Version 4.0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),

        ],
      ),
    );
  }

  void emitDeleteMyId(Map<String, dynamic> jsonPayload, Function() onComplete) {
    socket.emit('deleteMyId', jsonPayload);
    onComplete();
  }

  Future<void> _showConfirmationDialogAndNavigate(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: app_color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: app_color
                  ),
                ),
                const SizedBox(height: 18),

                // 📝 Title
                Text(
                  'Logout Confirmation',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // 💬 Message
                Text(
                  'Are you sure you want to log out of your account?',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // 🔘 Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ❌ Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: app_color),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: app_color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ✅ Logout Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          final jsonPayload = {
                            'username': username_prefs,
                            'password': password_prefs,
                            'macId': deviceIdentifier,
                          };

                          Navigator.of(context).pop();
                          emitDeleteMyId(jsonPayload, () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Login(
                                  username: '',
                                  password: '',
                                ),
                              ),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app_color,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
