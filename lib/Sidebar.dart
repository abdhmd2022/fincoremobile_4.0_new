import 'dart:convert';
import 'dart:io';

import 'package:FincoreGo/addVanAllocations.dart';
import 'package:FincoreGo/viewVanAllocations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'ChangePassword.dart';
import 'Dashboard.dart';
import 'Login.dart';
import 'Settings.dart';
import 'Help.dart';
import 'RolesView.dart';
import 'SerialSelect.dart';
import 'UserView.dart';
import 'constants.dart';

class Sidebar extends StatelessWidget {
  final bool isDashEnable,
      isRolesVisible,
      isUserEnable,
      isRolesEnable,
      isUserVisible;
  final String? Username, Email;
  final TickerProvider tickerProvider;

  bool isSalesEntryVisible = false, isSalesEntryEnable = true;
  bool isReceiptEntryVisible = false, isReceiptEntryEnable = true;
  bool isVanAllocationVisible = false, isVanAllocationEnable = true;

  String SalesEntryHolder = '',
      VanAllocationHolder = '',
      username_prefs = '',
      password_prefs = '',
      ReceiptEntryHolder = '',
      serial_no = '',
      company_name = '',
      assignedGodown = '';
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

    socket = IO.io(SOCKET_URL, <String, dynamic>{
      'transports': ['websocket'],
      'path': '/main/socket.io',
      'secure': true,
      'autoConnect': true,
      'auth': {'token': authTokenBase},
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
    VanAllocationHolder = prefs.getString("vanallocation") ?? "False";
    username_prefs = prefs.getString('username') ?? '';
    serial_no = prefs.getString('serial_no') ?? '';
    company_name = prefs.getString('company_name') ?? '';

    final allocationString = prefs.getString('spectra_allocations');

    if (allocationString != null && allocationString.isNotEmpty) {
      try {
        final List<dynamic> allocations = jsonDecode(allocationString);

        if (allocations.isNotEmpty) {
          final Map<String, dynamic> allocation = Map<String, dynamic>.from(
            allocations.first,
          );

          assignedGodown = allocation['godown']?.toString().trim() ?? '';
        }
      } catch (e) {
        debugPrint('Error reading assigned godown in sidebar -> $e');
      }
    }

    /*debugPrint('Sidebar assignedGodown -> $assignedGodown');
    debugPrint('Sidebar is Van Sales -> ${vanSalesSerialNo.contains(serial_no.trim())}');

    print('van allocation value - > $VanAllocationHolder');*/
    password_prefs = prefs.getString('password') ?? '';
    isSalesEntryVisible = SalesEntryHolder == 'True';
    isReceiptEntryVisible = ReceiptEntryHolder == 'True';
    isVanAllocationVisible = VanAllocationHolder == 'True';
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade600),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      enabled: enabled,
      onTap: onTap,
      horizontalTitleGap: 10,
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildInfoChip(IconData icon, String? text, BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7, // control width
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 🔥 important (no full width)
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            SizedBox(width: 6),

            Flexible(
              fit: FlexFit.loose, // 🔥 key fix
              child: Text(
                text ?? '',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                softWrap: true, // multi-line
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Very light purple-pink like in your screenshot

      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 90, bottom: 30, left: 20, right: 20),
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
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  radius: 24,
                  child: Icon(Icons.person, color: app_color, size: 24),
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
                      SizedBox(height: 4),

                      /*
                      Wrap(
                        spacing: 6,
                        runSpacing: 6, // 🔥 IMPORTANT
                        children: [
                          _buildInfoChip(Icons.confirmation_number, serial_no,context),
                          _buildInfoChip(Icons.business, company_name,context),
                        ],
                      ),*/
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width *
                              0.7, // control width
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).cardColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize
                                    .min, // 🔥 important (no full width)
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.confirmation_number,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 6),

                                  Flexible(
                                    fit: FlexFit.loose, // 🔥 key fix
                                    child: Text(
                                      serial_no ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                      softWrap: true, // multi-line
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4),

                              Row(
                                mainAxisSize: MainAxisSize
                                    .min, // 🔥 important (no full width)
                                crossAxisAlignment: CrossAxisAlignment.center,

                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 6),

                                  Flexible(
                                    fit: FlexFit.loose, // 🔥 key fix
                                    child: Text(
                                      company_name ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                      softWrap: true, // multi-line
                                    ),
                                  ),
                                ],
                              ),

                              if (vanSalesSerialNo.contains(serial_no.trim()) &&
                                  assignedGodown.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.local_shipping_outlined,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: Text(
                                        assignedGodown,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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
                _buildTile(
                  context,
                  title: 'Dashboard',
                  icon: Icons.dashboard,
                  enabled: isDashEnable,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Dashboard()),
                    );
                  },
                ),
                _buildTile(
                  context,
                  title: 'Companies',
                  icon: Icons.business,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => SerialSelect()),
                    );
                  },
                ),
                if (isRolesVisible)
                  _buildTile(
                    context,
                    title: 'Roles',
                    icon: Icons.group,
                    enabled: isRolesEnable,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RolesView()),
                      );
                    },
                  ),
                if (isUserVisible)
                  _buildTile(
                    context,
                    title: 'Users',
                    icon: Icons.person,
                    enabled: isUserEnable,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserView()),
                      );
                    },
                  ),

                if (vanSalesSerialNo.contains(serial_no.trim()) &&
                    isVanAllocationVisible)
                  _buildTile(
                    context,
                    title: 'Van Allocation',
                    icon: Icons.local_shipping_outlined,
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ViewVanAllocationScreen(),
                        ),
                      );
                    },
                  ),
                _buildTile(
                  context,
                  title: 'Settings',
                  icon: Icons.settings,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Settings()),
                    );
                  },
                ),
                Divider(),

                _buildTile(
                  context,
                  title: 'Change Password',
                  icon: Icons.lock_outline,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChangePassword()),
                    );
                  },
                ),

                _buildTile(
                  context,
                  title: 'Help',
                  icon: Icons.help_outline,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Help()),
                    );
                  },
                ),
                _buildTile(
                  context,
                  title: 'Logout',
                  icon: Icons.logout,
                  onTap: () {
                    _showConfirmationDialogAndNavigate(context);
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '© CSH LLC 2023-2026 • Version 4.0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
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
                    color: app_color,
                  ),
                ),
                const SizedBox(height: 18),

                // 📝 Title
                Text(
                  'Logout Confirmation',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // 💬 Message
                Text(
                  'Are you sure you want to log out of your account?',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                builder: (_) =>
                                    Login(username: '', password: ''),
                              ),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app_color,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
