import 'dart:convert';
import 'package:fincoremobile/currencyFormat.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Dashboard.dart';
import 'SerialSelect.dart';
import 'Sidebar.dart';
import 'TransactionClicked.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'constants.dart';
import 'package:cross_file/cross_file.dart';

class Sale_purc_cash {
  final String vchname;
  final String vchno;
  final double amount;
  final String vchdate;
  final String ledger;
  final String isoptional;
  final String ispostdated;
  final String refno;
  final String refdate;
  final String masterid;

  Sale_purc_cash({

    required this.vchname,
    required this.vchno,
    required this.amount,
    required this.vchdate,
    required this.ledger,
    required this.isoptional,
    required this.ispostdated,
    required this.refno,
    required this.refdate,
    required this.masterid,

  });



  factory Sale_purc_cash.fromJson(Map<String, dynamic> json) {
    return Sale_purc_cash(
      vchname: json['vchname'].toString(),
      vchno: json['vchno'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      vchdate: json['vchdate'].toString(),
      ledger: json['ledger'].toString(),
      isoptional: json['isoptional'].toString(),
      ispostdated: json['ispostdated'].toString(),
      refno: json['refno'].toString(),
      refdate: json['refdate'].toString(),
      masterid: json['masterid'].toString(),

    );
  }

 }

class Receivable_payable {

  final String ledger,billno,billdate,billtype,duedate;
  double outstanding;

  Receivable_payable({

    required this.ledger,
    required this.billno,
    required this.billdate,
    required this.billtype,
    required this.duedate,
    required this.outstanding,


  });

  factory Receivable_payable.fromJson(Map<String, dynamic> json) {
    return Receivable_payable(
      ledger: json['ledger'].toString(),
      billno: json['billno'].toString(),
      billdate: json['billdate'].toString(),
      billtype: json['billtype'].toString(),
      duedate: json['duedate'].toString(),
      outstanding: double.tryParse(json['outstanding'].toString()) ?? 0,
    );
  }
}

class DashboardClicked extends StatefulWidget {
  final String startdate_string,enddate_string,vchtypes;

  const DashboardClicked(
      {
        required this.startdate_string,
        required this.enddate_string,
        required this.vchtypes
      }
      );
  @override
  _DashboardClickedPageState createState() => _DashboardClickedPageState(startDateString: startdate_string,endDateString: enddate_string,vchtypes: vchtypes);
}

class _DashboardClickedPageState extends State<DashboardClicked> with TickerProviderStateMixin{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String startDateString = "",endDateString = "",vchtypes = "";

  String selectedSortOption = '',token = '';
  
  int counter = 0;

  bool _isVisibleduedate = false;

  List<Receivable_payable> filteredItems_receivable_payable = []; // Initialize an empty list to hold the filtered items
  List<Sale_purc_cash> filteredItems_sale_purc_cash = [];

  ScrollController _scrollController_salelist = ScrollController();
  ScrollController _scrollController_receivablellist = ScrollController();
  TextEditingController _voucherController = TextEditingController();

  _DashboardClickedPageState(
      {required this.startDateString,
        required this.endDateString,
        required this.vchtypes,}
      );

  String? SecuritybtnAcessHolder;
  bool isDashEnable = true,isRolesEnable = true,isUserEnable = true,isRolesVisible = true,
      isUserVisible = true,_isSearchViewVisible = false,_isSalesListVisible = false,_isOutstandingListVisible = false;

  String email = "";
  String name = "";

  String? opening_value = "0",openingheading = "";

  TextEditingController searchController = TextEditingController();

  bool isVisibleNoDataFound = false,_isopeningVisible = true;


