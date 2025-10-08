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
  bool isLedgerExpanded = false;

  bool isInventoryExpanded = false;

  bool isCostCenterExpanded = false;

  bool isBillsExpanded = false;
  int visibleLedgerCount = 3;
  int visibleBillsCount = 3;

  int visibleInventoryCount = 3;
  int visibleCostCenterCount = 3;
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
  String formatDate(String d) {
    if (d == '' || d == 'null') return 'N/A';
    try {
      return DateFormat('dd-MMM-yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  LinearGradient iconGradient() => const LinearGradient(
    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
          SingleChildScrollView(
            child:  Column(
              children: [
                _buildVoucherCard(),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                  child: Column(
                    children: [
                      if (isVisibleLedgerEntry)
                        ModernExpandableCard(
                          title: 'Accounting Details',
                          icon: Icons.account_balance,
                          children: [
                            ...ledgerentries_list
                                .take(visibleLedgerCount)
                                .map((entry) => buildLedgerRow(entry.ledger, formatAmount(entry.amount)))
                                .toList(),

                            if (ledgerentries_list.length > 3)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        if (isLedgerExpanded) {
                                          visibleLedgerCount = 3;
                                          isLedgerExpanded = false;
                                        } else {
                                          visibleLedgerCount = ledgerentries_list.length;
                                          isLedgerExpanded = true;
                                        }
                                      });
                                    },
                                    child: Text(
                                      isLedgerExpanded ? 'View Less' : 'View More',
                                      style: GoogleFonts.poppins(
                                        color: app_color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                          children: [
                            ...inventoryentries_list
                                .take(visibleInventoryCount)
                                .map((card) => Column(
                              children: [
                                buildInventoryRow('Item', card.item, 'Qty', card.qty,
                                    leftIcon: Icons.inventory_outlined, rightIcon: Icons.confirmation_num_outlined),
                                buildInventoryRow('Rate', formatRate(card.rate), 'Disc',
                                    "${formatNullto0(card.discount)}%",
                                    leftIcon: Icons.price_change, rightIcon: Icons.percent),
                                buildInventoryRow('GoDown', handleGodown(card.godown), 'Amt',
                                    formatAmount(card.amount),
                                    leftIcon: Icons.store, rightIcon: Icons.money),
                                const Divider(height: 24, thickness: 0.6),
                              ],
                            ))
                                .toList(),

                            if (inventoryentries_list.length > 3)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        if (isInventoryExpanded) {
                                          visibleInventoryCount = 3;
                                          isInventoryExpanded = false;
                                        } else {
                                          visibleInventoryCount = inventoryentries_list.length;
                                          isInventoryExpanded = true;
                                        }
                                      });
                                    },
                                    child: Text(
                                      isInventoryExpanded ? 'View Less' : 'View More',
                                      style: GoogleFonts.poppins(
                                        color: app_color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),



                      if (isVisibleCostCenter)
                        ModernExpandableCard(
                          title: 'Cost Centre Details',
                          icon: Icons.account_tree_outlined,
                          children: [
                            ...costcenter_list
                                .take(visibleCostCenterCount)
                                .map((card) => buildCostCenterRow(
                              formatCostCenter(card.costcentre),
                              formatAmount(card.amount),
                            ))
                                .toList(),


                            if (costcenter_list.length > 3)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        if (isCostCenterExpanded) {
                                          visibleCostCenterCount = 3;
                                          isCostCenterExpanded = false;
                                        } else {
                                          visibleCostCenterCount = costcenter_list.length;
                                          isCostCenterExpanded = true;
                                        }
                                      });
                                    },
                                    child: Text(
                                      isCostCenterExpanded ? 'View Less' : 'View More',
                                      style: GoogleFonts.poppins(
                                        color: app_color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),


                    ],
                  ),
                ),

                // Add bottom spacing
                const SizedBox(height: 20),
              ],
            ),

          ),

// Loader stays outside of scrollable content
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),

        ],
      ),
    );
  }

  Widget _buildVoucherCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: 12,right:12, top: 8,bottom:0),

      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(Icons.receipt_long_rounded, "Voucher No", widget.vchno),
          _buildRow(Icons.calendar_today, "Voucher Date", formatDate(widget.vchdate)),
          if (widget.refno != 'null')
            _buildRow(Icons.confirmation_number_outlined, "Ref No", widget.refno),
          if (widget.refdate != 'null')
            _buildRow(Icons.date_range_outlined, "Ref Date", formatDate(widget.refdate)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              if (widget.ispostdated == "1")
                _chip("Post Dated", const Color(0xFF00B4DB)),
              if (widget.isoptional == "1")
                _chip("Optional", const Color(0xFF8E2DE2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    // 🌈 Assign a unique gradient color based on the icon type
    LinearGradient getIconGradient() {
      if (icon == Icons.receipt_long_rounded) {
        return const LinearGradient(
          colors: [Color(0xFFFF9966), Color(0xFFFF5E62)], // orange-red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (icon == Icons.calendar_today ||
          icon == Icons.calendar_month ||
          icon == Icons.date_range_outlined) {
        return const LinearGradient(
          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)], // blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (icon == Icons.confirmation_number_outlined) {
        return const LinearGradient(
          colors: [Color(0xFF00B09B), Color(0xFF96C93D)], // green gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        return const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // purple default
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // 🎨 Rounded gradient icon background
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: getIconGradient(),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$label",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ModernExpandableCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const ModernExpandableCard({
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
  bool _isHovered = false;

  // 🌈 Unique gradient per icon type
  LinearGradient _getIconGradient(IconData icon) {
    if (icon == Icons.account_balance_wallet_rounded) {
      return const LinearGradient(
        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)], // cyan-green
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.receipt_long_rounded ||
        icon == Icons.description_outlined) {
      return const LinearGradient(
        colors: [Color(0xFFFF9966), Color(0xFFFF5E62)], // orange-red
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.inventory_2_outlined) {
      return const LinearGradient(
        colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)], // blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.account_tree_outlined) {
      return const LinearGradient(
        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // purple
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)], // green
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LinearGradient borderGradient = _getIconGradient(widget.icon);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? borderGradient.colors.first.withOpacity(0.25)
                  : Colors.black12.withOpacity(0.05),
              blurRadius: _isHovered ? 16 : 8,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            width: 1.3,
            color: _isHovered
                ? borderGradient.colors.last.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: borderGradient.colors.last.withOpacity(0.08),
          highlightColor: Colors.transparent,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    // 🌈 Gradient background for icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: _getIconGradient(widget.icon),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                            borderGradient.colors.last.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child:
                      Icon(widget.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.expand_more, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // 🔽 Expandable content
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: _isExpanded
                      ? const BoxConstraints()
                      : const BoxConstraints(maxHeight: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget buildLedgerRow(String ledger, String amount) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        double halfWidth = constraints.maxWidth / 2;

        return Row(
          children: [
            // Left side (icon + name)
            SizedBox(
              width: halfWidth,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ledger,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right side (amount)
            SizedBox(
              width: halfWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  amount,
                  textAlign: TextAlign.right,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700, // softer than green
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget buildBillRow(String label, String value, IconData icon) {
  LinearGradient gradient = const LinearGradient(
    colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      children: [
        // 🔸 Icon
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),

        // 🔸 Label
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),

        const SizedBox(width: 8),

        // 🔸 Value (right aligned, ellipsis if too long)
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildInventoryRow(
    String leftLabel,
    String leftValue,
    String rightLabel,
    String rightValue, {
      IconData? leftIcon,
      IconData? rightIcon,
    }) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    decoration: BoxDecoration(
      color: Colors.white,

    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔹 Top Row: Left + Right info side-by-side (wraps if text is long)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔸 Left Section
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leftIcon != null)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Icon(leftIcon, size: 16, color: Colors.white),
                    ),
                  if (leftIcon != null) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leftLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leftValue,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 9,),

            // 🔸 Right Section
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rightIcon != null)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Icon(rightIcon, size: 16, color: Colors.white),
                    ),
                  if (rightIcon != null) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rightLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rightValue,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


Widget buildCostCenterRow(String costCentre, String amount) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Top Row: Cost Centre Label with Icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)], // green
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(Icons.account_tree_outlined, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                costCentre,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔹 Bottom Row: Amount aligned to the right
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9966), Color(0xFFFF5E62)], // orange
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(Icons.money, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                amount,
                textAlign: TextAlign.right,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}




