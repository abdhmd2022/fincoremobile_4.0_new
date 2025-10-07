import 'dart:convert';
import 'package:fincoremobile/Constants.dart';
import 'package:fincoremobile/Items.dart';
import 'package:fincoremobile/currencyFormat.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class Data {

  final String vchno;
  final String vchdate;
  final String rate;
  final String qty;

  Data({
    required this.vchno,
    required this.vchdate,
    required this.rate,
    required this.qty,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      vchno : json['vchno'].toString(),
      vchdate: json['vchdate'].toString(),
      rate: json['rate'].toString(),
      qty: json['qty'].toString(),

    );
  }
}

class PartyClickedSoldPurchaseClicked extends StatefulWidget
{
  final String startdate_string,enddate_string,type,ledger,item,unit;

  const PartyClickedSoldPurchaseClicked(
      {required this.startdate_string,
        required this.enddate_string,
        required this.type,
        required this.ledger,
        required this.item,
        required this.unit,
      }
      );
  @override
  _PartyClickedSoldPurchaseClickedPageState createState() => _PartyClickedSoldPurchaseClickedPageState(startDateString: startdate_string,
      endDateString: enddate_string,type: type,item: item,ledger:  ledger,unit:unit);
}

class _PartyClickedSoldPurchaseClickedPageState extends State<PartyClickedSoldPurchaseClicked> with TickerProviderStateMixin{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String startDateString = "",endDateString = "",type = "",ledger = "",item = "",unit="";

  int counter = 0;
  double total_double  = 0;

  String total_main = "0",token = '';

  bool isSortVisible = false;

  String selectedSortOption = '';



  List<Data> filteredItems = []; // Initialize an empty list to hold the filtered items

  _PartyClickedSoldPurchaseClickedPageState(
      {required this.startDateString,
        required this.endDateString,
        required this.type,
        required this.ledger,
        required this.item,
        required this.unit,
      }
      );

  String? SecuritybtnAcessHolder;
  bool isDashEnable = true,isRolesEnable = true,isUserEnable = true,isRolesVisible = true,
      isUserVisible = true,_isSearchViewVisible = false,_isListVisible = false,_isBillsListVisible = false,
      _isVoucherTypeListVisible = false, _isCostCenterListVisible = false,isVisiblePostDated = true,isVisibleOptional = true;

  String email = "";
  String name = "";

   ScrollController _scrollController= ScrollController();

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


  List<Data> item_list = [];

  final List<String> itemList = ['Default', 'Newest to Oldest', 'Oldest to Newest', 'A->Z', 'Z->A'];

