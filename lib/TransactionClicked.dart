import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SerialSelect.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;
import 'Constants.dart';

class LedgerEntries {
  final String ledger ,amount;

  LedgerEntries({

    required this.ledger,
    required this.amount,
  });

  factory LedgerEntries.fromJson(Map<String, dynamic> json) {
    return LedgerEntries(
      ledger: json['ledger'].toString(),
      amount: json['amount'].toString(),
    );
  }
}

class Bills {
  final String billno ,amount,billtype,duedate,billdate;

  Bills({

    required this.billno,
    required this.amount,
    required this.billtype,
    required this.duedate,
    required this.billdate,

  });

  factory Bills.fromJson(Map<String, dynamic> json) {
    return Bills(
      billno: json['billno'].toString(),
      amount: json['amount'].toString(),
      billtype: json['billtype'].toString(),
      duedate: json['duedate'].toString(),
      billdate: json['billdate'].toString(),

    );
  }

}

class InventoryEntries {
  final String item ,qty,rate,discount,amount,godown;

  InventoryEntries({

    required this.item,
    required this.qty,
    required this.rate,
    required this.discount,
    required this.amount,
    required this.godown,

  });

  factory InventoryEntries.fromJson(Map<String, dynamic> json) {
    return InventoryEntries(
      item: json['item'].toString(),
      qty: json['qty'].toString(),
      rate: json['rate'].toString(),
      discount: json['discount'].toString(),
      amount: json['amount'].toString(),
      godown : json['godown'].toString()

    );
  }
}

class CostCenter {
  final String costcentre, amount;

  CostCenter({
    required this.costcentre,
    required this.amount,
  });

  factory CostCenter.fromJson(Map<String, dynamic> json) {
    return CostCenter(
      costcentre: json['costcentre'].toString(),
      amount: json['amount'].toString(),
    );
  }
}

class TransactionsClicked extends StatefulWidget
{
  final String vchtype ,startdate,enddate,vchno,vchdate,ispostdated,refno,refdate,masterid,isoptional;
   TransactionsClicked(
      {
        required this.vchtype,
        required this.startdate,
        required this.enddate,
        required this.vchno,
        required this.vchdate,
        required this.ispostdated,
        required this.refno,
        required this.refdate,
        required this.masterid,
        required this.isoptional,
      }
      );
  @override
  _TransactionsClickedPageState createState() => _TransactionsClickedPageState(vchtype: vchtype,startDateString:startdate,endDateString:enddate
  ,vchno:vchno,vchdate:vchdate,ispostdated:ispostdated,refno:refno,refdate:refdate,masterid:masterid,isoptional:isoptional);

}

class _TransactionsClickedPageState extends State<TransactionsClicked> with TickerProviderStateMixin{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String vchtype= "",vchno= "",vchdate= "",ispostdated= "",refno= "",refdate= "",masterid= "",isoptional= "";

  String startDateString = "", endDateString = "",token = '';

  List<LedgerEntries> ledgerentries_list = [];
  List<Bills> bills_list = [];
  List<InventoryEntries> inventoryentries_list = [];
  List<CostCenter> costcenter_list = [];

  _TransactionsClickedPageState(
      {
        required this.vchtype,
        required this.startDateString,
        required this.endDateString,
        required this.vchno,
        required this.vchdate,
        required this.ispostdated,
        required this.refno,
        required this.refdate,
        required this.masterid,
        required this.isoptional,
      }
      );

  String? SecuritybtnAcessHolder;
  bool isDashEnable = true,isRolesEnable = true,isUserEnable = true,isRolesVisible = true,
      isUserVisible = true;

  String email = "";
  String name = "";

  String billno="",billtype = "",billduedate = "",billamount = "";

  String? opening_value = "0",openingheading = "";

  TextEditingController searchController = TextEditingController();

  bool isVisibleNoDataFound = false;
  bool isVisibleLedgerEntry = false, isVisibleBills = false,isVisibleInventoryEntry = false,isVisibleCostCenter = false;

  bool isTopPanelBillsVisible = true,isDueDateBillsVisible = true;
  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  late SharedPreferences prefs;

