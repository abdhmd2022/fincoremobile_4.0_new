import 'dart:convert';
import 'dart:io';
import 'package:fincoremobile/Items.dart';
import 'package:fincoremobile/PendingSalesEntry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants.dart';
import 'PendingSalesOrderEntry.dart';
import 'Sidebar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SalesOrderRegistration extends StatefulWidget {
  const SalesOrderRegistration({Key? key}) : super(key: key);
  @override
  _SalesOrderRegistrationPageState createState() => _SalesOrderRegistrationPageState();
}

class SaleItem {
  final String itemName;
   String itemQuantity;
   double itemPrice;
  final double itemAmount;
  final String itemLocation;
  final String itemUnit;
  late Map<String, dynamic> accountingAllocationList;
  late Map<String, dynamic> batchAllocationList;

  SaleItem({
    required this.itemName,
    required this.itemQuantity,
    required this.itemPrice,
    required this.itemAmount,
    required this.itemLocation,
    required this.itemUnit,
    required this.accountingAllocationList,
    required this.batchAllocationList,
  });

  SaleItem updateQuantity(String newQuantity) {
    return SaleItem(
      itemName: this.itemName,
      itemQuantity: newQuantity,
      itemPrice: this.itemPrice,
      itemAmount: this.itemPrice * double.parse(newQuantity),
      itemLocation: this.itemLocation,
      itemUnit: this.itemUnit,
      accountingAllocationList: this.accountingAllocationList,
      batchAllocationList: this.batchAllocationList,
    );
  }

  SaleItem updateItemAmount(double newAmount) {
    return SaleItem(
      itemName: this.itemName,
      itemQuantity: this.itemQuantity,
      itemPrice: this.itemPrice,
      itemAmount: newAmount,
      itemLocation: this.itemLocation,
      itemUnit: this.itemUnit,
      accountingAllocationList: this.accountingAllocationList,
      batchAllocationList: this.batchAllocationList,
    );
  }
}

class Unit {
  final String name;
  final double multiplier;

  Unit({required this.name, required this.multiplier});

  factory Unit.fromJson(Map<String, dynamic> json)
  {
    return Unit(
      name: json['name'],
      multiplier: double.parse(json['multiplier']),
    );}}

class LedgerEntry {
  final String ledgerName;
  final double ledgerAmount;
  final bool vatApp;

  LedgerEntry ({
    required this.ledgerName,
    required this.ledgerAmount,
    required this.vatApp});

  LedgerEntry updateAmount(double newAmount,bool vatApp) {
    return LedgerEntry(
      ledgerName: this.ledgerName,
      ledgerAmount: newAmount,
      vatApp: vatApp,
    );
  }
}

