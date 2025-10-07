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
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout Confirmation', style: GoogleFonts.poppins()),
          content: Text('Do you really want to Logout?', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('No', style: TextStyle(color: Color(0xFF30D5C8))),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Yes', style: TextStyle(color: Color(0xFF30D5C8))),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.clear();

                final jsonPayload = {
                  'username': username_prefs,
                  'password': password_prefs,
                  'macId': deviceIdentifier,
                };
                Navigator.of(context).pop();
                emitDeleteMyId(jsonPayload, () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login(username: '', password: '')));
                });
              },
            ),
          ],
        );
      },
    );
  }
}
