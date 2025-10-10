import 'dart:convert';
import 'dart:io';
import 'package:fincoremobile/Dashboard.dart';
import 'package:fincoremobile/currencyFormat.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ItemsClicked.dart';
import 'SerialSelect.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'constants.dart';

class items {
  final String itemname;
  final String alias;
  final String unit;
  final String saleprice;
  final String c_qty;
  final String c_rate;
  final String c_amount;
  final String description;
  final String lastsale;
  final String lastpurc;
  final String purcprice;
  final String standardprice;
  final String alternate_unit;
  final String denominator;
  items({
    required this.itemname,
    required this.alias,
    required this.unit,
    required this.saleprice,
    required this.c_qty,
    required this.c_rate,
    required this.c_amount,
    required this.description,
    required this.lastsale,
    required this.lastpurc,
    required this.purcprice,
    required this.standardprice,
    required this.alternate_unit,
    required this.denominator,
  });
  
  factory items.fromJson(Map<String, dynamic> json)
  {
    return items(
      itemname: json['name'].toString(),
      alias: json['alias'].toString(),
      unit: json['unit'].toString(),
      saleprice: json['saleprice'].toString(),
      c_qty: json['c_qty'].toString(),
      c_rate: json['c_rate'].toString(),
      c_amount: json['c_amount'].toString(),
      description: json['description'].toString(),
      lastsale: json['lastsale'].toString(),
      lastpurc: json['lastpurc'].toString(),
      purcprice: json['purcprice'].toString(),
      standardprice: json['standardprice'].toString(),
      alternate_unit: json['alternateUnit'].toString(),
      denominator: json['denominator'].toString(),
    );
  }
}

String formatlastsaledate(String saledate) {
  String formated_saledate = "";

  if(saledate == 'null' || saledate == '') {
      formated_saledate = 'N/A';
   }
  else {
      DateTime saledate_date = DateTime.parse(saledate);
      formated_saledate = DateFormat("dd-MMM-yyyy").format(saledate_date);
    }
  return formated_saledate;
}

String formatValue(String value) {
  String value_string = "";

    if(value == "null")
      {
        value = "0";
      }
    value_string = CurrencyFormatter.formatCurrency_normal(value);
  return value_string;
}

String formatQtyDescription (String c_qty, String unit, String alternate_unit, String denominator) {
  String qty = '';

  if(alternate_unit != 'null' || denominator != 'null')
    {
      qty = '1 $alternate_unit = $denominator $unit';
    }
  return qty;
}

String formatRate(String value) {
  if(value == "null")
  {
    value = "-";
  }
  return value;
}

String formatRate_Report(String value) {
  if(value == "null")
  {
    value = "-";
  }
  return value;
}