  String HttpURL = "";

  String? hostname = "",company = "",serial_no = "",company_lowercase = "",username = "";
  List<dynamic> myData = [];
  bool _isLoading = false;

  String ledgerentries = '';
  String inventoryentries = '';
  String billsentries = '';
  String costcentreentries = '';

  String handleGodown(String godown) {
    if(godown == 'null' || godown.isEmpty)
      {
        godown = 'Not Available';
      }
      return godown;
  }

  String formatCostCenter(String costcenter) {

    String costcenter_string = "";
    if(costcenter == 'null')
    {
      costcenter_string = '*Not Applicable';
    }
    else
    {
      costcenter_string = costcenter;

    }
    // Apply any transformations or formatting to the 'amount' variable here
    return costcenter_string;
  }

  String formatRate(String rate) {

    if(rate == 'null')
      {
        rate = 'Not Available';
      }
    // Apply any transformations or formatting to the 'amount' variable here
    return rate;
  }

  String convertDateFormat(String dateStr) {

    String formattedDate = "";

    if(dateStr == '' || dateStr == 'null')
    {

    }
    else
    {
      DateTime date = DateTime.parse(dateStr);

      // Format the date to the desired output format
      formattedDate = DateFormat("dd-MMM-yyyy").format(date);
    }
    // Parse the input date string


    return formattedDate;
  }

