import 'dart:convert';
import 'package:fincoremobile/currencyFormat.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PartyTotalClickedCostCenterItemsVchType.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';

import 'dart:io';

class Bills{

  final String vchno,Partyledger,vchdate,amount;

  Bills({



    required this.vchno,
    required this.Partyledger,
    required this.vchdate,
    required this.amount,

  });

  factory Bills.fromJson(Map<String, dynamic> json) {
    return Bills(
      vchno: json['vchno'].toString(),
      Partyledger: json['Partyledger'].toString(),
      vchdate: json['vchdate'].toString(),
      amount: json['amount'].toString(),
    );
  }
}
class Vouchertype{

  final String vchname,qty,amount;

  Vouchertype({


    required this.vchname,
    required this.qty,
    required this.amount,

  });

  factory Vouchertype.fromJson(Map<String, dynamic> json) {
    return Vouchertype(
      vchname: json['vchname'].toString(),
      qty: json['qty'].toString(),
      amount: json['amount'].toString(),
    );
  }
}

class PartyTotalClickedCostCenterItems extends StatefulWidget
{
  final String startdate_string,enddate_string,type,ledger,total,costcenter,item;

  const PartyTotalClickedCostCenterItems(
      {required this.startdate_string,
        required this.enddate_string,
        required this.type,
        required this.ledger,
        required this.total,
        required this.costcenter,
        required this.item,

      }
      );
  @override
  _PartyTotalClickedCostCenterItemsPageState createState() => _PartyTotalClickedCostCenterItemsPageState(startDateString: startdate_string,
      endDateString: enddate_string,type: type,total: total,ledger:  ledger,costcenter:costcenter,item:item);
}

class _PartyTotalClickedCostCenterItemsPageState extends State<PartyTotalClickedCostCenterItems> with TickerProviderStateMixin{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String startDateString = "",endDateString = "",type = "",ledger = "",total = "",costcenter = "",item="";

  int counter = 0;
  double total_double  = 0;

  String total_main = "0",token = '';

  List<Bills> filteredItems_Bills = []; // Initialize an empty list to hold the filtered items
  List<Vouchertype> filteredItems_vouchertype = []; // Initialize an empty list to hold the filtered items

  _PartyTotalClickedCostCenterItemsPageState(
      {required this.startDateString,
        required this.endDateString,
        required this.type,
        required this.ledger,
        required this.total,
        required this.costcenter,
        required this.item,

      }
      );

  String? SecuritybtnAcessHolder;
  bool isDashEnable = true,isRolesEnable = true,isUserEnable = true,isRolesVisible = true,
      isUserVisible = true,_isSearchViewVisible = false,_isItemsListVisible = false,_isBillsListVisible = false,
      _isVoucherTypeListVisible = false, _isCostCenterListVisible = false;

  String email = "";
  String name = "";

  TextEditingController searchController = TextEditingController();

  bool isVisibleNoDataFound = false;

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  late SharedPreferences prefs;
  late String startdate_text = "", enddate_text = "";
  String? datetype;

  late String? startdate_pref, enddate_pref;

  String HttpURL = "";

  String? hostname = "",company = "",serial_no = "",company_lowercase = "",username = "";
  List<dynamic> myData = [];
  bool _isLoading = false;

  dynamic _selectedgroup = "Bills";
  List<String> spinner_list = [
    'Bills','Voucher Type'];

  List<Bills> bills_list = [];
  List<Vouchertype> vouchertype_list = [];