class Items extends StatefulWidget
{
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<Items> with TickerProviderStateMixin{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isClicked_allitems = true,isClicked_fastmoving = false, isClicked_inactiveitems = false,isClicked_slowmoving = false;

  int counter = 0;

  List<items> filteredItems_inactive_items = []; // Initialize an empty list to hold the filtered items
  List<items> filteredItems_all_items = []; // Initialize an empty list to hold the filtered items
  List<items> filteredItems_active_items = []; // Initialize an empty list to hold the filtered items

  String item_count = "0",token = '';

  String fastmovingdays = '',fastmovingqty= '',fastmovingvalue= '' ,inactivedays = '',slowmovingdays = '',slowmovingqty= '',slowmovingvalue= '';

  String? SecuritybtnAcessHolder;
  bool isDashEnable = true,isRolesEnable = true,isUserEnable = true,isRolesVisible = true,
      isUserVisible = true,_isSearchViewVisible = false,_isAllList = false,_isInactiveList = false,_isActiveList = false;

  bool allitems_visibility = false, fastmovingitems_visibility = false, inactiveitems_visibility = false, rate_visibility = false,
  amount_visibility = false;
  bool isVisibleNoAccess = false,isVisibleParent = false;
  String email = "";
  String name = "";

  bool isVisibleListLayout = false;

  String? _selectedFilter = 'qty';

  late String currencysymbol = '';

  late int? decimal;

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  TextEditingController searchController = TextEditingController();

  bool isVisibleNoDataFound = false;

  String allitems = 'All Items';

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  late SharedPreferences prefs;

  String fastmovingdate = '';

  String? hostname = "",company = "",serial_no = "",company_lowercase = "",username = "";
  bool _isLoading = false;

  String? HttpURL_Parent,HttpURL_allitems,HttpURL_active_inactive_items;

  dynamic _selecteditem = "";
  List<String> spinner_list = [];

  List<items> all_items_list = [];
  List<items> inactive_items_list = [];
  List<items> active_items_list = [];

  late NumberFormat currencyFormat;


  bool isVisibleFilterby = false;

  Future<void> generateAndShareCSV_AllItems() async {
    final List<List<dynamic>> csvData = [];
    csvData.add(['Item Name', 'Qty', 'Rate', 'Last Sale Price', 'Standard Selling Price', 'Amount']);

    for (final item in all_items_list) {
      csvData.add([
        item.itemname,
        item.c_qty,
        formatRate_Report(item.c_rate),
        formatValue(item.saleprice),
        formatValue(item.standardprice),
        formatAmount(item.c_amount),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/AllItems.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing All Items Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  Future<void> generateAndShareCSV_FastSlowItems() async {
    final List<List<dynamic>> csvData = [];
    csvData.add(['Item Name', 'Qty', 'Rate', 'Last Sale Price', 'Standard Selling Price', 'Amount']);

    for (final item in active_items_list) {
      csvData.add([
        item.itemname,
        item.c_qty,
        formatRate_Report(item.c_rate),
        formatValue(item.saleprice),
        formatValue(item.standardprice),
        formatAmount(item.c_amount),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/Fast_SlowMovingItems.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing Fast/Slow Moving Items Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  Future<void> generateAndShareCSV_InactiveItems() async {
    final List<List<dynamic>> csvData = [];
    csvData.add(['Item Name', 'Inactive Since', 'Qty', 'Rate', 'Last Sale Price', 'Standard Selling Price', 'Amount']);

    for (final item in inactive_items_list) {
      csvData.add([
        item.itemname,
        formatlastsaledate(item.lastsale),
        item.c_qty,
        formatRate_Report(item.c_rate),
        formatValue(item.saleprice),
        formatValue(item.standardprice),
        formatAmount(item.c_amount),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFilePath = '${tempDir.path}/InactiveItems.csv';
    final file = File(tempFilePath);
    await file.writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing Inactive Items Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  Future<void> generateAndSharePDF_AllItems() async {
    final pdf = pw.Document();
    final companyName = company!;
    final reportname = 'Stock Summary';
    final parentname = _selecteditem;
    final headersRow3 = ['Item Name', 'Qty', 'Rate', 'Last Sale Price', 'Standard Selling Price', 'Amount'];

    final itemsPerPage = 8;
    final pageCount = (all_items_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex = (pageNumber + 1) * itemsPerPage;
      final itemsSubset = all_items_list.sublist(
        startIndex,
        endIndex > all_items_list.length ? all_items_list.length : endIndex,
      );

      final tableSubsetRows = itemsSubset.map((item) {
        return [
          item.itemname,
          item.c_qty,
          formatRate_Report(item.c_rate),
          formatValue(item.saleprice),
          formatValue(item.standardprice),
          formatAmount(item.c_amount),
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
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
        headers: headersRow3,
        data: tableSubsetRows,
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
                  pw.Text('Group:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 5),
                  pw.Text(parentname, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(child: tableSubset),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/AllItems.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing All Items Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  Future<void> generateAndSharePDF_FastSlowItems() async {
    final pdf = pw.Document();
    final companyName = company!;
    final reportname = 'Stock Summary';
    final parentname = _selecteditem;
    final headersRow3 = ['Item Name', 'Qty', 'Rate', 'Last Sale Price', 'Standard Selling Price', 'Amount'];

    final itemsPerPage = 8;
    final pageCount = (active_items_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex = (pageNumber + 1) * itemsPerPage;
      final itemsSubset = active_items_list.sublist(
        startIndex,
        endIndex > active_items_list.length ? active_items_list.length : endIndex,
      );

      final tableSubsetRows = itemsSubset.map((item) {
        return [
          item.itemname,
          item.c_qty,
          formatRate_Report(item.c_rate),
          formatValue(item.saleprice),
          formatValue(item.standardprice),
          formatAmount(item.c_amount),
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
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
        headers: headersRow3,
        data: tableSubsetRows,
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
                  pw.Text('Group:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 5),
                  pw.Text(parentname, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(child: tableSubset),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/Fast_SlowMovingItems.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing Fast/Slow Moving Items Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }

  Future<void> generateAndSharePDF_InactiveItems() async {
    final pdf = pw.Document();
    final companyName = company!;
    final reportname = 'Stock Summary';
    final parentname = _selecteditem;
    final headersRow3 = ['Item Name', 'Inactive Since', 'Qty', 'Rate', 'Last Sale Price', 'Standard Selling Price', 'Amount'];

    final itemsPerPage = 8;
    final pageCount = (inactive_items_list.length / itemsPerPage).ceil();

    for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
      final startIndex = pageNumber * itemsPerPage;
      final endIndex = (pageNumber + 1) * itemsPerPage;
      final itemsSubset = inactive_items_list.sublist(
        startIndex,
        endIndex > inactive_items_list.length ? inactive_items_list.length : endIndex,
      );

      final tableSubsetRows = itemsSubset.map((item) {
        return [
          item.itemname,
          formatlastsaledate(item.lastsale),
          item.c_qty,
          formatRate_Report(item.c_rate),
          formatValue(item.saleprice),
          formatValue(item.standardprice),
          formatAmount(item.c_amount),
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
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 12),
        headers: headersRow3,
        data: tableSubsetRows,
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
                  pw.Text('Group:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 5),
                  pw.Text(parentname, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(child: tableSubset),
            ],
          ),
        ),
      );
    }

    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/InactiveItems.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Sharing Inactive Items Report of $company',
        files: [XFile(tempFilePath)],
      ),
    );
  }


  Future<void> fetchParentData() async {

    setState(() {
      _isLoading = true;
    });

    spinner_list.clear();

    try
    {
      final url = Uri.parse(HttpURL_Parent!);

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
          spinner_list.add(allitems);

        List<dynamic> data = jsonDecode(response.body);
        for (var item in data) {
          String itemname = item['parent'];
          spinner_list.add(itemname);
        }
        setState(() {
          _selecteditem = spinner_list[0];
        });

        if(allitems_visibility) {
          fetchItemData('All Items', _selecteditem);
        }
        else if (fastmovingitems_visibility)
          {
              fetchItemData ('FastMovingItems',_selecteditem);

          }
        else if (inactiveitems_visibility)
          {
            fetchItemData ('InactiveItems',_selecteditem);

          }
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

  void fetchItemData(String item_type,String item) {
    if(item == "All Items")
      {
        item = "";
      }
    if(item_type == "All Items")
      {
        fetchall_items(item);

      }
    else if (item_type == "FastMovingItems")
      {
        fetchactive_items(item,_selectedFilter!);

      }
    else if (item_type == "SlowMovingItems")
    {
      fetchslow_items(item,_selectedFilter!);

    }
    else if (item_type == "InactiveItems")
      {
        fetchinactive_items(item);

      }
  }



  Future<void> fetchall_items(final String parent) async{

    setState(() {
      item_count = "0";
      _isLoading = true;
      _isAllList = false;
      _isInactiveList = false;
      _isActiveList = false;
      isClicked_allitems = true;
      isClicked_fastmoving = false;
      isClicked_slowmoving = false;
      isClicked_inactiveitems = false;
      isVisibleNoDataFound = false;
      isVisibleFilterby = false;

    });

    filteredItems_all_items.clear();
    all_items_list.clear();

    try
    {
      final url = Uri.parse(HttpURL_allitems!);

      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'parent': parent

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

          all_items_list.addAll(values_list.map((json) => items.fromJson(json)).toList());
          filteredItems_all_items = all_items_list;
        }
        else
        {
          throw Exception('Failed to fetch data');
        }
      }
    }
    catch (e)
    {
      setState(() {
        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        _isLoading = false;
      });
      print(e);
    }

    setState(() {
      if(all_items_list.isEmpty)
      {
        item_count = "0";
        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        isVisibleNoDataFound = true;
      }
      else
        {
            item_count = filteredItems_all_items.length.toString();
            _isInactiveList = false;
            _isAllList = true;
            _isActiveList = false;
        }
      _isLoading = false;
    });

  }

  Future<void> fetchactive_items(final String parent,final String filter) async{

    String qty = '';
    String value = '';

    if(filter == 'qty')
      {
        qty = fastmovingqty;
      }
    if(filter == 'value')
      {
        value = fastmovingvalue;

      }

    int fastdays = int.parse(fastmovingdays);
    DateTime currentDate = DateTime.now();
    DateTime newDate = currentDate.subtract(Duration(days: fastdays));
    String formattedDate = DateFormat('yyyyMMdd').format(newDate);

    setState(() {
      item_count = "0";
      isClicked_allitems = false;
      isClicked_fastmoving = true;
      isClicked_slowmoving = false;
      isClicked_inactiveitems = false;
      _isLoading = true;
      _isAllList = false;
      _isInactiveList = false;
      _isActiveList = false;
      isVisibleNoDataFound = false;
      isVisibleFilterby = true;
    });

    filteredItems_active_items.clear();
    active_items_list.clear();

    try
    {
      final url = Uri.parse(HttpURL_active_inactive_items!);
      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {

        "date" : formattedDate,
        "status" : "FAST",
        "qty" : qty,
        "value" : value,
        "parent" : parent
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );
      final decoded = jsonDecode(response.body);

      final prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
      print(prettyJson);


      if (response.statusCode == 200)
      {
        final List<dynamic> values_list = jsonDecode(response.body);

        if (values_list != null) {
          isVisibleNoDataFound = false;

          for (var entry in values_list.asMap().entries) {
            int index = entry.key;
            dynamic item = entry.value;

            /*String lastpurchdate = item['lastpurc'].toString();
            String lastsaledate = item['lastsale'].toString();

            DateTime lastsale_date;
            DateTime lastpurc_date;

            Duration difference_lastsaledate = Duration(days: 181) ;
            Duration difference_lastpurcdate = Duration(days: 181);
            DateTime current_date = DateTime.now();

            bool diff_sale = false;
            bool diff_purchase = false;

            if(lastsaledate != 'null' && lastsaledate != '')
            {
              lastsale_date = DateTime.parse(lastsaledate);
              difference_lastsaledate = current_date.difference(lastsale_date);

              diff_sale = difference_lastsaledate.inDays <=190;
            }

            if (lastpurchdate != 'null'&& lastpurchdate != '')
            {
              lastpurc_date = DateTime.parse(lastpurchdate);
              difference_lastpurcdate = current_date.difference(lastpurc_date);
              diff_purchase = difference_lastpurcdate.inDays <=190;
            }

            if(diff_sale || diff_purchase )
              {
                active_items_list.add(items.fromJson(values_list[index]));
              }*/

            active_items_list.add(items.fromJson(values_list[index]));
          }
            filteredItems_active_items = active_items_list;
        }
        else
        {
          throw Exception('Failed to fetch data');
        }
      }
    }
    catch (e)
    {
      setState(() {
        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        _isLoading = false;
      });
      print(e);
    }

    setState(() {
      if(active_items_list.isEmpty)
      {
        item_count = "0";

        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        isVisibleNoDataFound = true;
      }
      else
        {
          item_count = filteredItems_active_items.length.toString();
          _isInactiveList = false;
          _isActiveList = true;
          _isAllList = false;
        }
      _isLoading = false;
    });
  }

  Future<void> fetchslow_items(final String parent,final String filter) async{

    String qty = '';
    String value = '';

    if(filter == 'qty')
    {
      qty = slowmovingqty;
    }
    if(filter == 'value')
    {
      value = slowmovingvalue;
    }

    int slowdays = int.parse(slowmovingdays);
    DateTime currentDate = DateTime.now();
    DateTime newDate = currentDate.subtract(Duration(days: slowdays));
    String formattedDate = DateFormat('yyyyMMdd').format(newDate);

    setState(() {
      item_count = "0";
      isClicked_allitems = false;
      isClicked_fastmoving = false;
      isClicked_slowmoving = true;
      isClicked_inactiveitems = false;
      _isLoading = true;
      _isAllList = false;
      _isInactiveList = false;
      _isActiveList = false;
      isVisibleNoDataFound = false;
      isVisibleFilterby = true;
    });

    filteredItems_active_items.clear();
    active_items_list.clear();

    try
    {
      final url = Uri.parse(HttpURL_active_inactive_items!);
      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {

        "date" : formattedDate,
        "status" : "SLOW",
        "qty" : qty,
        "value" : value,
        "parent" : parent
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        final List<dynamic> values_list = jsonDecode(response.body);

        if (values_list != null)
        {
          isVisibleNoDataFound = false;

          for (var entry in values_list.asMap().entries) {
            int index = entry.key;
            dynamic item = entry.value;

            /*String lastpurchdate = item['lastpurc'].toString();
            String lastsaledate = item['lastsale'].toString();

            DateTime lastsale_date;
            DateTime lastpurc_date;

            Duration difference_lastsaledate = Duration(days: 181) ;
            Duration difference_lastpurcdate = Duration(days: 181);
            DateTime current_date = DateTime.now();

            bool diff_sale = false;
            bool diff_purchase = false;

            if(lastsaledate != 'null' && lastsaledate != '')
            {
              lastsale_date = DateTime.parse(lastsaledate);
              difference_lastsaledate = current_date.difference(lastsale_date);

              diff_sale = difference_lastsaledate.inDays <=190;

            }

            if (lastpurchdate != 'null'&& lastpurchdate != '')
            {
              lastpurc_date = DateTime.parse(lastpurchdate);
              difference_lastpurcdate = current_date.difference(lastpurc_date);
              diff_purchase = difference_lastpurcdate.inDays <=190;

            }

            if(diff_sale || diff_purchase )
              {
                active_items_list.add(items.fromJson(values_list[index]));
              }*/
            active_items_list.add(items.fromJson(values_list[index]));
          }
          filteredItems_active_items = active_items_list;

        }
        else
        {
          throw Exception('Failed to fetch data');
        }
      }
    }
    catch (e)
    {
      setState(() {
        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        _isLoading = false;
      });
      print(e);
    }

    setState(() {
      if(active_items_list.isEmpty)
      {
        item_count = "0";

        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        isVisibleNoDataFound = true;
      }
      else
        {
          item_count = filteredItems_active_items.length.toString();
          _isInactiveList = false;
          _isActiveList = true;
          _isAllList = false;
        }
      _isLoading = false;
    });
  }

  Future<void> fetchinactive_items(final String parent) async{

    setState(() {
      item_count = "0";
      _isLoading = true;
      _isAllList = false;
      _isActiveList = false;
      _isInactiveList = false;
      isVisibleNoDataFound = false;
      isClicked_allitems = false;
      isClicked_fastmoving = false;
      isClicked_slowmoving = false;
      isVisibleFilterby = false;

      isClicked_inactiveitems = true;
    });

    filteredItems_inactive_items.clear();
    inactive_items_list.clear();

    int inactivedayss = int.parse(inactivedays);
    DateTime currentDate = DateTime.now();
    DateTime newDate = currentDate.subtract(Duration(days: inactivedayss));
    String formattedDate = DateFormat('yyyyMMdd').format(newDate);

    try
    {
      final url = Uri.parse(HttpURL_active_inactive_items!);

      Map<String,String> headers = {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        "date" : formattedDate,
        "status" : "INACTIVE",
        "parent" : parent,
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

          for (var entry in values_list.asMap().entries) {
            int index = entry.key;
            dynamic item = entry.value;
              inactive_items_list.add(items.fromJson(values_list[index]));
          }
          filteredItems_inactive_items = inactive_items_list;
        }
        else
        {

          throw Exception('Failed to fetch data');
        }
      }
    }
    catch (e)
    {
      setState(() {
        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        _isLoading = false;
      });
      print(e);
    }

    setState(() {
      if(inactive_items_list.isEmpty)
      {
        _isInactiveList = false;
        _isAllList = false;
        _isActiveList = false;
        item_count = "0";
        isVisibleNoDataFound = true;
      }
      else
        {
          item_count = filteredItems_inactive_items.length.toString();
          _isInactiveList = true;
          _isActiveList = false;
          _isAllList = false;
        }
      _isLoading = false;
    });
  }

  Future<void> _initSharedPreferences() async {

    prefs = await SharedPreferences.getInstance();

     decimal = prefs.getInt('decimalplace') ?? 2;

    currencyFormat = new NumberFormat();

    String? currencyCode = '';

    currencyCode = prefs.getString('currencycode')?? "AED";

    try {
      if (currencyCode == 'INR' || currencyCode == 'EUR' ||
          currencyCode == 'USD' || currencyCode == 'PKR') {
        currencyFormat = NumberFormat('#,##0');
        NumberFormat format = NumberFormat.simpleCurrency(
            locale: 'en', name: currencyCode);
        currencysymbol = format.currencySymbol;
      } else {
        NumberFormat format = NumberFormat.currency(
            locale: 'en', name: currencyCode);
        currencysymbol = format.currencySymbol;
        currencyFormat = NumberFormat('#,##0');
      }
    } catch (e) {
      NumberFormat format = NumberFormat.currency(
          locale: 'en', name: currencyCode);
      currencysymbol = format.currencySymbol;
      currencyFormat = NumberFormat('#,##0');
    }

    hostname = prefs.getString('hostname');
    company  = prefs.getString('company_name');
    company_lowercase = company!.replaceAll(' ', '').toLowerCase();
    serial_no = prefs.getString('serial_no');
    username = prefs.getString('username');
    token = prefs.getString('token')!;

    fastmovingdays = prefs.getString('fastmovingdays') ?? '180';
    fastmovingqty = prefs.getString('fastmovingqty') ?? '1000';
    fastmovingvalue = prefs.getString('fastmovingvalue') ?? '10000';

    slowmovingdays = prefs.getString('slowmovingdays') ?? '181';
    slowmovingqty = prefs.getString('slowmovingqty') ?? '1000';
    slowmovingvalue = prefs.getString('slowmovingvalue') ?? '10000';

    inactivedays = prefs.getString('inactivedays') ?? '182';

    String allitemsaccess = prefs.getString("allitems") ?? 'False';
    String fastmovingitemsaccess = prefs.getString("activeitems") ?? 'False';
    String inactiveitemsaccess = prefs.getString("inactiveitems") ?? 'False';
    String rateaccess = prefs.getString("rate") ?? 'False';
    String amountaccess = prefs.getString("item_amount") ?? 'False';

    if(allitemsaccess == 'True')
      {
        allitems_visibility = true;
      }
    else
      {
        allitems_visibility = false;
      }
    if(fastmovingitemsaccess == 'True')
    {
      fastmovingitems_visibility = true;
    }
    else
    {
      fastmovingitems_visibility = false;
    }
    if(inactiveitemsaccess == 'True')
    {
      inactiveitems_visibility = true;
    }
    else
    {
      inactiveitems_visibility = false;
    }
    if(rateaccess == 'True')
    {
      rate_visibility = true;
    }
    else
    {
      rate_visibility = false;
    }
    if(amountaccess == 'True')
    {
      amount_visibility = true;
    }
    else
    {
      amount_visibility = false;
    }

    HttpURL_Parent = '$hostname/api/item/getParent/$company_lowercase/$serial_no';
    HttpURL_allitems =  '$hostname/api/item/getitem/$company_lowercase/$serial_no';
    HttpURL_active_inactive_items =  '$hostname/api/item/getMoving/$company_lowercase/$serial_no';

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
    if(allitems_visibility || fastmovingitems_visibility || inactiveitems_visibility) {
      isVisibleParent = true;
      isVisibleListLayout = true;
      fetchParentData();
    }
    else
      {
        isVisibleListLayout = false;
        isVisibleNoAccess = true;
        isVisibleParent = false;
      }
  }

  String formatAmountinDecimals(num amount, int decimals) {
    final formatter = NumberFormat.decimalPattern('en')
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return formatter.format(amount);
  }


  String removeUnit(String value) {
    try {
      // Sirf number aur dot rakho
      String numberOnly = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (numberOnly.isEmpty) return value;

      double parsed = double.parse(numberOnly);

      // Agar value decimal ke bagair hai → int dikhado
      if (parsed % 1 == 0) {
        return parsed.toInt().toString(); // 731.0 → 731
      } else {
        return parsed.toString(); // 286.57 → 286.57
      }
    } catch (e) {
      return value; // agar parse fail ho jaye to original value
    }
  }
  @override
  void initState()
  {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [app_color.withOpacity(0.95), app_color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          title: Column(
            children: [
              Text(
                company ?? '',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text("Stock Summary",
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70)),
            ],
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: 26),
              onPressed: () => setState(() => _isSearchViewVisible = !_isSearchViewVisible),
            ),
            IconButton(
              icon: Icon(Icons.share_outlined, color: Colors.white, size: 26),
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
                              if(_isAllList)
                              {
                                if(!all_items_list.isEmpty)
                                {
                                  generateAndSharePDF_AllItems();
                                }
                                else
                                {
                                  showToast('Data Not Found');
                                }
                              }
                              else if (_isActiveList)
                              {
                                if(!active_items_list.isEmpty)
                                {
                                  generateAndSharePDF_FastSlowItems();
                                }
                                else
                                {
                                  showToast('Data Not Found');
                                }
                              }
                              else if (_isInactiveList)
                              {
                                if(!inactive_items_list.isEmpty)
                                {
                                  generateAndSharePDF_InactiveItems();
                                }
                                else
                                {
                                  showToast('Data Not Found');
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
                                style: TextStyle(
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

                                if(_isAllList)
                                {
                                  if(!all_items_list.isEmpty)
                                  {
                                    generateAndShareCSV_AllItems();
                                  }
                                }
                                else if(_isActiveList)
                                {
                                  if(!active_items_list.isEmpty)
                                  {
                                    generateAndShareCSV_FastSlowItems();
                                  }}
                                else if(_isInactiveList)
                                {
                                  if(!inactive_items_list.isEmpty)
                                  {
                                    generateAndShareCSV_InactiveItems();
                                  }}},
                              child:  Row(children: [
                                Icon( Icons.add_chart_outlined,
                                  size: 16,
                                  color: Color(0xFF26ADA3),),
                                SizedBox(width: 5,),

                                Text(
                                    'Share as CSV',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFF26ADA3),
                                      fontSize: 16,
                                    ))])))]);},
            ),
            if (isVisibleFilterby)
              IconButton(
                icon: Icon(Icons.filter_alt_rounded, color: Colors.white, size: 26),
                onPressed: _showFilterBottomSheet, // 👇 new bottom sheet filter
              ),
            SizedBox(width: 6),
          ],
        ),
      ),

      body: Stack(
        children: [
          Column(
            children: [
              // 🔹 Dropdown + Tabs Container
              if (isVisibleParent)
                Container(
                  margin: EdgeInsets.only(top:10,left:16,right:16,bottom: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      // Parent Dropdown
                      _buildParentDropdown(),

                      SizedBox(height: 14),

                      // Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (allitems_visibility)
                              _buildTab("All Items", Icons.inventory_2_outlined, isClicked_allitems,
                                      () => fetchItemData('All Items', _selecteditem)),
                            if (fastmovingitems_visibility)
                              _buildTab("Fast Moving", Icons.flash_on_rounded, isClicked_fastmoving,
                                      () => fetchItemData('FastMovingItems', _selecteditem)),
                            if (fastmovingitems_visibility)
                              _buildTab("Slow Moving", Icons.timer_outlined, isClicked_slowmoving,
                                      () => fetchItemData('SlowMovingItems', _selecteditem)),
                            if (inactiveitems_visibility)
                              _buildTab("Inactive", Icons.block, isClicked_inactiveitems, () {
                                _showInactiveDaysDialog(context); // 👈 open modern dialog instead of direct fetch
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // 🔹 Search bar
              if (_isSearchViewVisible)
                Container(
                  margin: EdgeInsets.only(left: 16,right:16,bottom:4),
                  padding: EdgeInsets.symmetric(horizontal: 16,vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search items...",
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey[600]),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

              SizedBox(height: 0),

              // 🔹 List / Empty State
              Expanded(
                child: isVisibleNoDataFound
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  itemCount: _getVisibleList().length,
                  itemBuilder: (context, index) {
                    final card = _getVisibleList()[index];
                    return _buildItemCard(card);
                  },
                ),
              ),
            ],
          ),

          // 🔹 Loader Overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
        ],
      ),
    );
  }

  // ------------------- 🔹 Widgets 🔹 -------------------

  Widget _buildParentDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selecteditem,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
        items: spinner_list.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selecteditem = value);
          fetchItemData('All Items', _selecteditem);
        },
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [app_color.withOpacity(0.9), app_color.withOpacity(0.7)])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? app_color : Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : app_color),
            SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : app_color,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic card) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: app_color.withOpacity(0.1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemsClicked(
                itemname: card.itemname,
                unit: card.unit,
                item_desc: card.description,
                item_lastsaledate: card.lastsale,
                item_lastpurchdate: card.lastpurc,
                item_rate: card.saleprice,
                inventory_closing: card.c_qty,
                lastpurcrate: card.purcprice,
                alias: card.alias,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.65),
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Title & Unit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Left side (Item name + Unit)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.itemname,
                                softWrap: true,
                                maxLines: 3, // allow wrapping for long names
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      "Qty: ${removeUnit(card.c_qty)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width:8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orange.shade300)
                                    ),
                                    child: Text(
                                      "Unit: ${card.unit}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              )

                            ],
                          ),
                        ),


                         SizedBox(width: 6),
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


                    // 🔹 Alternate Unit
                    if (card.alternate_unit != 'null') ...[
                      const SizedBox(height: 8),
                      Text(
                        formatQtyDescription(
                          card.c_qty,
                          card.unit,
                          card.alternate_unit,
                          card.denominator,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.shade300),
                    const SizedBox(height: 12),

                    // 🔹 Detail rows
                    _modernDetailRow(Icons.sell_outlined, "Last Sale Price",
                        card.saleprice != "null"
                            ? '$currencysymbol ${formatAmountinDecimals(double.parse(removeUnit(card.saleprice).toString()), decimal!)}'
                            : "-"),

                    _modernDetailRow(Icons.local_offer_outlined, "Standard Price",
                        card.standardprice != "null"
                            ? '$currencysymbol ${formatAmountinDecimals(double.parse(removeUnit(card.standardprice).toString()), decimal!)}'
                            : "-"),

                    if (rate_visibility && card.c_rate != "null")
                      _modernDetailRow(Icons.attach_money, "Rate",
                          '$currencysymbol ${formatAmountinDecimals(double.parse(removeUnit(card.c_rate).toString()), decimal!)}'),

                    if (amount_visibility)
                      _modernDetailRow(Icons.payments, "Amount",
                          card.c_amount != "null"
                              ? '$currencysymbol ${formatAmountinDecimals(double.parse(card.c_amount.toString()), decimal!)}'
                              : "-"),

                    if (_isInactiveList)
                      _modernDetailRow(Icons.calendar_today, "Inactive Since",
                          formatlastsaledate(card.lastsale)),
                  ],
                ),
              ),

                         ],
          ),
        ),
      ),
    );
  }

// 🔹 Modern detail row with icon pill
  Widget _modernDetailRow(IconData icon, String title, String value) {
    // Gradient selection based on title
    LinearGradient getGradient(String title) {
      if (title.contains("Sale")) {
        return LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]);
      } else if (title.contains("Standard")) {
        return LinearGradient(colors: [Colors.purple.shade400, Colors.purple.shade700]);
      } else if (title.contains("Rate")) {
        return LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]);
      } else if (title.contains("Amount")) {
        return LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade600]);
      } else if (title.contains("Inactive")) {
        return LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]);
      }
      return LinearGradient(colors: [app_color.withOpacity(0.4), app_color.withOpacity(0.7)]);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 🔹 Icon Badge with dynamic gradient
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

          // 🔹 Title
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


          // 🔹 Value
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text("No items found",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Text("Filter By",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          Divider(),
          RadioListTile<String>(
            value: "qty",
            groupValue: _selectedFilter,
            onChanged: (v) {
              setState(() => _selectedFilter = v);
              Navigator.pop(context);
              if (isClicked_fastmoving) fetchItemData('FastMovingItems', _selecteditem);
              if (isClicked_slowmoving) fetchItemData('SlowMovingItems', _selecteditem);
            },
            title: Text("Quantity"),
          ),
          RadioListTile<String>(
            value: "value",
            groupValue: _selectedFilter,
            onChanged: (v) {
              setState(() => _selectedFilter = v);
              Navigator.pop(context);
              if (isClicked_fastmoving) fetchItemData('FastMovingItems', _selecteditem);
              if (isClicked_slowmoving) fetchItemData('SlowMovingItems', _selecteditem);
            },
            title: Text("Sale Price"),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  List<dynamic> _getVisibleList() {
    if (_isAllList) return filteredItems_all_items;
    if (_isActiveList) return filteredItems_active_items;
    return filteredItems_inactive_items;
  }

  void _onSearchChanged(String value) {
    final query = value.toLowerCase();
    setState(() {
      if (_isAllList) {
        filteredItems_all_items = all_items_list.where((e) => e.itemname.toLowerCase().contains(query)).toList();
      } else if (_isActiveList) {
        filteredItems_active_items = active_items_list.where((e) => e.itemname.toLowerCase().contains(query)).toList();
      } else if (_isInactiveList) {
        filteredItems_inactive_items =
            inactive_items_list.where((e) => e.itemname.toLowerCase().contains(query)).toList();
      }
    });
  }


  Widget buildNeumorphicTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 50),
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isSelected
            ? LinearGradient(
          colors: [
           Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isSelected ? Colors.white.withOpacity(0.6) : Colors.white,
        border: Border.all(
          color: isSelected ? app_color : Colors.grey.shade300,
          width: isSelected ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey.shade200,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          splashColor: app_color.withOpacity(0.2),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: isSelected ? app_color : Colors.grey[700]),
                SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? app_color : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildIconRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
  void _showInactiveDaysDialog(BuildContext context) {
    final TextEditingController daysController = TextEditingController();
    daysController.text = inactivedays.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.9), Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_off, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text(
                  "Inactive Items",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter number of days to filter inactive items:",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),

                // Modern TextField
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "e.g. 30",
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.teal, width: 1.8),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx); // close without action
                      },
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        final input = daysController.text.trim();
                        if (input.isNotEmpty && int.tryParse(input) != null) {
                          inactivedays = input;



                          // Call your same logic with days
                          fetchItemData('InactiveItems', _selecteditem);

                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text(
                        "Apply",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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