import 'dart:convert';
import 'package:FincoreGo/ItemsTotalClickedLedger.dart';
import 'package:FincoreGo/currencyFormat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ItemsTotalClickedCostCenter.dart';
import 'ItemsTotalClickedVchType.dart';
import 'SerialSelect.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'constants.dart';

class Ledger {

  final String Partyledger;
  final String qty;
  final double amount;

  Ledger({

    required this.Partyledger,
    required this.qty,
    required this.amount,

  });

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      Partyledger: json['Partyledger'].toString(),
      qty: json['qty'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
    );
  }
}

class Bills{
  final String vchno,Partyledger,vchdate;
  final double amount;

  Bills({
    required this.vchno,
    required this.Partyledger,
    required this.vchdate,
    required this.amount,
  });

  factory Bills.fromJson(Map<String, dynamic> json)
  {
    return Bills(
      vchno: json['vchno'].toString(),
      Partyledger: json['Partyledger'].toString(),
      vchdate: json['vchdate'].toString(),
      amount:  double.tryParse(json['amount'].toString()) ?? 0,
    );
  }
}

class Costcenter{

  final String costcentre,qty;
  final double amount;

  Costcenter({
    required this.costcentre,
    required this.qty,
    required this.amount,
  });

  factory Costcenter.fromJson(Map<String, dynamic> json) {
    return Costcenter(
      costcentre: json['costcentre'].toString(),
      qty: json['qty'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
    );
  }
}

class Vouchertype{

  final String vchname,qty;
  final double amount;

  Vouchertype({
    required this.vchname,
    required this.qty,
    required this.amount,
  });

  factory Vouchertype.fromJson(Map<String, dynamic> json) {
    return Vouchertype(
      vchname: json['vchname'].toString(),
      qty: json['qty'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
    );
  }
}

class ItemsTotalClicked extends StatefulWidget
{
  final String startdate_string,enddate_string,type,item_name,total;

  const ItemsTotalClicked(
      {
        required this.startdate_string,
        required this.enddate_string,
        required this.type,
        required this.item_name,
        required this.total
      }
      );
  @override
  _ItemsTotalClickedPageState createState() => _ItemsTotalClickedPageState(startDateString: startdate_string,
      endDateString: enddate_string,type: type,total: total,item_name:  item_name);
}

class _ItemsTotalClickedPageState extends State<ItemsTotalClicked> with TickerProviderStateMixin{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String startDateString = "",endDateString = "",type = "",item_name = "",total = "";

  int counter = 0;

  List<Bills> filteredItems_Bills = []; // Initialize an empty list to hold the filtered items
  List<Ledger> filteredItems_ledger = []; // Initialize an empty list to hold the filtered items
  List<Vouchertype> filteredItems_vouchertype = []; // Initialize an empty list to hold the filtered items
  List<Costcenter> filteredItems_costcenter = [];

  ScrollController _scrollController_ledger = ScrollController(),
      _scrollController_bills= ScrollController(),
      _scrollController_vchtype= ScrollController(),
      _scrollController_costcenter= ScrollController();

  bool isSortVisible = false,showDateSort = false;// Initialize an empty list to hold the filtered items

  _ItemsTotalClickedPageState(
      {
        required this.startDateString,
        required this.endDateString,
        required this.type,
        required this.item_name,
        required this.total
      }
      );

  String? SecuritybtnAcessHolder;
  bool isDashEnable = true,isRolesEnable = true,isUserEnable = true,isRolesVisible = true,
      isUserVisible = true,_isSearchViewVisible = false,_isLedgerListVisible = false,_isBillsListVisible = false,
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

  String HttpURL = "",token = '';

  String selectedSortOption = '';

  String? hostname = "",company = "",serial_no = "",company_lowercase = "",username = "";
  List<dynamic> myData = [];
  bool _isLoading = false;

  dynamic _selectedgroup = "Ledger";
  List<String> spinner_list = [
    'Ledger','Bills', 'Voucher Type','Cost Center'];

  List<Ledger> ledger_list = [];
  List<Bills> bills_list = [];
  List<Vouchertype> vouchertype_list = [];
  List<Costcenter> costcenter_list = [];