  void sortByDefault() {
    setState(() {
      if(filteredItems.isNotEmpty) {
        filteredItems = List.from(item_list);
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void sortByAlphabetAtoZ() {
    setState(() {
      if(filteredItems.isNotEmpty)
      {
        filteredItems.sort((a, b) => a.vchno.compareTo(b.vchno));
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }


    });
  }

  void sortByAlphabetZtoA() {
    setState(() {
      if(filteredItems.isNotEmpty)
      {
        filteredItems.sort((a, b) => b.vchno.compareTo(a.vchno));
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void sortByDateLowtoHigh() {
    setState(() {
      if(filteredItems.isNotEmpty)
      {
        filteredItems.sort((a, b) => a.vchdate.compareTo(b.vchdate));
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void sortByDateHightoLow() {
    setState(() {
      if(filteredItems.isNotEmpty)
      {
        filteredItems.sort((a, b) => b.vchdate.compareTo(a.vchdate));
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

    });
  }

  void _showSelectionWindow(BuildContext context) {
    final List<IconData> icons = [
      Icons.sort_rounded,
      Icons.date_range_sharp,
      Icons.date_range_sharp,
      Icons.sort_by_alpha_rounded,
      Icons.sort_by_alpha_rounded,
    ];

    // Replace this list with your actual list data


    double totalHeight = itemList.length * 50.0 + 30.0 + 50.0; // Assuming each item has a height of 50 and adding padding height

    showModalBottomSheet<void>(
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

  Future<void> generateAndSharePDF_Sold() async {
    final pdf = pw.Document();

    final companyName = company!;
    final reportname = 'Party Wise Sales Summary';
    final ledgername = ledger;
    final item_name = item;

    final headersRow3 = ['Vch No', 'Last Date', 'Qty', 'Rate'];

    final itemsPerPage = 10;
    final pageCount = (item_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex =
      (pageNumber + 1) * itemsPerPage > item_list.length ? item_list.length : (pageNumber + 1) * itemsPerPage;
      final itemsSubset = item_list.sublist(startIndex, endIndex);

      final tableSubsetRows = itemsSubset.map((item) {
        return [
          item.vchno,
          convertDateFormat(item.vchdate),
          item.qty,
          item.rate
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
        cellPadding: pw.EdgeInsets.all(5),
        columnWidths: {
          0: pw.FractionColumnWidth(0.4),
          1: pw.FractionColumnWidth(0.4),
          2: pw.FractionColumnWidth(0.4),
          3: pw.FractionColumnWidth(0.4),
        },
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
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
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Ledger:',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 5),
                      pw.Text(ledgername, style: pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Item:',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 5),
                      pw.Text(item_name, style: pw.TextStyle(fontSize: 16)),
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
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/SoldReport.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    // ✅ Updated sharing method
    await Share.shareXFiles(
      [XFile(tempFilePath)],
      text: 'Sharing $reportname Report of $company',
    );
  }

  Future<void> generateAndSharePDF_Purchase() async {
    final pdf = pw.Document();

    final companyName = company!;
    final reportname = 'Party Wise Purchase Summary';
    final ledgername = ledger;
    final item_name = item;

    final headersRow3 = ['Vch No', 'Last Date', 'Qty', 'Rate'];

    final itemsPerPage = 10;
    final pageCount = (item_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex =
      (pageNumber + 1) * itemsPerPage > item_list.length ? item_list.length : (pageNumber + 1) * itemsPerPage;
      final itemsSubset = item_list.sublist(startIndex, endIndex);

      final tableSubsetRows = itemsSubset.map((item) {
        return [
          item.vchno,
          convertDateFormat(item.vchdate),
          item.qty,
          item.rate
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
        cellPadding: pw.EdgeInsets.all(5),
        columnWidths: {
          0: pw.FractionColumnWidth(0.4),
          1: pw.FractionColumnWidth(0.4),
          2: pw.FractionColumnWidth(0.4),
          3: pw.FractionColumnWidth(0.4),
        },
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
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
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Ledger:',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 5),
                      pw.Text(ledgername, style: pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Item:',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 5),
                      pw.Text(item_name, style: pw.TextStyle(fontSize: 16)),
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
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/PurchaseReport.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    // ✅ Updated sharing method
    await Share.shareXFiles(
      [XFile(tempFilePath)],
      text: 'Sharing $reportname Report of $company',
    );
  }

  Future<void> generateAndShareCSV_Sold() async {
    final List<List<dynamic>> csvData = [];
    final reportname = 'Party Wise Sales Summary';
    final headersRow = ['Vch No', 'Last Date', 'Qty', 'Rate'];
    csvData.add(headersRow);

    for (final item in item_list) {
      final rowData = [
        item.vchno,
        convertDateFormat(item.vchdate),
        item.qty,
        item.rate
      ];
      csvData.add(rowData);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/SoldReport.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    // ✅ Updated sharing method
    await Share.shareXFiles(
      [XFile(tempFilePath)],
      text: 'Sharing $reportname Report of $company',
    );
  }

  Future<void> generateAndShareCSV_Purchased() async {
    final List<List<dynamic>> csvData = [];
    final reportname = 'Party Wise Purchase Summary';
    final headersRow = ['Vch No', 'Last Date', 'Qty', 'Rate'];
    csvData.add(headersRow);

    for (final item in item_list) {
      final rowData = [
        item.vchno,
        convertDateFormat(item.vchdate),
        item.qty,
        item.rate
      ];
      csvData.add(rowData);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/PurchaseReport.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    // ✅ Updated sharing method
    await Share.shareXFiles(
      [XFile(tempFilePath)],
      text: 'Sharing $reportname Report of $company',
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


  String formatVchNo(String vchno) {

    if(vchno == "null")
    {
      vchno = "No Voucher No.";
    }

    return vchno;
  }

  String convertDateFormat(String dateStr) {
    // Parse the input date string
    DateTime date = DateTime.parse(dateStr);

    // Format the date to the desired output format
    String formattedDate = DateFormat("dd-MMM-yy").format(date);

    return formattedDate;
  }

  Future<void> fetchData(final String item, final String ledger, final String startdate, final String enddate, final String type,final String select,final String orderby) async
  {

    setState(() {
      _isLoading = true;
      _isListVisible = true;
      isSortVisible = false;
    });

    item_list.clear();
    filteredItems.clear();

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
        'vchtype' : type,
        'select' : select,
        'orderby' : orderby,
        'item' : item,
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        print(type);
        final List<dynamic> values_list = jsonDecode(response.body);
        if (values_list != null) {
          isVisibleNoDataFound = false;

          item_list.addAll(values_list.map((json) => Data.fromJson(json)).toList());
          filteredItems = item_list;

        }
        else {

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
      if(item_list.isEmpty)
      {
        isVisibleNoDataFound = true;
        isSortVisible = false;

      }
      else {
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

      if(!itemList.contains(selectedSortOption))
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

    fetchData(item, ledger,startDateString,endDateString,type,"true","vchno");
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
      appBar:   PreferredSize(
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
          centerTitle: true,
          title:


          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                  child:  Text(
                    ledger,
                    style:  GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),


                  ),
              ),
            ],
          ),

          actions: [
            IconButton(
              onPressed: () {
                counter++;
                setState(() {
                  _isSearchViewVisible =! _isSearchViewVisible;
                });
                searchController.clear();
                filteredItems = item_list;
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
                            if(type == 'Sales')
                            {
                              if(!item_list.isEmpty)
                              {
                                generateAndSharePDF_Sold();
                              }
                            }
                            else if (type == 'Purchase')
                            {
                              if(!item_list.isEmpty)
                              {
                                generateAndSharePDF_Purchase();
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

                            if(type == 'Sales')
                            {
                              if(!item_list.isEmpty)
                              {
                                generateAndShareCSV_Sold();
                              }
                            }
                            else if (type == 'Purchase')
                            {
                              if(!item_list.isEmpty)
                              {
                                generateAndShareCSV_Purchased();
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
                margin: EdgeInsets.only(left: 12,right:12,top:12, bottom: 6),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(padding: EdgeInsets.only(top: 0,left: 20,right: 20,bottom: 10),
                        child: Container(child:

                        Center(child:   Text(item,
                          textAlign: TextAlign.center,

                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 17
                          ),),),
                        ),),

                      SizedBox(height: 8),
                      /// 📆 Date Range (Single Widget)
                      InkWell(
                        onTap: () {

                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
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
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
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
                              onChanged: (value) {
                                setState(() {
                                  filteredItems = value.isEmpty
                                      ? item_list
                                      : item_list.where((item) => item.vchno.toLowerCase().contains(value.toLowerCase())).toList();
                                });
                              },
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
                      if (_isListVisible)
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: filteredItems.length,
                            padding: const EdgeInsets.only(left: 16,right:16,top:0, bottom: 12),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title Row
                                          Row(
                                            children: [
                                              Icon(Icons.receipt_long, size: 20, color: Colors.teal.shade600),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.vchno,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.teal.shade50,
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.inventory_2_outlined, size: 14, color: Colors.teal),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Qty: ${item.qty}',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.teal.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 14),

                                          // Details Row
                                          Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black45),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      convertDateFormat(item.vchdate),
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13.5,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons.attach_money, size: 18, color: Colors.black45),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Rate: ${formatRate(item.rate)}',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13.5,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                )])])));}))],
                  ),
                ),
              ),
            ],
          ),

          Visibility(
            visible: isSortVisible,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () => _showSelectionWindow(context),
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color:  app_color, // soft teal background
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sort, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Sort',
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        )]))))
            )
          ),

          Visibility(
            visible: _isLoading,
            child: Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator.adaptive(),
              ),
            ))
        ]  ));
  }
}