  Future<void> fetchData(final String ledgercollection,final String billscollection,final String inventorycollections,String costcentercollections,final String masterid) async
  {
    setState(() {
      isVisibleLedgerEntry = false;
      isVisibleBills = false;
      isVisibleInventoryEntry = false;
      isVisibleCostCenter = false;
      _isLoading = true;
    });

    try
    {
      if(ledgerentries == 'True')
      {
        final url_ledgerentry = Uri.parse(HttpURL!);

        Map<String,String> headers_ledgerentry = {
          'Authorization' : 'Bearer $token',
          "Content-Type": "application/json"
        };

        var body_ledgerentry = jsonEncode( {
          'collection':ledgercollection,
          'masterid':masterid

        });

        final response_ledgerentry = await http.post(
            url_ledgerentry,
            body: body_ledgerentry,
            headers:headers_ledgerentry
        );

        if (response_ledgerentry.statusCode == 200) {
          final List<dynamic> values_list_ledgerentry = jsonDecode(response_ledgerentry.body);

          if (values_list_ledgerentry != null)
          {
            ledgerentries_list.addAll(values_list_ledgerentry.map((json) => LedgerEntries.fromJson(json)).toList());

            if(!ledgerentries_list.isEmpty)
            {
              setState(() {
                isVisibleLedgerEntry = true;
              });
            }
          }
          else
          {
            throw Exception('Failed to fetch data');
          }
        }
        else
        {
          Map<String, dynamic> data = json.decode(response_ledgerentry.body);
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
      }

      if(billsentries == 'True')
      {
          final url_bills = Uri.parse(HttpURL!);

          Map<String,String> headers_bills = {
            'Authorization' : 'Bearer $token',
            "Content-Type": "application/json"
          };

          var body_bills = jsonEncode( {
            'collection':billscollection,
            'masterid':masterid

          });

          final response_bills = await http.post(
              url_bills,
              body: body_bills,
              headers:headers_bills
          );

          if (response_bills.statusCode == 200) {
            List<dynamic> values_list_bills = jsonDecode(response_bills.body);

            if (values_list_bills != null)
            {

            if(!values_list_bills.isEmpty)
            {
              for (var item in values_list_bills) {

                String billnoo = item['billno'].toString();
                String billamountt = item['amount'].toString();
                String billtypee = item['billtype'].toString();
                String billduedatee = item['duedate'].toString();
                String billdatee = item['billdate'].toString();

                if (billtypee == "On Account")
                {
                  setState(() {
                    isTopPanelBillsVisible = false;
                  });
                  billtype = billtypee;
                  billamount = formatAmount(billamountt);

                }
                else if(billtypee == "Advance")
                {
                  setState(() {
                    isTopPanelBillsVisible = true;
                    isDueDateBillsVisible = false;
                  });
                  billno = billnoo;
                  billtype = billtypee;
                  billamount = formatAmount(billamountt);
                }
                else if(billtypee == "Agst Ref" || billtypee == "New Ref")
                {
                  setState(() {
                    isTopPanelBillsVisible = true;
                    isDueDateBillsVisible = true;
                  });

                  if (billduedatee == "null")
                  {
                    billduedate = "N/A";
                  }
                  else
                  {
                    try
                    {
                      int days = int.parse(billduedatee.split(' ')[0]);

                      DateTime billdate_date = DateTime.parse(billdatee);

                      // Add the days to the billdate
                      DateTime dueDate = billdate_date.add(Duration(days: days));
                      DateFormat dateFormat = DateFormat('dd-MMM-yy');
                      String duedateafter_string = dateFormat.format(dueDate);

                      billduedate = duedateafter_string;
                    }
                    catch (e)
                    {
                      billduedate  = billduedatee;
                    }
                  }
                  billno = billnoo;
                  billtype = billtypee;
                  billamount = formatAmount(billamountt);
                }
              }
              setState(()
              {
                isVisibleBills = true;
              });
            }
            }
            else
            {
              throw Exception('Failed to fetch data');
            }
          }
          else
          {
            Map<String, dynamic> data = json.decode(response_bills.body);
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
        }

      if(inventoryentries == 'True')
      {
          final url_inventoryentry = Uri.parse(HttpURL!);

          Map<String,String> headers_inventoryentry = {
            'Authorization' : 'Bearer $token',
            "Content-Type": "application/json"
          };

          var body_inventoryentry= jsonEncode( {
            'collection':inventorycollections,
            'masterid':masterid

          });

          final response_inventoryentry = await http.post(
              url_inventoryentry,
              body: body_inventoryentry,
              headers:headers_inventoryentry
          );

          if (response_inventoryentry.statusCode == 200) {
            final List<dynamic> values_list_inventoryentry = jsonDecode(response_inventoryentry.body);

            if (values_list_inventoryentry != null)
            {
              inventoryentries_list.addAll(values_list_inventoryentry.map((json) => InventoryEntries.fromJson(json)).toList());

              if(!inventoryentries_list.isEmpty)
              {
                setState(() {
                  isVisibleInventoryEntry = true;
                });
              }
            }
            else
            {
              throw Exception('Failed to fetch data');
            }
          }
          else
          {
            Map<String, dynamic> data = json.decode(response_inventoryentry.body);
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
        }

      if(costcentreentries == 'True')
      {
          final url_costcenter = Uri.parse(HttpURL!);

          Map<String,String> headers_costcenter = {
            'Authorization' : 'Bearer $token',
            "Content-Type": "application/json"
          };

          var body_costcenter= jsonEncode( {
            'collection':costcentercollections,
            'masterid':masterid

          });

          final response_costcenter = await http.post(
              url_costcenter,
              body: body_costcenter,
              headers:headers_costcenter
          );

          if (response_costcenter.statusCode == 200) {
            final List<dynamic> values_list_costcenter = jsonDecode(response_costcenter.body);

            if (values_list_costcenter != null)
            {
              costcenter_list.addAll(values_list_costcenter.map((json) => CostCenter.fromJson(json)).toList());

              if(!costcenter_list.isEmpty)
              {
                setState(() {
                  isVisibleCostCenter = true;
                });
              }
            }
            else
            {
              throw Exception('Failed to fetch data');
            }
          }
          else
          {
            Map<String, dynamic> data = json.decode(response_costcenter.body);
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
        }

      setState(() {
        _isLoading = false;
      });
    }
    catch (e)
    {
      setState(() {
        isVisibleLedgerEntry = false;
        isVisibleBills = false;
        isVisibleInventoryEntry = false;
        isVisibleCostCenter = false;
        _isLoading = false;
      });
    }
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
    });

    ledgerentries = prefs.getString("ledgerentries") ?? 'False';
    inventoryentries = prefs.getString("inventoryentries") ?? 'False';
    billsentries = prefs.getString("billsentries") ?? 'False';
    costcentreentries = prefs.getString("costcentreentries") ?? 'False';

    SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

    HttpURL = '$hostname/api/voucher/getcollection/$company_lowercase/$serial_no';

    String? email_nav = prefs.getString('email_nav');
    String? name_nav = prefs.getString('name_nav');

    if (email_nav!=null && name_nav!= null)
    {
      name = name_nav;
      email = email_nav;
    }
    else
    {
      String val = "";
      if (SecuritybtnAcessHolder == "True")
      {
        val = SecuritybtnAcessHolder!;
      }
      else if (SecuritybtnAcessHolder == "False")
      {
        val = "";
      }
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

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(masterid),
      ),
    );

    fetchData("LedgerEntry","Bills","Inventory","CostCentre",masterid);
  }

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar:      PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          backgroundColor:   app_color,
          elevation: 6,
          automaticallyImplyLeading: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SerialSelect()),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    company ?? '',

                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,

                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.white),

              ],
            ),
          ),
          centerTitle: true,
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
          tickerProvider: this), // add the Sidebar widget here

      body: Stack(
        children: [
          Column(
            children: [
            Container(
              margin: EdgeInsets.only(left: 12, right: 12,top:8,bottom:0),
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.08),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding:  EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Voucher Type
                  Center(
                    child:  Container(
                      padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade50),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child:  Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.description_outlined, size: 16, color: Colors.orange.shade700),
                              SizedBox(width: 6),
                              Text(
                                vchtype,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        )
                      ),

                    ),
                  ),

                  // VCH No & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 18, color: Colors.teal),
                           SizedBox(width: 6),
                          Text(
                            vchno,
                            style:  GoogleFonts.poppins(color: Colors.black87),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: Colors.teal),
                           SizedBox(width: 6),
                          Text(
                            convertDateFormat(vchdate),
                            style:  GoogleFonts.poppins(color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Ref No & Ref Date
                  if (refdate != 'null' || refno != 'null') ...[
                     SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ref No
                        if (refno != 'null')
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.numbers, size: 16, color: Colors.teal),
                                 SizedBox(width: 6),
                                 Text(
                                  'Ref No: ',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                child: Text(
                                  refno,
                                  style:  GoogleFonts.poppins(color: Colors.black87),
                                ),
                                )
                                ),
                                SizedBox(width:5)
                              ],
                            ),
                          ),

                        // Ref Date
                        if (refdate != 'null')
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.date_range_outlined, size: 16, color: Colors.teal),
                                 SizedBox(width: 6),
                                 Text(
                                  'Ref Date: ',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                Flexible(
                                  child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  convertDateFormat(refdate),
                                  style:  GoogleFonts.poppins(color: Colors.black87),
                                ),
                                )
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],



                  // Post Dated / Optional Tags
                  if (ispostdated == "1" || isoptional == "1") ...[
                     SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      children: [
                        if (ispostdated == "1")
                          Container(
                            padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              border: Border.all(color: Colors.teal.shade100),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.teal.shade700),
                                 SizedBox(width: 6),
                                Text(
                                  "Post Dated",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isoptional == "1")
                          Container(
                            padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              border: Border.all(color: Colors.teal.shade100),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.teal.shade700),
                                 SizedBox(width: 6),
                                Text(
                                  "Optional",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

            Expanded(
                          child:  Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(left: 12,right:12, top: 8,bottom:16),
                              padding:  EdgeInsets.only(left:0,right:0,top:8,bottom:4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (isVisibleLedgerEntry)
                                      ModernExpandableCard(
                                        title: 'Accounting Details',
                                        icon: Icons.account_balance,
                                        children: ledgerentries_list.map((entry) {
                                          return buildLedgerRow(entry.ledger, formatAmount(entry.amount));
                                        }).toList(),
                                      ),

                                    if (isVisibleBills)
                                      ModernExpandableCard(
                                        title: 'Reference Details',
                                        icon: Icons.description_outlined,
                                        children: [
                                          if (isTopPanelBillsVisible)
                                            buildBillRow('Bill No', billno, Icons.receipt_long),
                                          if (isDueDateBillsVisible)
                                            buildBillRow('Due Date', billduedate, Icons.calendar_today),
                                          buildBillRow('Bill Type', billtype, Icons.label_important_outline),
                                          buildBillRow('Amount', billamount, Icons.money),
                                        ],
                                      ),

                                    if (isVisibleInventoryEntry)
                                      ModernExpandableCard(
                                        title: 'Item Details',
                                        icon: Icons.inventory_2_outlined,
                                        children: inventoryentries_list.map((card) {
                                          return Column(
                                            children: [
                                              buildInventoryRow('Item', card.item, 'Qty', card.qty,
                                                  leftIcon: Icons.inventory_outlined, rightIcon: Icons.confirmation_num_outlined),
                                              buildInventoryRow('Rate', formatRate(card.rate), 'Disc',
                                                  "${formatNullto0(card.discount)}%",
                                                  leftIcon: Icons.price_change, rightIcon: Icons.percent),
                                              buildInventoryRow('GoDown', handleGodown(card.godown), 'Amt',
                                                  formatAmount(card.amount),
                                                  leftIcon: Icons.store, rightIcon: Icons.money),
                                               Divider(height: 24, thickness: 0.6),
                                            ],
                                          );
                                        }).toList(),
                                      ),

                                    if (isVisibleCostCenter)
                                      ModernExpandableCard(
                                        title: 'Cost Centre Details',
                                        icon: Icons.account_tree_outlined,
                                        children: costcenter_list.map((card) {
                                          return buildCostCenterRow(
                                            formatCostCenter(card.costcentre),
                                            formatAmount(card.amount),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                )

                              ),

                          ),
                        ),
            ],
          ),
            Visibility(

              visible: _isLoading,
              child: Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),)
        ],
      ),
    );
  }
}

class ModernExpandableCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

   ModernExpandableCard({
    required this.title,
    required this.icon,
    required this.children,
    super.key,
  });

  @override
  State<ModernExpandableCard> createState() => _ModernExpandableCardState();
}

class _ModernExpandableCardState extends State<ModernExpandableCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:  [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:  EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.teal),
                   SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style:  GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration:  Duration(milliseconds: 200),
                    child:  Icon(Icons.expand_more, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // Animated content
          AnimatedSize(
            duration:  Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: _isExpanded
                  ?  BoxConstraints()
                  :  BoxConstraints(maxHeight: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildLedgerRow(String ledger, String amount) {
  return Padding(
    padding:  EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.teal.shade600),
               SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    ledger,
                    style:  GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                )
              ),
            ],
          ),
        ),
        Row(


          children: [
            SizedBox(width: 8),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget buildBillRow(String label, String value, IconData icon) {
  return Padding(
    padding:  EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal),
         SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              value,
              style:  GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87),
            ),
          )
        ),
      ],
    ),
  );
}
Widget buildInventoryRow(String leftLabel, String leftValue, String rightLabel, String rightValue,
    {IconData? leftIcon, IconData? rightIcon}) {
  return Padding(
    padding:  EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (leftIcon != null) Icon(leftIcon, size: 16, color: Colors.teal),
               SizedBox(width: 6),
              Text(
                '$leftLabel: ',
                style:  GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              Flexible(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                leftValue,
                style:  GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87),
              ),
              )
              ),
            ],
          ),
        ),
         SizedBox(width: 12),
        Row(
          children: [
            if (rightIcon != null) Icon(rightIcon, size: 16, color: Colors.teal),
             SizedBox(width: 6),
            Text(
              '$rightLabel: ',
              style:  GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            Text(
              rightValue,
              style:  GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget buildCostCenterRow(String costCentre, String amount) {
  return Padding(
    padding:  EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 16, color: Colors.deepPurple),
             SizedBox(width: 6),
            Text(costCentre, style:  GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87)),
          ],
        ),
        Row(
          children: [
            Icon(Icons.currency_rupee, size: 16, color: Colors.green),
             SizedBox(width: 4),
            Text(amount, style:  GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}