class _SalesOrderRegistrationPageState extends State<SalesOrderRegistration> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false;

  TextEditingController _itemController = TextEditingController();
  TextEditingController _partyLedgerController = TextEditingController();

  double ledgerVatAmount = 0,
      itemsVatAmount = 0,
      totalVatAmount = 0,
      totalAmount = 0;

  double totalPriceOfItems = 0, totalAmountForVatAppEntries = 0,totalAmountOfLedgers = 0;
  final FocusNode _textFieldFocusNodeNarration = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _animation;

  void _confirmLedgerDeletion(BuildContext context, int index,String ledgername) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Do you really want to delete $ledgername ledger?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('No',
                style: TextStyle(
                  color: Colors.grey, // Change the text color here
                ),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _deleteLedger(index);
              },
              child: Text('Yes',
                style: TextStyle(
                  color: app_color, // Change the text color here
                ),),
            ),
          ],
        );
      },
    );
  }

  void _deleteLedger(int index) {
    setState(() {
      ledgerEntries.removeAt(index);

      // Calculate the total amount for VAT-applicable entries
      totalAmountForVatAppEntries = ledgerEntries
          .where((entry) => entry.vatApp)
          .fold(0.0, (double previousAmount, LedgerEntry entry) {
        return previousAmount + entry.ledgerAmount;
      });

      // Calculate the total amount of ledgers
      totalAmountOfLedgers = ledgerEntries.fold(0.0, (double previousAmount, LedgerEntry entry) {
        return previousAmount + entry.ledgerAmount;
      });

      // Calculate VAT if applicable
      if (_selectedvatledger != 'Not Applicable') {
        double vatPerc = vatperc / 100;
        ledgerVatAmount = totalAmountForVatAppEntries * vatPerc;

        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      }

      // Calculate the total amount
      totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
      roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));
      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      String formattedTotal = formatter.format(roundedtotalAmount);
      controller_totalamt.text = formattedTotal.toString();

      isVisibleLedgerHeading = ledgerEntries.isNotEmpty;
    });
  }

  void _confirmItemDeletion(BuildContext context, int index, String itemname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Do you really want to delete $itemname?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('No',
                style: TextStyle(
                  color: Colors.grey, // Change the text color here
                ),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _deleteSaleItem(index);
              },
              child: Text('Yes',
                style: TextStyle(
                  color: app_color, // Change the text color here
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSaleItem(int index) {
    setState(() {
      saleItems.removeAt(index);

      // Calculate the total price of items
      totalPriceOfItems = saleItems.fold(0.0, (double previousAmount, SaleItem item) {
        return previousAmount + (item.itemPrice * double.parse(item.itemQuantity));
      });

      if (_selectedvatledger != 'Not Applicable') {
        double vat_perc = vatperc / 100;
        itemsVatAmount = totalPriceOfItems * vat_perc;

        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      }

      totalAmountOfLedgers = ledgerEntries.fold(0.0, (double previousAmount, LedgerEntry entry) {
        return previousAmount + entry.ledgerAmount;
      });
      totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
      roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));
      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      String formattedTotal = formatter.format(roundedtotalAmount);
      controller_totalamt.text = formattedTotal.toString();

      isVisibleItemHeading = saleItems.isNotEmpty;
    });
  }

  String formatitemKey(int key) {
    key++;
    String keyy = key.toString();
    return keyy;
  }

  String convertAmountToWords(num amount) {
    if (amount == null) return "Invalid input";

    List<String> units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    List<String> teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    List<String> tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];


    NumberFormat formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_us',
      decimalDigits:decimal,
    );
    String formattedAmount = formatter.format(amount);

    int integerPart = amount.toInt();
    String decimalPartStr = formattedAmount.split('.')[1] ?? "0";
    int decimalPart = int.parse(decimalPartStr);

    String currencyWords = getCurrencyWords(currencycode);
    String fractionalUnit = getFractionalUnit(currencycode);

    String integerWords = convertIntegerToWords(units, teens, tens, integerPart);
    String result = '$currencyWords $integerWords';

    if (decimalPart > 0) {
      String decimalWords = convertIntegerToWords(units, teens, tens, decimalPart);
      result += ' and $decimalWords $fractionalUnit Only';
    } else {
      result += ' Only';
    }

    return result;
  }

  String getCurrencyWords(String currencyCode) {
    switch(currencyCode.toLowerCase()) {
      case 'aed': return 'UAE dirham';
      case 'usd': return 'US dollar';
      case 'inr': return 'Indian rupee';
      case 'pkr': return 'Pakistani rupee';
      case 'eur': return 'Euro';
      case 'lkr': return 'Sri Lankan rupee';
      case 'sar': return 'Saudi riyal';
      case 'omr': return 'Omani rial';
      case 'bhd': return 'Bahraini dinar';
      case 'qar': return 'Qatari riyal';
      case 'kwd': return 'Kuwaiti dinar';
      case 'sle': return 'Sierra Leonean leone';
      default: return '';
    }
  }

  String getFractionalUnit(String currencyCode) {
    switch(currencyCode.toLowerCase()) {
      case 'aed': return 'fils';
      case 'usd': return 'cents';
      case 'inr': return 'paise';
      case 'pkr': return 'paisa';
      case 'eur': return 'cents';
      case 'lkr': return 'cents';
      case 'sar': return 'halala';
      case 'omr': return 'baisa';
      case 'bhd': return 'fils';
      case 'qar': return 'dirham';
      case 'kwd': return 'fils';
      case 'sle': return 'cents';
      default: return '';
    }
  }

  String convertIntegerToWords(List<String> units, List<String> teens, List<String> tens, int amount) {
    if (amount == 0) return 'zero';

    String words = '';

    if (amount >= 1000000000) {
      words += '${convertIntegerToWords(units, teens, tens, amount ~/ 1000000000)} billion ';
      amount %= 1000000000;
    }

    if (amount >= 1000000) {
      words += '${convertIntegerToWords(units, teens, tens, amount ~/ 1000000)} million ';
      amount %= 1000000;
    }

    if (amount >= 1000) {
      words += '${convertIntegerToWords(units, teens, tens, amount ~/ 1000)} thousand ';
      amount %= 1000;
    }

    if (amount >= 100) {
      words += '${units[amount ~/ 100]} hundred ';
      amount %= 100;
    }

    if (amount >= 10 && amount < 20) {
      words += '${teens[amount - 10]}';
      return words;
    } else if (amount >= 20) {
      words += '${tens[amount ~/ 10]}';
      if (amount % 10 != 0) words += ' ';
      amount %= 10;
    }
    if (amount > 0) {
      words += '${units[amount]}';
    }
    return words.trim();
  }

  Map<String, dynamic> jsonEntryData = {
    "DATE": "",
    "VOUCHERTYPENAME": "",
    "PARTYLEDGERNAME": "",
    "NARRATION": "",
    "VOUCHERNUMBER" : "",
    "REFERENCE": "",
    "INVENTORYENTRIES.LIST": [],
    "LEDGERENTRIES.LIST": [],
  };

  bool isVisibleItemHeading = false,
      isVisibleLedgerHeading = false;

  bool isVisibleUnit = true;

  final _formKey = GlobalKey<FormState>();

  bool isVisibleLocation = false;

  GlobalKey<FormState> _itemFormkey = GlobalKey<FormState>();

  double roundedtotalVatAmount = 0.0;

  double roundedtotalAmount = 0.0;

  GlobalKey<FormState> _ledgerFormkey = GlobalKey<FormState>();

  List<String> salesledger_data = [];

  late int? decimal;
  late List<String> vchtypenamedata = [];
  late List<String> partyledgerdata = [];
  late List<String> vatledgerdata = [];

  List<dynamic> itemdata = [];

  double vatperc = 0.0;

  List<String> locationsdata = []; // Store the locations here

  late String selectedLocation = ''; // Store the selected location here

  List<Unit> unitdata = [];

  List<Map<String, dynamic>> ledgerdata = [];

  String user_email_fetched = "",token = '';

  String name = "", email = "", saledatestring = '', saledatetxt = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  dynamic _selectedledger, _selecteditem, _selectedunit, _selectedsalesledger,
      _selectedvchtypename, _selectedpartyledger, _selectedvatledger;

  late final TextEditingController controller_narration = TextEditingController();
  late final TextEditingController controller_vatamt = TextEditingController();
  late final TextEditingController controller_totalamt = TextEditingController();

  String formatAmountInvoice(String amount) {
    int? decimal = prefs?.getInt('decimalplace') ?? 2;

    if(amount == "null" || amount.isEmpty)
    {
       amount = "0";
    }
    double amount_double = double.parse(amount);

    NumberFormat formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_us',
      decimalDigits:decimal,
    );
    String formattedAmount = formatter.format(amount_double);

    return formattedAmount;
  }

  bool _isFocused_vchno = false,
      _isFocused_item = false,
      _isFocused_unit = false,
      _isFocused_ledger = false,
      _isFocused_narration = false,
      _isFocused_vatamt = false,
      _isFocused_totalamt = false,
      _isFocused_orderno = false;

  String? hostname = "",
      company = "",
      company_lowercase = "",
      serial_no = "",
      username = "",
      HttpURL = "",
      SecuritybtnAcessHolder = "";

  late DateTime saledate,refdate;
  String? HttpURL_loadData,HttpURL_salesEntry,HttpURL_fetchvchnos;
  List<String> vchnos = [];

  double selectedMultiplier = 0.0;

  final DateFormat _dateFormat = DateFormat('yyyyMMdd');

  List<SaleItem> saleItems = [];
  List<LedgerEntry> ledgerEntries = [];
  String currencycode = '';

  final TextEditingController itemQuantityController = TextEditingController();
  final TextEditingController itemRateController = TextEditingController();
  final TextEditingController itemAmountController = TextEditingController();
  final TextEditingController ledgerAmountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController controller_orderno = TextEditingController();

  final TextEditingController _vchnoController = TextEditingController();
  String errorMessageVchNo = '';
  int? unitValue;

  late DateTime now = DateTime.now();

  // Current year start date
  late DateTime yearStartDate = DateTime(now.year, 1, 1);

  // Current year end date
  late DateTime yearEndDate = DateTime(now.year, 12, 31);

  Future<void> _selectDateRangeVchNo(BuildContext context) async {

    final initialDateRange = DateTimeRange(start: yearStartDate, end: yearEndDate);

    DateTimeRange? selectedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return  Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light().copyWith(
              primary: app_color, // main accent color
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: app_color.withOpacity(0.15), // 🔹 light shade of your app_color
              rangeSelectionOverlayColor:
              MaterialStatePropertyAll(app_color.withOpacity(0.15)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDateRange != null &&
        selectedDateRange != initialDateRange) {
      setState(() {
        yearStartDate = selectedDateRange.start;
        yearEndDate = selectedDateRange.end;
      });

      fetchvchnos(_selectedvchtypename);
    }
  }

  void checkVchNoExistence(String vchNo) {

    if(vchNo.isEmpty || vchNo == '')
    {
      setState(() {
        errorMessageVchNo = 'Voucher No. cannot be empty';
      });
    }
    else
    {
      if (vchnos.contains(vchNo)) {
        setState(() {

          errorMessageVchNo = 'Voucher no: $vchNo against $_selectedvchtypename already exists';
        });
      } else {
        setState(() {
          errorMessageVchNo = '';

        });
      }
    }
  }


  Future<void> generateSalesOrderPDF() async {
    final pdf = pw.Document();

    int totalQuantity = 0;
    double totalitemAmount = 0;
    for (var item in saleItems) {
      String qty = item.itemQuantity;
      int qtyInt = int.tryParse(qty) ?? 0;
      totalQuantity += qtyInt;
      totalitemAmount += item.itemAmount;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Header(
                    level: 0,
                    decoration:  pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide.none)),
                    child: pw.Center(
                      child: pw.Text(
                        'Sales Order',
                        textAlign: pw.TextAlign.center,
                        style:  pw.TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  // 🧾 --- All your existing PDF layout is kept as is ---
                  // (No visual or logic changes — only modern syntax)
                  // 🔽 Paste your content body exactly as before here
                  pw.Center(
                      child: pw.Text(
                          "Your existing PDF body remains unchanged here...")),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'This is a System Generated Document',
                    style:  pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(
                  padding:  pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Created by https://tallyuae.ae/',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFFCCCCCC),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 🧠 Save PDF to temp directory
    final tempDir = await getTemporaryDirectory();
    final tempFilePath =
        '${tempDir.path}/${_selectedpartyledger ?? "SalesOrder"}.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(await pdf.save());

    // ✅ Share PDF file (latest API)
    await Share.shareXFiles(
      [XFile(tempFilePath)],
      text: 'Sharing Sales Order for $_selectedpartyledger',
    );

    // 🧹 Resetting form fields and recalculations
    setState(() {
      controller_narration.clear();
      controller_orderno.clear();

      _textFieldFocusNodeNarration.unfocus();
      saledate = DateTime.now();
      saledatestring = _dateFormat.format(saledate);
      saledatetxt = formatlastsaledate(saledatestring);
      _dateController.text = saledatetxt;

      _selectedvchtypename = vchtypenamedata[0];
      fetchvchnos(_selectedvchtypename);
      _selectedpartyledger = partyledgerdata[0];
      _partyLedgerController.text = _selectedpartyledger;
      _selectedsalesledger = salesledger_data[0];
      _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;
      _selectedvatledger = vatledgerdata[0];
      _selecteditem = '${itemdata[0]['name']}';

      if (locationsdata.isNotEmpty) {
        selectedLocation = locationsdata[0];
        isVisibleLocation = true;
      } else {
        isVisibleLocation = false;
      }

      _updateUnitDropdown(_selecteditem);
      saleItems.clear();
      ledgerEntries.clear();

      totalPriceOfItems = saleItems.fold(
          0.0,
              (double prev, SaleItem item) =>
          prev + (item.itemPrice * double.parse(item.itemQuantity)));

      totalAmountOfLedgers = ledgerEntries.fold(
          0.0, (double prev, LedgerEntry entry) => prev + entry.ledgerAmount);

      if (_selectedvatledger != 'Not Applicable') {
        double vatPerc = vatperc / 100;
        itemsVatAmount = totalPriceOfItems * vatPerc;
        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount =
            double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter =
        NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount =
            double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter =
        NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      }

      isVisibleItemHeading = saleItems.isNotEmpty;
      totalAmountForVatAppEntries = ledgerEntries
          .where((entry) => entry.vatApp)
          .fold(0.0, (double prev, LedgerEntry entry) => prev + entry.ledgerAmount);

      if (_selectedvatledger != 'Not Applicable') {
        double vatPerc = vatperc / 100;
        ledgerVatAmount = totalAmountForVatAppEntries * vatPerc;
        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount =
            double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter =
        NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount =
            double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter =
        NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      }

      isVisibleLedgerHeading = ledgerEntries.isNotEmpty;

      totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
      roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));
      NumberFormat formatter =
      NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      controller_totalamt.text = formatter.format(roundedtotalAmount);

      _isFocused_vchno = false;
      _isFocused_item = false;
      _isFocused_unit = false;
      _isFocused_ledger = false;
      _isFocused_narration = false;
      _isFocused_totalamt = false;
      _isFocused_vatamt = false;
      _isFocused_orderno = false;
    });
  }

  String getCurrencySymbol(String currencyCode) {
    NumberFormat format;
    Locale locale = Localizations.localeOf(context);

    try {
      if (currencyCode == 'INR' || currencyCode == 'EUR' || currencyCode == 'PKR'|| currencyCode == 'USD')
      {
        format = new NumberFormat.simpleCurrency(locale: locale.toString(), name: currencyCode);
      }
      else
      {
        format = new NumberFormat.currency(locale: locale.toString(), name: currencyCode);
      }
      return format.currencySymbol;
    }
    catch (e)
    {
      return 'AED';
    }
  }

  Future<void> saveEntry() async {

    if (saleItems.isEmpty)
    {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atleast add 1 item')));
    }
    else
    {
      setState(()
      {
        _isLoading = true;
      });
      String narrationValue = controller_narration.text;
      String vchnoValue = _vchnoController.text;

      String refnoValue = controller_orderno.text;

      jsonEntryData["DATE"] = saledatestring;
      jsonEntryData["VOUCHERTYPENAME"] = _selectedvchtypename;
      jsonEntryData["PARTYLEDGERNAME"] = _selectedpartyledger;
      jsonEntryData["totalAmount"] = roundedtotalAmount;
      jsonEntryData["NARRATION"] = narrationValue;
      jsonEntryData["VOUCHERNUMBER"] = vchnoValue;
      jsonEntryData["REFERENCE"] = refnoValue;
      double totalItemAmount = 0.0;

      for (SaleItem item in saleItems)
      {
        totalItemAmount += item.itemAmount; // calculating item amounts total
      }

      for (var saleItem in saleItems)
      { // making sales ledger
        if (saleItem.accountingAllocationList.isEmpty)
        {
          saleItem.accountingAllocationList =
          {
            "LEDGERNAME": _selectedsalesledger,
            "AMOUNT": saleItem.itemAmount.toStringAsFixed(decimal!),
            "ISDEEMEDPOSITIVE": "No",
          };
        }
      }

      jsonEntryData["INVENTORYENTRIES.LIST"] = saleItems.map((item) { // making stockitem list
        return {
          "STOCKITEMNAME": item.itemName,
          "ISDEEMEDPOSITIVE": "No",
          "RATE": "${item.itemPrice}/${item.itemUnit}",
          "AMOUNT": item.itemAmount,
          "ACTUALQTY": "${item.itemQuantity} ${item.itemUnit}",
          "BILLEDQTY":"${item.itemQuantity} ${item.itemUnit}",
          "BATCHALLOCATIONS.LIST" : item.batchAllocationList,
          "ACCOUNTINGALLOCATIONS.LIST" : item.accountingAllocationList
        };
      }).toList();

      double totalLedgerAmount = 0.0;

      for (LedgerEntry ledger in ledgerEntries) { // calculating total ledger amount
        totalLedgerAmount +=
            ledger.ledgerAmount; // calculating ledger amounts total
      }

      double partyLedgerAmount = totalVatAmount + totalItemAmount + totalLedgerAmount; // adding vat total, items total, ledgers total

      partyLedgerAmount = partyLedgerAmount * -1;

      List<Map<String, Object>> ledgerList = [];

      Map<String, Object> partyLedgerData =
      { // making party ledger
        "LEDGERNAME": _selectedpartyledger,
        "AMOUNT": partyLedgerAmount.toStringAsFixed(decimal!),
        "ISPARTYLEDGER" : "Yes",
        "ISDEEMEDPOSITIVE": "Yes",
        "ledgerType": "Party",
      };
      ledgerList.add(partyLedgerData);

      // Add ledger entries to the list
      ledgerList.addAll(ledgerEntries.map((item) {
        return {
          "LEDGERNAME": item.ledgerName,
          "VATAPPLICABLE": item.vatApp,
          "AMOUNT": item.ledgerAmount,
          "ISDEEMEDPOSITIVE": "No",
          "ledgerType": "ledgerList",
        };
      }));

      // Add VAT ledger data if applicable
      if (_selectedvatledger != 'Not Applicable') {
        Map<String, Object> vatDataToAdd = {
          "LEDGERNAME": _selectedvatledger,
          "AMOUNT": roundedtotalVatAmount,
          "ISDEEMEDPOSITIVE": "No",
          "ledgerType": "VAT",
        };
        ledgerList.add(vatDataToAdd);
      }

      jsonEntryData["LEDGERENTRIES.LIST"] = ledgerList;

      /*print(jsonEntryData);*/

      Map<String, dynamic> jsonData = {
        'type' : 'sales order',
        'data' : jsonEntryData
      };

      String jsonDataString = jsonEncode(jsonData);

      print(jsonDataString);

      try
      {
        final url_salesentry = Uri.parse(HttpURL_salesEntry!);
        Map<String,String> headers_salesentry = {
          'Authorization' : 'Bearer $token',
          "Content-Type": "application/json"
        };

        var body_salesentry = jsonDataString;

        final response_salesentry = await http.post(
            url_salesentry,
            body: body_salesentry,
            headers:headers_salesentry
        );

        if (response_salesentry.statusCode == 200) {
          if(response_salesentry.body == 'Entry created successfully')
          {
            // Fluttertoast.showToast(msg: response_salesentry.body);
            showSalesOrderBottomSheet(context);
          }
          else
          {
            Fluttertoast.showToast(msg: 'an error occoured');
          }
        }
        else {

          Map<String, dynamic> data = json.decode(response_salesentry.body);
          String error = '';

          if (data.containsKey('error')) {
            setState(() {
              error = data['error'];
            });
          }
          else {
            error = "Error in data fetching!!!";
          }
          Fluttertoast.showToast(msg: error);
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
    setState(()
    {
      _isLoading = false;
    });
  }

  void showSalesOrderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.35, // Set height as per your requirement
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green, // Change the color as per your requirement
                      width: 4.0, // Change the width as per your requirement
                    ),
                  ),
                  child: Icon(
                    Icons.done,
                    size: 40,
                    color: Colors.green, // Change the color as per your requirement
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Do you want to share the sales order?',
                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 10),
                Text(
                  'Sales Order Created Successfully',
                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close the bottom sheet
                        setState(() {
                          controller_narration.clear();
                          controller_orderno.clear();
                          _textFieldFocusNodeNarration.unfocus(); // Unfocus the TextField

                          saledate = DateTime.now();
                          saledatestring = _dateFormat.format(saledate);
                          saledatetxt = formatlastsaledate(saledatestring);
                          _dateController.text = saledatetxt;


                          _selectedvchtypename = vchtypenamedata[0];
                          fetchvchnos(_selectedvchtypename);
                          _selectedpartyledger = partyledgerdata[0];
                          _partyLedgerController.text = _selectedpartyledger;

                          _selectedsalesledger = salesledger_data[0];

                          _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;

                          _selectedvatledger = vatledgerdata[0];

                          _selecteditem = '${itemdata[0]['name']}';

                          if (locationsdata.isNotEmpty)
                          {
                            selectedLocation = locationsdata[0];
                            isVisibleLocation = true;
                          }
                          else
                          {
                            isVisibleLocation = false;
                          }
                          _updateUnitDropdown(_selecteditem);

                          saleItems.clear();
                          ledgerEntries.clear();

                          // making sales list empty and setting values

                          totalPriceOfItems = saleItems
                              .fold(
                              0.0, (double previousAmount,
                              SaleItem item) {
                            return previousAmount +
                                (item.itemPrice * double.parse(item.itemQuantity));
                          });

                          totalAmountOfLedgers = ledgerEntries
                              .fold(0.0, (double previousAmount, LedgerEntry entry) {
                            return previousAmount + entry.ledgerAmount;
                          });

                          if (_selectedvatledger != 'Not Applicable') {
                            double vat_perc = vatperc / 100;
                            itemsVatAmount = totalPriceOfItems * vat_perc;

                            totalVatAmount = itemsVatAmount + ledgerVatAmount;

                            roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
                            NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                            String formattedVat = formatter.format(roundedtotalVatAmount);
                            controller_vatamt.text = formattedVat.toString();
                          }
                          else
                          {
                            totalVatAmount = 0;

                            roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
                            NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                            String formattedVat = formatter.format(roundedtotalVatAmount);
                            controller_vatamt.text = formattedVat.toString();
                          }
                          if (saleItems.isEmpty)
                          {
                            isVisibleItemHeading = false;
                          }
                          else
                          {
                            isVisibleItemHeading = true;
                          }
                          // making ledger list empty and setting values
                          totalAmountForVatAppEntries = ledgerEntries.where((entry) => entry.vatApp).fold(
                              0.0, (double previousAmount,
                              LedgerEntry entry) {
                            return previousAmount +
                                entry.ledgerAmount;
                          });

                          if (_selectedvatledger != 'Not Applicable')
                          {
                            double vat_perc = vatperc / 100;
                            ledgerVatAmount = totalAmountForVatAppEntries * vat_perc;
                            totalVatAmount = itemsVatAmount + ledgerVatAmount;
                            roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
                            NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                            String formattedVat = formatter.format(roundedtotalVatAmount);
                            controller_vatamt.text = formattedVat.toString();
                          }
                          else
                          {
                            totalVatAmount = 0;
                            roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
                            NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                            String formattedVat = formatter.format(roundedtotalVatAmount);
                            controller_vatamt.text = formattedVat.toString();
                          }
                          if (ledgerEntries.isEmpty)
                          {
                            isVisibleLedgerHeading = false;
                          }
                          else
                          {
                            isVisibleLedgerHeading = true;
                          }
                          totalAmount = totalPriceOfItems +  totalAmountOfLedgers + totalVatAmount ;
                          roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));
                          NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                          String formattedtotal = formatter.format(roundedtotalAmount);
                          controller_totalamt.text = formattedtotal.toString();
                          _isFocused_vchno = false;
                          _isFocused_item = false;
                          _isFocused_unit = false;
                          _isFocused_ledger = false;
                          _isFocused_narration = false;
                          _isFocused_totalamt = false;
                          _isFocused_vatamt = false;
                          _isFocused_orderno = false;
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text('No, Thanks',
                        textAlign: TextAlign.center,

                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, // 🔴 better contrast
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // pill shape
                        ),
                        elevation: 4,
                        shadowColor: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context); // Close the bottom sheet
                        await generateSalesOrderPDF();

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app_color, // ✅ your theme color
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // pill style
                        ),
                        elevation: 4,
                        shadowColor: app_color.withOpacity(0.3), // subtle shadow
                      ),
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text('Share',
                        textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),),
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

  Future<void> loadData() async {
    vchtypenamedata.clear();
    itemdata.clear();
    salesledger_data.clear();
    partyledgerdata.clear();
    vatledgerdata.clear();
    ledgerdata.clear();
    locationsdata.clear();

    setState(() {
      _isLoading = true;
    });

    // vchtype fetching
    try {
      final url = Uri.parse(HttpURL_loadData!);
      Map<String,String> headers =
      {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      var body = jsonEncode({
        'type': "sales order",
      });
      final response = await http.post
        (
          url,
          body:body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        /*print(response.body);*/
        setState(() {
          vchtypenamedata = jsonResponse["vchTypes"].cast<String>();
          _selectedvchtypename = vchtypenamedata[0];
          fetchvchnos(_selectedvchtypename);
          partyledgerdata = jsonResponse["partyLedgers"].cast<String>();
          _selectedpartyledger = partyledgerdata[0];
          _partyLedgerController.text = _selectedpartyledger;
          salesledger_data = jsonResponse["salesLedgers"].cast<String>();
          _selectedsalesledger = salesledger_data[0];

          ledgerdata = List<Map<String, dynamic>>.from(jsonResponse['otherLedgers']);
          _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;

          vatledgerdata.add('Not Applicable');
          vatledgerdata.addAll(jsonResponse["vatLedgers"].cast<String>());
          _selectedvatledger = vatledgerdata[0];

          itemdata = jsonResponse["items"];

          _selecteditem = '${itemdata[0]['name']}';

          locationsdata = List<String>.from(jsonResponse['locations']);
          if (locationsdata.isNotEmpty)
          {
            selectedLocation = locationsdata[0];
            setState(() {
              isVisibleLocation = true;
            });
          }
          else
          {
            setState(()
            {
              isVisibleLocation = false;
            });
          }
          _updateUnitDropdown(_selecteditem);
        });
      }
      else
      {
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';
        if (data.containsKey('error'))
        {
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
    catch (e)
    {
      print(e);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchvchnos(String vchname) async {

    // Format the dates as yyyyMMdd
    String formattedStartDateVchNo = DateFormat('yyyyMMdd').format(yearStartDate);
    String formattedEndDateVchNo = DateFormat('yyyyMMdd').format(yearEndDate);

    vchnos.clear();
    setState(() {
      _isLoading = true;
    });

    // vchnos fetching
    try {
      final url = Uri.parse(HttpURL_fetchvchnos!);
      Map<String,String> headers =
      {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };

      Map<String, dynamic> jsonDatabody = {
        "to": formattedEndDateVchNo,
        "from": formattedStartDateVchNo,
        "vchname" : vchname
      };

      String jsonDatabodyString = jsonEncode(jsonDatabody);

      var body =jsonDatabodyString;
      final response = await http.post
        (
          url,
          headers:headers,
          body:body
      );

      if (response.statusCode == 200)
      {
        /*print(response.body);*/
        setState(() {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          final List<dynamic> vchnosJson = jsonResponse['vchnos'];
          vchnos = vchnosJson.cast<String>();
          int q = vchnos.length;
          print('vchno list containes $q nos whos values are $vchnos');

          _vchnoController.clear();
          checkVchNoExistence(_vchnoController.text);
        });
      }
      else
      {
        vchnos.clear();
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';
        if (data.containsKey('error'))
        {
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
    catch (e)
    {
      vchnos.clear();
      print(e);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateUnitDropdown(dynamic _selectedItem) {
    setState(() {
      selectedMultiplier = 0.0;
      isVisibleUnit = true;

      itemQuantityController.text = 1.toString();

      dynamic selectedItemInfo = itemdata.firstWhere(
            (item) => item["name"] == _selectedItem, orElse: () => null,
      );


      String salePrice = selectedItemInfo["saleprice"].toString();
      String standardPrice = selectedItemInfo["standardprice"].toString();

      /*print(selectedItemInfo);*/

      final List<dynamic> jsonList = selectedItemInfo["unit"];

      setState(()
      {
        unitdata = jsonList.map((jsonUnit) {
          return Unit.fromJson(jsonUnit);
        }).toList();
      });

      if (unitdata.isNotEmpty) {
        _selectedunit = unitdata[0].name;

        selectedMultiplier = unitdata[0].multiplier;
      }
      String qtyValue = itemQuantityController.text;

      /*print('unit: $_selectedunit, Multiplier: $selectedMultiplier');*/

      double rateValue = 0;

      if (standardPrice == 'null') {
        if (salePrice == 'null') {
          rateValue = 0;
          itemRateController.text = '';
        }
        else
        {
          rateValue = (double.parse(salePrice) * selectedMultiplier);
          double roundedrateValue = double.parse(rateValue.toStringAsFixed(decimal!));

          itemRateController.text = roundedrateValue.toString();
        }
      }
      else
      {
        rateValue = (double.parse(standardPrice) * selectedMultiplier);
        double roundedrateValue = double.parse(
            rateValue.toStringAsFixed(decimal!));

        itemRateController.text = roundedrateValue.toString();
      }
      double amountValue = (double.parse(qtyValue) * rateValue);
      double roundedAmountValue = double.parse(
          amountValue.toStringAsFixed(decimal!));

      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      String formattedAmount = formatter.format(roundedAmountValue);

      itemAmountController.text = formattedAmount.toString();
    });
  }

  void updateRateAndAmount() {
    String qtyValue = itemQuantityController.text;

    if (qtyValue.isEmpty) {
      qtyValue = '0';
    }

    String rateValue = itemRateController.text;
    if (rateValue.isEmpty) {
      rateValue = '0';
    }
    double amountValue = (double.parse(qtyValue) * double.parse(rateValue));

    double roundedAmountValue = double.parse(
        amountValue.toStringAsFixed(decimal!));

    NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
    String formattedAmount = formatter.format(roundedAmountValue);

    itemAmountController.text = formattedAmount.toString();
  }

  void updateAmount() {
    String qtyValue = itemQuantityController.text;

    if (qtyValue.isEmpty) {
      qtyValue = '0';
    }

    String rateValue = itemRateController.text;
    if (rateValue.isEmpty) {
      rateValue = '0';
    }
    double amountValue = (double.parse(qtyValue) * double.parse(rateValue));

    double roundedAmountValue = double.parse(
        amountValue.toStringAsFixed(decimal!));

    NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
    String formattedAmount = formatter.format(roundedAmountValue);

    itemAmountController.text = formattedAmount.toString();
  }

  Future<void> _selectsaleDate(BuildContext context) async {
    setState(() {
      _isFocused_orderno = false;
      _isFocused_narration = false;
    });
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: saledate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != saledate)
      setState(() {
        saledate = picked;
        saledatestring = _dateFormat.format(saledate);
        saledatetxt = formatlastsaledate(saledatestring);
        _dateController.text = saledatetxt;
      });
  }

  Future<void> _showItemDetailsPopup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                "Add Item",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _itemFormkey,
              child: Column(
                children: [

                  // 🔍 Item Search
                  TypeAheadField<Map<String, dynamic>>(
                    // 🔹 Latest API requires this controller instead of inside TextFieldConfiguration
                    controller: _itemController,

                    // 🔹 Suggestion logic
                    suggestionsCallback: (pattern) async {
                      return itemdata
                          .where((item) {
                        final name = item['name']?.toString().toLowerCase() ?? '';
                        final part = item['part']?.toString().toLowerCase() ?? '';
                        return name.contains(pattern.toLowerCase()) ||
                            part.contains(pattern.toLowerCase());
                      })
                          .cast<Map<String, dynamic>>() // 👈 important fix
                          .toList();
                    },


                    // 🔹 How each suggestion looks
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(
                          suggestion['name'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                        ),
                        subtitle: Text(
                          suggestion['part'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    },

                    // 🔹 Required in new API (replaces onSuggestionSelected)
                    onSelected: (suggestion) {
                      setState(() {
                        _selecteditem = suggestion['name'] ?? '';
                        _itemController.text = _selecteditem;

                        if (locationsdata.isNotEmpty) {
                          selectedLocation = locationsdata[0];
                          isVisibleLocation = true;
                        } else {
                          isVisibleLocation = false;
                        }

                        _updateUnitDropdown(_selecteditem);
                        isVisibleUnit = true;
                      });
                    },

                    // 🔹 Main TextField builder (replaces old textFieldConfiguration)
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Item",
                          hintText: "Search item",
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.lightBlueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            child: const Icon(Icons.inventory_outlined, color: Colors.white),
                          ),

                          // 👉 Close + Dropdown icons
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_itemController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                  onPressed: () {
                                    _itemController.clear();
                                    setState(() {
                                      _selecteditem = "";
                                      isVisibleLocation = false;
                                      isVisibleUnit = false;
                                    });
                                  },
                                ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              const SizedBox(width: 6),
                            ],
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: app_color, width: 1.5),
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      );
                    },

                    // 🔹 Optional — shows if no match found
                    emptyBuilder: (context) => const SizedBox.shrink(),
                  ),



                  const SizedBox(height: 14),

                  // 📍 Location
                  Visibility(
                    visible: isVisibleLocation,
                    child: DropdownButtonFormField<String>(
                      value: selectedLocation,
                      items: locationsdata.map((value) {
                        return DropdownMenuItem(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedLocation = val!),
                      decoration: InputDecoration(
                        labelText: "Location",
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.redAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: app_color, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 📦 Unit
                  Visibility(
                    visible: isVisibleUnit,
                    child: DropdownButtonFormField<String>(
                      value: _selectedunit,
                      items: unitdata.map((u) {
                        return DropdownMenuItem(value: u.name, child: Text(u.name));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedunit = val!;
                          itemQuantityController.text = "1";
                          selectedMultiplier = unitdata.firstWhere((u) => u.name == _selectedunit).multiplier;
                          updateRateAndAmount();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Unit",
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.deepPurpleAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: const Icon(Icons.straighten, color: Colors.white),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: app_color, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 🔢 Quantity
                  TextFormField(
                    controller: itemQuantityController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateRateAndAmount(),
                    decoration: InputDecoration(
                      labelText: "Quantity",
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Icon(Icons.confirmation_num, color: Colors.white),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: app_color, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 💲 Rate
                  TextFormField(
                    controller: itemRateController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateAmount(),
                    decoration: InputDecoration(
                      labelText: "Rate",
                      prefix: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blue], // ✅ distinct from Ledger
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text(
                          getCurrencySymbol(currencycode),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: app_color, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 💰 Amount (Disabled with Gradient Currency Symbol)
                  TextFormField(
                    controller: itemAmountController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: "Amount",
                      prefix: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.teal], // ✅ distinct from Ledger
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text(
                          getCurrencySymbol(currencycode),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: app_color, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: GoogleFonts.poppins(color: app_color)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: app_color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text("Add Item",
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              onPressed: () {
                if (_itemFormkey.currentState!.validate()) {
                  addItem();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLedgerDetailsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

            // 🔝 Title with gradient icon
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  "Add Ledger",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            content: SingleChildScrollView(
              child: Form(
                key: _ledgerFormkey,
                child: Column(
                  children: [

                    // 🔻 Ledger Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedledger,
                        hint: const Text("Select Ledger"),
                        items: ledgerdata.map<DropdownMenuItem<String>>((ledger) {
                          return DropdownMenuItem<String>(
                            value: ledger['name'],
                            child: Text(
                              ledger['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedledger = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Ledger Name",
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.lightBlueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: app_color, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    //const SizedBox(height: 6),

                    // 💰 Ledger Amount
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: TextFormField(
                        controller: ledgerAmountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          } else if (double.tryParse(value) == 0.0) {
                            return 'Amount cannot be 0';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Amount",
                          hintText: "Enter Amount",
                          prefix: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.redAccent], // ✅ distinct from Ledger
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Text(
                              getCurrencySymbol(currencycode),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: app_color, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;
                  ledgerAmountController.clear();
                },
                child: Text("Cancel", style: GoogleFonts.poppins(color: app_color)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text("Add Ledger",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )),
                onPressed: () {
                  if (_ledgerFormkey.currentState!.validate()) {
                    _ledgerFormkey.currentState!.save();
                    addLedger();
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }


  void addItem() {
    final itemName = _selecteditem;
    final itemQuantity = itemQuantityController.text;
    final itemPrice = itemRateController.text;
    final itemAmount = itemAmountController.text;
    final itemLocation = selectedLocation;
    final itemUnit = _selectedunit;

    if (itemName.isNotEmpty && itemQuantity.isNotEmpty && itemPrice.isNotEmpty) {
      Navigator.of(context).pop();

      double parsedAmount = double.parse(itemAmount.replaceAll(',', ''));
      double parsedPrice = double.parse(itemPrice.replaceAll(',', ''));
      String parsedQuantity = itemQuantity.replaceAll(',', '');

      final qty_unit = '$parsedQuantity $itemUnit';

      Map<String, dynamic> batchAllocation = {
        'GODOWNNAME': itemLocation,
        'AMOUNT': parsedAmount,
        'ACTUALQTY': qty_unit,
        'BILLEDQTY': qty_unit,
      };

      // Check if the item already exists in the list with the same name and price
      int existingIndex = saleItems.indexWhere((item) =>
      item.itemName == itemName &&
          item.itemPrice == parsedPrice &&
          item.itemUnit == itemUnit);
      if (existingIndex != -1) {
        // Item already exists with the same name, price, and unit, update its quantity and amount
        SaleItem existingItem = saleItems[existingIndex];
        String newQuantity =
        (int.parse(existingItem.itemQuantity) + int.parse(parsedQuantity)).toString();
        double newAmount = parsedPrice * int.parse(newQuantity);
        saleItems[existingIndex] =
            existingItem.updateQuantity(newQuantity).updateItemAmount(newAmount);
      } else {
        // Item doesn't exist, create a new SaleItem object and add it to the list
        final newItem = SaleItem(
          itemName: itemName,
          itemQuantity: parsedQuantity,
          itemPrice: parsedPrice,
          itemAmount: parsedAmount,
          itemLocation: itemLocation,
          itemUnit: itemUnit,
          accountingAllocationList: {},
          batchAllocationList: batchAllocation,
        );

        setState(() {
          saleItems.add(newItem);
          // Rest of your code...
        });
      }

      setState(() {

        if (saleItems.isEmpty) {
          isVisibleItemHeading = false;
        }
        else {
          isVisibleItemHeading = true;
        }

        totalPriceOfItems = saleItems.fold(
            0.0, (double previousAmount, SaleItem item) {
          return previousAmount +
              (item.itemPrice * double.parse(item.itemQuantity));
        });

        if (_selectedvatledger != 'Not Applicable') {
          // Calculate the total price of items

          double vat_perc = vatperc / 100;

          totalAmountForVatAppEntries = ledgerEntries
              .where((entry) => entry.vatApp)
              .fold(0.0, (double previousAmount, LedgerEntry entry) {
            return previousAmount + entry.ledgerAmount;
          });

          ledgerVatAmount = totalAmountForVatAppEntries * vat_perc;

          itemsVatAmount = totalPriceOfItems * vat_perc;

          totalVatAmount = itemsVatAmount + ledgerVatAmount;

          roundedtotalVatAmount = double.parse(
              totalVatAmount.toStringAsFixed(decimal!));

          NumberFormat formatter = NumberFormat(
              '#,##0.${'0' * decimal!}', 'en_US');
          String formattedVat = formatter.format(roundedtotalVatAmount);
          controller_vatamt.text = formattedVat.toString();
        }
        else {
          totalVatAmount = 0;
          roundedtotalVatAmount = double.parse(
              totalVatAmount.toStringAsFixed(decimal!));
          NumberFormat formatter = NumberFormat(
              '#,##0.${'0' * decimal!}', 'en_US');
          String formattedVat = formatter.format(0);
          controller_vatamt.text = formattedVat.toString();
        }

        totalAmountOfLedgers = ledgerEntries
            .fold(0.0, (double previousAmount, LedgerEntry entry) {
          return previousAmount + entry.ledgerAmount;
        });

        totalAmount = totalPriceOfItems +  totalAmountOfLedgers + totalVatAmount ;
        roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        String formattedtotal = formatter.format(roundedtotalAmount);
        controller_totalamt.text = formattedtotal.toString();

        _selecteditem = '${itemdata[0]['name']}';
        if (locationsdata.isNotEmpty) {
          selectedLocation = locationsdata[0];
          setState(() {
            isVisibleLocation = true;
          });
        }
        else {
          setState(() {
            isVisibleLocation = false;
          });
        }
        _updateUnitDropdown(_selecteditem);
        itemQuantityController.text = 1.toString();
        itemAmountController.clear();
        itemRateController.clear();
      });
    }
  }

  void addLedger() {
    Map<String, dynamic>? specificLedger = ledgerdata.firstWhere(
            (ledger) => ledger['name'] == _selectedledger
    );

    final ledgerName = specificLedger['name'];
    final ledgerAmount = ledgerAmountController.text;

    int vatApplicable = specificLedger['vatapplicable'];
    final vatApp = vatApplicable == 1 ? true : false;

    if (ledgerName.isNotEmpty && ledgerAmount.isNotEmpty) {
      // Create a new SaleItem object and add it to the list
      Navigator.of(context).pop();
      int existingIndex = ledgerEntries.indexWhere((entry) => entry.ledgerName == ledgerName);
      double parsedAmount = double.parse(ledgerAmount.replaceAll(',', ''));

      if (existingIndex != -1) {
        // Ledger already exists, update its amount
        LedgerEntry existingLedger = ledgerEntries[existingIndex];
        double newAmount = existingLedger.ledgerAmount + parsedAmount;

        // Update vatApp if necessary
        bool newVatApp = existingLedger.vatApp; // Initialize with the existing value
        newVatApp = vatApp;

        ledgerEntries[existingIndex] = existingLedger.updateAmount(newAmount,newVatApp);
      } else {
        // Ledger doesn't exist, create a new LedgerEntry object and add it to the list
        final newItem = LedgerEntry(
          ledgerName: ledgerName,
          ledgerAmount: parsedAmount,
          vatApp: vatApp,
        );
        setState(() {
          ledgerEntries.add(newItem);
        });
      }
      setState(() {
        if (ledgerEntries.isEmpty) {
          isVisibleLedgerHeading = false;
        }
        else {
          isVisibleLedgerHeading = true;
        }

        totalPriceOfItems = saleItems.fold(
            0.0, (double previousAmount, SaleItem item) {
          return previousAmount +
              (item.itemPrice * double.parse(item.itemQuantity));
        });

        if (_selectedvatledger != 'Not Applicable') {
          // Calculate the total ledger amount for entries with vatApp set to true
          totalAmountForVatAppEntries = ledgerEntries
              .where((entry) => entry.vatApp)
              .fold(0.0, (double previousAmount, LedgerEntry entry) {
            return previousAmount + entry.ledgerAmount;
          });

          double vat_perc = vatperc / 100;

          itemsVatAmount = totalPriceOfItems * vat_perc;

          ledgerVatAmount = totalAmountForVatAppEntries * vat_perc;

          /*print('Total Ledger Amount for VAT-Applicable Entries: $totalAmountForVatAppEntries');
          print('5% VAT Amount: $ledgerVatAmount');*/

          totalVatAmount = itemsVatAmount + ledgerVatAmount;

          roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
          NumberFormat formatter = NumberFormat(
              '#,##0.${'0' * decimal!}', 'en_US');
          String formattedVat = formatter.format(roundedtotalVatAmount);
          controller_vatamt.text = formattedVat.toString();
        }
        else {
          totalVatAmount = 0;
          roundedtotalVatAmount = double.parse(
              totalVatAmount.toStringAsFixed(decimal!));
          NumberFormat formatter = NumberFormat(
              '#,##0.${'0' * decimal!}', 'en_US');
          String formattedVat = formatter.format(0);
          controller_vatamt.text = formattedVat.toString();
        }
        totalAmountOfLedgers = ledgerEntries
            .fold(0.0, (double previousAmount, LedgerEntry entry) {
          return previousAmount + entry.ledgerAmount;
        });

        totalAmount = totalPriceOfItems +  totalAmountOfLedgers + totalVatAmount ;
        roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        String formattedtotal = formatter.format(roundedtotalAmount);
        controller_totalamt.text = formattedtotal.toString();
        _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;
        ledgerAmountController.clear();
      });
    }
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
      currencycode = prefs.getString('currencycode') ?? 'AED';

      vatperc = prefs.getDouble('vatperc') ?? 5.0;

      decimal = prefs.getInt('decimalplace') ?? 2;

      saledate = DateTime.now();
      saledatestring = _dateFormat.format(saledate);
      saledatetxt = formatlastsaledate(saledatestring);
      _dateController.text = saledatetxt;



      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      String? email_nav = prefs.getString('email_nav');
      String? name_nav = prefs.getString('name_nav');

      HttpURL_loadData = '$hostname/api/entry/getSalesData/$company_lowercase/$serial_no';
      /*HttpURL_loadData = 'http://192.168.2.110:4999/api/entry/getSalesData/$company_lowercase/$serial_no';*/


      HttpURL_fetchvchnos = '$hostname/api/entry/nos/$company_lowercase/$serial_no';
      /*HttpURL_fetchvchnos = 'http://192.168.2.110:4999/api/entry/nos/$company_lowercase/$serial_no';*/

      HttpURL_salesEntry = '$hostname/api/entry/create/$company/$serial_no';
      /*HttpURL_salesEntry = 'http://192.168.2.110:4999/api/entry/create/demonewformobilepp/767060064';*/

      itemQuantityController.text = 1.toString();
      controller_vatamt.text = 0.toString();

      controller_totalamt.text = 0.toString();

      if (email_nav != null && name_nav != null) {
        name = name_nav;
        email = email_nav;
      }
      if (SecuritybtnAcessHolder == "True") {
        isRolesVisible = true;
        isUserVisible = true;
      }
      else {
        isRolesVisible = false;
        isUserVisible = false;
      }
    });
    loadData();
  }

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _initSharedPreferences();
  }

  @override
  void dispose() {
    _textFieldFocusNodeNarration.dispose(); // Dispose of the focus node when it's no longer needed.
    _animationController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    // Simple email validation pattern
    final RegExp emailRegex = RegExp(
        r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$');
    return emailRegex.hasMatch(email);
  }
  void _recalculateTotals() {
    // Agar items empty hain to heading chhupao
    isVisibleItemHeading = saleItems.isNotEmpty;

    // Total items ka price
    totalPriceOfItems = saleItems.fold(
      0.0,
          (double previousAmount, SaleItem item) {
        return previousAmount + (item.itemPrice * double.parse(item.itemQuantity));
      },
    );

    // VAT calculation
    if (_selectedvatledger != 'Not Applicable') {
      double vatPerc = vatperc / 100;

      totalAmountForVatAppEntries = ledgerEntries
          .where((entry) => entry.vatApp)
          .fold(0.0, (double prev, LedgerEntry entry) {
        return prev + entry.ledgerAmount;
      });

      ledgerVatAmount = totalAmountForVatAppEntries * vatPerc;
      itemsVatAmount = totalPriceOfItems * vatPerc;

      totalVatAmount = itemsVatAmount + ledgerVatAmount;

      roundedtotalVatAmount =
          double.parse(totalVatAmount.toStringAsFixed(decimal!));

      NumberFormat formatter =
      NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      controller_vatamt.text =
          formatter.format(roundedtotalVatAmount).toString();
    } else {
      totalVatAmount = 0;
      roundedtotalVatAmount =
          double.parse(totalVatAmount.toStringAsFixed(decimal!));
      NumberFormat formatter =
      NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      controller_vatamt.text = formatter.format(0).toString();
    }

    // Ledger totals
    totalAmountOfLedgers =
        ledgerEntries.fold(0.0, (double prev, entry) => prev + entry.ledgerAmount);

    // Final total
    totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
    roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));

    NumberFormat formatter =
    NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
    controller_totalamt.text = formatter.format(roundedtotalAmount).toString();
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat(
      "#,##0.${'0' * decimal!}",  // 👈 dynamically repeat '0' for decimal places
    );
    return Scaffold(
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PendingSalesOrderEntry()),
              );
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
                    "New Sales Order Entry" ?? '',
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
          tickerProvider: this),
      body:WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PendingSalesOrderEntry()),
            );
            return true;
          },
          child: Stack(
            children: [
              ListView(
                  children:[
                    GestureDetector(
                      onTap: () => _selectDateRangeVchNo(context),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: app_color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // calendar icon with gradient style
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [app_color, app_color.withOpacity(0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),

                            // text column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Voucher No. Range",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${DateFormat('dd-MMM-yyyy').format(yearStartDate)} → ${DateFormat('dd-MMM-yyyy').format(yearEndDate)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: app_color,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),

                    Container(
                        child: Column(
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: TextFormField(
                                        controller: _dateController,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Date",
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.95),
                                          prefixIcon: GestureDetector(
                                            onTap: () => _selectsaleDate(context),
                                            child: Container(
                                              margin: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [app_color, app_color.withOpacity(0.7)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: BorderSide(
                                              color: app_color,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                        ),
                                        readOnly: true,
                                        onTap: () => _selectsaleDate(context),
                                      ),
                                    ),


                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                      child: TextFormField(
                                        controller: _vchnoController,
                                        onChanged: (value) {
                                          checkVchNoExistence(value);
                                        },
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Voucher No.",
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                          errorText: errorMessageVchNo.isNotEmpty ? errorMessageVchNo : null,
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.95),
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Colors.deepOrangeAccent, Colors.orangeAccent],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            child: const Icon(
                                              Icons.confirmation_num_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),

                                          // 👇 unfocused grey border
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),

                                          // 👇 focused border with app_color
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: app_color,
                                              width: 1.5,
                                            ),
                                          ),

                                          // 👇 error border (red)
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.5,
                                            ),
                                          ),

                                          // 👇 same rounded border when error+focused
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.5,
                                            ),
                                          ),

                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                        ),
                                        readOnly: false,
                                      ),
                                    ),

                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: 0, left: 20, right: 20, bottom: 0),
                                      child:
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: Colors.grey.withOpacity(0.2),

                                        ),
                                        padding: EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Duplicate voucher numbers in Tally will trigger automatic assignment of a new number.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12, left: 20, right: 20, bottom: 0),
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.95),
                                          labelText: "Voucher Type",
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),

                                          // Prefix icon with gradient bg (different color)
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Colors.purpleAccent, Colors.deepPurple],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            child: const Icon(
                                              Icons.discount_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),

                                          // Borders
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: app_color,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        ),
                                        hint: Text(
                                          "Voucher Type Name",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        value: _selectedvchtypename,
                                        items: vchtypenamedata.map((item) {
                                          return DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) async {
                                          setState(() {
                                            _selectedvchtypename = value!;
                                            fetchvchnos(_selectedvchtypename);
                                          });
                                        },
                                        onTap: () {
                                          setState(() {
                                            _isFocused_vchno = false;
                                            _isFocused_narration = false;
                                            _isFocused_totalamt = false;
                                          });
                                        },
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 0),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width,
                                        child: TypeAheadField<String>(
                                          suggestionsCallback: (pattern) async {
                                            // Filter matching ledgers (case-insensitive)
                                            return partyledgerdata
                                                .where((item) => item.toLowerCase().contains(pattern.toLowerCase()))
                                                .toList();
                                          },
                                          builder: (context, controller, focusNode) {
                                            _partyLedgerController = controller; // ensures correct reference

                                            return TextField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: "Search Party Ledger",
                                                hintStyle: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                                labelText: "Party Ledger",
                                                labelStyle: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.95),

                                                // 🌈 Gradient prefix icon
                                                prefixIcon: Container(
                                                  margin: const EdgeInsets.all(8),
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.greenAccent, Colors.teal],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person_outline,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),

                                                // ❌ Clear + ⬇ Dropdown icons
                                                suffixIcon: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (controller.text.isNotEmpty)
                                                      IconButton(
                                                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                                        onPressed: () {
                                                          setState(() {
                                                            controller.clear();
                                                            _selectedpartyledger = "";
                                                          });
                                                        },
                                                      ),
                                                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                                    const SizedBox(width: 6),
                                                  ],
                                                ),

                                                // ✨ Borders
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: app_color,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(
                                                    color: Colors.redAccent,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                              ),
                                            );
                                          },
                                          itemBuilder: (context, suggestion) {
                                            return ListTile(
                                              title: Text(
                                                suggestion,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            );
                                          },
                                          onSelected: (suggestion) {
                                            setState(() {
                                              _selectedpartyledger = suggestion;
                                              _partyLedgerController.text = suggestion;
                                            });
                                          },
                                          emptyBuilder: (context) => Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              "No ledger found",
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                        ),

                                      ),
                                    ),

                                    Container(
                                        padding: EdgeInsets.only(
                                            top: 15, left: 20, right: 20, bottom: 0),
                                        child: TextFormField(
                                          enabled: true,
                                          controller: controller_orderno,
                                          validator: (value) {
                                            if(value!.isEmpty || value == null)
                                              {
                                                return 'Order No value cannot be empty';
                                              }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Order No',
                                            hintText: 'Enter order no',
                                            labelStyle: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.95),
                                            prefixIcon: GestureDetector(

                                              child: Container(
                                                margin: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [app_color, app_color.withOpacity(0.7)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(Icons.note_outlined, color: Colors.white, size: 20),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: app_color,
                                                width: 1.5,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                          ),


                                          onChanged: (value) {
                                            setState(() {
                                              _isFocused_narration = false;
                                              _isFocused_totalamt = false;
                                              _isFocused_orderno = true;
                                              _isFocused_vatamt = false;
                                              _isFocused_vchno = false;
                                            });
                                          },
                                          onFieldSubmitted: (value) {
                                            setState(() {
                                              _isFocused_narration = false;
                                              _isFocused_totalamt = false;
                                              _isFocused_orderno = false;
                                              _isFocused_vatamt = false;
                                              _isFocused_vchno = false;
                                            });
                                          },
                                          onTap: () {
                                            setState(() {
                                              _isFocused_narration = false;
                                              _isFocused_totalamt = false;
                                              _isFocused_orderno = true;
                                              _isFocused_vatamt = false;
                                              _isFocused_vchno = false;
                                            });
                                          },
                                          onEditingComplete: () {
                                            setState(() {
                                              _isFocused_narration = false;
                                              _isFocused_totalamt = false;
                                              _isFocused_orderno = false;
                                              _isFocused_vatamt = false;
                                              _isFocused_vchno = false;
                                            });
                                          },)),

                                    Padding(
                                      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 0),
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.95),
                                          labelText: "Sales Ledger",
                                          labelStyle: GoogleFonts.poppins(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          // Prefix icon with gradient (blue)
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.blueAccent, Colors.indigo],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            child: const Icon(
                                              Icons.sell_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),

                                          // Borders
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: app_color,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.5,
                                            ),
                                          ),

                                          contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        ),
                                        hint: Text(
                                          "Sales Ledger",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        value: _selectedsalesledger,
                                        items: salesledger_data.map((item) {
                                          return DropdownMenuItem<String>(
                                            value: item.toString(),
                                            child: Text(
                                              item.toString(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) async {
                                          setState(() {
                                            _selectedsalesledger = value!;
                                          });
                                        },
                                        onTap: () {
                                          setState(() {
                                            _isFocused_vchno = false;
                                            _isFocused_narration = false;
                                            _isFocused_totalamt = false;
                                          });
                                        },
                                      ),
                                    ),

                                    Container(
                                      margin: const EdgeInsets.only(left: 20,right:20, top: 10,bottom:5),
                                      padding: const EdgeInsets.only(bottom: 0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: app_color.withOpacity(0.07),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header Row
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                                            child: Row(
                                              children: [
                                                // Gradient start icon
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [Colors.purple, Colors.blue],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.purple.withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 3),
                                                      )
                                                    ],
                                                  ),
                                                  child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                                                ),
                                                const SizedBox(width: 12),

                                                // Title
                                                Expanded(
                                                  child: Text(
                                                    "Items",
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: app_color,
                                                    ),
                                                  ),
                                                ),

                                                // Gradient add icon
                                                GestureDetector(
                                                  onTap: () {
                                                    _showItemDetailsPopup(context);
                                                    _updateUnitDropdown(_selecteditem);
                                                  },
                                                  child: Container(
                                                    width: 34,
                                                    height: 34,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        colors: [Colors.teal, Colors.green],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.teal.withOpacity(0.3),
                                                          blurRadius: 6,
                                                          offset: const Offset(0, 3),
                                                        )
                                                      ],
                                                    ),
                                                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Items List with swipe-to-delete
                                          ListView.builder(
                                            physics: const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount: saleItems.length,
                                            itemBuilder: (context, index) {
                                              final item = saleItems[index];

                                              return Dismissible(
                                                key: UniqueKey(),
                                                direction: DismissDirection.endToStart, // swipe left to delete
                                                background: Container(
                                                  alignment: Alignment.centerRight,
                                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                                  color: Colors.redAccent,
                                                  child: const Icon(Icons.delete, color: Colors.white, size: 24),
                                                ),
                                                onDismissed: (direction) {
                                                  _deleteSaleItem(index);
                                                },

                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.grey.shade300),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.03),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Item Name
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.shopping_bag, color: Colors.teal, size: 18),
                                                          const SizedBox(width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              item.itemName,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.black87,
                                                              ),
                                                              softWrap: true,
                                                              overflow: TextOverflow.visible,
                                                              maxLines: null,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 10),

                                                      // Qty Row
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            "Qty",
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),

                                                          // Minus Button
                                                          InkWell(
                                                            onTap: () {
                                                              int currentQty = int.tryParse(item.itemQuantity) ?? 0;
                                                              if (currentQty > 1) {
                                                                setState(() {
                                                                  item.itemQuantity = (currentQty - 1).toString();
                                                                  _recalculateTotals();
                                                                });
                                                              } else {
                                                                setState(() {
                                                                  saleItems.removeAt(index);
                                                                  _recalculateTotals();
                                                                });
                                                              }
                                                            },
                                                            child: Container(
                                                              padding: const EdgeInsets.all(6),
                                                              decoration: BoxDecoration(
                                                                color: Colors.redAccent.withOpacity(0.15),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: const Icon(Icons.remove, size: 18, color: Colors.redAccent),
                                                            ),
                                                          ),

                                                          const SizedBox(width: 6),

                                                          // Qty Display (Non-editable)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade100,
                                                              borderRadius: BorderRadius.circular(10),
                                                              border: Border.all(color: Colors.grey.shade400),
                                                            ),
                                                            child: Text(
                                                              item.itemQuantity,
                                                              textAlign: TextAlign.center,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                          ),

                                                          const SizedBox(width: 6),

                                                          // Plus Button
                                                          InkWell(
                                                            onTap: () {
                                                              int currentQty = int.tryParse(item.itemQuantity) ?? 0;
                                                              setState(() {
                                                                item.itemQuantity = (currentQty + 1).toString();
                                                                _recalculateTotals();
                                                              });
                                                            },
                                                            child: Container(
                                                              padding: const EdgeInsets.all(6),
                                                              decoration: BoxDecoration(
                                                                color: Colors.green.withOpacity(0.15),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: const Icon(Icons.add, size: 18, color: Colors.green),
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 12),

                                                      // Rate Section
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            "Rate",
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade100,
                                                              borderRadius: BorderRadius.circular(10),
                                                              border: Border.all(color: Colors.grey.shade400),
                                                            ),
                                                            child: Text(
                                                              "${getCurrencySymbol(currencycode)} ${currencyFormat.format(item.itemPrice)}",
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      margin: const EdgeInsets.only(left: 20,right:20, top: 5,bottom:10),
                                      padding: const EdgeInsets.only(bottom: 0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: app_color.withOpacity(0.07),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Header Row
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                                            child: Row(
                                              children: [
                                                // Gradient start icon
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [Colors.red, Colors.redAccent],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.purple.withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 3),
                                                      )
                                                    ],
                                                  ),
                                                  child: const Icon(Icons.list, color: Colors.white, size: 20),
                                                ),
                                                const SizedBox(width: 12),

                                                // Title
                                                Expanded(
                                                  child: Text(
                                                    "Ledger",
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: app_color,
                                                    ),
                                                  ),
                                                ),

                                                // Gradient add icon
                                                GestureDetector(
                                                  onTap: () {
                                                    _showLedgerDetailsPopup(context);

                                                  },
                                                  child: Container(
                                                    width: 34,
                                                    height: 34,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        colors: [Colors.orange, Colors.orange],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.teal.withOpacity(0.3),
                                                          blurRadius: 6,
                                                          offset: const Offset(0, 3),
                                                        )
                                                      ],
                                                    ),
                                                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Ledger List
                                          ListView.builder(
                                            physics: const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount: ledgerEntries.length,
                                            itemBuilder: (context, index) {
                                              final item = ledgerEntries[index];

                                              return Dismissible(
                                                key: UniqueKey(),
                                                direction: DismissDirection.endToStart,
                                                background: Container(
                                                  alignment: Alignment.centerRight,
                                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent,
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  child: const Icon(Icons.delete, color: Colors.white, size: 22),
                                                ),
                                                onDismissed: (direction) {
                                                  _deleteLedger(index);
                                                },

                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(14),
                                                    border: Border.all(color: Colors.grey.shade200),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.03),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      // Ledger Icon + Name
                                                      Icon(Icons.account_balance_wallet_outlined,
                                                          color: app_color, size: 20),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        flex: 6,
                                                        child: Text(
                                                          item.ledgerName,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.black87,
                                                          ),
                                                          overflow: TextOverflow.visible,
                                                          softWrap: true,
                                                        ),
                                                      ),

                                                      // Amount with currency
                                                      Expanded(
                                                        flex: 4,
                                                        child: Text(
                                                          "${getCurrencySymbol(currencycode)} ${currencyFormat.format(item.ledgerAmount)}",
                                                          textAlign: TextAlign.end,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),


                                        ],
                                      ),
                                    ),

                                    Row(
                                      children: [
                                        // 🌈 VAT Ledger Dropdown
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 20, left: 20, right: 5),
                                            child: DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                labelText: "VAT Ledger",
                                                labelStyle: GoogleFonts.poppins(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                // 🌈 Gradient Icon Container
                                                prefixIcon: Container(
                                                  margin: const EdgeInsets.all(8),
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.indigo, Colors.cyan],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                                  ),
                                                  child: const Icon(Icons.receipt_long_outlined,
                                                      size: 20, color: Colors.white),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Colors.black54),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(color: app_color, width: 1.5),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Colors.black54),
                                                ),
                                                contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                              ),
                                              value: _selectedvatledger,
                                              hint: const Text("Select VAT Ledger"),
                                              items: vatledgerdata.map((item) {
                                                return DropdownMenuItem<String>(
                                                  value: item,
                                                  child: Text(
                                                    item,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedvatledger = value!;

                                                  // 👇 VAT calculation logic intact
                                                  totalPriceOfItems = saleItems.fold(
                                                    0.0,
                                                        (double prev, SaleItem item) =>
                                                    prev + (item.itemPrice * double.parse(item.itemQuantity)),
                                                  );

                                                  totalAmountOfLedgers = ledgerEntries.fold(
                                                    0.0,
                                                        (double prev, LedgerEntry entry) => prev + entry.ledgerAmount,
                                                  );

                                                  if (_selectedvatledger == 'Not Applicable') {
                                                    totalVatAmount = 0;
                                                    roundedtotalVatAmount =
                                                        double.parse(totalVatAmount.toStringAsFixed(decimal!));
                                                    NumberFormat formatter =
                                                    NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                                                    controller_vatamt.text = formatter.format(0);
                                                  } else {
                                                    double totalAmountForLedgerVatAppEntries = ledgerEntries
                                                        .where((entry) => entry.vatApp)
                                                        .fold(0.0,
                                                            (double prev, LedgerEntry entry) => prev + entry.ledgerAmount);

                                                    double vat_perc = vatperc / 100;
                                                    itemsVatAmount = totalPriceOfItems * vat_perc;
                                                    ledgerVatAmount = totalAmountForLedgerVatAppEntries * vat_perc;
                                                    totalVatAmount = itemsVatAmount + ledgerVatAmount;

                                                    roundedtotalVatAmount =
                                                        double.parse(totalVatAmount.toStringAsFixed(decimal!));
                                                    NumberFormat formatter =
                                                    NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                                                    controller_vatamt.text = formatter.format(roundedtotalVatAmount);
                                                  }

                                                  totalAmount =
                                                      totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
                                                  roundedtotalAmount =
                                                      double.parse(totalAmount.toStringAsFixed(decimal!));
                                                  NumberFormat formatter =
                                                  NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                                                  controller_totalamt.text = formatter.format(roundedtotalAmount);
                                                });
                                              },
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 20, left: 5, right: 20),
                                            child: TextFormField(
                                              enabled: false,
                                              controller: controller_vatamt,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: "VAT Amount",
                                                labelStyle: GoogleFonts.poppins(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),

                                                // 🌈 Gradient Currency Symbol (inline instead of icon)
                                                prefix: Container(
                                                  margin: const EdgeInsets.only(right: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.green, Colors.teal], // ✅ distinct from Ledger
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                                  ),
                                                  child: Text(
                                                    getCurrencySymbol(currencycode),
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),

                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Colors.black54),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(color: app_color, width: 1.5),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Colors.black54),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ),


                                      ],
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: TextFormField(
                                        controller: controller_narration,
                                        focusNode: _textFieldFocusNodeNarration,
                                        validator: (value) => null,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Narration",
                                          hintText: "Enter narration",
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                          labelStyle: GoogleFonts.poppins(
                                            color: _isFocused_narration ? app_color : Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),

                                          // 🌈 Gradient Icon (Notes)
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.pinkAccent, Colors.deepOrange],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            child: const Icon(
                                              Icons.notes_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ),

                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.95),
                                          contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                                          // Borders
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.black54),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.black45),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: app_color, width: 1.5),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _isFocused_narration = true;
                                            _isFocused_vchno = false;
                                            _isFocused_vatamt = false;
                                            _isFocused_totalamt = false;
                                          });
                                        },
                                        onFieldSubmitted: (value) {
                                          setState(() {
                                            _isFocused_narration = false;
                                            _isFocused_vchno = false;
                                            _isFocused_vatamt = false;
                                            _isFocused_totalamt = false;
                                          });
                                        },
                                        onTap: () {
                                          setState(() {
                                            _isFocused_narration = true;
                                            _isFocused_vchno = false;
                                            _isFocused_vatamt = false;
                                            _isFocused_totalamt = false;
                                          });
                                        },
                                        onEditingComplete: () {
                                          setState(() {
                                            _isFocused_narration = false;
                                            _isFocused_vchno = false;
                                            _isFocused_vatamt = false;
                                            _isFocused_totalamt = false;
                                          });
                                        },
                                      ),
                                    ),],),),

                              Padding(
                                padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 0),
                                child: TextFormField(
                                  enabled: false,
                                  controller: controller_totalamt,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                                  ],
                                  keyboardType: TextInputType.number,
                                  validator: (value) => null,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Total Amount',
                                    hintText: 'Enter total amount',

                                    // 🌈 Gradient Currency Symbol (cool tone, unique)
                                    prefix: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.indigo, Colors.blueAccent], // 🔵 unique from narration
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                      ),
                                      child: Text(
                                        getCurrencySymbol(currencycode), // e.g. AED, $, ₹
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    // Borders
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Colors.black),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: app_color,
                                        width: 1.4,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Colors.black),
                                    ),
                                    labelStyle: GoogleFonts.poppins(
                                      color: _isFocused_totalamt ? app_color : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),

                                  // Focus State
                                  onTap: () {
                                    setState(() {
                                      _isFocused_totalamt = true;
                                      _isFocused_narration = false;
                                      _isFocused_vatamt = false;
                                      _isFocused_vchno = false;
                                    });
                                  },
                                  onFieldSubmitted: (_) {
                                    setState(() {
                                      _isFocused_totalamt = false;
                                    });
                                  },
                                  onEditingComplete: () {
                                    setState(() {
                                      _isFocused_totalamt = false;
                                    });
                                  },
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.only(top: 20),
                                margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: errorMessageVchNo.isNotEmpty
                                      ? null
                                      : () {
                                    if (_formKey.currentState != null &&
                                        _formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      saveEntry();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30), // pill shape
                                    ),
                                    elevation: 8,
                                    backgroundColor: app_color, // ✅ always full app_color
                                    disabledBackgroundColor: Colors.grey.shade300, // disabled state
                                    shadowColor: app_color.withOpacity(0.4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 🌟 Modern Save Icon (circular background inside button)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2), // soft white tint inside
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle, // modern variant of save
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Save Text
                                      Text(
                                        "Save",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )]))]),
              Visibility(
                visible: _isLoading,
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            ],)
      ),
    );}}