  void sortByDefault() {
    setState(() {
      if(filteredItems_ledger.isNotEmpty) {
        filteredItems_ledger = List.from(ledger_list);
        _scrollController_ledger.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_Bills.isNotEmpty) {
        filteredItems_Bills = List.from(bills_list);
        _scrollController_bills.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_vouchertype.isNotEmpty) {
        filteredItems_vouchertype = List.from(vouchertype_list);
        _scrollController_vchtype.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_costcenter.isNotEmpty) {
        filteredItems_costcenter = List.from(costcenter_list);
        _scrollController_costcenter.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void sortByAlphabetAtoZ() {
    setState(() {
      if(filteredItems_ledger.isNotEmpty)
      {
        filteredItems_ledger.sort((a, b) => a.Partyledger.compareTo(b.Partyledger));
        _scrollController_ledger.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_Bills.isNotEmpty)
      {
        filteredItems_Bills.sort((a, b) => a.Partyledger.compareTo(b.Partyledger));
        _scrollController_bills.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_vouchertype.isNotEmpty)
      {
        filteredItems_vouchertype.sort((a, b) => a.vchname.compareTo(b.vchname));
        _scrollController_vchtype.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_costcenter.isNotEmpty)
      {
        filteredItems_costcenter.sort((a, b) => a.costcentre.compareTo(b.costcentre));
        _scrollController_costcenter.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void sortByAlphabetZtoA() {
    setState(() {
      if(filteredItems_ledger.isNotEmpty)
      {
        filteredItems_ledger.sort((a, b) => b.Partyledger.compareTo(a.Partyledger));
        _scrollController_ledger.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_Bills.isNotEmpty)
      {
        filteredItems_Bills.sort((a, b) => b.Partyledger.compareTo(a.Partyledger));
        _scrollController_bills.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_vouchertype.isNotEmpty)
      {
        filteredItems_vouchertype.sort((a, b) => b.vchname.compareTo(a.vchname));
        _scrollController_vchtype.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if(filteredItems_costcenter.isNotEmpty)
      {
        filteredItems_costcenter.sort((a, b) => b.costcentre.compareTo(a.costcentre));
        _scrollController_costcenter.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void sortByDateLowtoHigh() {
    setState(() {
      if(filteredItems_Bills.isNotEmpty)
      {
        setState(() {
          showDateSort = true;
        });
        filteredItems_Bills.sort((a, b) => a.vchdate.compareTo(b.vchdate));
        _scrollController_bills.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void sortByDateHightoLow() {
    setState(() {
      if(filteredItems_Bills.isNotEmpty)
      {
        setState(() {
          showDateSort = true;
        });
        filteredItems_Bills.sort((a, b) => b.vchdate.compareTo(a.vchdate));
        _scrollController_bills.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void sortByAmountLowtoHigh() {
    setState(() {
      if(filteredItems_ledger.isNotEmpty)
      {
        if(type == 'Sales')
          {
            filteredItems_ledger.sort((a, b) => a.amount.compareTo(b.amount));
            _scrollController_ledger.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else if (type == 'Purchase')
          {
            filteredItems_ledger.sort((a, b) => b.amount.compareTo(a.amount));
            _scrollController_ledger.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }

      }
      else if(filteredItems_Bills.isNotEmpty)
      {
        if(type == 'Sales')
        {
          filteredItems_Bills.sort((a, b) => a.amount.compareTo(b.amount));
          _scrollController_bills.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        else if (type == 'Purchase')
        {
          filteredItems_Bills.sort((a, b) => b.amount.compareTo(a.amount));
          _scrollController_bills.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

      }
      else if(filteredItems_vouchertype.isNotEmpty)
      {
        if(type == 'Sales')
        {
          filteredItems_vouchertype.sort((a, b) => a.amount.compareTo(b.amount));
          _scrollController_vchtype.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        else if (type == 'Purchase')
        {
          filteredItems_vouchertype.sort((a, b) => b.amount.compareTo(a.amount));
        _scrollController_vchtype.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        }
      }
      else if(filteredItems_costcenter.isNotEmpty)
      {
        if(type == 'Sales')
        {
          filteredItems_costcenter.sort((a, b) => a.amount.compareTo(b.amount));
          _scrollController_costcenter.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        else if (type == 'Purchase')
        {
          filteredItems_costcenter.sort((a, b) => b.amount.compareTo(a.amount));
          _scrollController_costcenter.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void sortByAmountHightoLow() {
    setState(() {
      if(filteredItems_ledger.isNotEmpty)
      {
        if(type == 'Sales')
          {
            filteredItems_ledger.sort((a, b) => b.amount.compareTo(a.amount));
            _scrollController_ledger.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else if (type == 'Purchase')
          {
            filteredItems_ledger.sort((a, b) => a.amount.compareTo(b.amount));
            _scrollController_ledger.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }

      }
      else if(filteredItems_Bills.isNotEmpty)
      {
        if(type == 'Sales')
          {
            filteredItems_Bills.sort((a, b) => b.amount.compareTo(a.amount));
            _scrollController_bills.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else if (type == 'Purchase')
          {
            filteredItems_Bills.sort((a, b) => a.amount.compareTo(b.amount));
            _scrollController_bills.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }

      }
      else if(filteredItems_vouchertype.isNotEmpty)
      {
        if(type == 'Sales')
          {
            filteredItems_vouchertype.sort((a, b) => b.amount.compareTo(a.amount));
            _scrollController_vchtype.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else if (type == 'Purchase')
          {
            filteredItems_vouchertype.sort((a, b) => a.amount.compareTo(b.amount));
            _scrollController_vchtype.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }

      }
      else if(filteredItems_costcenter.isNotEmpty)
      {
        if(type == 'Sales')
          {
            filteredItems_costcenter.sort((a, b) => b.amount.compareTo(a.amount));
            _scrollController_costcenter.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else if (type == 'Purchase')
          {
            filteredItems_costcenter.sort((a, b) => a.amount.compareTo(b.amount));
            _scrollController_costcenter.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }

      }
    });
  }

  void _showSelectionWindow(BuildContext context) {
    final List<IconData> icons = [
      Icons.sort_rounded,
      if(showDateSort) Icons.date_range_sharp,
      if (showDateSort) Icons.date_range_sharp,
      Icons.sort_by_alpha_rounded,
      Icons.sort_by_alpha_rounded,
      Icons.attach_money_outlined,
      Icons.attach_money_outlined,
    ];

    // Replace this list with your actual list data
    final List<String> itemList = ['Default', if(showDateSort) 'Newest to Oldest', if(showDateSort) 'Oldest to Newest', 'A->Z', 'Z->A', 'Amount High to Low', 'Amount Low to High'];

    double totalHeight = itemList.length * 50.0 + 30.0 + 50.0; // Assuming each item has a height of 50 and adding padding height

    showModalBottomSheet<void>(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: totalHeight, // Set the maximum height of the selection window with additional padding
          ),
          color: Colors.white, // Set the background color of the selection window
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sort', // Replace with your desired heading text
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded( // Wrap the ListView.builder with Expanded
                child: ListView.builder(
                  itemCount: itemList.length,
                  itemExtent: 50, // Set the height of each item in the list
                  itemBuilder: (BuildContext context, int index) {
                    // Replace this with your custom tile widget
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSortOption = itemList[index]; // Update the selected value
                        });
                        // Now, you can use a switch or if-else statement to check the selected value
                        switch (selectedSortOption) {
                          case 'Default':
                            sortByDefault(); // Call the sorting function
                            break;
                          case 'Newest to Oldest':
                            sortByDateHightoLow(); // Call the sorting function
                            break;
                          case 'Oldest to Newest':
                            sortByDateLowtoHigh(); // Call the sorting function
                            break;
                          case 'A->Z':
                            sortByAlphabetAtoZ(); // Call the sorting function
                            break;
                          case 'Z->A':
                            sortByAlphabetZtoA(); // Call the sorting function
                            break;
                          case 'Amount High to Low':
                            sortByAmountHightoLow(); // Call the sorting function
                            break;
                          case 'Amount Low to High':
                            sortByAmountLowtoHigh(); // Call the sorting function
                            break;
                        }
                        print('Tile $index selected');
                        Navigator.pop(context); // Close the selection window after a tile is selected
                      },
                      child: Container(
                        child: ListTile(
                          leading: Icon(icons[index]), // Add the icon to each list tile
                          title: Text(
                            itemList[index],
                            style: GoogleFonts.poppins(
                              fontWeight: itemList[index] == selectedSortOption ? FontWeight.bold : FontWeight.normal, // Apply bold style to the text if the tile is selected
                            ),
                          ),
                          trailing: itemList[index] == selectedSortOption ? Icon(Icons.check,
                            color: app_color,) : null, // Show arrow icon if the tile is selected
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> generateAndSharePDF_Ledger() async {
    final font = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans.ttf"));
    final pdf = pw.Document();
    final companyName = company!;
    final parentname = _selectedgroup;
    final reportname = '$parentname Wise $type Summary';
    final itemname = item_name;

    final headersRow3 = ['Party Name', 'Qty', 'Amount'];
    final itemsPerPage = 8;
    final pageCount = (ledger_list.length / itemsPerPage).ceil();

    for (int i = 0; i < pageCount; i++) {
      final start = i * itemsPerPage;
      final end = (i + 1) * itemsPerPage;
      final subset = ledger_list.sublist(start, end > ledger_list.length ? ledger_list.length : end);

      final rows = subset.map((item) => [
        item.Partyledger,
        item.qty,
        formatAmount(item.amount.toString()),
      ]).toList();

      final table = pw.Table.fromTextArray(
        headers: headersRow3,
        data: rows,
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font), // ✅ Use your font
        cellStyle: pw.TextStyle(fontSize: 12, font: font), // ✅ Use your font here too
      );

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(reportname, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(convertDateFormat(startDateString)),
                  pw.SizedBox(width: 5),
                  pw.Text('to'),
                  pw.SizedBox(width: 5),
                  pw.Text(convertDateFormat(endDateString)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Stock Item:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 5),
                  pw.Text(itemname),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(child: table),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/${type}_Report.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  Future<void> generateAndSharePDF_Bills() async {
    final font = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans.ttf"));
    final pdf = pw.Document();
    final companyName = company!;
    final parentname = _selectedgroup;
    final reportname = '$parentname Wise $type Summary';
    final itemname = item_name;

    final headers = ['Vch Date', 'Vch No', 'Party Name', 'Amount'];
    final perPage = 8;
    final totalPages = (bills_list.length / perPage).ceil();

    for (int i = 0; i < totalPages; i++) {
      final start = i * perPage;
      final end = (i + 1) * perPage;
      final subset = bills_list.sublist(start, end > bills_list.length ? bills_list.length : end);

      final rows = subset.map((e) => [
        convertDateFormat(e.vchdate),
        e.vchno,
        e.Partyledger,
        formatAmount(e.amount.toString())
      ]).toList();

      final table = pw.Table.fromTextArray(
        headers: headers,
        data: rows,
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font), // ✅ Use your font
        cellStyle: pw.TextStyle(fontSize: 12, font: font), // ✅ Use your font here too
      );

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(reportname, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(convertDateFormat(startDateString)),
                  pw.SizedBox(width: 5),
                  pw.Text('to'),
                  pw.SizedBox(width: 5),
                  pw.Text(convertDateFormat(endDateString)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Stock Item:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 5),
                  pw.Text(itemname),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(child: table),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${type}_Report.pdf';
    final file = File(path);
    await file.writeAsBytes(pdfData);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(path)],
      ),
    );
  }

  Future<void> generateAndSharePDF_VchType() async {
    final font = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans.ttf"));
    final pdf = pw.Document();
    final companyName = company!;
    final parentname = _selectedgroup;
    final reportname = '$parentname Wise $type Summary';
    final itemname = item_name;

    final headers = ['Vch Name', 'Qty', 'Amount'];
    final perPage = 8;
    final totalPages = (vouchertype_list.length / perPage).ceil();

    for (int i = 0; i < totalPages; i++) {
      final start = i * perPage;
      final end = (i + 1) * perPage;
      final subset = vouchertype_list.sublist(start, end > vouchertype_list.length ? vouchertype_list.length : end);

      final rows = subset.map((e) => [e.vchname, e.qty, formatAmount(e.amount.toString())]).toList();

      final table = pw.Table.fromTextArray(
        headers: headers,
        data: rows,
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font), // ✅ Use your font
        cellStyle: pw.TextStyle(fontSize: 12, font: font), // ✅ Use your font here too
      );

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(reportname, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(convertDateFormat(startDateString)),
                  pw.SizedBox(width: 5),
                  pw.Text('to'),
                  pw.SizedBox(width: 5),
                  pw.Text(convertDateFormat(endDateString)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Stock Item: $itemname', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Expanded(child: table),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${type}_Report.pdf';
    await File(path).writeAsBytes(pdfData);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(path)],
      ),
    );
  }

  Future<void> generateAndSharePDF_CostCenter() async {
    final font = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans.ttf"));
    final pdf = pw.Document();
    final companyName = company!;
    final parentname = _selectedgroup;
    final reportname = '$parentname Wise $type Summary';
    final itemname = item_name;

    final headers = ['Cost Center', 'Qty', 'Amount'];
    final perPage = 8;
    final totalPages = (costcenter_list.length / perPage).ceil();

    for (int i = 0; i < totalPages; i++) {
      final start = i * perPage;
      final end = (i + 1) * perPage;
      final subset = costcenter_list.sublist(start, end > costcenter_list.length ? costcenter_list.length : end);

      final rows = subset.map((e) => [
        formatCostCenter(e.costcentre),
        e.qty,
        formatAmount(e.amount.toString())
      ]).toList();

      final table = pw.Table.fromTextArray(
        headers: headers,
        data: rows,
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
        cellStyle: pw.TextStyle(fontSize: 12, font: font),
      );

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(reportname, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(convertDateFormat(startDateString)),
                  pw.SizedBox(width: 5),
                  pw.Text('to'),
                  pw.SizedBox(width: 5),
                  pw.Text(convertDateFormat(endDateString)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Stock Item: $itemname', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Expanded(child: table),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${type}_Report.pdf';
    await File(path).writeAsBytes(pdfData);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(path)],
      ),
    );
  }


  Future<void> generateAndShareCSV_Ledger() async {
    final parentname = _selectedgroup;
    final csvData = [
      ['Party Name', 'Qty', 'Amount'],
      ...ledger_list.map((item) => [item.Partyledger, item.qty, formatAmount(item.amount.toString())])
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await Directory.systemTemp.createTemp();
    final path = '${dir.path}/${type}_Report.pdf';
    await File(path).writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(path)],
      ),
    );
  }

  Future<void> generateAndShareCSV_Bills() async {
    final parentname = _selectedgroup;
    final csvData = [
      ['Vch Date', 'Vch No', 'Party Name', 'Amount'],
      ...bills_list.map((e) => [
        convertDateFormat(e.vchdate),
        e.vchno,
        e.Partyledger,
        formatAmount(e.amount.toString())
      ])
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await Directory.systemTemp.createTemp();
    final path = '${dir.path}/${type}_Report.pdf';
    await File(path).writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(path)],
      ),
    );
  }

  Future<void> generateAndShareCSV_VchType() async {
    final parentname = _selectedgroup;
    final csvData = [
      ['Vch Name', 'Qty', 'Amount'],
      ...vouchertype_list.map((e) => [e.vchname, e.qty, formatAmount(e.amount.toString())])
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await Directory.systemTemp.createTemp();
    final path = '${dir.path}/${type}_Report.pdf';
    await File(path).writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(path)],
      ),
    );
  }

  Future<void> generateAndShareCSV_CostCenter() async {
    final parentname = _selectedgroup;
    final csvData = [
      ['Cost Center', 'Qty', 'Amount'],
      ...costcenter_list.map((e) => [formatCostCenter(e.costcentre), e.qty, formatAmount(e.amount.toString())])
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await Directory.systemTemp.createTemp();
    final path = '${dir.path}/${type}_Report.pdf';
    await File(path).writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $parentname wise $type Report of $company',
        files: [XFile(path)],
      ),
    );
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
    String formattedDate = DateFormat("dd-MMM-yyyy").format(date);

    return formattedDate;
  }

  Future<void> fetchBills(final String item,final String startdate, final String enddate, final String vchtype, final String groupby,final String orderby) async
  {


    setState(() {
      _isLoading = true;
      _isBillsListVisible = true;
      _isLedgerListVisible = false;
      _isVoucherTypeListVisible = false;
      _isCostCenterListVisible = false;
      showDateSort = true;


      if(prefs.getString('sort') == null)
        {
          selectedSortOption = 'Default';
        }
      else if(prefs.getString('sort') == 'Newest to Oldest' )
      {
        selectedSortOption = 'Newest to Oldest';
      }
      else if (prefs.getString('sort') == 'Oldest to Newest')
      {
        selectedSortOption = 'Oldest to Newest';
      }
    });

    bills_list.clear();
    filteredItems_Bills.clear();

    ledger_list.clear();
    filteredItems_ledger.clear();

    vouchertype_list.clear();
    filteredItems_vouchertype.clear();

    costcenter_list.clear();
    filteredItems_costcenter.clear();

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
        'item': item,
        'vchtype' : vchtype,
        'groupby' : groupby,
        'orderby' : orderby
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

        }
        else
        {
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
        isSortVisible = false;

      }
      else
        {
          isSortVisible = true;
          switch (selectedSortOption) {
            case 'Default':
              sortByDefault(); // Call the sorting function
              break;
            case 'Newest to Oldest':
              sortByDateHightoLow(); // Call the sorting function
              break;
            case 'Oldest to Newest':
              sortByDateLowtoHigh(); // Call the sorting function
              break;
            case 'A->Z':
              sortByAlphabetAtoZ(); // Call the sorting function
              break;
            case 'Z->A':
              sortByAlphabetZtoA(); // Call the sorting function
              break;
            case 'Amount High to Low':
              sortByAmountHightoLow(); // Call the sorting function
              break;
            case 'Amount Low to High':
              sortByAmountLowtoHigh(); // Call the sorting function
              break;
          }
        }
      _isLoading = false;
    });

  }

  Future<void> fetchLedger(final String item,final String startdate, final String enddate, final String vchtype, final String groupby,final String orderby) async
  {

    setState(() {
      _isLoading = true;
      _isBillsListVisible = false;
      _isLedgerListVisible = true;
      _isVoucherTypeListVisible = false;
      _isCostCenterListVisible = false;
      showDateSort = false;

      if(prefs.getString('sort') == null || prefs.getString('sort') == 'Newest to Oldest' || prefs.getString('sort') == 'Oldest to Newest' )
      {
        selectedSortOption = 'Default';
      }
    });

    bills_list.clear();
    filteredItems_Bills.clear();

    ledger_list.clear();
    filteredItems_ledger.clear();

    vouchertype_list.clear();
    filteredItems_vouchertype.clear();

    costcenter_list.clear();
    filteredItems_costcenter.clear();

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
        'item': item,
        'vchtype' : vchtype,
        'groupby' : groupby,
        'orderby' : orderby
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

          ledger_list.addAll(values_list.map((json) => Ledger.fromJson(json)).toList());
          filteredItems_ledger = ledger_list;

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
      if(ledger_list.isEmpty)
      {
        isVisibleNoDataFound = true;
        isSortVisible = false;

      }
      else
        {
          isSortVisible = true;
          switch (selectedSortOption) {
            case 'Default':
              sortByDefault(); // Call the sorting function
              break;
            case 'Newest to Oldest':
              sortByDateHightoLow(); // Call the sorting function
              break;
            case 'Oldest to Newest':
              sortByDateLowtoHigh(); // Call the sorting function
              break;
            case 'A->Z':
              sortByAlphabetAtoZ(); // Call the sorting function
              break;
            case 'Z->A':
              sortByAlphabetZtoA(); // Call the sorting function
              break;
            case 'Amount High to Low':
              sortByAmountHightoLow(); // Call the sorting function
              break;
            case 'Amount Low to High':
              sortByAmountLowtoHigh(); // Call the sorting function
              break;
          }
        }

      _isLoading = false;
    });

  }

  Future<void> fetchVoucherType(final String item,final String startdate, final String enddate, final String vchtype, final String groupby,final String orderby) async
  {
    setState(() {
      _isLoading = true;
      _isBillsListVisible = false;
      _isLedgerListVisible = false;
      _isVoucherTypeListVisible = true;
      _isCostCenterListVisible = false;
      showDateSort = false;

      if(prefs.getString('sort') == null || prefs.getString('sort') == 'Newest to Oldest' || prefs.getString('sort') == 'Oldest to Newest' )
      {
        selectedSortOption = 'Default';
      }


    });

    bills_list.clear();
    filteredItems_Bills.clear();

    ledger_list.clear();
    filteredItems_ledger.clear();

    vouchertype_list.clear();
    filteredItems_vouchertype.clear();


    costcenter_list.clear();
    filteredItems_costcenter.clear();



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
        'item': item,
        'vchtype' : vchtype,
        'groupby' : groupby,
        'orderby' : orderby
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
        isSortVisible = false;

      }
      else
      {
        isSortVisible = true;
        switch (selectedSortOption) {
          case 'Default':
            sortByDefault(); // Call the sorting function
            break;
          case 'Newest to Oldest':
            sortByDateHightoLow(); // Call the sorting function
            break;
          case 'Oldest to Newest':
            sortByDateLowtoHigh(); // Call the sorting function
            break;
          case 'A->Z':
            sortByAlphabetAtoZ(); // Call the sorting function
            break;
          case 'Z->A':
            sortByAlphabetZtoA(); // Call the sorting function
            break;
          case 'Amount High to Low':
            sortByAmountHightoLow(); // Call the sorting function
            break;
          case 'Amount Low to High':
            sortByAmountLowtoHigh(); // Call the sorting function
            break;
        }
      }
      _isLoading = false;
    });

  }

  Future<void> fetchCostCenter(final String item,final String startdate, final String enddate, final String vchtype, final String groupby,final String orderby) async
  {
    setState(() {
      _isLoading = true;
      _isBillsListVisible = false;
      _isLedgerListVisible = false;
      _isVoucherTypeListVisible = false;
      _isCostCenterListVisible = true;
      showDateSort = false;
      if(prefs.getString('sort') == null || prefs.getString('sort') == 'Newest to Oldest' || prefs.getString('sort') == 'Oldest to Newest' )
      {
        selectedSortOption = 'Default';
      }
    });

    bills_list.clear();
    filteredItems_Bills.clear();

    ledger_list.clear();
    filteredItems_ledger.clear();

    vouchertype_list.clear();
    filteredItems_vouchertype.clear();


    costcenter_list.clear();
    filteredItems_costcenter.clear();


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
        'item': item,
        'vchtype' : vchtype,
        'groupby' : groupby,
        'orderby' : orderby
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

          costcenter_list.addAll(values_list.map((json) => Costcenter.fromJson(json)).toList());
          filteredItems_costcenter = costcenter_list;

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
      if(costcenter_list.isEmpty)
      {
        isVisibleNoDataFound = true;
        isSortVisible = false;

      }
      else
      {
        isSortVisible = true;
        switch (selectedSortOption) {
          case 'Default':
            sortByDefault(); // Call the sorting function
            break;
          case 'Newest to Oldest':
            sortByDateHightoLow(); // Call the sorting function
            break;
          case 'Oldest to Newest':
            sortByDateLowtoHigh(); // Call the sorting function
            break;
          case 'A->Z':
            sortByAlphabetAtoZ(); // Call the sorting function
            break;
          case 'Z->A':
            sortByAlphabetZtoA(); // Call the sorting function
            break;
          case 'Amount High to Low':
            sortByAmountHightoLow(); // Call the sorting function
            break;
          case 'Amount Low to High':
            sortByAmountLowtoHigh(); // Call the sorting function
            break;
        }
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
    try
    {
      selectedSortOption = prefs.getString('sort')!;
      if(selectedSortOption == null || selectedSortOption == 'null')
      {
        selectedSortOption = 'Default';
      }
    }
    catch (e)
    {
      selectedSortOption = 'Default';
    }


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

    if(_selectedgroup == "Ledger")
      {
        fetchLedger(item_name,startDateString,endDateString,type,"Partyledger","Partyledger");

      }
    else if (_selectedgroup == "Bills")
      {
        fetchBills(item_name,startDateString,endDateString,type,"vchno","vchno");

      }
    else if (_selectedgroup == "Voucher Type")
    {
      fetchVoucherType(item_name,startDateString,endDateString,type,"vchname","vchname");

    }
    else if (_selectedgroup == "Cost Center")
    {
      fetchCostCenter(item_name,startDateString,endDateString,type,"costcentre","costcentre");

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
                item_name,
                style:  GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.visible,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                counter++;
                setState(() {
                  _isSearchViewVisible =!_isSearchViewVisible;

                  if(!_isSearchViewVisible)
                    {
                      searchController.clear();
                      if (_selectedgroup == "Ledger") {
                        filteredItems_ledger = ledger_list;
                      } else if (_selectedgroup == "Bills") {
                        filteredItems_Bills = bills_list;
                      } else if (_selectedgroup == "Voucher Type") {
                        filteredItems_vouchertype = vouchertype_list;
                      } else if (_selectedgroup == "Cost Center") {
                        filteredItems_costcenter = costcenter_list;
                      }
                    }

                });
              },
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
            ),
            IconButton(
              onPressed: () {
                final RenderBox button = context.findRenderObject() as RenderBox;
                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    overlay.size.width - buttonPosition.dx,
                    buttonPosition.dy - button.size.height,
                    overlay.size.width - buttonPosition.dx,
                    buttonPosition.dy,
                  ),
                  items: <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (_selectedgroup == "Ledger" && ledger_list.isNotEmpty) {
                            generateAndSharePDF_Ledger();
                          } else if (_selectedgroup == "Bills" && bills_list.isNotEmpty) {
                            generateAndSharePDF_Bills();
                          } else if (_selectedgroup == "Voucher Type" && vouchertype_list.isNotEmpty) {
                            generateAndSharePDF_VchType();
                          } else if (_selectedgroup == "Cost Center" && costcenter_list.isNotEmpty) {
                            generateAndSharePDF_CostCenter();
                          }
                        },
                        child: Row(children:  [
                          Icon(Icons.picture_as_pdf, size: 16, color: app_color),
                          SizedBox(width: 5),
                          Text(
                            'Share as PDF',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.normal,
                              color: app_color,
                              fontSize: 16,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    PopupMenuItem<String>(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (_selectedgroup == "Ledger" && ledger_list.isNotEmpty) {
                            generateAndShareCSV_Ledger();
                          } else if (_selectedgroup == "Bills" && bills_list.isNotEmpty) {
                            generateAndShareCSV_Bills();
                          } else if (_selectedgroup == "Voucher Type" && vouchertype_list.isNotEmpty) {
                            generateAndShareCSV_VchType();
                          } else if (_selectedgroup == "Cost Center" && costcenter_list.isNotEmpty) {
                            generateAndShareCSV_CostCenter();
                          }
                        },
                        child: Row(children:  [
                          Icon(Icons.add_chart_outlined, size: 16, color: app_color),
                          SizedBox(width: 5),
                          Text(
                            'Share as CSV',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.normal,
                              color: app_color,
                              fontSize: 16,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
              icon: const Icon(Icons.share, color: Colors.white, size: 28),
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
        tickerProvider: this,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Group & Summary Section
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
                    Center(
                      child: Text(
                        widget.total,
                        style:  GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child:  Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            SizedBox(width: 10),
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.only(left: 14,right:14, top: 5,bottom:5),
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
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedgroup,
                                icon: AnimatedRotation(
                                  turns: 0,
                                  duration:  Duration(milliseconds: 300),
                                  child:  Icon(Icons.arrow_drop_down, color: Colors.black),
                                ),
                                style:  GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                onChanged: (String? newValue) {
                                  setState(() => _selectedgroup = newValue);
                                  switch (_selectedgroup) {
                                    case "Ledger":
                                      fetchLedger(item_name, startDateString, endDateString, type, "Partyledger", "Partyledger");
                                      break;
                                    case "Bills":
                                      fetchBills(item_name, startDateString, endDateString, type, "vchno", "vchno");
                                      break;
                                    case "Voucher Type":
                                      fetchVoucherType(item_name, startDateString, endDateString, type, "vchname", "vchname");
                                      break;
                                    case "Cost Center":
                                      fetchCostCenter(item_name, startDateString, endDateString, type, "costcentre", "costcentre");
                                      break;
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
                  margin: const EdgeInsets.only(left: 16,right:16, bottom: 16),
                  padding: const EdgeInsets.only(left:0,right:0,top:4,bottom:4),
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

                      if(_isSearchViewVisible)...[

                        Padding( padding:  EdgeInsets.only(left: 12,right:12, top:12 ),
                            child:  Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(14),
                              shadowColor: Colors.black12,

                              child: TextField(
                                controller: searchController,
                                onChanged: _handleSearchChange,
                                style:  GoogleFonts.poppins(fontSize: 15),
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

                      Expanded(
                        child: _buildListSection(),
                      ),
                    ],
                  ),
                ),
              ),



            ],
          ),

          // Loading Spinner
          if (_isLoading)
            const Center(child: CircularProgressIndicator.adaptive()),

          // Sort FAB
          if (isSortVisible)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showSelectionWindow(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [app_color, app_color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color:  app_color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sort',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),




          // No Data Message
          if (isVisibleNoDataFound)
             Center(
              child: Text(
                'No data found',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  void _handleSearchChange(String value) {
    setState(() {
      final query = value.toLowerCase();


      if (value.isEmpty) {
        if (_selectedgroup == "Ledger") {
          filteredItems_ledger = ledger_list;
        } else if (_selectedgroup == "Bills") {
          filteredItems_Bills = bills_list;
        } else if (_selectedgroup == "Voucher Type") {
          filteredItems_vouchertype = vouchertype_list;
        } else if (_selectedgroup == "Cost Center") {
          filteredItems_costcenter = costcenter_list;
        }
      } else {
        if (_selectedgroup == "Ledger") {
          filteredItems_ledger = ledger_list
              .where((item) => item.Partyledger.toLowerCase().contains(query))
              .toList();
        } else if (_selectedgroup == "Bills") {
          filteredItems_Bills = bills_list
              .where((item) => item.vchno.toLowerCase().contains(query))
              .toList();
        } else if (_selectedgroup == "Voucher Type") {
          filteredItems_vouchertype = vouchertype_list
              .where((item) => item.vchname.toLowerCase().contains(query))
              .toList();
        } else if (_selectedgroup == "Cost Center") {
          filteredItems_costcenter = costcenter_list
              .where((item) => item.costcentre.toLowerCase().contains(query))
              .toList();
        }
      }
    });
  }

  Widget _buildListSection() {
    if (_isLedgerListVisible) {
      return ListView.builder(
        controller: _scrollController_ledger,
        itemCount: filteredItems_ledger.length,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        itemBuilder: (context, index) {
          final item = filteredItems_ledger[index];
          return _buildCard(
            title: item.Partyledger,
            amount: item.amount,
            qty: item.qty,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemsTotalClickedLedger(
                    startdate_string: startDateString,
                    enddate_string: endDateString,
                    type: type,
                    total: formatAmount(item.amount.toString()),
                    item_name: item_name,
                    ledgername: item.Partyledger,
                  ),
                ),
              );
            },

          );
        },
      );
    }

    if (_isBillsListVisible) {
      return ListView.builder(
        controller: _scrollController_bills,
        itemCount: filteredItems_Bills.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          final item = filteredItems_Bills[index];
          return _buildCard(
            title: item.vchno,
            subtitle: '${item.Partyledger}',
            date: item.vchdate,
            amount: item.amount,
          );
        },
      );
    }

    if (_isVoucherTypeListVisible) {
      return ListView.builder(
        controller: _scrollController_vchtype,
        itemCount: filteredItems_vouchertype.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          final item = filteredItems_vouchertype[index];
          return _buildCard(
            title: item.vchname,
            qty: item.qty,
            amount: item.amount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemsTotalClickedVchType(
                    startdate_string: startDateString,
                    enddate_string: endDateString,
                    type: type,
                    total: formatAmount(item.amount.toString()),
                    item_name: item_name,
                    vchname: item.vchname,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    if (_isCostCenterListVisible) {
      return ListView.builder(
        controller: _scrollController_costcenter,
        itemCount: filteredItems_costcenter.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          final item = filteredItems_costcenter[index];
          return _buildCard(
            title: formatCostCenter(item.costcentre),
            qty: item.qty,
            amount: item.amount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemsTotalClickedCostCenter(
                    startdate_string: startDateString,
                    enddate_string: endDateString,
                    type: type,
                    total: formatAmount(item.amount.toString()),
                    item_name: item_name,
                    costcenter: item.costcentre,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return const SizedBox.shrink(); // Fallback
  }

  Widget _buildCard({
    required String title,
    String? subtitle,
    required double amount,
    String? date, // for Bills
    String? qty,  // for Ledger/VchType/CostCenter
    VoidCallback? onTap,
  }) {
    IconData leadingIcon;
    String? topRightLabel;

    if (_isLedgerListVisible) {
      leadingIcon = Icons.account_balance_wallet_rounded;
      topRightLabel = qty != null ? "Qty: $qty" : null;
    } else if (_isBillsListVisible) {
      leadingIcon = Icons.receipt_long_rounded;
      topRightLabel =
      (date != null && date.isNotEmpty) ? convertDateFormat(date) : null;
    } else if (_isVoucherTypeListVisible) {
      leadingIcon = Icons.assignment_outlined;
      topRightLabel = qty != null ? "Qty: $qty" : null;
    } else {
      leadingIcon = Icons.business_center_rounded;
      topRightLabel = qty != null ? "Qty: $qty" : null;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Title row with badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gradient icon
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        app_color.withOpacity(0.9),
                        app_color.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: app_color.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    leadingIcon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Text and badge column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + qty/date badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title (wraps)
                          Expanded(
                            child: Text(
                              title,
                              softWrap: true,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (topRightLabel != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isBillsListVisible
                                      ? [
                                    Colors.orangeAccent.withOpacity(0.9),
                                    Colors.deepOrangeAccent.withOpacity(0.8)
                                  ]
                                      : [
                                    Colors.orangeAccent.withOpacity(0.9),
                                    Colors.deepOrangeAccent.withOpacity(0.8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                topRightLabel,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Subtitle (wraps if present)
                      if (subtitle != null)
                        Text(
                          subtitle,
                          softWrap: true,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ Amount + chevron (no overlap, fully visible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4A5568).withOpacity(0.15),
                              Color(0xFF4A5568).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(0xFF4A5568).withOpacity(0.2), width: 1),
                        ),
                        child: Text(
                          formatAmount(amount.toString()),
                          softWrap: true,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A5568).withOpacity(0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.chevron_right_rounded,
                        color: Colors.black45, size: 22),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }






}