import 'dart:convert';
import 'package:FincoreGo/Dashboard.dart';
import 'package:FincoreGo/ModifySalesEntry.dart';
import 'package:FincoreGo/SalesRegistration.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;
import 'currencyFormat.dart';

class SalesModel {
  final int id;
  final Map<String, dynamic> data;
  final String type;
  final int isSynced;

  SalesModel({
    required this.id,
    required this.data,
    required this.type,
    required this.isSynced,
  });

  factory SalesModel.fromJson(Map<String, dynamic> json) {
    return SalesModel(
      id: json['id'],
      data: json['data'],
      type: json['type'],
      isSynced: json['isSynced']
    );
  }}

class PendingSalesEntry extends StatefulWidget {

  const PendingSalesEntry({Key? key}) : super(key: key);
  @override
  _PendingSalesEntryPageState createState() => _PendingSalesEntryPageState();
}

class _PendingSalesEntryPageState extends State<PendingSalesEntry> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
       isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoSalesEntryFound = false;

  String? HttpURL_loadData,HttpURL_deleteEntry,token = '';

  String rolename_fetched = "";

  final List<SalesModel> salesentries = [];

  String name = "",email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

  String formatAmount(String amount) {
    String amount_string = "";
    if(amount.contains("-"))
    {
      amount = amount.replaceAll("-", "");
      double amount_double = double.parse(amount);
      amount_string = CurrencyFormatter.formatCurrency_double(amount_double);
      amount_string = amount_string;
    }
    else
    {
      if(amount == "null")
      {
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
      company  = prefs.getString('company_name');
      company_lowercase = company!.replaceAll(' ', '').toLowerCase();
      serial_no = prefs.getString('serial_no');
      username = prefs.getString('username');
      token = prefs.getString('token')!;

      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      String? email_nav = prefs.getString('email_nav');
      String? name_nav = prefs.getString('name_nav');

      HttpURL_loadData = '$hostname/api/entry/getEntries/$company_lowercase/$serial_no?type=sales&isSynced=false';
      HttpURL_deleteEntry = '$hostname/api/entry/deleteEntry/$company_lowercase/$serial_no';
      if (email_nav!=null && name_nav!= null)
      {
        name = name_nav;
        email = email_nav;
      }

      if(SecuritybtnAcessHolder == "True")
      {
        isRolesVisible = true;
        isUserVisible = true;
      }
      else
      {
        isRolesVisible = false;
        isUserVisible = false;
      }
    });
    fetchSalesEntries();
  }

  Future<void> _showConfirmationDialogAndNavigate(BuildContext context, int id) async {
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
            backgroundColor: Colors.white,
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
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Confirm Deletion",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            content: Text(
              "Do you really want to delete this entry?",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),

            actions: [
              // ❌ Cancel Button
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "No",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),

              // ✅ Confirm Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  backgroundColor: app_color,
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

    Map<String,String> headers = {
      'Authorization' : 'Bearer $token',
      "Content-Type": "application/json"
    };

    var body = jsonEncode( {
      'id': id.toString(),
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final responsee = response.body;
      if (responsee != null){

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );
        if (responsee == "Entry deleted successfully")
        {
          setState(() {
            _isLoading = true;
            fetchSalesEntries();
          });
        }
        else
        {
          setState(() {
            _isLoading = false;
          });
        }
      }
      else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to fetch data');
      }
    }
    else
    {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });
      }
      else
      {
        error = 'Server Error!!!';
      }

      Fluttertoast.showToast(msg: error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchSalesEntries() async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse(HttpURL_loadData!);

    Map<String,String> headers = {
      'Authorization' : 'Bearer $token',
      "Content-Type": "application/json"
    };

    final response = await http.post(
        url,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      salesentries.clear();
      /*print(response.body);*/
      try
      {
        final List<dynamic> jsonList = json.decode(response.body) ;

        if (jsonList != null) {

          isVisibleNoSalesEntryFound = false;
          salesentries.addAll(jsonList.map((json) => SalesModel.fromJson(json)).toList());
        }
        else
        {
          throw Exception('Failed to fetch data');
        }
        setState(() {
          if(salesentries.isEmpty)
          {
            isVisibleNoSalesEntryFound = true;
          }
          _isLoading = false;
        });
      }
      catch (e)
      {
        print(e);
      }
    }
    else
    {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });
      }
      else
      {
        error = 'Server Error!!!';
      }

      Fluttertoast.showToast(msg: error);
    }

    setState(() {
      if(salesentries.isEmpty)
      {
        isVisibleNoSalesEntryFound = true;
      }
      _isLoading = false;
    });}

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  Future<void> _refresh() async {
    setState(()
    {
      fetchSalesEntries();
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
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: AppBar(
            backgroundColor:  app_color,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            centerTitle: true,
            title: GestureDetector(
              onTap: () {

              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      "Pending Sales Entry" ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        drawer: Sidebar(
            isDashEnable: isDashEnable,
            isRolesVisible: isRolesVisible,
            isRolesEnable: isRolesEnable,
            isUserEnable: isUserEnable,
            isUserVisible: isUserVisible,
            Username: name,
            Email: email,
            tickerProvider: this
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Stack(
            children: [


              if(isVisibleNoSalesEntryFound)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No Pending Sales Entry Found',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child:  ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: salesentries.length,
                  itemBuilder: (context, index) {
                    final card = salesentries[index];
                    final partyLedger = card.data['PARTYLEDGERNAME'];
                    final dateStr = card.data['DATE'];
                    final totalAmount = card.data['totalAmount'];
                    final vchno = card.data['VOUCHERNUMBER'];
                    final vchtype = card.data['VOUCHERTYPENAME'] ?? 'N/A';

                    DateTime date = DateTime.parse(dateStr);
                    String formattedDate = DateFormat("dd-MMM-yyyy").format(date);



                    return Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Top Row: Invoice + Action Icons
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Gradient Icon
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.receipt_long, size: 18, color: Colors.white),
                                      ),
                                      const SizedBox(width: 10),

                                      // Invoice Text (⚡ remove Expanded/Flexible here)
                                      Text(
                                        "Invoice #$vchno",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis, // to handle overflow safely
                                      ),
                                    ],
                                  ),


                                  Row(
                                    children: [
                                      // Edit
                                      _buildGradientAction(
                                        icon: Icons.edit,
                                        colors: [const Color(0xFF42A5F5), const Color(0xFF1E88E5)],
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ModifySalesEntry(
                                                type: card.type,
                                                id: card.id,
                                                isSynced: card.isSynced,
                                                data: card.data,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      // Delete
                                      _buildGradientAction(
                                        icon: Icons.delete_outline,
                                        colors: [const Color(0xFFEF5350), const Color(0xFFD32F2F)],
                                        onTap: () {
                                          _showConfirmationDialogAndNavigate(context, card.id);
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 🔹 Detail Rows
                            DetailRowTile(
                              label: "Party Ledger",
                              value: partyLedger,
                            ),
                            DetailRowTile(
                              label: "Voucher Type",
                              value: vchtype,
                            ),
                            DetailRowTile(
                              label: "Date",
                              value: formattedDate,
                            ),
                            DetailRowTile(
                              label: "Total Amount",
                              value: formatAmount(totalAmount.toString()),
                            ),
                          ],
                        ),
                      ),
                    );


                  },
                ),
              ),








          // Loading spinner
              Visibility(
                visible: _isLoading,
                child: const Center(child: CircularProgressIndicator.adaptive()),
              ),

              // Floating Action Button
              Positioned(
                bottom: 40,
                right: 30,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SalesRegistration()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: LinearGradient(
                        colors: [app_color.withOpacity(0.9), app_color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: app_color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 26),
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
      ));
    // TODO: implement build
    }

  Widget _buildGradientAction({
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 3),
            )
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.white),
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

  // Gradient chooser
  LinearGradient _getGradient(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('date')) {
      return LinearGradient(colors: [Colors.indigo.shade400, Colors.indigo.shade700]);
    } else if (lower.contains('voucher')) {
      return LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade600]);
    } else if (lower.contains('amount')) {
      return LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]);
    } else if (lower.contains('party')) {
      return LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]);
    }
    return LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]);
  }

  // Icon chooser
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

  // Amount color logic
  Color _getValueColor() {
    if (label.toLowerCase().contains('amount')) {
      if (value.toLowerCase().contains("dr") || value.startsWith("-")) {
        return Colors.red.shade700; // Debit
      } else {
        return Colors.green.shade700; // Credit
      }
    }
    return Colors.black87; // Normal
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(label);
    final icon = _getIcon(label);

    final row = Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Gradient Icon
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

          // 🔹 Label (Left Half)
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),

          // 🔹 Value (Right Half)
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _getValueColor(),
              ),
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      )

    );

    return onTap != null ? GestureDetector(onTap: onTap, child: row) : row;
  }
}