  Future<void> generateAndSharePDF_Bills() async {
    final pdf = pw.Document();

    final companyName = company!;
    final parentname = _selectedgroup;
    final reportname = '$parentname Wise $type Summary';
    final ledgername = ledger;

    final headersRow3 = ['Vch Date', 'Vch No', 'Amount'];
    final itemsPerPage = 10;
    final pageCount = (bills_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex = (pageNumber + 1) * itemsPerPage > bills_list.length
          ? bills_list.length
          : (pageNumber + 1) * itemsPerPage;
      final itemsSubset = bills_list.sublist(startIndex, endIndex);

      final tableSubsetRows = itemsSubset
          .map((item) => [
        convertDateFormat(item.vchdate),
        item.vchno,
        formatAmount(item.amount)
      ])
          .toList();

      final tableSubset = pw.Table.fromTextArray(
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(2),
          color: PdfColors.grey300,
        ),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
        headers: headersRow3,
        data: tableSubsetRows,
        cellPadding: pw.EdgeInsets.all(5),
        cellAlignment: pw.Alignment.center,
      );

      pdf.addPage(
        pw.Page(
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(companyName,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(reportname,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(convertDateFormat(startDateString),
                        style: pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(width: 5),
                    pw.Text('to', style: pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(width: 5),
                    pw.Text(convertDateFormat(endDateString),
                        style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Ledger:',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 5),
                    pw.Text(ledgername, style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Cost Center:',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 5),
                    pw.Text(formatCostCenter(costcenter),
                        style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Stock Item:',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 5),
                    pw.Text(item, style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 20),
              pw.Expanded(child: tableSubset),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/$type' 'Report.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    await Share.shareXFiles([XFile(tempFilePath)],
        text: 'Sharing $parentname wise $type Report of $company');
  }

  Future<void> generateAndSharePDF_VchType() async {
    final pdf = pw.Document();

    final companyName = company!;
    final parentname = _selectedgroup;
    final reportname = '$parentname Wise $type Summary';
    final ledgername = ledger;

    final headersRow3 = ['Vch Name', 'Amount'];
    final itemsPerPage = 10;
    final pageCount = (vouchertype_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex = (pageNumber + 1) * itemsPerPage > vouchertype_list.length
          ? vouchertype_list.length
          : (pageNumber + 1) * itemsPerPage;
      final itemsSubset = vouchertype_list.sublist(startIndex, endIndex);

      final tableSubsetRows = itemsSubset
          .map((item) => [item.vchname, formatAmount(item.amount)])
          .toList();

      final tableSubset = pw.Table.fromTextArray(
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(2),
          color: PdfColors.grey300,
        ),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
        headers: headersRow3,
        data: tableSubsetRows,
        cellPadding: pw.EdgeInsets.all(5),
        cellAlignment: pw.Alignment.center,
      );

      pdf.addPage(
        pw.Page(
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(companyName,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(reportname,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(convertDateFormat(startDateString),
                        style: pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(width: 5),
                    pw.Text('to', style: pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(width: 5),
                    pw.Text(convertDateFormat(endDateString),
                        style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Ledger:',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 5),
                    pw.Text(ledgername, style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Cost Center:',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 5),
                    pw.Text(formatCostCenter(costcenter),
                        style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Stock Item:',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 5),
                    pw.Text(item, style: pw.TextStyle(fontSize: 16)),
                  ]),
              pw.SizedBox(height: 20),
              pw.Expanded(child: tableSubset),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/$type' 'Report.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    await Share.shareXFiles([XFile(tempFilePath)],
        text: 'Sharing $parentname wise $type Report of $company');
  }

  Future<void> generateAndShareCSV_Bills() async {
    final parentname = _selectedgroup;
    final List<List<dynamic>> csvData = [['Vch Date', 'Vch No', 'Amount']];

    for (final item in bills_list) {
      csvData.add([
        convertDateFormat(item.vchdate),
        item.vchno,
        formatAmount(item.amount)
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/$type' 'Report.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    await Share.shareXFiles([XFile(tempFilePath)],
        text: 'Sharing $parentname wise $type Report of $company');
  }

  Future<void> generateAndShareCSV_VchType() async {
    final parentname = _selectedgroup;
    final List<List<dynamic>> csvData = [['Vch Name', 'Amount']];

    for (final item in vouchertype_list) {
      csvData.add([item.vchname, formatAmount(item.amount)]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/$type' 'Report.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    await Share.shareXFiles([XFile(tempFilePath)],
        text: 'Sharing $parentname wise $type Report of $company');
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




  String formatOpening(String opening) {
    String opening_string = "";

    if(opening.contains("-"))
    {
      opening = opening.replaceAll("-", "");
      double opening_double = double.parse(opening);
      int opening_int = opening_double.round();
      opening_string = CurrencyFormatter.formatCurrency_int(opening_int);
      opening_string = opening_string + " DR";
    }
    else
    {
      double opening_double = double.parse(opening);
      int opening_int = opening_double.round();
      opening_string = CurrencyFormatter.formatCurrency_int(opening_int);
      opening_string = opening_string + " CR";
    }
    return opening_string;
  }

  String convertDateFormat(String dateStr) {
    // Parse the input date string
    DateTime date = DateTime.parse(dateStr);

    // Format the date to the desired output format
    String formattedDate = DateFormat("dd-MMM-yy").format(date);

    return formattedDate;
  }

  Future<void> fetchBills(final String ledger,final String startdate, final String enddate, final String vchtype, final String groupby,final String orderby,final String costcenter,final String item) async
  {


    setState(() {
      _isLoading = true;
      _isBillsListVisible = true;
      _isItemsListVisible = false;
      _isVoucherTypeListVisible = false;
      _isCostCenterListVisible = false;
      total_main = total;

    });

    bills_list.clear();
    filteredItems_Bills.clear();



    try
    {

      final url = Uri.parse(HttpURL!);

      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'startdate': startdate,
        'enddate': enddate,
        'party': ledger,
        'vchtype' : vchtype,
        'groupby' : groupby,
        'orderby' : orderby,
        'costcentre' : costcenter,
        'item' : item,
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {

        final List<dynamic> values_list = jsonDecode(response.body);
        if (values_list != null) {
          isVisibleNoDataFound = false;

          bills_list.addAll(values_list.map((json) => Bills.fromJson(json)).toList());
          filteredItems_Bills = bills_list;


        } else {

          throw Exception('Failed to fetch data');
        }
        setState(() {
          _isLoading = false;
        });

      }
    }
    catch (e)
    {
      setState(() {
        _isLoading = false;
      });
      print(e);
    }

    setState(() {
      if(bills_list.isEmpty)
      {
        isVisibleNoDataFound = true;
      }
      _isLoading = false;
    });

  }

  Future<void> fetchVoucherType(final String ledger,final String startdate, final String enddate, final String vchtype, final String groupby,final String orderby,final String costcenter,final String item) async
  {
    setState(() {
      _isLoading = true;
      _isBillsListVisible = false;
      _isItemsListVisible = false;
      _isVoucherTypeListVisible = true;
      _isCostCenterListVisible = false;
      total_main = total;

    });

    vouchertype_list.clear();
    filteredItems_vouchertype.clear();


    try
    {

      final url = Uri.parse(HttpURL!);

      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'startdate': startdate,
        'enddate': enddate,
        'party': ledger,
        'vchtype' : vchtype,
        'groupby' : groupby,
        'orderby' : orderby,
        'costcentre' : costcenter,
        'item' : item,
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {

        final List<dynamic> values_list = jsonDecode(response.body);
        if (values_list != null) {
          isVisibleNoDataFound = false;

          vouchertype_list.addAll(values_list.map((json) => Vouchertype.fromJson(json)).toList());
          filteredItems_vouchertype = vouchertype_list;


        } else {

          throw Exception('Failed to fetch data');
        }
        setState(() {
          _isLoading = false;
        });

      }
    }
    catch (e)
    {
      setState(() {
        _isLoading = false;
      });
      print(e);
    }

    setState(() {
      if(vouchertype_list.isEmpty)
      {
        isVisibleNoDataFound = true;
      }
      _isLoading = false;
    });

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

    HttpURL = '$hostname/api/item/getTotalAmount/$company_lowercase/$serial_no';

    SecuritybtnAcessHolder = prefs.getString('secbtnaccess');


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

    startdate_text = convertDateFormat(startDateString);
    enddate_text = convertDateFormat(endDateString);

   if (_selectedgroup == "Bills")
    {
      fetchBills(ledger,startDateString,endDateString,type,"vchno","vchno",costcenter,item);

    }
    else if (_selectedgroup == "Voucher Type")
    {
      fetchVoucherType(ledger,startDateString,endDateString,type,"vchname","vchname",costcenter,item);

    }
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor:  app_color,
          elevation: 6,
          automaticallyImplyLeading: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style:  GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ledger,
                style:  GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                counter++;

                _isSearchViewVisible=!_isSearchViewVisible;


                setState(() {
                  if(!_isSearchViewVisible)
                  {
                    searchController.clear();
                    if (_selectedgroup == "Bills") {
                      filteredItems_Bills = bills_list;
                    } else if (_selectedgroup == "Voucher Type") {
                      filteredItems_vouchertype = vouchertype_list;
                    }
                  }
                });
              },
              icon: Icon(
                Icons.search,
                color: Colors.white,
                size: 30,
              ),
            ),
            IconButton(
              onPressed: () {

                final RenderBox button = context.findRenderObject() as RenderBox;
                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    overlay.size.width - buttonPosition.dx ,
                    buttonPosition.dy - button.size.height,
                    overlay.size.width - buttonPosition.dx,
                    buttonPosition.dy,
                  ),
                  items: <PopupMenuEntry<String>>[


                    PopupMenuItem<String>(

                        child: GestureDetector(
                          onTap: ()
                          {
                            Navigator.pop(context);

                            if (_selectedgroup == "Bills")
                            {
                              if(!bills_list.isEmpty)
                              {
                                generateAndSharePDF_Bills();
                              }
                            }
                            else if (_selectedgroup == "Voucher Type")
                            {
                              if(!vouchertype_list.isEmpty)
                              {
                                generateAndSharePDF_VchType();
                              }
                            }



                          },
                          child:  Row(children: [

                            Icon( Icons.picture_as_pdf,
                              size: 16,
                              color: Color(0xFF26ADA3),),
                            SizedBox(width: 5,),

                            Text(
                              'Share as PDF',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF26ADA3),
                                fontSize: 16,
                              ),
                            )]),)

                    ),

                    PopupMenuItem<String>(
                        child: GestureDetector(
                          onTap: ()
                          {
                            Navigator.pop(context);

                            if (_selectedgroup == "Bills")
                            {
                              if(!bills_list.isEmpty)
                              {
                                generateAndShareCSV_Bills();
                              }
                            }
                            else if (_selectedgroup == "Voucher Type")
                            {
                              if(!vouchertype_list.isEmpty)
                              {
                                generateAndShareCSV_VchType();
                              }
                            }

                          },

                          child:  Row(children: [

                            Icon( Icons.add_chart_outlined,
                              size: 16,
                              color: Color(0xFF26ADA3),),
                            SizedBox(width: 5,),

                            Text(
                              'Share as CSV',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF26ADA3),
                                fontSize: 16,
                              ),
                            )]),)
                    )
                  ],
                );
              },
              icon: Icon(
                Icons.share,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Value
                    Center(
                      child: Text(
                        total_main,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Date Range pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: app_color, width: 1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 18, color: app_color),
                            const SizedBox(width: 10),
                            Text(
                              "$startdate_text → $enddate_text",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 20, // spacing *between* the two items, adjust if needed
                      runSpacing: 10, // spacing if wrapped into next line
                      children: [


                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child:      Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.apartment_rounded, size: 18, color: Colors.black54),
                              SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    formatCostCenter(costcenter),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Cost Center',
                                    style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),

                              const Icon(Icons.chevron_right, size: 24, color: Colors.black54),
                            ],
                          ),
                        ),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child:      Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_rounded, size: 18, color: Colors.black54),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Item',
                                    style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black54),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),

                      ],
                    ),



                    const SizedBox(height: 16),

                    // Group By dropdown
                    Container(
                      padding: const EdgeInsets.only(left: 14, right: 14, top: 5, bottom: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt_outlined, size: 20, color: Colors.black54),
                          const SizedBox(width: 10),
                          Text(
                            'Group by:',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedgroup,
                                icon: AnimatedRotation(
                                  turns: 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                ),
                                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                onChanged: (String? newValue) {
                                  setState(() => _selectedgroup = newValue);

                                  // Adjust logic below based on your screen context
                                  if (_selectedgroup == "Bills") {
                                    fetchBills(ledger, startDateString, endDateString, type, "vchno", "vchno",costcenter,item);
                                  } else if (_selectedgroup == "Voucher Type") {
                                    fetchVoucherType(ledger, startDateString, endDateString, type, "vchname", "vchname",costcenter,item);
                                  }
                                },

                                items: spinner_list.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
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
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  padding: const EdgeInsets.only(left: 0, right: 0, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      // Search Field
                      if (_isSearchViewVisible) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(14),
                            shadowColor: Colors.black12,
                            child: TextField(
                              controller: searchController,
                              onChanged: _handleSearchChange, // Your unified search logic here
                              style: GoogleFonts.poppins(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: app_color, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],

                      // No data found message
                      if (isVisibleNoDataFound)
                        Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No Records Found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),


                      const SizedBox(height: 8),

                      // List section
                      Expanded(
                        child: _buildListSection(), // Refactored list rendering below
                      ),
                    ],
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


  Widget _buildListSection() {

    if (_isBillsListVisible) {
      return ListView.builder(
        itemCount: filteredItems_Bills.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          final card = filteredItems_Bills[index];
          return _buildCard(
            title: card.vchno,
            subtitle: '${convertDateFormat(card.vchdate)}',
            amount: double.tryParse(card.amount.toString()) ?? 0.0,
          );
        },
      );
    }

    if (_isVoucherTypeListVisible) {
      return ListView.builder(
        itemCount: filteredItems_vouchertype.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          final card = filteredItems_vouchertype[index];
          return _buildCard(
            title: card.vchname,
            subtitle: 'Qty: ${card.qty}',
            amount: double.tryParse(card.amount.toString()) ?? 0.0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartyTotalClickedCostCenterItemsVchType(
                    startdate_string: startDateString,
                    enddate_string: endDateString,
                    type: type,
                    total: formatAmount(card.amount),
                    ledger: ledger,
                    vchname: card.vchname,
                    item: item,
                    costcenter: costcenter,
                  ),
                ),
              );
            },
          );
        },
      );
    }


    return const SizedBox.shrink(); // fallback
  }
  Widget _buildCard({
    required String title,
    required String subtitle,
    required double amount,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: app_color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),

            // Amount pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: app_color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: app_color, width: 0.8),
              ),
              child: Row(
                children: [
                  Text(
                    formatAmount(amount.toString()),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: app_color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black45),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _handleSearchChange(String value) {
    setState(() {
      if (value.isEmpty) {
        if (_selectedgroup == "Bills") {
          filteredItems_Bills = bills_list;
        } else if (_selectedgroup == "Voucher Type") {
          filteredItems_vouchertype = vouchertype_list;
        }
      } else {
        final query = value.toLowerCase();
        if (_selectedgroup == "Bills") {
          filteredItems_Bills = bills_list.where((item) {
            return item.vchno.toLowerCase().contains(query);
          }).toList();
        } else if (_selectedgroup == "Voucher Type") {
          filteredItems_vouchertype = vouchertype_list.where((item) {
            return item.vchname.toLowerCase().contains(query);
          }).toList();
        }
      }
    });
  }
}