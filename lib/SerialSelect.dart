import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:fincoremobile/Dashboard.dart';
import 'package:fincoremobile/Login.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'constants.dart';
 // import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Serial {
  final String serial;
  final String role_id;
  final String license_expiry;
  final String hostname;
  final String token;

  Serial(
      {
        required this.serial,
        required this.role_id,
        required this.license_expiry,
        required this.hostname,
        required this.token,
      });
}

class SerialSelect extends StatefulWidget {
  const SerialSelect({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<SerialSelect> with TickerProviderStateMixin{

   late String  SalesDashHolder,ReceiptsDashHolder,PurchaseDashHolder,PaymentsDashHolder,OutstandingReceivablesDashHolder
  ,OutstandingPayablesDashHolder,CashDashHolder,AllitemsHolder,InActiveitemsHolder,ActiveitemsHolder
  ,RateHolder,AmountHolder,ItemSalesHolder,ItemPurchaseHolder,SalesPartyHolder,ReceiptPartyHolder,PurchasePartyHolder,PaymentPartyHolder,CreditNotePartyHolder
  ,DebitNotePartyHolder,JournalPartyHolder,ReceivablePartyHolder,PayablePartyHolder,PendingSalesOrderPartyHolder,PartySuppliersHolder,PartyCustomersHolder
  ,PendingPurchaseOrderPartyHolder,LedgerEntriesHolder,BillsEntriesHolder,InventoryEntriesHolder,CostCentreEntriesHolder, PostDatedTransactionsHolder,
       BarChartDashHolder,LineChartDashHolder,PieChartDashHolder,SalesEntryHolder,ReceiptEntryHolder,SalesOrderEntryHolder;
   List<dynamic> myData = [];
   List<dynamic> myData_company = [];
   List<dynamic> myData_admin = [];
   List<dynamic> myData_role = [];

   // late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

   bool isVisibleCompanyName = false;

   String socketId = ''; // To store the socket ID.
   String? deviceIdentifier = '';

   late IO.Socket socket;
   String? username_prefs ='',password_prefs = '';

   late String lastsyncvalue = "Not Available";

   late TickerProvider tickerProvider;

   String? company;

   late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

   late String admin_email = "",allowed_user = "";

   bool _isVisibleCompany = false;
   dynamic _selectedserial,_selectcompany,_selectedadmin,_selectedrole;
   bool _isLoading = false;
   String serial_no = "",role_id = "",license_expiry= "",license_expiry_text="",hostname= "",token = "";
   String secbtnaccess = "",company_name = "",startfrom = "";
   late SharedPreferences prefs;

   /*void showNotification(int daysRemaining, String serial_no) async {
     const AndroidNotificationDetails androidPlatformChannelSpecifics =
     AndroidNotificationDetails(
       '2', // Channel ID
       'expiryChannel', // Channel name
       channelDescription: 'Notification channel for license expiry alerts',
       importance: Importance.max,
       priority: Priority.high,
       showWhen: false,
     );

     const DarwinNotificationDetails iosPlatformChannelSpecifics =
     DarwinNotificationDetails(); // ✅ updated for iOS/macOS

     const NotificationDetails platformChannelSpecifics = NotificationDetails(
       android: androidPlatformChannelSpecifics,
       iOS: iosPlatformChannelSpecifics,
     );

     await flutterLocalNotificationsPlugin.show(
       0, // notification ID
       'Fincore Mobile License Expiry Alert',
       '$serial_no license will expire in $daysRemaining days ($license_expiry_text)',
       platformChannelSpecifics,
       payload:
       'mailto:example@example.com?subject=License%20Expiry&body=My%20license%20is%20expiring%20soon.',
     );
   }*/

   void checkExpiryDate(String expiryDate, String serial_no) {
     final DateTime now = DateTime.now();
     final DateTime expiry = DateTime.parse(expiryDate);

     final int difference = expiry.difference(now).inDays;

     if (difference <= 60) {

       //showNotification(difference,serial_no);
     }
   }

   void showProgressDialog(BuildContext context, bool _isLoading)  {
      ProgressDialog progressDialog;
      progressDialog = ProgressDialog(context, isDismissible: true,);

     progressDialog.style(
       message: 'Processing your request...', // Message displayed in the dialog
       messageTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold,),
     );
     if (_isLoading)
     {
        progressDialog.show();
     }
     else
     {
       progressDialog.hide();
     }
   }

   void _showContinueDialog(BuildContext context, String company, String lastsync) {
     showDialog(
       context: context,
       barrierDismissible: true,
       builder: (BuildContext context) {
         return AlertDialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           backgroundColor: Colors.white,
           titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 8),
           contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
           actionsPadding: EdgeInsets.only(right: 16, bottom: 16),

           title: Row(
             children: [
               Icon(Icons.sync, color: app_color),
               SizedBox(width: 10),
               Text(
                 "Sync Information",
                 style: GoogleFonts.poppins(
                   fontSize: 18,
                   fontWeight: FontWeight.bold,
                   color: Colors.black87,
                 ),
               ),
             ],
           ),

           content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 "$company was last synced on $lastsync",
                 style: GoogleFonts.poppins(
                   fontSize: 14.5,
                   color: Colors.black87,
                 ),
               ),
               SizedBox(height: 24), // <-- This adds space above the button
             ],
           ),

           actions: [

             ElevatedButton.icon(
               onPressed: () async {
                 Map<String, dynamic> selected_data = _selectcompany;
                 company_name = selected_data['company_name'] as String;
                 startfrom = selected_data['startfrom'] as String;

                 prefs = await SharedPreferences.getInstance();
                 prefs.setString("startfrom", startfrom);
                 prefs.setString("company_name", company_name);
                 prefs.setString("serial_no", serial_no);

                 if (secbtnaccess == "True") {
                   for (String key in [
                     "salesdash", "purchasedash", "barchartdash", "linechartdash", "piechartdash",
                     "salesentry", "receiptentry", "salesorderentry", "outstandingreceivabledash",
                     "outstandingpayabledash", "cashdash", "receiptsdash", "paymentsdash", "allitems",
                     "activeitems", "inactiveitems", "rate", "item_amount", "item_sales",
                     "item_purchase", "salesparty", "purchaseparty", "creditnoteparty", "journalparty",
                     "payableparty", "pendingpurchaseorderparty", "receiptparty", "paymentparty",
                     "debitnoteparty", "receivableparty", "pendingsalesorderparty", "party_suppliers",
                     "party_customers", "ledgerentries", "inventoryentries", "postdatedtransactions",
                     "billsentries", "costcentreentries"
                   ]) {
                     prefs.setString(key, "True");
                   }

                   Navigator.of(context).pop();
                   Navigator.pushReplacement(
                     context,
                     MaterialPageRoute(builder: (context) => Dashboard()),
                   );
                 } else {
                   if (mounted) {
                     setState(() {
                       _isLoading = true;
                     });
                   }
                   getroledata(context, serial_no, role_id);
                 }
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: app_color,
                 elevation: 3,
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(30),
                 ),
                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               ),
               icon: Icon(Icons.arrow_forward, color: Colors.white, size: 18),
               label: Text(
                 "Continue",
                 style: GoogleFonts.poppins(
                   fontSize: 15,
                   fontWeight: FontWeight.w500,
                   color: Colors.white,
                 ),
               ),
             ),
           ],
         );
       },
     );
   }

   Color getExpiryColor(String expiryDate) {
     try {
       final now = DateTime.now();
       final expiry = DateTime.parse(expiryDate);
       final daysLeft = expiry.difference(now).inDays;

       if (daysLeft < 0) {
         return Colors.redAccent; // ❌ Expired
       } else if (daysLeft <= 30) {
         return Colors.orangeAccent; // ⚠️ Expiring soon
       } else {
         return Colors.white; // ✅ Valid
       }
     } catch (e) {
       return Colors.grey; // fallback color
     }
   }


   @override
   void didChangeDependencies() {
     super.didChangeDependencies();
     _getDeviceIdentifier();
   }

   /*Future<String> getCompanyLastSync (BuildContext context,  String company, String serial) async {

     setState(() {
       _isLoading = true;
     });

           DateTime now = DateTime.now();

           // Get the timezone offset
           Duration offset = now.timeZoneOffset;

           // Format the offset in "+HH:mm" format
           String formattedTimeZone = '${offset.isNegative ? '-' : '+'}'
               '${offset.inHours.abs().toString().padLeft(2, '0')}:'
               '${(offset.inMinutes % 60).abs().toString().padLeft(2, '0')}';
      try
      {
        final url = Uri.parse("$hostname/api/main/$company/$serial");
        Map<String,String> headers = {
          'Authorization' : 'Bearer $token',
          "Content-Type": "application/json"
        };



        final response = await http.get(
            url,
            headers:headers
        );

        if (response.statusCode == 200)
        {
          Map<String, dynamic> jsonMap = jsonDecode(response.body);

          // Extract the "lastSync" value
          String lastSyncString = jsonMap['lastSync'];

          String trn = jsonMap['trn'];


          // Define the input format of the "lastSync" string
          DateFormat inputFormat = DateFormat('yyyy-MM-dd hh:mm:ss a');

          // Parse the "lastSync" string into a DateTime object
          DateTime lastSync;
          try {
            lastSync = inputFormat.parse(lastSyncString);
          } catch (e) {
            print('Error parsing date: $e');
            return "";
          }
          String formattedLastSync =
          DateFormat('dd-MMM-yyyy hh:mm a').format(lastSync);
          setState(() {
            company_name = _selectcompany['company_name'].toString();
            lastsyncvalue = formattedLastSync;
          });
        }
        else
        {
          setState(() {
            lastsyncvalue = "Not Available";
            isVisibleCompanyName = false;
          });
        }
      }
      catch (e)
      {
        setState(()
        {
               lastsyncvalue = "Not Available";
               isVisibleCompanyName = false;
        });
             print(e);
           }
     setState(() {
       _isLoading = false;
     });
     return lastsyncvalue;
   }*/


   Future<Map<String, String>> getCompanyLastSync(BuildContext context, String company, String serial) async {
     setState(() {
       _isLoading = true;
     });

     try {
       final url = Uri.parse("$hostname/api/main/$company/$serial");
       Map<String, String> headers = {
         'Authorization': 'Bearer $token',
         "Content-Type": "application/json"
       };

       final response = await http.get(url, headers: headers);

       if (response.statusCode == 200) {
         Map<String, dynamic> jsonMap = jsonDecode(response.body);

         // Extract the "lastSync" and "trn" values
         String lastSyncString = jsonMap['lastSync'];
         String trn = jsonMap['trn'].toString();
         String address = jsonMap['address'].toString();
         String emirate = jsonMap['state'].toString();
         String country = jsonMap['country'].toString();



         // Define the input format of the "lastSync" string
         DateFormat inputFormat = DateFormat('yyyy-MM-dd hh:mm:ss a');

         // Parse the "lastSync" string into a DateTime object
         DateTime lastSync;
         try {
           lastSync = inputFormat.parse(lastSyncString);
         } catch (e) {
           print('Error parsing date: $e');
           return {"lastSync": "", "trn": "","address" : "", "emirate" : "","country" : ""};
         }

         String formattedLastSync = DateFormat('dd-MMM-yyyy hh:mm a').format(lastSync);

         // Update UI elements if needed
         setState(() {
           company_name = _selectcompany['company_name'].toString();
           lastsyncvalue = formattedLastSync;
         });

         // Return both "lastSync" and "trn"
         return {"lastSync": formattedLastSync, "trn": trn,"address" : address, "emirate" : emirate,"country" : country};

       } else {
         setState(() {
           lastsyncvalue = "Not Available";
           isVisibleCompanyName = false;
         });
         return {"lastSync": "Not Available", "trn": "Not Available","address" : "Not Available", "emirate" : "Not Available","country" : "Not Available"};
       }
     } catch (e) {
       setState(() {
         lastsyncvalue = "Not Available";
         isVisibleCompanyName = false;
       });
       print(e);
       return {"lastSync": "Not Available", "trn": "Not Available","address" : "Not Available", "emirate" : "Not Available","country" : "Not Available"};
     } finally {
       setState(() {
         _isLoading = false;
       });
     }
   }


   Future<void> _getDeviceIdentifier() async {
     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
     String? identifier = '';

     try {
       if (Theme.of(context).platform == TargetPlatform.android) {
         final androidInfo = await deviceInfo.androidInfo;
         identifier = androidInfo.id; // ✅ use 'id' instead of 'androidId'
       } else if (Theme.of(context).platform == TargetPlatform.iOS) {
         final iosInfo = await deviceInfo.iosInfo;
         identifier = iosInfo.identifierForVendor; // ✅ same key in iOS
       }
     } catch (e) {
       debugPrint('Error getting device identifier: $e');
     }
     setState(() {
       deviceIdentifier = identifier;
     });
   }

   Future<void> _showConfirmationDialogAndExit(BuildContext context) async {
     await showDialog<void>(
       context: context,
       barrierDismissible: false, // user must tap button to close dialog
       builder: (BuildContext context) {
         return ScaleTransition(
           scale: CurvedAnimation(
             parent: AnimationController(
               duration: const Duration(milliseconds: 500),
               vsync: tickerProvider,
             )..forward(),
             curve: Curves.fastOutSlowIn,
           ),
           child: AlertDialog(
             title: Text('Exit Confirmation'),
             content: SingleChildScrollView(
               child: ListBody(
                 children: <Widget>[
                   Text('Do you really want to Exit?'),
                 ],
               ),
             ),
             actions: <Widget>[

               TextButton(
                 child: Text(
                   'No',
                   style: GoogleFonts.poppins(
                     color: app_color, // Change the text color here
                   ),
                 ),
                 onPressed: () {
                   Navigator.of(context).pop();
                 },
               ),

               TextButton(
                 child: Text(
                   'Yes',
                   style: GoogleFonts.poppins(
                     color: app_color, // Change the text color here
                   ),
                 ),
                 onPressed: () async {
                   Navigator.of(context).pop();
                   exit(0);
                 },
               ),
             ],
           ),
         );
       },
     );
   }

   void emitDeleteMyId(Map<String, dynamic> jsonPayload, Function() onComplete) {
     socket.emit('deleteMyId', jsonPayload);

     if (onComplete != null) {
       onComplete();
     }
   }

   Future<void> _initSharedPreferences() async {
     prefs = await SharedPreferences.getInstance();

     username_prefs = prefs.getString('username');
     password_prefs = prefs.getString('password');

     await prefs.remove('company_name');
     await prefs.remove('serial_no');
     await prefs.remove('datetype');
     await prefs.remove('startdate');
     await prefs.remove('enddate');
     await prefs.remove('name_nav');
     await prefs.remove('email_nav');
     await prefs.remove('sort');

     // flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

     tickerProvider = this;

     // do something with _prefs
   }

   @override
   void initState() {
    super.initState();
  _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    // Initialize Socket.IO connection
    socket = IO.io('$BASE_URL_config', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth' : {
        'token' : '$authTokenBase'
      }
    });

    /*socket = IO.io('http://192.168.2.80:5999', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth' : {
        'token' : '$authTokenBase'
      }
    });*/

    // Listen for the socket connection event and get the socket ID
    socket.on('connect', (_) {
      socketId = socket.id!;
    });
    socket.connect();

    _initSharedPreferences();
    fetchSerial();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
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
                leading: null,
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: _showConfirmationDialogAndNavigate,
                  ),
                  SizedBox(width: 5,)
                ],
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        "Fincore",
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



            body: SingleChildScrollView(
          child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [

                        // Card Content
                        Container(
                          height: 130,
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: app_color.withOpacity(0.9),
                                blurRadius: 1,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 20, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      admin_email,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.group, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Users Allowed: ',
                                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                                  ),
                                  Text(
                                    '$allowed_user',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.lock_clock, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'License Expiry: ',
                                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                                  ),
                                  Text(
                                    license_expiry_text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: getExpiryColor(license_expiry), // ✅ dynamic color
                                    ),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),




                Container(
                  margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                  child: DropdownButtonFormField<dynamic>(
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: "Serial Number",
                        labelStyle: GoogleFonts.poppins(color: app_color),
                        prefixIcon: Icon(Icons.confirmation_number_outlined, color: app_color),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder( // 👈 selected/focused state border
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: app_color, // your highlight color
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder( // 👈 default border
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        fillColor: Colors.grey.shade50,
                        filled: true,

                      ),
                    hint: Text('Serial No'),
                    value: _selectedserial,
                    items: myData.map((item) {
                      return DropdownMenuItem<dynamic>(
                        value: item,
                        child: Row(
                          children: [
                            SizedBox(width: 8),
                            Text(item['serial_no'],
                            style: GoogleFonts.poppins(
                              color: Colors.black
                            ),),
                          ]));
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedserial = value!;
                        _isLoading = true;
                      });

                      Map<String, dynamic> selected_data = _selectedserial;
                      serial_no = selected_data['serial_no'] as String;
                      role_id = selected_data['role_id'].toString();
                      hostname = selected_data['website_url'] as String;
                      token = selected_data['token'].toString();

                      if (role_id == "0")
                      {
                        secbtnaccess = "True";
                      }
                      else
                      {
                        secbtnaccess = "False";
                      }
                      prefs.setString("hostname", hostname);
                      prefs.setString("secbtnaccess", secbtnaccess);
                      prefs.setString("serial_no", serial_no);

                      getadmindata(serial_no);
                    })),

                Visibility(
                    visible: _isVisibleCompany,
                    child : Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 15, right: 10, top: 0, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: myData_company.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String firstThreeLetters = myData_company[index]["company_name"].substring(0, 3);
                                  return Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    child: ListTile(
                                        tileColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        leading: CircleAvatar(
                                          backgroundColor: app_color,

                                          child: Text(firstThreeLetters, style: GoogleFonts.poppins(color: Colors.white70)),
                                        ),
                                        title: Text(myData_company[index]['company_name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                        trailing: Icon(Icons.chevron_right, color: app_color),
                                      onTap: () async {

                                        String lastsync = '';
                                        String company_name = '';
                                        print('click');
                                        _selectcompany = myData_company[index];
                                        company_name = _selectcompany['company_name'].toString();
                                        Map<String, String> result = await getCompanyLastSync(context, company_name, serial_no);

                                        lastsync = result['lastSync'] ?? "Not Available";
                                        String trn = result['trn'].toString();
                                        String address = result['address'].toString();
                                        String emirate = result['emirate'].toString();
                                        String country = result['country'].toString();

                                        prefs.setString("company_trn", trn);
                                        prefs.setString("company_address", address);
                                        prefs.setString("company_emirate", emirate);
                                        prefs.setString("company_country", country);

                                        print("trn of $company_name is $trn");
                                        print("address of $company_name is $address");
                                        print("emirate of $company_name is $emirate");
                                        print("country of $company_name is $country");
                                        _showContinueDialog(context,company_name,lastsync);
                                        }
                                    ),
                                  );
                                },
                              ),
                            ),
                          ])))
                ),
                if (_isLoading)
                  Center(child: CircularProgressIndicator.adaptive())
              ]))))),
          onWillPop: () async {
        _showConfirmationDialogAndExit(context);
        return true;
      });
  }

  Future<void> fetchSerial() async {
    prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('login_list');
    if (jsonString != null) {
      setState(()
      {
        myData = jsonDecode(jsonString);
        _selectedserial = myData.first;

        print('serial -> $_selectedserial');
      });

      Map<String, dynamic> selected_data = _selectedserial;
      serial_no = selected_data['serial_no'] as String;
      role_id = selected_data['role_id'].toString();
      hostname = selected_data['website_url'] as String;
      token = selected_data['token'].toString();

      if (role_id == "0")
      {
        secbtnaccess = "True";
      }
      else
      {
        secbtnaccess = "False";
      }
      prefs = await SharedPreferences.getInstance();

      prefs.setString("hostname", hostname);
      prefs.setString("secbtnaccess", secbtnaccess);

      setState(() {
        _isLoading=true;
      });

      getadmindata(serial_no);
    }
  }

  Future<void> getroledata(BuildContext context, String serialno,String roleid) async {
    final url = Uri.parse('$BASE_URL_config/api/roles/get');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode( {
      'serialno': serialno,
      'roleid': roleid
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final role_data = jsonDecode(response.body);
      if (role_data != null) {
        if(mounted)
          {
            setState(() {
              myData_role = role_data;
              _selectedrole = myData_role;
            });
          }
        else
          {
            myData_role = role_data;
            _selectedrole = myData_role;
          }
          SalesDashHolder = _selectedrole[0]["isSaleDash"] ;
          BarChartDashHolder = _selectedrole[0]["isBarChartDash"] ;
          LineChartDashHolder = _selectedrole[0]["isLineChartDash"] ;
          PieChartDashHolder = _selectedrole[0]["isPieChartDash"] ;
          SalesEntryHolder = _selectedrole[0]["isSalesEntry"] ;
          ReceiptEntryHolder = _selectedrole[0]["isReceiptsEntry"] ;
          SalesOrderEntryHolder = _selectedrole[0]["isSalesOrderEntry"] ;

          ReceiptsDashHolder = _selectedrole[0]["isReceiptsDash"] ;
          PurchaseDashHolder = _selectedrole[0]["isPurchaseDash"];
          PaymentsDashHolder = _selectedrole[0]["isPaymentsDash"];
          OutstandingReceivablesDashHolder = _selectedrole[0]["isOutstandingReceivableDash"] ;
          OutstandingPayablesDashHolder = _selectedrole[0]["isOutstandingPayableDash"];
          CashDashHolder = _selectedrole[0]["isCashDash"];
          AllitemsHolder = _selectedrole[0]["isAllItems"] ;
          InActiveitemsHolder = _selectedrole[0]["isInactiveItems"] ;
          ActiveitemsHolder = _selectedrole[0]["isActiveItems"];
          RateHolder = _selectedrole[0]["isRate"] ;
          AmountHolder = _selectedrole[0]["isItemAmount"] ;
          ItemSalesHolder = _selectedrole[0]["isItemSales"] ;
          ItemPurchaseHolder = _selectedrole[0]["isItemPurchase"] ;
          SalesPartyHolder = _selectedrole[0]["isSalesParty"] ;
          ReceiptPartyHolder = _selectedrole[0]["isReceiptParty"] ;
          PurchasePartyHolder = _selectedrole[0]["isPurchaseParty"];
          PaymentPartyHolder = _selectedrole[0]["isPaymentParty"] ;
          CreditNotePartyHolder = _selectedrole[0]["isCreditNoteParty"];
          DebitNotePartyHolder = _selectedrole[0]["isDebitNoteParty"];
          JournalPartyHolder = _selectedrole[0]["isJournalParty"];
          ReceivablePartyHolder = _selectedrole[0]["isReceivableParty"];
          PayablePartyHolder = _selectedrole[0]["isPayableParty"];
          PendingSalesOrderPartyHolder = _selectedrole[0]["isPendingSalesOrderParty"] ;
          PendingPurchaseOrderPartyHolder = _selectedrole[0]["isPendingPurchaseOrderParty"] ;
          PartySuppliersHolder = _selectedrole[0]["isParty_Suppliers"] ;
          PartyCustomersHolder = _selectedrole[0]["isParty_Customers"];
          LedgerEntriesHolder = _selectedrole[0]["isLedgerEntries"] ;
          BillsEntriesHolder = _selectedrole[0]["isBillsEntries"] ;
          InventoryEntriesHolder = _selectedrole[0]["isInventoryEntries"] ;
          CostCentreEntriesHolder = _selectedrole[0]["isCostCentreEntries"];
          PostDatedTransactionsHolder = _selectedrole[0]["isPostDatedTransactions"];

            prefs.setString("salesdash", SalesDashHolder);
            prefs.setString("purchasedash", PurchaseDashHolder);
            prefs.setString("barchartdash", BarChartDashHolder);
            prefs.setString("linechartdash", LineChartDashHolder);
            prefs.setString("piechartdash", PieChartDashHolder);
            prefs.setString("salesentry", SalesEntryHolder);
            prefs.setString("receiptentry", ReceiptEntryHolder);
            prefs.setString("salesorderentry", SalesOrderEntryHolder);
            prefs.setString("outstandingreceivabledash", OutstandingReceivablesDashHolder);
            prefs.setString("outstandingpayabledash", OutstandingPayablesDashHolder);
            prefs.setString("cashdash", CashDashHolder);
            prefs.setString("receiptsdash", ReceiptsDashHolder);
            prefs.setString("paymentsdash", PaymentsDashHolder);
            prefs.setString("allitems", AllitemsHolder);
            prefs.setString("activeitems", ActiveitemsHolder);
            prefs.setString("inactiveitems", InActiveitemsHolder);
            prefs.setString("rate", RateHolder);
            prefs.setString("item_amount", AmountHolder);
            prefs.setString("item_sales", ItemSalesHolder);
            prefs.setString("item_purchase", ItemPurchaseHolder);
            prefs.setString("salesparty", SalesPartyHolder);
            prefs.setString("purchaseparty", PurchasePartyHolder);
            prefs.setString("creditnoteparty", CreditNotePartyHolder);
            prefs.setString("journalparty", JournalPartyHolder);
            prefs.setString("payableparty", PayablePartyHolder);
            prefs.setString("pendingpurchaseorderparty", PendingPurchaseOrderPartyHolder);
            prefs.setString("receiptparty", ReceiptPartyHolder);
            prefs.setString("paymentparty", PaymentPartyHolder);
            prefs.setString("debitnoteparty", DebitNotePartyHolder);
            prefs.setString("receivableparty", ReceivablePartyHolder);
            prefs.setString("pendingsalesorderparty", PendingSalesOrderPartyHolder);
            prefs.setString("party_suppliers", PartySuppliersHolder);
            prefs.setString("party_customers", PartyCustomersHolder);
            prefs.setString("ledgerentries", LedgerEntriesHolder);
            prefs.setString("inventoryentries", InventoryEntriesHolder);
            prefs.setString("postdatedtransactions" , PostDatedTransactionsHolder);
            prefs.setString("billsentries", BillsEntriesHolder);
            prefs.setString("costcentreentries", CostCentreEntriesHolder);


        Navigator.of(context).pop();


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );

      }
      else
      {
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
        error = 'Something went wrong!!!';
      }

      Fluttertoast.showToast(msg: error);

    }

    setState(() {
      _isLoading  = false;
    });
  }

  Future<void> getadmindata(String selectedserial) async {
    final url = Uri.parse('$BASE_URL_config/api/admin/getConfig');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode( {
      'serialno': selectedserial
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final admin_data = jsonDecode(response.body);
      if (admin_data != null) {
        myData_admin = admin_data;
        _selectedadmin = myData_admin;
        admin_email = _selectedadmin[0]['email'];
        allowed_user = _selectedadmin[0]['allowed_user'].toString();
        if(allowed_user!=null || allowed_user!="null")
        {
          int allowed_userr= 0;
          allowed_userr = int.parse(allowed_user);
          allowed_userr += 1;

          allowed_user = "$allowed_userr";
        }
        else
        {
          allowed_user = "0";
        }
        license_expiry = _selectedadmin[0]['license_expiry'].toString();



        if(license_expiry!= "null" || license_expiry !="") {
          DateTime expire_date = DateTime.parse(license_expiry);
          DateTime today_date = DateTime.now();

          if(token != null && token != "" && token.isNotEmpty && token != 'null') // checking if token is not empty
          {
            myData_company.clear();
            prefs.setString("token", token);

            if (today_date.isBefore(expire_date))
            {

              fetchAllowedCompany(serial_no,username_prefs!);


              DateTime dt1 = DateTime.parse(license_expiry);
              license_expiry_text = DateFormat('dd-MMM-yyyy').format(dt1);
              checkExpiryDate(license_expiry,serial_no);

            }
            else
            {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("License is expired against $serial_no"),
                ),
              );
              setState(() {
                _isVisibleCompany = false;
                _isLoading = false;
              });
            }

            DateTime dt1 = DateTime.parse(license_expiry);
            license_expiry_text = DateFormat('dd-MMM-yyyy').format(dt1);
            prefs.setString("license_expiry", license_expiry);
          }
          else
          {
            setState(()
            {
              _isVisibleCompany = false;
              _isLoading = false;
            });
            prefs.remove("token"); // removing token from internal memory incase token is empty, null or not available
            Fluttertoast.showToast(msg: 'Authorization Error. Contact your administrator');
          }
        }
      }
      else
      {
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
        error = 'Something went wrong!!!';
      }

      Fluttertoast.showToast(msg: error);
      setState(()
      {
        _isVisibleCompany = false;
        _isLoading = false;
      });
    }
  }

  Future<void> fetchCompany(String selectedserial) async {
    myData_company.clear();
    final url = Uri.parse('$BASE_URL_config/api/admin/getCompany');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial
    });

    final response = await http.post(
        url,
        body : body,
        headers : headers
    );

    if (response.statusCode == 200)
    {
      final company_data = jsonDecode(response.body);
      if (company_data != null) {
        setState(() {
          myData_company = company_data;
          _isVisibleCompany = true;
          _selectcompany = myData_company.first;
        });
    }
    else
    {
        setState(() {
          _isVisibleCompany = false;
        });
      throw Exception('Failed to fetch data');
    }
      setState(() {
        _isLoading = false;
      });
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
        error = 'Something went wrong!!!';
      }
      Fluttertoast.showToast(msg: error);

      setState(() {
        _isLoading = false;
      });
    }
}

   Future<void> fetchAllowedCompany(String selectedserial, String email) async {
     myData_company.clear();
     final url = Uri.parse('$BASE_URL_config/api/roles/allowed_companies?user_name=$email&serial_no=$selectedserial');

     Map<String,String> headers = {
       'Authorization' : 'Bearer $authTokenBase',
       "Content-Type": "application/json"
     };



     final response = await http.get(
         url,
         headers : headers
     );

     if (response.statusCode == 200)
     {

       print(response.body);
       final company_data = jsonDecode(response.body);
       if (company_data != null) {

         myData_company = company_data;

         if(myData_company.isEmpty)
         {
           fetchCompany(serial_no);

         }
         else
         {
           setState(() {
             _isVisibleCompany = true;
             _selectcompany = myData_company.first;
           });
         }
       }
       else
       {
         setState(() {
           _isVisibleCompany = false;
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
           _isLoading = false;
         });
       }
       else
       {
         error = 'Something went wrong!!!';
         setState(() {
           _isLoading = false;
         });
       }
       Fluttertoast.showToast(msg: error);


     }
   }


   Future<void> _showConfirmationDialogAndNavigate() async {
     final AnimationController controller = AnimationController(
       duration: const Duration(milliseconds: 400),
       vsync: tickerProvider,
     );

     await showGeneralDialog(
       context: context,
       barrierDismissible: true,
       barrierLabel: "Logout Confirmation",
       pageBuilder: (context, anim1, anim2) => SizedBox.shrink(),
       transitionBuilder: (context, anim1, anim2, child) {
         return ScaleTransition(
           scale: CurvedAnimation(parent: controller..forward(), curve: Curves.easeOutBack),
           child: AlertDialog(
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             backgroundColor: Colors.white,
             title: Text(
               'Logout Confirmation',
               style: GoogleFonts.poppins(
                 fontSize: 18,
                 fontWeight: FontWeight.bold,
                 color: Colors.black87,
               ),
             ),
             content: Text(
               'Do you really want to logout?',
               style: GoogleFonts.poppins(
                 fontSize: 15,
                 color: Colors.black54,
               ),
             ),
             actions: [
               TextButton(
                 onPressed: () => Navigator.of(context).pop(),
                 child: Text(
                   'Cancel',
                   style: GoogleFonts.poppins(
                     fontSize: 14,
                     fontWeight: FontWeight.w500,
                     color: app_color,
                   ),
                 ),
               ),
               TextButton(
                 onPressed: () async {
                   final prefs = await SharedPreferences.getInstance();

                   await prefs.remove('username_remember');
                   await prefs.remove('password_remember');
                   await prefs.remove('username');
                   await prefs.remove('password');
                   await prefs.remove('serial_no');
                   await prefs.remove('company_name');
                   await prefs.remove('startfrom');
                   await prefs.remove('token');
                   await prefs.remove('inactiveparties_days');

                   final jsonPayload = {
                     'username': username_prefs,
                     'password': password_prefs,
                     'macId': deviceIdentifier,
                   };

                   Navigator.of(context).pop();

                   emitDeleteMyId(jsonPayload, () {
                     Navigator.pushReplacement(
                       context,
                       MaterialPageRoute(builder: (_) => Login(username: '', password: '')),
                     );
                   });
                 },
                 child: Text(
                   'Logout',
                   style: GoogleFonts.poppins(
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     color: Colors.redAccent,
                   ),
                 ),
               ),
             ],
           ),
         );
       },
       transitionDuration: Duration(milliseconds: 400),
     );
   }

}