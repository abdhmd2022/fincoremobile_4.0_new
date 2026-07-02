import 'dart:convert';
import 'package:FincoreGo/Dashboard.dart';
import 'package:FincoreGo/ReceiptRegistration.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'widgets/entry_widgets.dart';
import 'ModifyReceiptEntry.dart';
import 'package:http/http.dart' as http;
import 'currencyFormat.dart';
import 'package:FincoreGo/widgets/app_bottom_nav.dart';
import 'package:FincoreGo/widgets/app_navigation.dart';

class ReceiptModel {
  final int id;
  final Map<String, dynamic> data;
  final String type;
  final int isSynced;
  final String? message;

  ReceiptModel({
    required this.id,
    required this.data,
    required this.type,
    required this.isSynced,
    this.message,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'],
      data: json['data'],
      type: json['type'],
      isSynced: json['isSynced'],
      message: json['message'],
    );
  }
}

class PendingReceiptEntry extends StatefulWidget {
  const PendingReceiptEntry({Key? key}) : super(key: key);
  @override
  _PendingReceiptEntryPageState createState() =>
      _PendingReceiptEntryPageState();
}

class _PendingReceiptEntryPageState extends State<PendingReceiptEntry>
    with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoReceiptEntryFound = false;

  final Set<int> expandedCards = {};

  String? HttpURL_loadData, HttpURL_deleteEntry, token = '';

  String rolename_fetched = "";

  final List<ReceiptModel> receiptentries = [];

  String name = "", email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late SharedPreferences prefs;

  String? hostname = "",
      company = "",
      company_lowercase = "",
      serial_no = "",
      username = "",
      HttpURL = "",
      SecuritybtnAcessHolder = "";

  TextEditingController _searchController = TextEditingController();

  List<ReceiptModel> filteredReceiptEntries = [];

  String formatAmount(String amount) {
    String amount_string = "";
    if (amount.contains("-")) {
      amount = amount.replaceAll("-", "");
      double amount_double = double.parse(amount);
      amount_string = CurrencyFormatter.formatCurrency_double(amount_double);
      amount_string = amount_string;
    } else {
      if (amount == "null") {
        amount = "0";
      }
      double amount_double = double.parse(amount);
      amount_string = CurrencyFormatter.formatCurrency_double(amount_double);
      amount_string = amount_string;
    }
    // Apply any transformations or formatting to the 'amount' variable here
    return amount_string;
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      hostname = prefs.getString('hostname');
      company = prefs.getString('company_name');
      company_lowercase = company!.replaceAll(' ', '').toLowerCase();
      serial_no = prefs.getString('serial_no');
      username = prefs.getString('username');
      token = prefs.getString('token')!;

      print("serial_no: $serial_no");
      print("isVanSalesSerial: $isVanSalesSerial");
      print("vanSalesSerialNo: $vanSalesSerialNo");

      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      String? email_nav = prefs.getString('email_nav');
      String? name_nav = prefs.getString('name_nav');

      HttpURL_loadData =
          '$hostname/api/entry/getEntries/$company_lowercase/$serial_no?type=receipt';
      HttpURL_deleteEntry =
          '$hostname/api/entry/deleteEntry/$company_lowercase/$serial_no';
      if (email_nav != null && name_nav != null) {
        name = name_nav;
        email = email_nav;
      }

      if (SecuritybtnAcessHolder == "True") {
        isRolesVisible = true;
        isUserVisible = true;
      } else {
        isRolesVisible = false;
        isUserVisible = false;
      }
    });
    fetchReceiptEntries();
  }

  Future<void> _showConfirmationDialogAndNavigate(
    BuildContext context,
    int id,
  ) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return const SizedBox.shrink(); // required
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedValue = Curves.easeInOut.transform(anim1.value);

        return Transform.scale(
          scale: curvedValue,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 8,
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),

            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Confirm Deletion",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            content: Text(
              "Do you really want to delete this entry?",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            actions: [
              // ❌ Cancel Button
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "No",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // ✅ Confirm Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  entrydelete(id);
                },
                child: Text(
                  "Yes",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> entrydelete(int id) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse(HttpURL_deleteEntry!);

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json",
    };

    var body = jsonEncode({'id': id.toString()});

    final response = await http.post(url, body: body, headers: headers);

    if (response.statusCode == 200) {
      final responsee = response.body;
      if (responsee != null) {
        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );*/
        if (responsee == "Entry deleted successfully") {
          setState(() {
            _isLoading = true;
            fetchReceiptEntries();
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to fetch data');
      }
    } else {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });
      } else {
        error = 'Something went wrong!!!';
      }
      Fluttertoast.showToast(msg: error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchReceiptEntries() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    String? voucherTypeName;

    final String? spectraAllocationsString = prefs.getString(
      'spectra_allocations',
    );

    if (spectraAllocationsString != null &&
        spectraAllocationsString.isNotEmpty) {
      final List<dynamic> spectraAllocations = jsonDecode(
        spectraAllocationsString,
      );

      if (spectraAllocations.isNotEmpty) {
        voucherTypeName = spectraAllocations.first['receipt_voucher_type'];
      }
    }
    dynamic url;
    if (voucherTypeName != null && voucherTypeName.trim().isNotEmpty) {
      url = Uri.parse(
        '$hostname/api/entry/getEntries/$company_lowercase/$serial_no?type=receipt&vchName=$voucherTypeName',
      );
    } else {
      url = Uri.parse(
        '$hostname/api/entry/getEntries/$company_lowercase/$serial_no?type=receipt',
      );
    }
    print('receipt voucher type -> $voucherTypeName');
    print('getting receipts from url -> $url');

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json",
    };

    final response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      receiptentries.clear();
      filteredReceiptEntries.clear();

      /*print(response.body);*/

      try {
        final List<dynamic> jsonList = json.decode(response.body);

        if (jsonList != null) {
          isVisibleNoReceiptEntryFound = false;

          receiptentries.addAll(
            jsonList.map((json) => ReceiptModel.fromJson(json)).toList(),
          );
          receiptentries.sort((a, b) {
            final vchA = int.tryParse((a.data['VOUCHERNUMBER'] ?? '').toString()) ?? 0;
            final vchB = int.tryParse((b.data['VOUCHERNUMBER'] ?? '').toString()) ?? 0;
            if (vchA != vchB) return vchB.compareTo(vchA);
            DateTime dateA = DateTime.parse(a.data['DATE']);
            DateTime dateB = DateTime.parse(b.data['DATE']);
            return dateB.compareTo(dateA);
          });
          filteredReceiptEntries = List.from(receiptentries);

          setState(() {
            FocusManager.instance.primaryFocus?.unfocus();
            _searchController.clear();
          });
        } else {
          throw Exception('Failed to fetch data');
        }
        setState(() {
          if (filteredReceiptEntries.isEmpty) {
            isVisibleNoReceiptEntryFound = true;
          }
          _isLoading = false;
        });
      } catch (e) {
        print(e);
      }
    } else {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });
      } else {
        error = 'Something went wrong!!!';
      }
      Fluttertoast.showToast(msg: error);
    }
    setState(() {
      if (filteredReceiptEntries.isEmpty) {
        isVisibleNoReceiptEntryFound = true;
      }
      _isLoading = false;
    });
  }

  void searchReceipt(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        filteredReceiptEntries = List.from(receiptentries);
      });
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      filteredReceiptEntries = receiptentries.where((entry) {
        final d = entry.data;

        return (d['PARTYLEDGERNAME'] ?? '').toString().toLowerCase().contains(
              q,
            ) ||
            (d['VOUCHERNUMBER'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  bool get isVanSalesSerial {
    final currentSerial = serial_no?.trim().toLowerCase();

    if (currentSerial == null || currentSerial.isEmpty) {
      return false;
    }

    return vanSalesSerialNo.any((s) => s.trim().toLowerCase() == currentSerial);
  }

  Future<void> _refresh() async {
    setState(() {
      fetchReceiptEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
        return true;
      },
      child: Scaffold(
        bottomNavigationBar: const AppBottomNav(
          activeTab: AppBottomNavTab.entries,
          activeEntryType: AppEntryType.receipt,
        ),
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: entryAppBar(
          context: context,
          title: "Receipt Entries",
          onBack: () => AppNavigation.backOrDashboard(context),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              if (receiptentries.isNotEmpty)
                EntrySearchBar(
                  controller: _searchController,
                  onChanged: searchReceipt,
                  hintText: "Search receipt entries...",
                ),
              Expanded(
                child: Stack(
                  children: [
                    if (isVisibleNoReceiptEntryFound)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Receipt Entry Found',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (!isVisibleNoReceiptEntryFound)
                      ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                        itemCount: filteredReceiptEntries.length,
                        itemBuilder: (context, index) {
                          final card = filteredReceiptEntries[index];
                          final partyLedger = card.data['PARTYLEDGERNAME'];
                          final dateStr = card.data['DATE'];
                          var firstEntry = card.data['ALLLEDGERENTRIES.LIST'][0];
                          final vchno = card.data['VOUCHERNUMBER'];
                          final vchtype = card.data['VOUCHERTYPENAME'] ?? 'N/A';
                          final totalAmount = firstEntry['AMOUNT'];
                          final bool isExpanded = expandedCards.contains(card.id);

                          DateTime date = DateTime.parse(dateStr);
                          String formattedDate = DateFormat("dd-MMM-yyyy").format(date);

                          final bool canActOnCard = card.isSynced != 1 &&
                              (serial_no != uniGasSerialNumber);

                          return PendingEntryCard(
                            voucherNo: '$vchno',
                            date: formattedDate,
                            partyName: partyLedger,
                            amount: formatAmount(totalAmount.toString()),
                            isSynced: card.isSynced == 1,
                            errorMessage: (card.isSynced == 2 && card.message != null)
                                ? card.message
                                : null,
                            isExpanded: isExpanded,
                            onTap: () {
                              setState(() {
                                isExpanded
                                    ? expandedCards.remove(card.id)
                                    : expandedCards.add(card.id);
                              });
                            },
                            onEdit: canActOnCard
                                ? () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ModifyReceiptEntry(
                                          type: card.type,
                                          id: card.id,
                                          isSynced: card.isSynced,
                                          data: card.data,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            onDelete: canActOnCard
                                ? () {
                                    _showConfirmationDialogAndNavigate(
                                      context,
                                      card.id,
                                    );
                                  }
                                : null,
                            expandedContent: [
                              DetailRowTile(
                                label: "Voucher Type",
                                value: vchtype,
                              ),
                              DetailRowTile(
                                label: "Total Amount",
                                value: formatAmount(totalAmount.toString()),
                              ),
                            ],
                          );
                        },
                      ),

                    // Loading spinner
                    Visibility(
                      visible: _isLoading,
                      child: const Center(child: AppLogoLoader()),
                    ),

                    // Floating Action Button
                    Positioned(
                      bottom: 40,
                      right: 30,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReceiptRegistration(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [app_color.withValues(alpha: 0.9), app_color],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: app_color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Create Entry",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailRowTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const DetailRowTile({
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  LinearGradient _getGradient(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('date')) {
      return LinearGradient(
        colors: [Colors.indigo.shade400, Colors.indigo.shade700],
      );
    } else if (lower.contains('voucher')) {
      return LinearGradient(
        colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
      );
    } else if (lower.contains('amount')) {
      return LinearGradient(
        colors: [Colors.green.shade400, Colors.green.shade700],
      );
    } else if (lower.contains('party')) {
      return LinearGradient(
        colors: [Colors.blue.shade400, Colors.blue.shade700],
      );
    }
    return LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]);
  }

  IconData _getIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('date')) {
      return Icons.calendar_today_rounded;
    } else if (lower.contains('voucher')) {
      return Icons.receipt_long_rounded;
    } else if (lower.contains('amount')) {
      return Icons.attach_money_rounded;
    } else if (lower.contains('party')) {
      return Icons.person_outline;
    }
    return Icons.info_outline;
  }

  Color _getValueColor(BuildContext context) {
    if (label.toLowerCase().contains('amount')) {
      if (value.toLowerCase().contains("dr") || value.startsWith("-")) {
        return Colors.red.shade700;
      } else {
        return Colors.green.shade700;
      }
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(label);
    final icon = _getIcon(label);

    final row = Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2937)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.last.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _getValueColor(context),
              ),
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: row) : row;
  }
}