  bool isSortVisible = false;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }
  void _showSelectionWindow(BuildContext context) {
    final List<IconData> icons = [
      Icons.sort_rounded,
      Icons.date_range_sharp,
      Icons.date_range_sharp,
      Icons.sort_by_alpha_rounded,
      Icons.sort_by_alpha_rounded,
      Icons.attach_money_outlined,
      Icons.attach_money_outlined,
    ];

    // Replace this list with your actual list data
    final List<String> itemList = ['Default', 'Newest to Oldest', 'Oldest to Newest', 'A->Z', 'Z->A', 'Amount High to Low', 'Amount Low to High'];

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
                          selectedSortOption = itemList[index]; // Update the selected index
                        });
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

  void sortByDefault() {
    setState(() {
      if(filteredItems_sale_purc_cash.isNotEmpty)
        {
          filteredItems_sale_purc_cash = List.from(sales_purc_cash_list);
          _scrollController_salelist.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      else if (filteredItems_receivable_payable.isNotEmpty)
        {
          filteredItems_receivable_payable = List.from(receivable_payable_list);
          _scrollController_receivablellist.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

    });
  }

  void sortByAlphabetAtoZ() {
    setState(() {
      if(filteredItems_sale_purc_cash.isNotEmpty)
        {
          if(vchtypes == 'Sales' || vchtypes == 'Purchase')
            {
              filteredItems_sale_purc_cash.sort((a, b) => a.vchname.compareTo(b.vchname));
              _scrollController_salelist.animateTo(
                0.0,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          else
            {
              filteredItems_sale_purc_cash.sort((a, b) => a.ledger.compareTo(b.ledger));
              _scrollController_salelist.animateTo(
                0.0,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }

        }
      else if (filteredItems_receivable_payable.isNotEmpty)
        {
          filteredItems_receivable_payable.sort((a, b) => a.ledger.compareTo(b.ledger));
          _scrollController_receivablellist.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
    });
  }

  void sortByAlphabetZtoA() {
    setState(() {
      if(filteredItems_sale_purc_cash.isNotEmpty)
      {
        if(vchtypes == 'Sales' || vchtypes == 'Purchase')
          {
            filteredItems_sale_purc_cash.sort((a, b) => b.vchname.compareTo(a.vchname));
            _scrollController_salelist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else
          {
            filteredItems_sale_purc_cash.sort((a, b) => b.ledger.compareTo(a.ledger));
            _scrollController_salelist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
          }
      else if (filteredItems_receivable_payable.isNotEmpty)
      {
        filteredItems_receivable_payable.sort((a, b) => b.ledger.compareTo(a.ledger));
        _scrollController_receivablellist.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void sortByDateLowtoHigh() {
    setState(() {
      if(filteredItems_sale_purc_cash.isNotEmpty)
      {
        filteredItems_sale_purc_cash.sort((a, b) => a.vchdate.compareTo(b.vchdate));
        _scrollController_salelist.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if (filteredItems_receivable_payable.isNotEmpty)
        {
          filteredItems_receivable_payable.sort((a, b) => formatDueDate_Sort(a.billdate,a.billtype,a.duedate).compareTo(formatDueDate_Sort(b.billdate,b.billtype,b.duedate)));
          _scrollController_receivablellist.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
    });
  }

  void sortByDateHightoLow() {
    setState(() {
      if(filteredItems_sale_purc_cash.isNotEmpty)
      {
        filteredItems_sale_purc_cash.sort((a, b) => b.vchdate.compareTo(a.vchdate));
        _scrollController_salelist.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      else if (filteredItems_receivable_payable.isNotEmpty)
      {
        filteredItems_receivable_payable.sort((a, b) => formatDueDate(b.billdate,b.billtype,b.duedate).compareTo(formatDueDate(a.billdate,a.billtype,a.duedate)));
        _scrollController_receivablellist.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void sortByAmountLowtoHigh() {
    setState(() {
      if(filteredItems_sale_purc_cash.isNotEmpty)
      {
        if(vchtypes == 'Payment')
          {
            filteredItems_sale_purc_cash.sort((a, b) => b.amount.compareTo(a.amount));
            _scrollController_salelist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else
          {
            filteredItems_sale_purc_cash.sort((a, b) => a.amount.compareTo(b.amount));
            _scrollController_salelist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }

      }
      else if (filteredItems_receivable_payable.isNotEmpty)
      {
        if(vchtypes == "Receivable")
          {
            filteredItems_receivable_payable.sort((a, b) => b.outstanding.compareTo(a.outstanding));
            _scrollController_receivablellist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else
          {
            filteredItems_receivable_payable.sort((a, b) => a.outstanding.compareTo(b.outstanding));
            _scrollController_receivablellist.animateTo(
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
      if(filteredItems_sale_purc_cash.isNotEmpty)
      {
        if(vchtypes == "Payment")
          {
            filteredItems_sale_purc_cash.sort((a, b) => a.amount.compareTo(b.amount));
            _scrollController_salelist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else
          {
            filteredItems_sale_purc_cash.sort((a, b) => b.amount.compareTo(a.amount));
            _scrollController_salelist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
      }
      else if (filteredItems_receivable_payable.isNotEmpty)
      {
        if(vchtypes == "Receivable")
          {
            filteredItems_receivable_payable.sort((a, b) => a.outstanding.compareTo(b.outstanding));
            _scrollController_receivablellist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        else
          {
            filteredItems_receivable_payable.sort((a, b) => b.outstanding.compareTo(a.outstanding));
            _scrollController_receivablellist.animateTo(
              0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }

      }
    });
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String allparties = 'All Parties',allvchtypes = 'All Voucher Types';

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  late SharedPreferences prefs;
  late String startdate_text = "", enddate_text = "";
  late DateTime _startDate ;
  late DateTime _endDate  ;
  String? datetype;

  late String? startdate_pref, enddate_pref;

  String HttpURL = "";

  String? hostname = "",company = "",serial_no = "",company_lowercase = "",username = "";
  List<dynamic> myData = [];
  bool _isLoading = false;

  String? HttpURL_sale_purc_cash,HttpURL_receipt_payment,HttpURL_receivable_payable ,HttpURL_sale_purc_cash_parent,
      HttpURL_receivable_payable_parent;

  dynamic _selectedvoucher = "";
  List<String> spinner_list = [];

  List<Sale_purc_cash> sales_purc_cash_list = [];
  List<Receivable_payable> receivable_payable_list = [];

  // csv of all
  Future<void> generateAndShareCSV_SalesList() async {
    final List<List<dynamic>> csvData = [];
    final headersRow = ['Vch No', 'Vch Name', 'Vch Date', 'Party Name', 'Amount'];
    csvData.add(headersRow);

    for (final item in sales_purc_cash_list) {
      final rowData = [
        item.vchno,
        item.vchname,
        convertDateFormat(item.vchdate),
        item.ledger,
        formatAmount(item.amount.toString()),
      ];
      csvData.add(rowData);
    }

    final csvString = const ListToCsvConverter().convert(csvData);

    // Save CSV to a temporary file
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/Vouchers.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    // ✅ Use ShareParams for new API
    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $vchtypes Summary Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }


  Future<void> generateAndShareCSV_Outstanding() async {
    final List<List<dynamic>> csvData = [];
    final headersRow = ['Bill No', 'Bill Type', 'Due Date', 'Party Name', 'Amount'];
    csvData.add(headersRow);

    for (final item in receivable_payable_list) {
      final rowData = [
        item.billno,
        item.billtype,
        formatDueDate(item.billdate, item.billtype, item.duedate),
        item.ledger,
        formatAmount(item.outstanding.toString()),
      ];
      csvData.add(rowData);
    }

    final csvString = const ListToCsvConverter().convert(csvData);

    // Save CSV to a temporary file
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/Outstanding.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    // ✅ Share CSV file using the latest SharePlus API
    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $vchtypes Summary Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  // pdf of all
  Future<void> generateAndSharePDF_SalesList() async {
    final pdf = pw.Document();

    final companyName = company!;
    final reportname = '$vchtypes Summary';
    final parentname = _selectedvoucher;

    final headersRow3 = ['Vch No', 'Vch Name', 'Vch Date', 'Party Name', 'Amount'];

    final itemsPerPage = 8; // Adjust this value as needed
    final pageCount = (sales_purc_cash_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex = (pageNumber + 1) * itemsPerPage;
      final itemsSubset = sales_purc_cash_list.sublist(
        startIndex,
        endIndex > sales_purc_cash_list.length ? sales_purc_cash_list.length : endIndex,
      );

      final tableSubsetRows = itemsSubset.map((item) {
        return [
          item.vchno,
          item.vchname,
          convertDateFormat(item.vchdate),
          item.ledger,
          formatAmount(item.amount.toString()),
        ];
      }).toList();

      final tableSubset = pw.Table.fromTextArray(
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(2),
          color: PdfColors.grey300,
        ),
        headerHeight: 30,
        cellAlignment: pw.Alignment.center,
        cellPadding: const pw.EdgeInsets.all(5),
        columnWidths: {
          0: const pw.FractionColumnWidth(0.4),
          1: const pw.FractionColumnWidth(0.4),
          2: const pw.FractionColumnWidth(0.4),
          3: const pw.FractionColumnWidth(0.4),
          4: const pw.FractionColumnWidth(0.4),
        },
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12, fontFallback: []),
        rowDecoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(width: 1),
            bottom: pw.BorderSide(width: 1),
          ),
        ),
        headers: headersRow3,
        data: tableSubsetRows,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text(reportname, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(convertDateFormat(startDateString), style: pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(width: 5),
                      pw.Text('to', style: pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(width: 5),
                      pw.Text(convertDateFormat(endDateString), style: pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Vch Name:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 5),
                      pw.Text(parentname, style: pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Expanded(child: tableSubset),
                ],
              ),
            );
          },
        ),
      );
    }

    final pdfData = await pdf.save();

    // Save the PDF to a temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/Vouchers.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    // ✅ Share using the latest SharePlus API
    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $vchtypes Summary Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  Future<void> generateAndSharePDF_Outstanding() async {
    final pdf = pw.Document();

    final companyName = company!;
    final reportname = '$vchtypes Summary';
    final parentname = _selectedvoucher;

    final headersRow3 = ['Bill No', 'Bill Type', 'Due Date', 'Party Name', 'Amount'];
    final itemsPerPage = 8;
    final pageCount = (receivable_payable_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex = (pageNumber + 1) * itemsPerPage;
      final itemsSubset = receivable_payable_list.sublist(
        startIndex,
        endIndex > receivable_payable_list.length ? receivable_payable_list.length : endIndex,
      );

      final tableSubsetRows = itemsSubset.map((item) {
        return [
          item.billno,
          item.billtype,
          formatDueDate(item.billdate, item.billtype, item.duedate),
          item.ledger,
          formatAmount(item.outstanding.toString()),
        ];
      }).toList();

      final tableSubset = pw.Table.fromTextArray(
        border: pw.TableBorder.all(width: 1),
        headerDecoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(2),
          color: PdfColors.grey300,
        ),
        headerHeight: 30,
        cellAlignment: pw.Alignment.center,
        cellPadding: const pw.EdgeInsets.all(5),
        columnWidths: {
          0: const pw.FractionColumnWidth(0.4),
          1: const pw.FractionColumnWidth(0.4),
          2: const pw.FractionColumnWidth(0.4),
          3: const pw.FractionColumnWidth(0.4),
          4: const pw.FractionColumnWidth(0.4),
        },
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
        rowDecoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(width: 1),
            bottom: pw.BorderSide(width: 1),
          ),
        ),
        headers: headersRow3,
        data: tableSubsetRows,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text(reportname, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(convertDateFormat(startDateString), style: const pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(width: 5),
                      pw.Text('to', style: const pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(width: 5),
                      pw.Text(convertDateFormat(endDateString), style: const pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Ledger:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 5),
                      pw.Text(parentname, style: const pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Expanded(child: tableSubset),
                ],
              ),
            );
          },
        ),
      );
    }

    final pdfData = await pdf.save();

    // Save the PDF to a temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/Outstanding.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    // ✅ Share using latest SharePlus API
    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing $vchtypes Summary Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  void fetchParentData() {
    if(vchtypes == "Sales" || vchtypes == "Purchase" || vchtypes == "Receipt" || vchtypes == "Payment" || vchtypes == "Cash")
    {

      if(vchtypes == "Sales" || vchtypes == "Purchase" || vchtypes == "Cash")
      {
        _isopeningVisible= true;
        if(vchtypes == "Sales")
        {
          fetchParent("sales,creditnote");
        }
        else if (vchtypes == "Purchase")
        {
          fetchParent("purchase,debitnote");
        }
        else if (vchtypes =="Cash")
        {
          fetchParent("");
        }

      }
      else if (vchtypes == "Receipt" || vchtypes == "Payment")
      {_isopeningVisible = false;
        fetchParent(vchtypes);
      }
      setState(() {
        _isSalesListVisible = true;
        _isOutstandingListVisible = false;
      });
    }
    else if(vchtypes == "Receivable" || vchtypes == "Payable")
    {
      if(vchtypes == "Receivable")
        {
          fetchParent_Receivable_Payable("ledger","true","true","true");

        }
      else if (vchtypes == "Payable")
        {
          fetchParent_Receivable_Payable("ledger","","true","true");

        }
      setState(() {
        _isSalesListVisible = false;
        _isOutstandingListVisible = true;
      });

    }
  }

  void fetchListData() {

    if(_selectedvoucher == "All Voucher Types")
    {
      if(vchtypes == "Sales" || vchtypes == "Purchase" || vchtypes == "Cash")
      {
        if(vchtypes == "Sales")
        {
          fetchSales_purchase_cash("Sales Accounts", startDateString, endDateString, "Sales,creditNote","true","");
        }
        else if (vchtypes == "Purchase")
        {
          fetchSales_purchase_cash("Purchase Accounts", startDateString, endDateString, "Purchase,debitnote","true","");
        }
        else if (vchtypes =="Cash")
        {
          fetchSales_purchase_cash("cash-in-hand,bank accounts", startDateString, endDateString, "","true","");
        }

      }
      else if (vchtypes == "Receipt" || vchtypes == "Payment")
      {
        fetchReceipt_Payment(startDateString,endDateString,vchtypes,"");
      }
      else if (vchtypes == "Receivable" || vchtypes == "Payable")
        {
          if(vchtypes == "Receivable")
            {
              fetchReceivable_payable("billno",startDateString,endDateString,"true","");

            }
          else if (vchtypes == "Payable")
            {
              fetchReceivable_payable("billno",startDateString,endDateString,"","");

            }
        }
    }
    else
    {
      if(_selectedvoucher == "All Parties" )
        {
          if(vchtypes == "Receivable")
          {
            fetchReceivable_payable("billdate",startDateString,endDateString,"true","");

          }
          else if (vchtypes == "Payable")
          {
            fetchReceivable_payable("billdate",startDateString,endDateString,"","");

          }
        }
      else
        {
          if(vchtypes == "Sales" || vchtypes == "Purchase" || vchtypes == "Cash")
          {
            if(vchtypes == "Sales")
            {
              fetchSales_purchase_cash("Sales Accounts", startDateString, endDateString, "Sales,creditNote","true",_selectedvoucher);
            }
            else if (vchtypes == "Purchase")
            {
              fetchSales_purchase_cash("Purchase Accounts", startDateString, endDateString, "Purchase,debitnote","true",_selectedvoucher);
            }
            else if (vchtypes =="Cash")
            {
              fetchSales_purchase_cash("cash-in-hand,bank accounts", startDateString, endDateString, "","true",_selectedvoucher);
            }

          }
          else if (vchtypes == "Receipt" || vchtypes == "Payment")
          {
            fetchReceipt_Payment(startDateString,endDateString,vchtypes,_selectedvoucher);
          }
          else if (vchtypes == "Receivable" || vchtypes == "Payable")
          {
            if(vchtypes == "Receivable")
            {
              fetchReceivable_payable("billdate",startDateString,endDateString,"true",_selectedvoucher);

            }
            else if (vchtypes == "Payable")
            {
              fetchReceivable_payable("billdate",startDateString,endDateString,"",_selectedvoucher);

            }
          }
        }
    }
  }

  Future<void> fetchParent(final String type) async {

    setState(() {
      _isLoading = true;
    });

    spinner_list.clear();

    try
    {
      final url = Uri.parse(HttpURL_sale_purc_cash_parent!);

      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'vchtypes': type,
        'orderby' : 'vchname'
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        if(vchtypes == "Receivable"|| vchtypes == "Payable")
          {
            spinner_list.add(allparties);
            _selectedvoucher = allparties;
          }
        else
          {
            spinner_list.add(allvchtypes);
            _selectedvoucher = allvchtypes;
          }
        List<dynamic> data = jsonDecode(response.body);
        for (var item in data)
        {
          String vchname = item['vchname'];
          spinner_list.add(vchname);
        }
        setState(()
        {
          _selectedvoucher = spinner_list[0];
          _voucherController.text = _selectedvoucher;
          fetchListData();
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
  }

  Future<void> fetchParent_Receivable_Payable(final String orderby,final String isdebit, final String select,final String parent) async {
    setState(() {
      _isLoading = true;
    });

    spinner_list.clear();

    try
    {
      final url = Uri.parse(HttpURL_receivable_payable_parent!);
      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'orderby': orderby,
        'isDebit': isdebit,
        'select': select,
        'parent': parent,
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        if(vchtypes == "Receivable"|| vchtypes == "Payable")
        {
          spinner_list.add(allparties);
          _selectedvoucher = allparties;
        }
        else
        {
          spinner_list.add(allvchtypes);
          _selectedvoucher = allvchtypes;
        }

        List<dynamic> data = jsonDecode(response.body);
        for (var item in data) {
          String ledger = item['ledger'];
          spinner_list.add(ledger);
        }
        setState(() {
          _selectedvoucher = spinner_list[0];
          _voucherController.text = _selectedvoucher;
          fetchListData();
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
  }

  Future<void> fetchSales_purchase_cash(final String ledgroup, final String startdate, final String enddate, final String vchtypes,final String opening,final String vchname) async {
    setState(()
    {
      _isLoading = true;
      isSortVisible = false;
    });

    sales_purc_cash_list.clear();
    filteredItems_sale_purc_cash.clear();

    receivable_payable_list.clear();
    filteredItems_receivable_payable.clear();

    try
    {
      final url = Uri.parse(HttpURL_sale_purc_cash!);

      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'ledgroup': ledgroup,
        'startdate': startdate,
        'enddate': enddate,
        'vchtypes': vchtypes,
        'opening': opening,
        'vchname' : vchname
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {

        Map<String, dynamic> data = jsonDecode(response.body);
        String opening = data['opening'].toString();
        setState(()
        {
          opening_value = formatOpening(opening);
        });

        String values = jsonEncode(data['values']);

        final List<dynamic> values_list = jsonDecode(values);
        if (values_list != null) {
          isVisibleNoDataFound = false;

          sales_purc_cash_list.addAll(values_list.map((json) => Sale_purc_cash.fromJson(json)).toList());
          filteredItems_sale_purc_cash = sales_purc_cash_list;

        } else
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
      if(sales_purc_cash_list.isEmpty)
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

  Future<void> fetchReceivable_payable(final String orderby, final String startdate, final String enddate, final String isdebit,final String ledger) async {
    setState(() {
      _isLoading = true;
      isSortVisible = false;
    });

    receivable_payable_list.clear();
    filteredItems_receivable_payable.clear();

    sales_purc_cash_list.clear();
    filteredItems_sale_purc_cash.clear();

    try
    {
      final url = Uri.parse(HttpURL_receivable_payable!);
      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode({
        'orderby': orderby,
        'startdate': startdate,
        'enddate': enddate,
        'isDebit': isdebit,
        'ledger': ledger,
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        print(response.body);

        Map<String, dynamic> data = jsonDecode(response.body);
        String opening = data['opening'].toString();
        setState(() {
          opening_value = formatOpening(opening);
        });
        String values = jsonEncode(data['values']);

        final List<dynamic> values_list = jsonDecode(values);
        if (values_list != null) {
          isVisibleNoDataFound = false;

          receivable_payable_list.addAll(values_list.map((json) => Receivable_payable.fromJson(json)).toList());

          filteredItems_receivable_payable = receivable_payable_list;
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
      if(receivable_payable_list.isEmpty)
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

  Future<void> fetchReceipt_Payment(final String startdate, final String enddate, final String vchtypes,final String vchname) async {


    setState(() {
      _isLoading = true;
      isSortVisible = false;


    });

    sales_purc_cash_list.clear();
    filteredItems_sale_purc_cash.clear();
    receivable_payable_list.clear();
    filteredItems_receivable_payable.clear();

    try
    {

      final url = Uri.parse(HttpURL_receipt_payment!);

      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'startdate': startdate,
        'enddate': enddate,
        'vchtypes': vchtypes,
        'vchname' : vchname
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

          sales_purc_cash_list.addAll(values_list.map((json) => Sale_purc_cash.fromJson(json)).toList());
          filteredItems_sale_purc_cash = sales_purc_cash_list;

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
      if(sales_purc_cash_list.isEmpty)
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

  String formatDueDate(String billdate,String type, String duedate) {
    String formattedDate = '';

    if(type == 'On Account')
      {
            _isVisibleduedate = false;
      }
    else if (type == 'Advance')
      {
          _isVisibleduedate = false;
      }
    else if (type == 'Agst Ref' || type == 'New Ref')
      {
          _isVisibleduedate = true;

        if(duedate == 'null')
          {
            formattedDate = 'N/A';
          }
        else
          {
            try
            {
              if(duedate.contains("Days"))
              {
                String pattern = r'(\d+)';
                RegExp regex = RegExp(pattern);
                Match? match = regex.firstMatch(duedate);

                if (match != null) {
                  String numberString = match.group(0)!;
                  int nodays = int.parse(numberString);

                  DateTime billdate_date = DateTime.parse(billdate);
                  DateTime futureDate = billdate_date.add(Duration(days: nodays));

                  formattedDate = DateFormat('dd-MMM-yy').format(futureDate);
                }
              }
              else
                {
                  // Parse the input date string
                  DateTime date = DateTime.parse(duedate);
                  // Format the date to the desired output format
                  formattedDate = DateFormat("dd-MMM-yy").format(date);
                }
            }
            catch (e)
            {
              formattedDate = duedate;
              print(e);
            }
          }
      }
    return formattedDate;
  }

  DateTime formatDueDate_Sort(String billdate,String type, String duedate) {
    DateTime formattedDate = DateTime.now() ;

    if(type == 'On Account')
    {
      _isVisibleduedate = false;
    }
    else if (type == 'Advance')
    {
      _isVisibleduedate = false;
    }
    else if (type == 'Agst Ref' || type == 'New Ref')
    {
      _isVisibleduedate = true;

      if(duedate == 'null')
      {

        formattedDate = DateTime.now();
      }
      else
      {
        try
        {
          if(duedate.contains("Days"))
          {
            String pattern = r'(\d+)';
            RegExp regex = RegExp(pattern);
            Match? match = regex.firstMatch(duedate);

            if (match != null) {
              String numberString = match.group(0)!;
              int nodays = int.parse(numberString);

              DateTime billdate_date = DateTime.parse(billdate);
              formattedDate = billdate_date.add(Duration(days: nodays));

            }
          }
          else
          {
            // Parse the input date string
            formattedDate = DateTime.parse(duedate);
            // Format the date to the desired output format
          }
        }
        catch (e)
        {
          formattedDate = DateTime.parse(duedate);
          print(e);
        }
      }
    }

    return formattedDate;
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

    HttpURL_sale_purc_cash_parent = '$hostname/api/voucher/getvoucherNames/$company_lowercase/$serial_no';
    HttpURL_receivable_payable_parent = '$hostname/api/ledger/getOutstandingList/$company_lowercase/$serial_no';

    HttpURL_sale_purc_cash = '$hostname/api/ledger/getTotal/$company_lowercase/$serial_no';
    HttpURL_receipt_payment = '$hostname/api/voucher/getVouchers/$company_lowercase/$serial_no';
    HttpURL_receivable_payable = '$hostname/api/ledger/getOutstandingOpening/$company_lowercase/$serial_no';
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

    startdate_pref = startDateString;
    enddate_pref = endDateString;

    _startDate = DateTime.parse(startdate_pref!);
    _endDate = DateTime.parse(enddate_pref!);

    DateTime start = _startDate;
    DateTime end = _endDate;


    String startMonth = DateFormat('MMM').format(start);
    String startDay = DateFormat('dd').format(start);
    int startYear = start.year;

    String endMonth = DateFormat('MMM').format(end);
    String endDay = DateFormat('dd').format(end);
    int endYear = end.year;

    startdate_text = startDay + "-" + startMonth + "-" + startYear.toString();
    enddate_text = endDay + "-" + endMonth  + "-" + endYear.toString();

    fetchParentData();

    if (vchtypes == "Cash" || vchtypes == "Receivable" || vchtypes == "Payable")
    {
      setState(() {
        openingheading = 'OnAccount';

      });
    }
    else
    {
      setState(() {
        openingheading = 'Opening';

      });    }

  }

  Future<void> _selectDateRange(BuildContext context) async {

        final initialDateRange = DateTimeRange(start: _startDate, end: _endDate);
        String? startfrom = prefs.getString('startfrom');
        DateTime earliestDate = DateTime.parse(startfrom!);

        DateTimeRange? selectedDateRange = await showDateRangePicker(
          context: context,
          initialDateRange: initialDateRange,
          firstDate: earliestDate,
          lastDate: DateTime(2100),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light().copyWith(
                  primary: app_color,
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedDateRange != null) {
          setState(() {
            _startDate = selectedDateRange.start;
            _endDate = selectedDateRange.end;

            DateTime start = _startDate;
            DateTime end = _endDate;


            String startMonth = DateFormat('MMM').format(start);
            String sdf = DateFormat('MM').format(start); // converting month into string
            String startDay = DateFormat('dd').format(start);
            int startYear = start.year;

            String endMonth = DateFormat('MMM').format(end);
            String sdfEnd = DateFormat('MM').format(end);
            String endDay = DateFormat('dd').format(end);
            int endYear = end.year;

            startDateString = '$startYear$sdf$startDay';
            endDateString = '$endYear$sdfEnd$endDay';

            startdate_text = startDay + "-" + startMonth + "-" + startYear.toString();
            enddate_text = endDay + "-" + endMonth  + "-" + endYear.toString();

            fetchListData();


            /*fetchDashData(startDateString,endDateString);*/

          });
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
      appBar:PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          backgroundColor:  app_color,
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
                    overflow: TextOverflow.visible,

                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                counter++;
                setState(() {
                  _isSearchViewVisible = counter % 2 != 0;
                  if(!_isSearchViewVisible)
                  {
                    searchController.clear();
                    if (vchtypes == "Receivable" || vchtypes == "Payable") {
                      filteredItems_receivable_payable = receivable_payable_list;
                    } else {
                      filteredItems_sale_purc_cash = sales_purc_cash_list;
                    }
                  }
                });
              },
              icon: Icon(Icons.search, color: Colors.white, size: 26),
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
                  items: [
                    PopupMenuItem<String>(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (_isSalesListVisible && sales_purc_cash_list.isNotEmpty) {
                            generateAndSharePDF_SalesList();
                          } else if (_isOutstandingListVisible && receivable_payable_list.isNotEmpty) {
                            generateAndSharePDF_Outstanding();
                          } else {
                            showToast('Data Not Found');
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 16, color: app_color),
                            SizedBox(width: 6),
                            Text('Share as PDF', style: GoogleFonts.poppins(fontSize: 16, color: app_color)),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (_isSalesListVisible && sales_purc_cash_list.isNotEmpty) {
                            generateAndShareCSV_SalesList();
                          } else if (_isOutstandingListVisible && receivable_payable_list.isNotEmpty) {
                            generateAndShareCSV_Outstanding();
                          } else {
                            showToast('Data Not Found');
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.add_chart_outlined, size: 16, color: app_color),
                            SizedBox(width: 6),
                            Text('Share as CSV', style: GoogleFonts.poppins(fontSize: 16, color: app_color)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              icon: Icon(Icons.share, color: Colors.white, size: 26),
            ),
            SizedBox(width:5)
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

      body:WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Dashboard()),
          );
          return true;
        },
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 16,right:16, top: 10,bottom:10),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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

                  Container(
                  margin: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TypeAheadField<String>(
          controller: _voucherController,
          suggestionsCallback: (pattern) {
            return spinner_list
                .where((item) => item.toLowerCase().contains(pattern.toLowerCase()))
                .toList();
          },

          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_voucherController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _voucherController.clear();
                            _selectedvoucher = spinner_list.first;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black87),
                  ],
                ),
                prefixIcon: Icon(Icons.receipt_long_outlined, color: app_color),
              ),
            );
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: Icon(Icons.receipt_long_outlined, color: app_color),
              title: Text(
                suggestion,
                  style: GoogleFonts.poppins( // 👈 Apply Poppins style to menu items
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  )
              ),
            );
          },
          onSelected: (suggestion) {
            setState(() {
              _selectedvoucher = suggestion;
              _voucherController.text = suggestion;
              fetchListData();
            });
          },
          emptyBuilder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "No voucher found",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        )


                  ),

         SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        margin: EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: GestureDetector(
                          onTap: () => _selectDateRange(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 18, color: Colors.teal.shade600),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '$startdate_text  ➜  $enddate_text',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              SizedBox(width: 8),

                              Icon(Icons.calendar_month_outlined, size: 18, color: Colors.teal.shade600),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16,right:16, bottom: 12),
                    padding: EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_isopeningVisible)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12,left:10,right:10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    openingheading ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    opening_value ?? '',
                                    textAlign: TextAlign.right,
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

                        if (_isSearchViewVisible)

                          Padding( padding:  EdgeInsets.only(left: 12,right:12, top:5,bottom:10),
                            child:  Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(14),
                              shadowColor: Colors.black12,
                              child: TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  if (value.isEmpty) {
                                    setState(() {
                                      if (vchtypes == "Receivable" || vchtypes == "Payable") {
                                        filteredItems_receivable_payable = receivable_payable_list;
                                      } else {
                                        filteredItems_sale_purc_cash = sales_purc_cash_list;
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      final query = value.toLowerCase();
                                      if (vchtypes == "Receivable" || vchtypes == "Payable") {
                                        filteredItems_receivable_payable = receivable_payable_list
                                            .where((item) => item.ledger.toLowerCase().contains(query))
                                            .toList();
                                      } else {
                                        filteredItems_sale_purc_cash = sales_purc_cash_list
                                            .where((item) => item.ledger.toLowerCase().contains(query))
                                            .toList();
                                      }
                                    });
                                  }
                                },

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
                          ),






                        if (isVisibleNoDataFound)
                          Center(
                            child: Column(
                              children: [
                                SizedBox(height: 20),
                                Icon(Icons.inbox_rounded, size: 40, color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  "No records found",
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),

                        if (_isSalesListVisible)
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController_salelist,
                              itemCount: filteredItems_sale_purc_cash.length,
                              itemBuilder: (context, index) {
                                final card = filteredItems_sale_purc_cash[index];
                                return buildModernVoucherCard(card);
                              },
                            ),
                          ),

                        if (_isOutstandingListVisible)
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController_receivablellist,
                              itemCount: filteredItems_receivable_payable.length,
                              itemBuilder: (context, index) {
                                final card = filteredItems_receivable_payable[index];
                                return buildReceivableCard(card);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),


              ],
            ),

            Visibility(
              visible: isSortVisible,
              child: Padding(padding: EdgeInsets.only(bottom: 50),
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 85,
                    height: 35,
                    child:
                    FloatingActionButton.extended(
                      onPressed: () => _showSelectionWindow(context),
                      backgroundColor: app_color, // 🔹 Center filled with your app theme color
                      elevation: 8, // 🔹 Strong elevation for floating effect
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      label: Row(
                        children: [
                          Icon(Icons.sort, color: Colors.white, size: 20), // white icon
                          const SizedBox(width: 6),
                          Text(
                            "Sort",
                            style: GoogleFonts.poppins(
                              color: Colors.white, // white text for contrast
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )

                    ,)
              ),
            ),),

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
      ),


    );

  }
  Widget buildModernVoucherCard(Sale_purc_cash card) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: app_color.withOpacity(0.1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionsClicked(
                vchtype: card.vchname,
                startdate: startDateString,
                enddate: endDateString,
                vchno: card.vchno,
                vchdate: card.vchdate,
                ispostdated: card.ispostdated,
                isoptional: card.isoptional,
                refno: card.refno,
                refdate: card.refdate,
                masterid: card.masterid,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade200.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 Ledger + Gradient Icon
                Row(

                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade400, Colors.indigo.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        card.ledger,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),

                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 20, color: Colors.grey.shade600),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 14),

                /// 🔹 Voucher No
                _modernDetailRow(Icons.receipt_long_outlined, "Voucher No",
                    card.vchno.isNotEmpty ? card.vchno : "-"),

                /// 🔹 Voucher Name
                _modernDetailRow(Icons.bookmark_border, "Voucher Name",
                    card.vchname.isNotEmpty ? card.vchname : "-"),

                /// 🔹 Date
                _modernDetailRow(Icons.calendar_today_outlined, "Date",
                    convertDateFormat(card.vchdate)),

                /// 🔹 Amount
                _modernDetailRow(Icons.payments_outlined, "Amount",
                    formatAmount(card.amount.toString())),

                /// 🔹 Tags
                if (card.ispostdated == "1" || card.isoptional == "1") ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (card.ispostdated == "1")
                        _buildTag("Post Dated", Colors.orange),
                      if (card.isoptional == "1")
                        _buildTag("Optional", Colors.blue),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Detail row (Voucher info with gradient icon)
  Widget _modernDetailRow(IconData icon, String title, String value) {
    LinearGradient getGradient(String title) {
      if (title.contains("Voucher No")) {
        return LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]);
      } else if (title.contains("Voucher Name")) {
        return LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700]);
      } else if (title.contains("Date")) {
        return LinearGradient(colors: [Colors.blueGrey.shade400, Colors.blueGrey.shade700]);
      } else if (title.contains("Amount")) {
        return LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]);
      }
      return LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade400.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),

      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: getGradient(title),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right, // ✅ text inside also right aligned

                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Tag chip
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.7),
        ),
      ),
    );
  }


// 🔹 Receivable/Payable Card
  Widget buildReceivableCard(Receivable_payable card) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: app_color.withOpacity(0.08),
        onTap: () {
          // 👉 Navigation ya detail view logic yahan rakhna
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Ledger Row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        card.ledger,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 12),

                // 🔹 Bill No row (Blue)
                _modernDetailRowReceivable(Icons.confirmation_number_outlined, "Bill No",
                    card.billno != "null" ? card.billno : "-",
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                    )),

                // 🔹 Bill Type row (Purple)
                _modernDetailRowReceivable(Icons.description_outlined, "Bill Type",
                    card.billtype != "null" ? card.billtype : "-",
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade700],
                    )),


                // 🔹 Due Date (conditional, dynamic color)
                if (_isVisibleduedate &&
                    (card.billtype == 'Agst Ref' || card.billtype == 'New Ref'))
                  _modernDetailRowReceivable(Icons.calendar_today_rounded, "Due Date",
                      formatDueDate(card.billdate, card.billtype, card.duedate),
                      gradient: LinearGradient(
                        colors: [
                          getDueDateColor(
                              formatDueDate(card.billdate, card.billtype, card.duedate),
                              vchtypes)
                              .withOpacity(0.7),
                          getDueDateColor(
                              formatDueDate(card.billdate, card.billtype, card.duedate),
                              vchtypes)
                              .withOpacity(0.9),
                        ],
                      )),

                // 🔹 Outstanding Amount (Receivable = Green / Payable = Red)
                _modernDetailRowReceivable(Icons.payments_rounded, "Outstanding",
                    "${formatAmount(card.outstanding.toString())}",
                    gradient: LinearGradient(
                      colors: [
                        getAmountColor(vchtypes).withOpacity(0.7),
                        getAmountColor(vchtypes).withOpacity(0.9),

                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Modern detail row (reusable)
  Widget _modernDetailRowReceivable(IconData icon, String title, String value,
      {required LinearGradient gradient}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade400.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right, // ✅ text inside also right aligned

                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
Color getDueDateColor(String dueDateStr, String type) {
  try {
    final due = DateFormat("dd-MMM-yy").parse(dueDateStr);
    final now = DateTime.now();
    final diffDays = due.difference(now).inDays;

    if (due.isBefore(now)) return Colors.red;

    if (diffDays <= 7) {
      return type == "Receivable" ? Colors.orange : Colors.deepOrange;
    }

    return type == "Receivable" ? Colors.green : Colors.teal;
  } catch (_) {
    return Colors.grey.shade600;
  }
}
Color getAmountColor(String type) {
  switch (type) {
    case 'Receivable':
      return Colors.green.shade700;
    case 'Payable':
      return Colors.red.shade700;
    default:
      return Colors.blueGrey;
  }
}




