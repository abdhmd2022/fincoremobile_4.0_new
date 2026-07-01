import 'dart:convert';
import 'dart:io';
import 'package:FincoreGo/Items.dart';
import 'package:FincoreGo/PendingSalesEntry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'theme_controller.dart';
import 'package:FincoreGo/widgets/app_bottom_nav.dart';

class SalesRegistration extends StatefulWidget {
  const SalesRegistration({Key? key}) : super(key: key);
  @override
  _SalesRegistrationPageState createState() => _SalesRegistrationPageState();
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

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      name: json['name'],
      multiplier: double.parse(json['multiplier']),
    );
  }
}

class LedgerEntry {
  final String ledgerName;
  final double ledgerAmount;
  final bool vatApp;

  LedgerEntry({
    required this.ledgerName,
    required this.ledgerAmount,
    required this.vatApp,
  });

  LedgerEntry updateAmount(double newAmount, bool vatApp) {
    return LedgerEntry(
      ledgerName: this.ledgerName,
      ledgerAmount: newAmount,
      vatApp: vatApp,
    );
  }
}

class _SalesRegistrationPageState extends State<SalesRegistration>
    with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false;

  bool isVchEditable = false; // state variable

  TextEditingController _itemController = TextEditingController();
  TextEditingController _partyLedgerController = TextEditingController();

  String? selectedPartyLedgerPriceLevel;
  String? selectedItemMasterId;

  bool isPriceLevelLoading = false;
  bool isRateFieldEnabled = true;
  bool showRateField = true;

  bool isVoucherTypeLocked = false;
  bool isSalesLedgerLocked = false;

  String startfrom = '';

  Map<String, String?> partyLedgerPriceLevelMap = {};

  double ledgerVatAmount = 0,
      itemsVatAmount = 0,
      totalVatAmount = 0,
      totalAmount = 0;

  double totalPriceOfItems = 0,
      totalAmountForVatAppEntries = 0,
      totalAmountOfLedgers = 0;
  final FocusNode _textFieldFocusNodeNarration = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _animation;

  void resetItemDialogFields() {
    _selecteditem = null;
    selectedItemMasterId = null;
    _selectedunit = null;

    _itemController.clear();
    itemQuantityController.clear();
    itemRateController.clear();
    itemAmountController.clear();

    selectedMultiplier = 0.0;
    selectedLocation = '';

    isVisibleLocation = false;
    isVisibleUnit = false;
    isPriceLevelLoading = false;
    isRateFieldEnabled = true;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: app_color, width: 1.5),
      ),
    );
  }

  InputDecoration _currencyDecoration({
    required String label,
    required bool enabled,
  }) {
    return InputDecoration(
      labelText: label,
      filled: !enabled,
      fillColor: !enabled
          ? (Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Colors.grey.shade100)
          : null,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: enabled
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      prefix: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? const [Colors.blue, Colors.blue]
                : const [Colors.grey, Colors.grey],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: app_color, width: 1.5),
      ),
    );
  }

  Future<void> fetchPriceLevelDetailsForSelectedItem(
    StateSetter setStateDialog,
  ) async {
    if (serial_no == null ||
        serial_no!.trim().isEmpty ||
        !vanSalesSerialNo.contains(serial_no!.trim())) {
      return;
    }

    if (selectedItemMasterId == null || selectedItemMasterId!.trim().isEmpty) {
      debugPrint(
        'Price level API skipped: selected item masterid is null/empty',
      );
      return;
    }

    if (selectedPartyLedgerPriceLevel == null ||
        selectedPartyLedgerPriceLevel.toString().trim().isEmpty) {
      setStateDialog(() {
        isRateFieldEnabled = true;
        showRateField = true;
      });
      return;
    }

    setStateDialog(() {
      isPriceLevelLoading = true;
    });

    try {
      final String selectedDate = saledatestring.isNotEmpty
          ? saledatestring
          : DateFormat('yyyyMMdd').format(DateTime.now());

      final Uri url =
          Uri.parse(
            '$hostname/api/item/getPriceLevelDetails/$company_lowercase/$serial_no',
          ).replace(
            queryParameters: {
              'date': selectedDate,
              'itemId': selectedItemMasterId!,
              'name': selectedPartyLedgerPriceLevel!,
            },
          );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is List && decodedResponse.isNotEmpty) {
          final Map<String, dynamic> priceData = Map<String, dynamic>.from(
            decodedResponse.first,
          );

          final double apiRate =
              double.tryParse(priceData['rate']?.toString() ?? '0') ?? 0.0;

          final double qty =
              double.tryParse(
                itemQuantityController.text.trim().isEmpty
                    ? '1'
                    : itemQuantityController.text.trim(),
              ) ??
              1.0;

          final double amount = apiRate * qty;

          setStateDialog(() {
            itemRateController.text = apiRate.toStringAsFixed(decimal ?? 2);
            itemAmountController.text = amount.toStringAsFixed(decimal ?? 2);
            isRateFieldEnabled = false;
            showRateField = true;
          });
        } else {
          setStateDialog(() {
            itemRateController.clear();
            itemAmountController.clear();
            isRateFieldEnabled = true;
            showRateField = true;
          });
        }
      } else {
        setStateDialog(() {
          isRateFieldEnabled = true;
          showRateField = true;
        });
      }
    } catch (e) {
      setStateDialog(() {
        isRateFieldEnabled = true;
        showRateField = true;
      });
    } finally {
      setStateDialog(() {
        isPriceLevelLoading = false;
      });
    }
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
      totalAmountOfLedgers = ledgerEntries.fold(0.0, (
        double previousAmount,
        LedgerEntry entry,
      ) {
        return previousAmount + entry.ledgerAmount;
      });

      // Calculate VAT if applicable
      if (_selectedvatledger != 'Not Applicable') {
        double vatPerc = vatperc / 100;
        ledgerVatAmount = totalAmountForVatAppEntries * vatPerc;

        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
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

  void _deleteSaleItem(int index) {
    setState(() {
      saleItems.removeAt(index);

      // Calculate the total price of items
      totalPriceOfItems = saleItems.fold(0.0, (
        double previousAmount,
        SaleItem item,
      ) {
        return previousAmount +
            (double.parse(item.itemPrice.toStringAsFixed(decimal!)) *
                double.parse(item.itemQuantity));
      });

      if (_selectedvatledger != 'Not Applicable') {
        double vat_perc = vatperc / 100;
        itemsVatAmount = double.parse(
          (totalPriceOfItems * vat_perc).toStringAsFixed(decimal!),
        );
        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      }

      totalAmountOfLedgers = ledgerEntries.fold(0.0, (
        double previousAmount,
        LedgerEntry entry,
      ) {
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

    List<String> units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    List<String> teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    List<String> tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    NumberFormat formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_us',
      decimalDigits: decimal,
    );
    String formattedAmount = formatter.format(amount);

    int integerPart = amount.toInt();
    String decimalPartStr = formattedAmount.split('.')[1] ?? "0";
    int decimalPart = int.parse(decimalPartStr);

    String currencyWords = getCurrencyWords(currencycode);
    String fractionalUnit = getFractionalUnit(currencycode);

    String integerWords = convertIntegerToWords(
      units,
      teens,
      tens,
      integerPart,
    );
    String result = '$currencyWords $integerWords';

    if (decimalPart > 0) {
      String decimalWords = convertIntegerToWords(
        units,
        teens,
        tens,
        decimalPart,
      );
      result += ' and $decimalWords $fractionalUnit Only';
    } else {
      result += ' Only';
    }

    return result;
  }

  String getCurrencyWords(String currencyCode) {
    switch (currencyCode.toLowerCase()) {
      case 'aed':
        return 'UAE dirham';
      case 'usd':
        return 'US dollar';
      case 'inr':
        return 'Indian rupee';
      case 'pkr':
        return 'Pakistani rupee';
      case 'eur':
        return 'Euro';
      case 'lkr':
        return 'Sri Lankan rupee';
      case 'sar':
        return 'Saudi riyal';
      case 'omr':
        return 'Omani rial';
      case 'bhd':
        return 'Bahraini dinar';
      case 'qar':
        return 'Qatari riyal';
      case 'kwd':
        return 'Kuwaiti dinar';
      case 'sle':
        return 'Sierra Leonean leone';
      default:
        return '';
    }
  }

  String getFractionalUnit(String currencyCode) {
    switch (currencyCode.toLowerCase()) {
      case 'aed':
        return 'fils';
      case 'usd':
        return 'cents';
      case 'inr':
        return 'paise';
      case 'pkr':
        return 'paisa';
      case 'eur':
        return 'cents';
      case 'lkr':
        return 'cents';
      case 'sar':
        return 'halala';
      case 'omr':
        return 'baisa';
      case 'bhd':
        return 'fils';
      case 'qar':
        return 'dirham';
      case 'kwd':
        return 'fils';
      case 'sle':
        return 'cents';
      default:
        return '';
    }
  }

  String convertIntegerToWords(
    List<String> units,
    List<String> teens,
    List<String> tens,
    int amount,
  ) {
    if (amount == 0) return 'zero';

    String words = '';

    if (amount >= 1000000000) {
      words +=
          '${convertIntegerToWords(units, teens, tens, amount ~/ 1000000000)} billion ';
      amount %= 1000000000;
    }

    if (amount >= 1000000) {
      words +=
          '${convertIntegerToWords(units, teens, tens, amount ~/ 1000000)} million ';
      amount %= 1000000;
    }

    if (amount >= 1000) {
      words +=
          '${convertIntegerToWords(units, teens, tens, amount ~/ 1000)} thousand ';
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
    "VOUCHERNUMBER": "",
    "REFERENCE": "",
    "REFERENCEDATE": "",
    "INVENTORYENTRIES.LIST": [],
    "LEDGERENTRIES.LIST": [],
  };

  bool isVisibleItemHeading = false, isVisibleLedgerHeading = false;

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

  String user_email_fetched = "", token = '';

  String name = "",
      email = "",
      saledatestring = '',
      saledatetxt = '',
      refdatestring = '',
      refdatetxt = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  dynamic _selectedledger,
      _selecteditem,
      _selectedunit,
      _selectedsalesledger,
      _selectedvchtypename,
      _selectedpartyledger,
      _selectedvatledger;

  late final TextEditingController controller_narration =
      TextEditingController();
  late final TextEditingController controller_vatamt = TextEditingController();
  late final TextEditingController controller_totalamt =
      TextEditingController();

  String formatAmountInvoice(String amount) {
    int? decimal = prefs?.getInt('decimalplace') ?? 2;

    if (amount == "null" || amount.isEmpty) {
      amount = "0";
    }
    double amount_double = double.parse(amount);

    NumberFormat formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_us',
      decimalDigits: decimal,
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
      _isFocused_refno = false;

  String? hostname = "",
      company = "",
      company_lowercase = "",
      serial_no = "",
      username = "",
      HttpURL = "",
      SecuritybtnAcessHolder = "";

  late DateTime saledate, refdate;
  String? HttpURL_loadData,
      HttpURL_salesEntry,
      HttpURL_fetchvchnos,
      HttpURL_loadLedgerData;
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
  final TextEditingController controller_refno = TextEditingController();
  final TextEditingController _refdateController = TextEditingController();

  final TextEditingController _vchnoController = TextEditingController();
  String errorMessageVchNo = '';
  int? unitValue;

  late DateTime now = DateTime.now();

  // Current year start date
  late DateTime yearStartDate = DateTime(now.year, 1, 1);

  // Current year end date
  late DateTime yearEndDate = DateTime(now.year, 12, 31);

  Future<void> _selectDateRangeVchNo(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: yearStartDate,
      end: yearEndDate,
    );

    DateTimeRange? selectedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: app_color, // main accent color
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: app_color.withOpacity(
                0.15,
              ), // 🔹 light shade of your app_color
              rangeSelectionOverlayColor: MaterialStatePropertyAll(
                app_color.withOpacity(0.15),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDateRange != null && selectedDateRange != initialDateRange) {
      setState(() {
        yearStartDate = selectedDateRange.start;
        yearEndDate = selectedDateRange.end;
      });

      fetchvchnos(_selectedvchtypename);
    }
  }

  void checkVchNoExistence(String vchNo) {
    if (vchNo.isEmpty || vchNo == '') {
      setState(() {
        errorMessageVchNo = 'Voucher No. cannot be empty';
      });
    } else {
      if (vchnos.contains(vchNo)) {
        setState(() {
          errorMessageVchNo =
              'Voucher no: $vchNo against $_selectedvchtypename already exists';
        });
      } else {
        setState(() {
          errorMessageVchNo = '';
        });
      }
    }
  }

  String generateNextVchNo(List<String> vchnos) {
    if (vchnos.isEmpty) return "1";

    Map<String, List<Map<String, dynamic>>> patternGroups = {};

    for (String vch in vchnos) {
      List<RegExpMatch> matches = RegExp(r'\d+').allMatches(vch).toList();

      if (matches.isNotEmpty) {
        RegExpMatch selectedMatch = matches.last;

        // 🔥 Ignore year like 2026
        if (matches.length > 1) {
          for (int i = matches.length - 1; i >= 0; i--) {
            String val = matches[i].group(0)!;
            int num = int.tryParse(val) ?? 0;

            if (!(val.length == 4 && num >= 2000 && num <= 2099)) {
              selectedMatch = matches[i];
              break;
            }
          }
        }

        String numberPart = selectedMatch.group(0)!;
        int number = int.tryParse(numberPart) ?? 0;

        String prefix = vch.substring(0, selectedMatch.start);
        String suffix = vch.substring(selectedMatch.end);

        String patternKey = prefix + "#" + suffix;

        patternGroups.putIfAbsent(patternKey, () => []);

        bool exists = patternGroups[patternKey]!.any(
          (e) => e["number"] == number,
        );

        if (!exists) {
          patternGroups[patternKey]!.add({
            "original": vch,
            "number": number,
            "length": numberPart.length,
          });
        }
      }
    }

    if (patternGroups.isEmpty) {
      return vchnos.last + "1";
    }

    // ✅ Dominant pattern
    String selectedPattern = patternGroups.entries
        .reduce((a, b) => a.value.length > b.value.length ? a : b)
        .key;

    List<Map<String, dynamic>> selectedList = patternGroups[selectedPattern]!;

    // 🔥 STEP 1: Extract & sort numbers
    List<int> numbers = selectedList.map((e) => e["number"] as int).toList();
    numbers = numbers.toSet().toList();

    numbers.sort();

    int length = selectedList.first["length"];

    // 🔥 STEP 2: Find missing number (gap)
    int expected = numbers.first;

    int nextNumber = numbers.last + 1; // fallback

    for (int num in numbers) {
      if (num != expected) {
        nextNumber = expected;
        break;
      }
      expected++;
    }

    // 🔥 STEP 3: Format number
    String newNumber = nextNumber.toString().padLeft(length, '0');

    // reconstruct
    List<String> parts = selectedPattern.split("#");
    String prefix = parts[0];
    String suffix = parts[1];

    return prefix + newNumber + suffix;
  }

  Future<void> generateInvoicePDF(
    String trn,
    String address,
    String emirate,
    String country,
  ) async {
    final pdf = pw.Document();

    int totalQuantity = 0;
    double totalitemAmount = 0;
    for (var item in saleItems) {
      String qty = item.itemQuantity;
      int qty_int = int.parse(qty);
      totalQuantity += qty_int;

      totalitemAmount += double.parse(
        item.itemAmount.toStringAsFixed(decimal!),
      );
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Tax Invoice Heading
                  pw.Header(
                    level: 0,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide.none),
                    ),

                    child: pw.Center(
                      child: pw.Text(
                        'Tax Invoice',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),

                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(width: 1.0),
                        top: pw.BorderSide(width: 1.0),
                        left: pw.BorderSide(width: 1.0),
                        bottom: pw.BorderSide(width: 1.0),
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        // Left column
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: pw.EdgeInsets.only(
                              left: 5,
                              top: 2,
                              bottom: 2,
                              right: 5,
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [
                                pw.Text(company!),

                                if (company_address != "null" ||
                                    company_address != "Not Available")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Text(company_address),
                                    ],
                                  ),

                                if (company_emirate != "null" ||
                                    company_emirate != "Not Available")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Row(
                                        children: [
                                          pw.Text("Emirate "),

                                          pw.SizedBox(width: 20),
                                          pw.Text(company_emirate),
                                        ],
                                      ),
                                    ],
                                  ),

                                if (company_country != "null" ||
                                    company_country != "Not Available")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Row(
                                        children: [
                                          pw.Text("Country "),

                                          pw.SizedBox(width: 20),
                                          pw.Text(company_country),
                                        ],
                                      ),
                                    ],
                                  ),

                                if (company_trn != "null" ||
                                    company_trn != "Not Available")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Row(
                                        children: [
                                          pw.Text("TRN "),

                                          pw.SizedBox(width: 35),
                                          pw.Text(company_trn),
                                        ],
                                      ),
                                    ],
                                  ),

                                pw.SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),

                        // Right column
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(width: 1.0),
                                top: pw.BorderSide(width: 1.0),

                                bottom: pw.BorderSide(width: 1.0),
                                left: pw.BorderSide(width: 1.0),
                              ),
                            ),

                            child: pw.Column(
                              children: [
                                // first row right column
                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(width: 1),
                                  ),
                                  child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.start,
                                    children: [
                                      // invoice no
                                      pw.Expanded(
                                        child: pw.Container(
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border(
                                              right: pw.BorderSide(width: 1),
                                            ),
                                          ),
                                          padding: pw.EdgeInsets.only(
                                            left: 5,
                                            top: 5,
                                            bottom: 5,
                                            right: 5,
                                          ),

                                          child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                pw.MainAxisAlignment.start,
                                            children: [
                                              pw.Text('Invoice No:'),
                                              pw.SizedBox(height: 2),
                                              pw.Text(_vchnoController.text),
                                            ],
                                          ),
                                        ),
                                      ),

                                      pw.Expanded(
                                        child: pw.Container(
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border(
                                              left: pw.BorderSide(width: 1),
                                            ),
                                          ),
                                          padding: pw.EdgeInsets.only(
                                            left: 5,
                                            top: 5,
                                            bottom: 5,
                                            right: 5,
                                          ),
                                          child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                pw.MainAxisAlignment.start,
                                            children: [
                                              pw.Text('Dated:'),
                                              pw.SizedBox(height: 2),
                                              pw.Text(
                                                formatlastsaledate(
                                                  saledatestring,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                //second row right column
                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(width: 1),
                                  ),
                                  child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Container(
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border(
                                              right: pw.BorderSide(width: 1),
                                            ),
                                          ),
                                          padding: pw.EdgeInsets.only(
                                            left: 5,
                                            top: 5,
                                            bottom: 5,
                                            right: 5,
                                          ),

                                          child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                pw.MainAxisAlignment.start,

                                            children: [
                                              pw.Text('Reference No:'),
                                              pw.SizedBox(height: 2),
                                              pw.Text(controller_refno.text),
                                            ],
                                          ),
                                        ),
                                      ),

                                      pw.Expanded(
                                        child: pw.Container(
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border(
                                              left: pw.BorderSide(width: 1),
                                            ),
                                          ),
                                          padding: pw.EdgeInsets.only(
                                            left: 5,
                                            top: 5,
                                            bottom: 5,
                                            right: 5,
                                          ),
                                          child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                pw.MainAxisAlignment.start,
                                            children: [
                                              pw.Text('Reference Date:'),
                                              pw.SizedBox(height: 2),
                                              pw.Text(
                                                formatlastsaledate(
                                                  refdatestring,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // third row right column
                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      top: pw.BorderSide(width: 1),
                                      left: pw.BorderSide(width: 1),
                                    ),
                                  ),
                                  child: pw.Row(
                                    children: [
                                      pw.Expanded(
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.only(
                                            left: 5,
                                            top: 5,
                                            bottom: 5,
                                            right: 5,
                                          ),

                                          child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.Text('Remarks:'),
                                              pw.SizedBox(height: 2),
                                              pw.Text(
                                                controller_narration.text,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      /* pw.Expanded(child: pw.Container(
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border(left: pw.BorderSide(width: 1)
                                              ),
                                            ),
                                            padding: pw.EdgeInsets.only(left: 5,top: 5,bottom: 25,right: 5),
                                            child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                children: [

                                                  pw.Text('Other Reference(s)'),

                                                ]


                                            )
                                        ),)*/
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(width: 1.0),

                        left: pw.BorderSide(width: 1.0),
                        bottom: pw.BorderSide(width: 1.0),
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        // Left column
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: pw.EdgeInsets.only(
                              left: 5,
                              top: 2,
                              bottom: 2,
                              right: 5,
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [
                                pw.Text("Buyer's Name"),

                                pw.Column(
                                  children: [
                                    pw.SizedBox(height: 2),

                                    pw.Text(
                                      _selectedpartyledger!,
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                if (address != "null")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Text(address),
                                    ],
                                  ),

                                if (emirate != "null")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Row(
                                        children: [
                                          pw.Text("Emirate "),

                                          pw.SizedBox(width: 20),
                                          pw.Text(emirate),
                                        ],
                                      ),
                                    ],
                                  ),

                                if (country != "null")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Row(
                                        children: [
                                          pw.Text("Country "),

                                          pw.SizedBox(width: 20),
                                          pw.Text(country),
                                        ],
                                      ),
                                    ],
                                  ),

                                if (trn != "null")
                                  pw.Column(
                                    children: [
                                      pw.SizedBox(height: 2),

                                      pw.Row(
                                        children: [
                                          pw.Text("TRN "),

                                          pw.SizedBox(width: 35),
                                          pw.Text(trn),
                                        ],
                                      ),
                                    ],
                                  ),

                                pw.SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        // Right column
                        /*pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                  width: 1.0
                              ),
                              top: pw.BorderSide(
                                  width: 1.0
                              ),

                              bottom: pw.BorderSide(
                                  width: 1.0
                              ),
                              left:pw.BorderSide(
                                  width: 1.0
                              ), ),
                          ),

                          child: pw.Column(
                              children: [
                                // first row right column

                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(width: 1

                                    ),
                                  ),
                                  child: pw.Row(

                                      children: [


                                        // invoice no
                                        pw.Expanded(child: pw.Container(
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border(right: pw.BorderSide(width: 1)
                                              ),
                                            ),
                                            padding: pw.EdgeInsets.only(left: 5,top: 5,bottom: 5,right: 5),

                                            child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                children: [

                                                  pw.Text('Buyers Order No.'),
                                                ]
                                            ))
                                        ),

                                        pw.Expanded(child: pw.Container(
                                            padding: pw.EdgeInsets.only(left: 5,top: 5,bottom: 5,right: 5),
                                            child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                children: [
                                                  pw.Text('Dated:'),
                                                ]
                                            )
                                        ),)
                                      ]
                                  ),
                                ),

                                //second row right column
                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(width: 1
                                    ),
                                  ),
                                  child: pw.Row(
                                      children: [
                                        pw.Expanded(child: pw.Container(
                                            padding: pw.EdgeInsets.only(left: 5,top: 5,bottom: 5,right: 5),
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border(right: pw.BorderSide(width: 1)
                                              ),
                                            ),
                                            child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                children: [

                                                  pw.Text('Dispatch Document No.'),

                                                ]


                                            ))
                                        ),



                                        pw.Expanded(child: pw.Container(

                                            padding: pw.EdgeInsets.only(left: 5,top: 5,bottom: 5,right: 5),
                                            child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                                children: [

                                                  pw.Text('Delivery Note Date.'),
                                                  pw.Text(''),
                                                ]


                                            )
                                        ),)

                                      ]
                                  ),
                                ),

                                // third row right column

                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(width: 1

                                    ),
                                  ),
                                  child: pw.Row(

                                      children: [


                                        pw.Expanded(child: pw.Container(

                                            padding: pw.EdgeInsets.only(left: 5,top: 5,bottom: 25,right: 5),

                                            child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                children: [

                                                  pw.Text('Dispatched through.'),

                                                ]



                                            ))
                                        ),



                                        pw.Expanded(child: pw.Container(
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border(left: pw.BorderSide(width: 1)
                                              ),
                                            ),
                                            padding: pw.EdgeInsets.only(left: 5,top: 5,bottom: 25,right: 5),
                                            child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                children: [

                                                  pw.Text('Destination'),

                                                ]


                                            )
                                        ),)

                                      ]
                                  ),
                                ),
                              ]
                          )
                      ),),*/
                      ],
                    ),
                  ),

                  /*pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                      right: pw.BorderSide(
                          width: 1.0
                      ),

                      left: pw.BorderSide(
                          width: 1.0
                      ),
                      bottom: pw.BorderSide(
                          width: 1.0
                      )),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    // Left column
                    pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                  width: 1.0
                              ),
                            ),
                          ),
                          padding: pw.EdgeInsets.only(left: 5,top: 2,bottom: 10,right: 5),
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [
                                pw.Text('Buyer'),
                                pw.Text(_selectedpartyledger!),
                              ]
                          ),)),

                    // Right column
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                          child: pw.Expanded(child: pw.Container(
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)
                                ),
                              ),
                              padding: pw.EdgeInsets.only(left: 5,top: 2,bottom: 20,right: 5),
                              child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Buyers Order No.'),
                                  ]
                              ))
                          ),
                      ),),
                  ],
                ),
              ),*/
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(width: 1.0),
                        left: pw.BorderSide(width: 1.0),
                        bottom: pw.BorderSide(width: 1.0),
                      ),
                    ),
                    child: pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 1,
                                child: pw.Container(
                                  padding: pw.EdgeInsets.fromLTRB(
                                    5,
                                    5,
                                    5,
                                    5,
                                  ), // Left, Top, Right, Bottom
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      right: pw.BorderSide(width: 1.0),
                                      bottom: pw.BorderSide(width: 1.0),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'Sr No.',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Container(
                                  padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      right: pw.BorderSide(width: 1.0),
                                      bottom: pw.BorderSide(width: 1.0),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'Description of Goods/Services',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Container(
                                  padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      right: pw.BorderSide(width: 1.0),
                                      bottom: pw.BorderSide(width: 1.0),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'Quantity',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Container(
                                  padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      right: pw.BorderSide(width: 1.0),
                                      bottom: pw.BorderSide(width: 1.0),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'Rate',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Container(
                                  padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      right: pw.BorderSide(width: 1.0),
                                      bottom: pw.BorderSide(width: 1.0),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'per',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Container(
                                  padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      right: pw.BorderSide(width: 1.0),
                                      bottom: pw.BorderSide(width: 1.0),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'Disc. %',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Container(
                                  padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                      bottom: pw.BorderSide(width: 1.0),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'Amount',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(width: 1.0),
                        left: pw.BorderSide(width: 1.0),
                        bottom: pw.BorderSide(width: 1.0),
                      ),
                    ),
                    child: pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Table(
                            border: pw.TableBorder(
                              horizontalInside: pw.BorderSide.none,
                              verticalInside: pw.BorderSide(
                                color: PdfColor.fromHex('#050400'),
                              ),
                              bottom: pw.BorderSide.none,
                              top: pw.BorderSide.none,
                            ),
                            children: [
                              for (var item in saleItems.asMap().entries)
                                pw.TableRow(
                                  children: [
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ), // Left, Top, Right, Bottom
                                        alignment: pw.Alignment.center,

                                        child: pw.Text(
                                          formatitemKey(item.key),
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),

                                    pw.Expanded(
                                      flex: 3,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.center,

                                        child: pw.Text(
                                          item.value.itemName,
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,

                                        child: pw.Row(
                                          mainAxisAlignment:
                                              pw.MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.center,
                                          children: [
                                            pw.Text(
                                              item.value.itemQuantity,
                                              textAlign: pw.TextAlign.right,
                                              style: pw.TextStyle(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.center,

                                        child: pw.Text(
                                          formatAmountInvoice(
                                            item.value.itemPrice.toString(),
                                          ),
                                          textAlign: pw.TextAlign.center,
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.center,
                                        child: pw.Text(
                                          item.value.itemUnit,
                                          textAlign: pw.TextAlign.center,
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.center,
                                        child: pw.Text(
                                          '',
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 2,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Text(
                                          formatAmountInvoice(
                                            item.value.itemAmount
                                                .toStringAsFixed(decimal!),
                                          ),
                                          textAlign: pw.TextAlign.right,
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          pw.Table(
                            border: pw.TableBorder(
                              horizontalInside: pw.BorderSide.none,
                              verticalInside: pw.BorderSide(
                                color: PdfColor.fromHex('#050400'),
                              ),
                              top: pw.BorderSide.none,
                              bottom: pw.BorderSide(
                                color: PdfColor.fromHex('#050400'),
                              ),
                            ),
                            children: [
                              pw.TableRow(
                                children: [
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ), // Left, Top, Right, Bottom
                                      alignment: pw.Alignment.center,
                                    ),
                                  ),

                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                      child: pw.Text(
                                        '',
                                        style: pw.TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),

                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.center,
                                      child: pw.Text(
                                        '',
                                        style: pw.TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 2,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        50,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                      child: pw.Text(
                                        formatAmountInvoice(
                                          totalitemAmount.toStringAsFixed(
                                            decimal!,
                                          ),
                                        ),
                                        textAlign: pw.TextAlign.right,
                                        style: pw.TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          if (ledgerEntries.isNotEmpty)
                            for (var ledger in ledgerEntries.asMap().entries)
                              pw.Table(
                                border: pw.TableBorder(
                                  horizontalInside: pw.BorderSide(
                                    color: PdfColor.fromHex('#050400'),
                                  ),
                                  verticalInside: pw.BorderSide(
                                    color: PdfColor.fromHex('#050400'),
                                  ),
                                  bottom: pw.BorderSide(
                                    color: PdfColor.fromHex('#050400'),
                                  ),
                                  top: pw.BorderSide.none,
                                ),
                                children: [
                                  pw.TableRow(
                                    children: [
                                      pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            5,
                                          ), // Left, Top, Right, Bottom
                                          alignment: pw.Alignment.center,
                                        ),
                                      ),

                                      pw.Expanded(
                                        flex: 3,
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            5,
                                          ),
                                          alignment: pw.Alignment.centerRight,

                                          child: pw.Text(
                                            ledger.value.ledgerName,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                      pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            5,
                                          ),
                                          alignment: pw.Alignment.centerRight,
                                        ),
                                      ),
                                      pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            5,
                                          ),
                                          alignment: pw.Alignment.centerRight,
                                        ),
                                      ),
                                      pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            5,
                                          ),
                                          alignment: pw.Alignment.centerRight,
                                        ),
                                      ),
                                      pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            5,
                                          ),
                                          alignment: pw.Alignment.centerRight,
                                        ),
                                      ),
                                      pw.Expanded(
                                        flex: 2,
                                        child: pw.Container(
                                          padding: pw.EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            5,
                                          ),
                                          alignment: pw.Alignment.centerRight,
                                          child: pw.Text(
                                            formatAmountInvoice(
                                              ledger.value.ledgerAmount
                                                  .toString(),
                                            ),
                                            textAlign: pw.TextAlign.right,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                          if (vatledgerdata.isNotEmpty &&
                              _selectedvatledger != 'Not Applicable')
                            pw.Table(
                              border: pw.TableBorder(
                                horizontalInside: pw.BorderSide(
                                  color: PdfColor.fromHex('#050400'),
                                ),
                                verticalInside: pw.BorderSide(
                                  color: PdfColor.fromHex('#050400'),
                                ),
                                bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#050400'),
                                ),
                                top: pw.BorderSide.none,
                              ),
                              children: [
                                pw.TableRow(
                                  children: [
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ), // Left, Top, Right, Bottom
                                        alignment: pw.Alignment.center,
                                      ),
                                    ),

                                    pw.Expanded(
                                      flex: 3,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,

                                        child: pw.Text(
                                          _selectedvatledger,
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 2,
                                      child: pw.Container(
                                        padding: pw.EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          5,
                                        ),
                                        alignment: pw.Alignment.centerRight,

                                        child: pw.Text(
                                          formatAmountInvoice(
                                            totalVatAmount.toString(),
                                          ),
                                          textAlign: pw.TextAlign.right,
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                          pw.Table(
                            border: pw.TableBorder(
                              horizontalInside: pw.BorderSide(
                                color: PdfColor.fromHex('#050400'),
                              ),
                              verticalInside: pw.BorderSide(
                                color: PdfColor.fromHex('#050400'),
                              ),
                              bottom: pw.BorderSide.none,
                            ),
                            children: [
                              pw.TableRow(
                                children: [
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ), // Left, Top, Right, Bottom
                                      alignment: pw.Alignment.center,
                                    ),
                                  ),

                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,

                                      child: pw.Text(
                                        'Total',
                                        style: pw.TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),

                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.center,
                                      child: pw.Text(
                                        totalQuantity.toString(),
                                        style: pw.TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 2,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      alignment: pw.Alignment.centerRight,

                                      child: pw.Text(
                                        formatAmountInvoice(
                                          roundedtotalAmount.toString(),
                                        ),
                                        textAlign: pw.TextAlign.right,
                                        style: pw.TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          pw.Table(
                            border: pw.TableBorder(
                              horizontalInside: pw.BorderSide.none,
                              verticalInside: pw.BorderSide.none,
                              bottom: pw.BorderSide.none,
                              top: pw.BorderSide(
                                color: PdfColor.fromHex('#050400'),
                              ),
                            ),
                            children: [
                              pw.TableRow(
                                children: [
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ), // Left, Top, Right, Bottom
                                      alignment: pw.Alignment.centerLeft,

                                      child: pw.Column(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text(
                                            'Amount Chargeable (in words)',
                                            textAlign: pw.TextAlign.left,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),

                                          pw.Text(
                                            convertAmountToWords(totalAmount),
                                            textAlign: pw.TextAlign.left,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),

                                          pw.SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // declaration table
                          pw.Table(
                            border: pw.TableBorder(
                              horizontalInside: pw.BorderSide.none,
                              verticalInside: pw.BorderSide.none,
                              bottom: pw.BorderSide.none,
                              top: pw.BorderSide(
                                color: PdfColor.fromHex('#050400'),
                              ),
                            ),
                            children: [
                              pw.TableRow(
                                children: [
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ), // Left, Top, Right, Bottom
                                      alignment: pw.Alignment.centerLeft,

                                      child: pw.Column(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.SizedBox(height: 10),

                                          pw.Text(
                                            'Declaration',
                                            textAlign: pw.TextAlign.left,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),

                                          pw.Text(
                                            'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct',
                                            textAlign: pw.TextAlign.left,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),

                                          pw.SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ),

                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      margin: pw.EdgeInsets.only(top: 30),
                                      padding: pw.EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        5,
                                      ),
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border(
                                          top: pw.BorderSide(width: 1.0),
                                          left: pw.BorderSide(width: 1.0),
                                        ),
                                      ),

                                      // Left, Top, Right, Bottom
                                      alignment: pw.Alignment.center,

                                      child: pw.Column(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        children: [
                                          pw.Text(
                                            'for $company',
                                            textAlign: pw.TextAlign.center,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),

                                          pw.SizedBox(height: 30),

                                          pw.Text(
                                            'Authorised Signatory',
                                            textAlign: pw.TextAlign.left,
                                            style: pw.TextStyle(fontSize: 10),
                                          ),

                                          pw.SizedBox(height: 5),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.Container(
                    padding: pw.EdgeInsets.fromLTRB(
                      5,
                      5,
                      5,
                      5,
                    ), // Left, Top, Right, Bottom
                    alignment: pw.Alignment.center,

                    child: pw.Text(
                      'This is a System Generated Document',
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(
                  padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Created in Fincore Go',
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

    // 🗂 Save to temp file
    final pdfData = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/SaleInvoice.pdf';

    final file = File(filePath);
    await file.writeAsBytes(pdfData);

    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/pdf'),
    ], text: 'Sharing Sale Invoice for $_selectedpartyledger');

    setState(() {
      controller_narration.clear();
      controller_refno.clear();

      _textFieldFocusNodeNarration.unfocus(); // Unfocus the TextField

      saledate = DateTime.now();
      saledatestring = _dateFormat.format(saledate);
      saledatetxt = formatlastsaledate(saledatestring);
      _dateController.text = saledatetxt;
      refdate = DateTime.now();
      refdatestring = _dateFormat.format(refdate);
      refdatetxt = formatlastsaledate(refdatestring);
      _refdateController.text = refdatetxt;
      // _selectedvchtypename = vchtypenamedata[0];
      fetchvchnos(_selectedvchtypename);
      _selectedpartyledger = null;
      _partyLedgerController.clear();
      // _selectedsalesledger = salesledger_data[0];

      _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;

      _selectedvatledger = vatledgerdata[0];

      _selecteditem = '${itemdata[0]['name']}';
      _itemController.text = _selecteditem;
      if (locationsdata.isNotEmpty) {
        selectedLocation = locationsdata[0];
        isVisibleLocation = true;
      } else {
        isVisibleLocation = false;
      }
      _updateUnitDropdown(_selecteditem);

      saleItems.clear();
      ledgerEntries.clear();

      // making sales list empty and setting values

      totalPriceOfItems = saleItems.fold(0.0, (
        double previousAmount,
        SaleItem item,
      ) {
        return previousAmount +
            (double.parse(item.itemPrice.toStringAsFixed(decimal!)) *
                double.parse(item.itemQuantity));
      });

      totalAmountOfLedgers = ledgerEntries.fold(0.0, (
        double previousAmount,
        LedgerEntry entry,
      ) {
        return previousAmount + entry.ledgerAmount;
      });

      if (_selectedvatledger != 'Not Applicable') {
        double vat_perc = vatperc / 100;
        itemsVatAmount = double.parse(
          (totalPriceOfItems * vat_perc).toStringAsFixed(decimal!),
        );
        totalVatAmount = itemsVatAmount + ledgerVatAmount;

        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      } else {
        totalVatAmount = 0;

        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      }
      if (saleItems.isEmpty) {
        isVisibleItemHeading = false;
      } else {
        isVisibleItemHeading = true;
      }
      // making ledger list empty and setting values
      totalAmountForVatAppEntries = ledgerEntries
          .where((entry) => entry.vatApp)
          .fold(0.0, (double previousAmount, LedgerEntry entry) {
            return previousAmount + entry.ledgerAmount;
          });

      if (_selectedvatledger != 'Not Applicable') {
        double vat_perc = vatperc / 100;
        ledgerVatAmount = totalAmountForVatAppEntries * vat_perc;
        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount = double.parse(
          totalVatAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedVat = formatter.format(roundedtotalVatAmount);
        controller_vatamt.text = formattedVat.toString();
      }
      if (ledgerEntries.isEmpty) {
        isVisibleLedgerHeading = false;
      } else {
        isVisibleLedgerHeading = true;
      }
      totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
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
    });
  }

  /*Future<void> generateInvoicePDF(String trn, String address, String emirate, String country) async {
    final font = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans.ttf"));
    final pdf = pw.Document();

    int totalQuantity = 0;
    double totalitemAmount = 0;
    for (var item in saleItems) {
      int qty_int = int.tryParse(item.itemQuantity) ?? 0;
      totalQuantity += qty_int;
      totalitemAmount += item.itemAmount;
    }

    // 🧾 Build PDF
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
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide.none),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Tax Invoice',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    company ?? '',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Party: ${_selectedpartyledger ?? "N/A"}',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                  if (address.isNotEmpty && address != "null")
                    pw.Text('Address: $address', style: pw.TextStyle(fontSize: 11)),
                  if (emirate.isNotEmpty && emirate != "null")
                    pw.Text('Emirate: $emirate', style: pw.TextStyle(fontSize: 11)),
                  if (country.isNotEmpty && country != "null")
                    pw.Text('Country: $country', style: pw.TextStyle(fontSize: 11)),
                  if (trn.isNotEmpty && trn != "null")
                    pw.Text('TRN: $trn', style: pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 10),

                  pw.Table.fromTextArray(
                    border: pw.TableBorder.all(width: 1),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
                    cellStyle: pw.TextStyle(fontSize: 10, font: font), // ✅ Use your font here too
                    headers: ['Sr No', 'Item', 'Qty', 'Rate', 'Amount'],
                    data: [
                      for (int i = 0; i < saleItems.length; i++)
                        [
                          (i + 1).toString(),
                          saleItems[i].itemName,
                          saleItems[i].itemQuantity,
                          formatAmountInvoice(saleItems[i].itemPrice.toString()),
                          formatAmountInvoice(saleItems[i].itemAmount.toString()),
                        ],
                    ],
                  ),

                  pw.SizedBox(height: 10),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Quantity: $totalQuantity',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          'Total Amount: ${formatAmountInvoice(totalitemAmount.toString())}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Text(
                    'This is a system-generated document',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(5),
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

    // 🗂 Save to temp file
    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath =
        '${tempDir.path}/SaleInvoice_${_selectedpartyledger ?? "Unknown"}.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfData);

    // ✅ Share using ShareXFiles (modern API)
    final xfile = XFile(tempFilePath);
    await Share.shareXFiles(
      [xfile],
      text: 'Sharing Sale Invoice for $_selectedpartyledger',
    );

    // ♻️ Reset all UI fields after sharing
    setState(() {
      controller_narration.clear();
      controller_refno.clear();

      _textFieldFocusNodeNarration.unfocus();

      saledate = DateTime.now();
      saledatestring = _dateFormat.format(saledate);
      _dateController.text = formatlastsaledate(saledatestring);

      refdate = DateTime.now();
      refdatestring = _dateFormat.format(refdate);
      _refdateController.text = formatlastsaledate(refdatestring);

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

      totalPriceOfItems = saleItems.fold(0.0, (sum, item) {
        return sum + (item.itemPrice * double.parse(item.itemQuantity));
      });

      totalAmountOfLedgers = ledgerEntries.fold(0.0, (sum, entry) {
        return sum + entry.ledgerAmount;
      });

      if (_selectedvatledger != 'Not Applicable') {
        double vatPerc = vatperc / 100;
        itemsVatAmount = totalPriceOfItems * vatPerc;
        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      }

      isVisibleItemHeading = saleItems.isNotEmpty;
      totalAmountForVatAppEntries = ledgerEntries
          .where((entry) => entry.vatApp)
          .fold(0.0, (sum, entry) => sum + entry.ledgerAmount);

      if (_selectedvatledger != 'Not Applicable') {
        double vatPerc = vatperc / 100;
        ledgerVatAmount = totalAmountForVatAppEntries * vatPerc;
        totalVatAmount = itemsVatAmount + ledgerVatAmount;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      } else {
        totalVatAmount = 0;
        roundedtotalVatAmount = double.parse(totalVatAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        controller_vatamt.text = formatter.format(roundedtotalVatAmount);
      }

      isVisibleLedgerHeading = ledgerEntries.isNotEmpty;
      totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
      roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));
      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      controller_totalamt.text = formatter.format(roundedtotalAmount);

      _isFocused_vchno = false;
      _isFocused_item = false;
      _isFocused_unit = false;
      _isFocused_ledger = false;
      _isFocused_narration = false;
      _isFocused_totalamt = false;
      _isFocused_vatamt = false;
    });
  }*/

  String getCurrencySymbol(String currencyCode) {
    NumberFormat format;
    Locale locale = Localizations.localeOf(context);

    try {
      if (currencyCode == 'INR' ||
          currencyCode == 'EUR' ||
          currencyCode == 'PKR' ||
          currencyCode == 'USD') {
        format = new NumberFormat.simpleCurrency(
          locale: locale.toString(),
          name: currencyCode,
        );
      } else {
        format = new NumberFormat.currency(
          locale: locale.toString(),
          name: currencyCode,
        );
      }
      return format.currencySymbol;
    } catch (e) {
      return 'AED';
    }
  }

  Future<void> saveEntry() async {
    // ❌ Prevent save if Party Ledger not selected
    if (_selectedpartyledger == null ||
        _selectedpartyledger.toString().trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please select Party Ledger");

      return;
    }

    if (saleItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Atleast add 1 item')));
    } else {
      setState(() {
        _isLoading = true;
      });
      String narrationValue = controller_narration.text;
      String vchnoValue = _vchnoController.text;

      String refnoValue = controller_refno.text;
      roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));

      jsonEntryData["DATE"] = saledatestring;
      jsonEntryData["VOUCHERTYPENAME"] = _selectedvchtypename;
      jsonEntryData["PARTYLEDGERNAME"] = _selectedpartyledger;
      jsonEntryData["totalAmount"] = roundedtotalAmount.toStringAsFixed(
        decimal!,
      );
      jsonEntryData["NARRATION"] = narrationValue;
      jsonEntryData["VOUCHERNUMBER"] = vchnoValue;
      jsonEntryData["REFERENCE"] = refnoValue;
      jsonEntryData["REFERENCEDATE"] = refdatestring;

      double totalItemAmount = 0.0;

      for (SaleItem item in saleItems) {
        totalItemAmount += double.parse(
          item.itemAmount.toStringAsFixed(decimal!),
        ); // calculating item amounts total
      }

      for (var saleItem in saleItems) {
        // making sales ledger
        if (saleItem.accountingAllocationList.isEmpty) {
          saleItem.accountingAllocationList = {
            "LEDGERNAME": _selectedsalesledger,
            "AMOUNT": saleItem.itemAmount.toStringAsFixed(decimal!),
            "ISDEEMEDPOSITIVE": "No",
          };
        }
      }

      jsonEntryData["INVENTORYENTRIES.LIST"] = saleItems.map((item) {
        // making stockitem list
        return {
          "STOCKITEMNAME": item.itemName,
          "ISDEEMEDPOSITIVE": "No",
          "RATE":
              "${item.itemPrice.toStringAsFixed(decimal!)}/${item.itemUnit}",
          "AMOUNT": item.itemAmount.toStringAsFixed(decimal!),
          "ACTUALQTY": "${item.itemQuantity} ${item.itemUnit}",
          "BILLEDQTY": "${item.itemQuantity} ${item.itemUnit}",
          "BATCHALLOCATIONS.LIST": item.batchAllocationList,
          "ACCOUNTINGALLOCATIONS.LIST": item.accountingAllocationList,
        };
      }).toList();

      double totalLedgerAmount = 0.0;

      for (LedgerEntry ledger in ledgerEntries) {
        // calculating total ledger amount
        totalLedgerAmount += double.parse(
          ledger.ledgerAmount.toStringAsFixed(decimal!),
        ); // calculating ledger amounts total
      }

      double partyLedgerAmount = double.parse(
        (double.parse(totalVatAmount.toStringAsFixed(decimal!)) +
                double.parse(totalItemAmount.toStringAsFixed(decimal!)) +
                double.parse(totalLedgerAmount.toStringAsFixed(decimal!)))
            .toStringAsFixed(decimal!),
      ); // adding vat total, items total, ledgers total

      partyLedgerAmount = partyLedgerAmount * -1;

      List<Map<String, Object>> ledgerList = [];

      Map<String, Object> partyLedgerData = {
        // making party ledger
        "LEDGERNAME": _selectedpartyledger,
        "AMOUNT": partyLedgerAmount.toStringAsFixed(decimal!),
        "ISPARTYLEDGER": "Yes",
        "ISDEEMEDPOSITIVE": "Yes",
        "ledgerType": "Party",
      };
      ledgerList.add(partyLedgerData);

      // Add ledger entries to the list
      ledgerList.addAll(
        ledgerEntries.map((item) {
          return {
            "LEDGERNAME": item.ledgerName,
            "VATAPPLICABLE": item.vatApp,
            "AMOUNT": item.ledgerAmount,
            "ISDEEMEDPOSITIVE": "No",
            "ledgerType": "ledgerList",
          };
        }),
      );

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

      Map<String, dynamic> jsonData = {'type': 'sales', 'data': jsonEntryData};

      String jsonDataString = jsonEncode(jsonData);

      print(jsonDataString);

      try {
        final url_salesentry = Uri.parse(HttpURL_salesEntry!);
        Map<String, String> headers_salesentry = {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json",
        };

        var body_salesentry = jsonDataString;

        final response_salesentry = await http.post(
          url_salesentry,
          body: body_salesentry,
          headers: headers_salesentry,
        );

        if (response_salesentry.statusCode == 200) {
          if (response_salesentry.body == 'Entry created successfully') {
            /*Fluttertoast.showToast(msg: response_salesentry. );*/

            loadLedgerData();

            /*showSalesInvoiceBottomSheet(context);*/ // show screen bottom message for sharing invoice
          } else {
            Fluttertoast.showToast(msg: 'an error occoured');
          }
        } else {
          Map<String, dynamic> data = json.decode(response_salesentry.body);
          String error = '';

          if (data.containsKey('error')) {
            setState(() {
              error = data['error'];
            });
          } else {
            error = "Error in data fetching!!!";
          }
          Fluttertoast.showToast(msg: error);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print(e);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void showSalesInvoiceDialog(
    BuildContext context,
    String trn,
    String address,
    String emirate,
    String country,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "SalesInvoice",
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(28), // 🔥 more rounded
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 4.0),
                    ),
                    child: const Icon(
                      Icons.done,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Do you want to share the sales invoice?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 18.0),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sales Invoice Created Successfully',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            controller_narration.clear();
                            controller_refno.clear();
                            _textFieldFocusNodeNarration.unfocus();

                            saledate = DateTime.now();
                            saledatestring = _dateFormat.format(saledate);
                            saledatetxt = formatlastsaledate(saledatestring);
                            _dateController.text = saledatetxt;

                            refdate = DateTime.now();
                            refdatestring = _dateFormat.format(refdate);
                            refdatetxt = formatlastsaledate(refdatestring);
                            _refdateController.text = refdatetxt;

                            fetchvchnos(_selectedvchtypename);

                            _selectedpartyledger = null;
                            _partyLedgerController.clear();

                            _selectedledger = ledgerdata.isNotEmpty
                                ? ledgerdata[0]['name']
                                : null;
                            _selectedvatledger = vatledgerdata[0];

                            _selecteditem = '${itemdata[0]['name']}';
                            _itemController.text = _selecteditem;

                            if (locationsdata.isNotEmpty) {
                              selectedLocation = locationsdata[0];
                              isVisibleLocation = true;
                            } else {
                              isVisibleLocation = false;
                            }

                            _updateUnitDropdown(_selecteditem);

                            saleItems.clear();
                            ledgerEntries.clear();

                            totalPriceOfItems = 0.0;
                            totalAmountOfLedgers = 0.0;
                            totalVatAmount = 0.0;

                            controller_vatamt.clear();
                            controller_totalamt.clear();

                            isVisibleItemHeading = false;
                            isVisibleLedgerHeading = false;

                            _isFocused_vchno = false;
                            _isFocused_item = false;
                            _isFocused_unit = false;
                            _isFocused_ledger = false;
                            _isFocused_narration = false;
                            _isFocused_totalamt = false;
                            _isFocused_vatamt = false;
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'No, Thanks',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await generateInvoicePDF(
                            trn,
                            address,
                            emirate,
                            country,
                          );
                        },
                        icon: const Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Share',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app_color,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: app_color.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),

                  /*Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            controller_narration.clear();
                            controller_refno.clear();
                            _textFieldFocusNodeNarration.unfocus();

                            saledate = DateTime.now();
                            saledatestring = _dateFormat.format(saledate);
                            saledatetxt = formatlastsaledate(saledatestring);
                            _dateController.text = saledatetxt;

                            refdate = DateTime.now();
                            refdatestring = _dateFormat.format(refdate);
                            refdatetxt = formatlastsaledate(refdatestring);
                            _refdateController.text = refdatetxt;

                            //_selectedvchtypename = vchtypenamedata[0];
                            fetchvchnos(_selectedvchtypename);
                            _selectedpartyledger = null;
                            _partyLedgerController.clear();
                            // _selectedsalesledger = salesledger_data[0];
                            _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;
                            _selectedvatledger = vatledgerdata[0];
                            _selecteditem = '${itemdata[0]['name']}';
                            _itemController.text = _selecteditem;

                            if (locationsdata.isNotEmpty) {
                              selectedLocation = locationsdata[0];
                              isVisibleLocation = true;
                            } else {
                              isVisibleLocation = false;
                            }

                            _updateUnitDropdown(_selecteditem);

                            saleItems.clear();
                            ledgerEntries.clear();

                            totalPriceOfItems = 0.0;
                            totalAmountOfLedgers = 0.0;
                            totalVatAmount = 0.0;
                            controller_vatamt.clear();
                            controller_totalamt.clear();

                            isVisibleItemHeading = false;
                            isVisibleLedgerHeading = false;

                            _isFocused_vchno = false;
                            _isFocused_item = false;
                            _isFocused_unit = false;
                            _isFocused_ledger = false;
                            _isFocused_narration = false;
                            _isFocused_totalamt = false;
                            _isFocused_vatamt = false;
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                        label: Text(
                          'No, Thanks',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await generateInvoicePDF(trn, address, emirate, country);
                        },
                        icon: const Icon(Icons.share_rounded, size: 20, color: Colors.white),
                        label: Text(
                          'Share',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app_color,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: app_color.withOpacity(0.3),
                        ),
                      )
                    ],
                  ),*/
                ],
              ),
            ),
          ),
        );
      },

      // 🔥 POPUP ANIMATION
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: Opacity(opacity: animation.value, child: child),
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

    String godownName = '';
    String? savedSalesLedger;
    String? savedVoucherType;

    final prefs = await SharedPreferences.getInstance();
    String? allocationString = prefs.getString('spectra_allocations');

    if (allocationString != null && allocationString.isNotEmpty) {
      try {
        List<dynamic> allocations = jsonDecode(allocationString);

        if (allocations.isNotEmpty) {
          final allocation = allocations.first as Map<String, dynamic>;

          godownName = allocation['godown']?.toString().trim() ?? '';
          savedSalesLedger = allocation['sales_ledger']?.toString().trim();
          savedVoucherType = allocation['sales_voucher_type']
              ?.toString()
              .trim();
        }
      } catch (e) {
        debugPrint('allocation decode error -> $e');
      }
    }

    try {
      final url = Uri.parse(HttpURL_loadData!);

      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json",
      };

      final String currentSerialNo = serial_no?.trim() ?? '';
      final bool isUniGasSerial = vanSalesSerialNo.contains(currentSerialNo);

      var body = jsonEncode({
        "type": "sales",
        if (isUniGasSerial && godownName.isNotEmpty) "godownName": godownName,
      });

      debugPrint('sales loadData serial_no -> $currentSerialNo');
      debugPrint('sales loadData isUniGasSerial -> $isUniGasSerial');
      debugPrint('sales loadData godownName -> $godownName');
      debugPrint('sales loadData body -> $body');

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        debugPrint('sales loadData response -> $jsonResponse');

        String? voucherTypeToFetch;

        setState(() {
          vchtypenamedata = List<String>.from(
            (jsonResponse["vchTypes"] ?? [])
                .where((e) => e != null)
                .map((e) => e.toString()),
          );

          final bool hasValidSavedVoucherType =
              savedVoucherType != null &&
              savedVoucherType!.isNotEmpty &&
              savedVoucherType!.toLowerCase() != 'null' &&
              vchtypenamedata.contains(savedVoucherType);

          _selectedvchtypename = hasValidSavedVoucherType
              ? savedVoucherType
              : (vchtypenamedata.isNotEmpty ? vchtypenamedata[0] : null);

          isVoucherTypeLocked = hasValidSavedVoucherType;
          voucherTypeToFetch = _selectedvchtypename;

          if (isUniGasSerial) {
            partyledgerdata.clear();
            partyLedgerPriceLevelMap.clear();

            for (var ledger in (jsonResponse["partyLedgers"] ?? [])) {
              if (ledger == null) continue;

              final String ledgerName = ledger['name']?.toString().trim() ?? '';

              final dynamic rawPriceLevel = ledger['price_level'];

              final String? priceLevel =
                  rawPriceLevel == null ||
                      rawPriceLevel.toString().trim().isEmpty ||
                      rawPriceLevel.toString().trim().toLowerCase() == 'null'
                  ? null
                  : rawPriceLevel.toString().trim();

              if (ledgerName.isEmpty) continue;

              if (!partyledgerdata.contains(ledgerName)) {
                partyledgerdata.add(ledgerName);
              }

              partyLedgerPriceLevelMap[ledgerName] = priceLevel;
            }
          } else {
            partyledgerdata = List<String>.from(
              (jsonResponse["partyLedgers"] ?? [])
                  .where((e) => e != null)
                  .map((e) => e.toString()),
            );
          }

          salesledger_data = List<String>.from(
            (jsonResponse["salesLedgers"] ?? [])
                .where((e) => e != null)
                .map((e) => e.toString()),
          );

          if (savedSalesLedger != null &&
              savedSalesLedger!.isNotEmpty &&
              savedSalesLedger!.toLowerCase() != 'null' &&
              salesledger_data.contains(savedSalesLedger)) {
            _selectedsalesledger = savedSalesLedger;
            isSalesLedgerLocked = true;
          } else {
            _selectedsalesledger = salesledger_data.isNotEmpty
                ? salesledger_data[0]
                : null;
            isSalesLedgerLocked = false;
          }

          ledgerdata = List<Map<String, dynamic>>.from(
            (jsonResponse['otherLedgers'] ?? []).where((e) => e != null),
          );

          _selectedledger = ledgerdata.isNotEmpty
              ? ledgerdata[0]['name']
              : null;

          vatledgerdata.add('Not Applicable');
          vatledgerdata.addAll(
            List<String>.from(
              (jsonResponse["vatLedgers"] ?? [])
                  .where((e) => e != null)
                  .map((e) => e.toString()),
            ),
          );

          _selectedvatledger = vatledgerdata.isNotEmpty
              ? vatledgerdata[0]
              : null;

          itemdata = jsonResponse["items"] ?? [];

          if (itemdata.isNotEmpty) {
            _selecteditem = '${itemdata[0]['name']}';
            _itemController.text = _selecteditem ?? '';
            _updateUnitDropdown(_selecteditem);
          }

          locationsdata = List<String>.from(
            (jsonResponse['locations'] ?? [])
                .where((e) => e != null)
                .map((e) => e.toString()),
          );

          if (locationsdata.isNotEmpty) {
            if (godownName.isNotEmpty && locationsdata.contains(godownName)) {
              selectedLocation = godownName;
            } else {
              selectedLocation = locationsdata[0];
            }

            isVisibleLocation = true;
          } else {
            isVisibleLocation = false;
          }
        });

        if (voucherTypeToFetch != null && voucherTypeToFetch!.isNotEmpty) {
          fetchvchnos(voucherTypeToFetch!);
        }
      } else {
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';

        if (data.containsKey('error')) {
          error = data['error'];
        } else {
          error = 'Something went wrong!!!';
        }

        Fluttertoast.showToast(msg: error);
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      _isLoading = false;
    });
  }

  /*Future<void> loadData() async {
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

    try {
      final url = Uri.parse(HttpURL_loadData!);

      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json",
      };

      final String currentSerialNo = serial_no?.trim() ?? '';
      final bool isUniGasSerial = vanSalesSerialNo.contains(currentSerialNo);

      String godownName = '';
      String? allocationString = prefs.getString('spectra_allocations');

      if (isUniGasSerial &&
          allocationString != null &&
          allocationString.isNotEmpty) {
        try {
          List<dynamic> allocations = jsonDecode(allocationString);

          if (allocations.isNotEmpty) {
            godownName = allocations.first['godown']?.toString() ?? '';
          }
        } catch (e) {
          debugPrint('allocation decode error -> $e');
        }
      }

      var body = jsonEncode({
        "type": "sales",
        if (isUniGasSerial && godownName.isNotEmpty)
          "godownName": godownName,
      });

      debugPrint('sales loadData serial_no -> $currentSerialNo');
      debugPrint('sales loadData isUniGasSerial -> $isUniGasSerial');
      debugPrint('sales loadData godownName -> $godownName');
      debugPrint('sales loadData body -> $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        debugPrint('sales loadData response -> $jsonResponse');

        setState(() {
          vchtypenamedata = List<String>.from(
            (jsonResponse["vchTypes"] ?? [])
                .where((e) => e != null)
                .map((e) => e.toString()),
          );

          _selectedvchtypename =
          vchtypenamedata.isNotEmpty ? vchtypenamedata[0] : null;

          fetchvchnos(_selectedvchtypename);



          if (vanSalesSerialNo.contains(currentSerialNo)) {
            partyledgerdata.clear();
            partyLedgerPriceLevelMap.clear();

            for (var ledger in (jsonResponse["partyLedgers"] ?? [])) {
              if (ledger == null) continue;

              final String ledgerName =
                  ledger['name']?.toString().trim() ?? '';

              final dynamic rawPriceLevel = ledger['price_level'];

              final String? priceLevel = rawPriceLevel == null ||
                  rawPriceLevel.toString().trim().isEmpty ||
                  rawPriceLevel.toString().trim().toLowerCase() == 'null'
                  ? null
                  : rawPriceLevel.toString().trim();

              if (ledgerName.isEmpty) continue;

              if (!partyledgerdata.contains(ledgerName)) {
                partyledgerdata.add(ledgerName);
              }

              partyLedgerPriceLevelMap[ledgerName] = priceLevel;
            }
          }
          else {
            partyledgerdata = List<String>.from(
              (jsonResponse["partyLedgers"] ?? [])
                  .where((e) => e != null)
                  .map((e) => e.toString()),
            );
          }

          // _selectedpartyledger = partyledgerdata.isNotEmpty ? partyledgerdata[0] : null;

          // _partyLedgerController.text = _selectedpartyledger ?? '';



          salesledger_data = List<String>.from(
            (jsonResponse["salesLedgers"] ?? [])
                .where((e) => e != null)
                .map((e) => e.toString()),
          );

          _selectedsalesledger =
          salesledger_data.isNotEmpty ? salesledger_data[0] : null;

          if (allocationString != null &&
              allocationString.isNotEmpty) {

            List<dynamic> allocations =
            jsonDecode(allocationString);

            if (allocations.isNotEmpty) {

              final allocation =
              allocations.first as Map<String, dynamic>;

              final savedSalesLedger =
              allocation['sales_ledger']?.toString();

              if (savedSalesLedger != null &&
                  savedSalesLedger.isNotEmpty &&
                  salesledger_data.contains(savedSalesLedger)) {

                _selectedsalesledger = savedSalesLedger;

                // LOCK DROPDOWN
                isSalesLedgerLocked = true;

              } else if (salesledger_data.isNotEmpty) {

                _selectedsalesledger = salesledger_data[0];

                isSalesLedgerLocked = false;
              }
            }
          }
          else if (salesledger_data.isNotEmpty) {

            _selectedsalesledger = salesledger_data[0];

            isSalesLedgerLocked = false;
          }

          ledgerdata = List<Map<String, dynamic>>.from(
            jsonResponse['otherLedgers'] ?? [],
          );

          _selectedledger =
          ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;

          vatledgerdata.add('Not Applicable');
          vatledgerdata.addAll(
            List<String>.from(
              (jsonResponse["vatLedgers"] ?? [])
                  .where((e) => e != null)
                  .map((e) => e.toString()),
            ),
          );

          _selectedvatledger =
          vatledgerdata.isNotEmpty ? vatledgerdata[0] : null;

          itemdata = jsonResponse["items"] ?? [];

          if (itemdata.isNotEmpty) {
            _selecteditem = '${itemdata[0]['name']}';
            _itemController.text = _selecteditem;
            _updateUnitDropdown(_selecteditem);
          }

          locationsdata = List<String>.from(
            (jsonResponse['locations'] ?? [])
                .where((e) => e != null)
                .map((e) => e.toString()),
          );

          if (locationsdata.isNotEmpty) {
            selectedLocation = locationsdata[0];
            isVisibleLocation = true;
          } else {
            isVisibleLocation = false;
          }

          if (isUniGasSerial &&
              godownName.isNotEmpty &&
              locationsdata.contains(godownName)) {
            selectedLocation = godownName;
            isVisibleLocation = true;
          }

          if (allocationString != null) {
            List<dynamic> allocations = jsonDecode(allocationString);

            if (allocations.isNotEmpty) {
              final allocation = allocations.first;

              // GODOWN
              if (allocation['godown'] != null &&
                  locationsdata.contains(allocation['godown'])) {
                selectedLocation = allocation['godown'];

                isVisibleLocation = true;

              }

              // SALES LEDGER
              */ /*if (allocation['sales_ledger'] != null &&
            salesledger_data.contains(allocation['sales_ledger'])) {
          _selectedsalesledger = allocation['sales_ledger'];
        }*/ /*

              // VOUCHER TYPE
              final savedVoucherType =
              allocation['sales_voucher_type']?.toString();

              if (savedVoucherType != null &&
                  savedVoucherType.isNotEmpty &&
                  vchtypenamedata.contains(savedVoucherType)) {

                _selectedvchtypename = savedVoucherType;

                isVoucherTypeLocked = true;

                // optional if your app fetches voucher numbers on selection
                fetchvchnos(_selectedvchtypename);

              } else if (vchtypenamedata.isNotEmpty) {

                _selectedvchtypename = vchtypenamedata[0];

                isVoucherTypeLocked = false;

                fetchvchnos(_selectedvchtypename);
              }

              setState(() {});
            }
          }

        });
      } else {
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';

        if (data.containsKey('error')) {
          error = data['error'];
        } else {
          error = 'Something went wrong!!!';
        }

        Fluttertoast.showToast(msg: error);
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      _isLoading = false;
    });
  }*/

  Future<void> loadLedgerData() async {
    setState(() {
      _isLoading = true;
    });

    // vchtype fetching
    try {
      final url = Uri.parse(HttpURL_loadLedgerData!);
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json",
      };

      var body = jsonEncode({"ledger": _selectedpartyledger});
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        /*print(response.body);*/

        List<dynamic> data = json.decode(response.body);

        String tinValue = data.first['tin'].toString();
        String address = data.first['address'].toString();

        String emirate = data.first['state'].toString();
        String country = data.first['country'].toString();

        /*print('trn value of $_selectedpartyledger is $tinValue');*/

        setState(() {
          showSalesInvoiceDialog(context, tinValue, address, emirate, country);
        });
      } else {
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';
        if (data.containsKey('error')) {
          setState(() {
            error = data['error'];
          });
        } else {
          error = 'Something went wrong!!!';
        }
        Fluttertoast.showToast(msg: error);
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchvchnos(String vchname) async {
    // Format the dates as yyyyMMdd
    String formattedStartDateVchNo = startfrom;
    String formattedEndDateVchNo = DateFormat('yyyyMMdd').format(yearEndDate);

    vchnos.clear();
    setState(() {
      _isLoading = true;
    });

    // vchnos fetching
    try {
      final url = Uri.parse(HttpURL_fetchvchnos!);
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json",
      };

      Map<String, dynamic> jsonDatabody = {
        "to": formattedEndDateVchNo,
        "from": formattedStartDateVchNo,
        "vchname": vchname,
      };

      debugPrint('body vch no -> $jsonDatabody');

      String jsonDatabodyString = jsonEncode(jsonDatabody);

      var body = jsonDatabodyString;
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        /*print(response.body);*/
        /*  setState(() {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          final List<dynamic> vchnosJson = jsonResponse['vchnos'];
          vchnos = vchnosJson.cast<String>();
          int q = vchnos.length;
          print('vchno list containes $q nos whos values are $vchnos');

          _vchnoController.clear();
          checkVchNoExistence(_vchnoController.text);
        });*/

        setState(() {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          final List<dynamic> vchnosJson = jsonResponse['vchnos'];

          print(response.body);
          vchnos = vchnosJson.cast<String>();

          // SORT first
          vchnos.sort((a, b) {
            RegExp regExp = RegExp(r'(\d+)(?!.*\d)');
            int numA = int.tryParse(regExp.firstMatch(a)?.group(0) ?? '0') ?? 0;
            int numB = int.tryParse(regExp.firstMatch(b)?.group(0) ?? '0') ?? 0;
            return numA.compareTo(numB);
          });

          debugPrint(' vch nos from api -> $vchnos');

          // GENERATE NEXT
          String nextVch = generateNextVchNo(vchnos);

          _vchnoController.text = nextVch;
        });
      } else {
        vchnos.clear();
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';
        if (data.containsKey('error')) {
          setState(() {
            error = data['error'];
          });
        } else {
          error = 'Something went wrong!!!';
        }
        Fluttertoast.showToast(msg: error);
      }
    } catch (e) {
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
        (item) => item["name"] == _selectedItem,
        orElse: () => null,
      );

      String salePrice = selectedItemInfo["saleprice"].toString();
      String standardPrice = selectedItemInfo["standardprice"].toString();

      /*print(selectedItemInfo);*/

      final List<dynamic> jsonList = selectedItemInfo["unit"];

      setState(() {
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
        } else {
          rateValue = (double.parse(salePrice) * selectedMultiplier);
          double roundedrateValue = double.parse(
            rateValue.toStringAsFixed(decimal!),
          );

          itemRateController.text = roundedrateValue.toString();
        }
      } else {
        rateValue = (double.parse(standardPrice) * selectedMultiplier);
        double roundedrateValue = double.parse(
          rateValue.toStringAsFixed(decimal!),
        );

        itemRateController.text = roundedrateValue.toString();
      }
      double amountValue = (double.parse(qtyValue) * rateValue);
      double roundedAmountValue = double.parse(
        amountValue.toStringAsFixed(decimal!),
      );

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
      amountValue.toStringAsFixed(decimal!),
    );

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
      amountValue.toStringAsFixed(decimal!),
    );

    NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
    String formattedAmount = formatter.format(roundedAmountValue);

    itemAmountController.text = formattedAmount.toString();
  }

  Future<void> _selectsaleDate(BuildContext context) async {
    setState(() {
      _isFocused_refno = false;
      _isFocused_narration = false;
    });
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: saledate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: app_color),
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

  Future<void> _selectrefDate(BuildContext context) async {
    setState(() {
      _isFocused_refno = false;
      _isFocused_narration = false;
    });
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: refdate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: app_color),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != refdate)
      setState(() {
        refdate = picked;
        refdatestring = _dateFormat.format(refdate);
        refdatetxt = formatlastsaledate(refdatestring);
        _refdateController.text = refdatetxt;
      });
  }

  /*Future<void> _showItemDetailsPopup(BuildContext context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        color: Theme.of(context).colorScheme.onSurface,
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
                                style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                suggestion['part'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            );
                          },

                          // 🔹 Required in new API (replaces onSuggestionSelected)

                          onSelected: (suggestion) {
                            setStateDialog(() {
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
                                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                                        onPressed: () {
                                          _itemController.clear();
                                          setStateDialog(() {
                                            _selecteditem = "";
                                            isVisibleLocation = false;
                                            isVisibleUnit = false;
                                          });
                                        },
                                      ),
                                    Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                            isExpanded: true,

                            value: selectedLocation,
                            items: locationsdata.map((value) {
                              return DropdownMenuItem(
                                value: value,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setStateDialog(() => selectedLocation = val!),
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
                              setStateDialog(() {
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

            },);}
    );
  }*/

  Future<void> _showItemDetailsPopup(BuildContext context) async {
    _selecteditem = null;
    _itemController.clear();
    itemRateController.clear();
    itemAmountController.clear();

    final String currentSerialNo = serial_no?.trim() ?? '';

    showModalBottomSheet(
      context: context,
      enableDrag: false,

      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final mediaQuery = MediaQuery.of(context);
            final screenHeight = mediaQuery.size.height;
            final keyboardOpen = mediaQuery.viewInsets.bottom > 0;

            final bool hasItemDetails =
                isVisibleUnit ||
                showRateField ||
                itemAmountController.text.isNotEmpty;

            double sheetSize;

            if (keyboardOpen) {
              sheetSize = screenHeight < 700 ? 0.95 : 0.82;
            } else if (hasItemDetails) {
              if (screenHeight < 700) {
                sheetSize = 0.90;
              } else if (screenHeight < 850) {
                sheetSize = 0.78;
              } else {
                sheetSize = 0.68;
              }
            } else {
              if (screenHeight < 700) {
                sheetSize = 0.65;
              } else if (screenHeight < 850) {
                sheetSize = 0.55;
              } else {
                sheetSize = 0.45;
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: DraggableScrollableSheet(
                initialChildSize: sheetSize,
                minChildSize: sheetSize,
                maxChildSize: keyboardOpen ? 0.95 : 0.90,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 14),

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
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Add Item",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.manual,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            child: Form(
                              key: _itemFormkey,
                              child: Column(
                                children: [
                                  TypeAheadField<Map<String, dynamic>>(
                                    controller: _itemController,
                                    decorationBuilder: (context, child) {
                                      return Material(
                                        elevation: 6,
                                        borderRadius: BorderRadius.circular(16),
                                        color: Theme.of(context).cardColor,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: child,
                                        ),
                                      );
                                    },
                                    suggestionsCallback: (pattern) async {
                                      return itemdata
                                          .where((item) {
                                            final name =
                                                item['name']
                                                    ?.toString()
                                                    .toLowerCase() ??
                                                '';
                                            final part =
                                                item['part']
                                                    ?.toString()
                                                    .toLowerCase() ??
                                                '';

                                            return name.contains(
                                                  pattern.toLowerCase(),
                                                ) ||
                                                part.contains(
                                                  pattern.toLowerCase(),
                                                );
                                          })
                                          .cast<Map<String, dynamic>>()
                                          .toList();
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(
                                          suggestion['name'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          suggestion['part'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    },
                                    onSelected: (suggestion) async {
                                      FocusScope.of(context).unfocus();

                                      setStateDialog(() {
                                        _selecteditem =
                                            suggestion['name']?.toString() ??
                                            '';

                                        selectedItemMasterId =
                                            suggestion['masterid']
                                                ?.toString() ??
                                            suggestion['itemId']?.toString() ??
                                            suggestion['id']?.toString();

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

                                      await fetchPriceLevelDetailsForSelectedItem(
                                        setStateDialog,
                                      );
                                    },
                                    builder: (context, controller, focusNode) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Item",
                                          hintText: "Search item",
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue,
                                                  Colors.lightBlueAccent,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.inventory_outlined,
                                              color: Colors.white,
                                            ),
                                          ),
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!isPriceLevelLoading &&
                                                  _itemController
                                                      .text
                                                      .isNotEmpty)
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    _itemController.clear();

                                                    setStateDialog(() {
                                                      _selecteditem = "";
                                                      selectedItemMasterId =
                                                          null;
                                                      itemRateController
                                                          .clear();
                                                      isVisibleLocation = false;
                                                      isVisibleUnit = false;
                                                    });
                                                  },
                                                ),
                                              if (!isPriceLevelLoading)
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              const SizedBox(width: 6),
                                            ],
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide(
                                              color: Theme.of(
                                                context,
                                              ).dividerColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide(
                                              color: app_color,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 14,
                                              ),
                                        ),
                                      );
                                    },
                                    emptyBuilder: (context) => Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        "No item found",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (isPriceLevelLoading)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 22,
                                            width: 22,
                                            child:
                                                Theme.of(context).platform ==
                                                    TargetPlatform.iOS
                                                ? const CupertinoActivityIndicator(
                                                    radius: 11,
                                                  )
                                                : CircularProgressIndicator(
                                                    strokeWidth: 2.4,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(app_color),
                                                  ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Loading item details...",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (!vanSalesSerialNo.contains(
                                    currentSerialNo,
                                  ))
                                    Visibility(
                                      visible: isVisibleLocation,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 14),

                                          DropdownButtonFormField<String>(
                                            isExpanded: true,

                                            value: selectedLocation,
                                            items: locationsdata.map((value) {
                                              return DropdownMenuItem(
                                                value: value,

                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: Text(
                                                    value,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                            onChanged: (val) => setStateDialog(
                                              () => selectedLocation = val!,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: "Location",
                                              labelStyle: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(8),
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.orange,
                                                      Colors.redAccent,
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                ),
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color: app_color,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (!isPriceLevelLoading) ...[
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child: Visibility(
                                        visible: isVisibleUnit,
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 14),
                                            DropdownButtonFormField<String>(
                                              value: _selectedunit,
                                              isExpanded: true,
                                              items: unitdata.map((u) {
                                                return DropdownMenuItem(
                                                  value: u.name,
                                                  child: Text(
                                                    u.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                setStateDialog(() {
                                                  _selectedunit = val!;
                                                  itemQuantityController.text =
                                                      "1";
                                                  selectedMultiplier = unitdata
                                                      .firstWhere(
                                                        (u) =>
                                                            u.name ==
                                                            _selectedunit,
                                                      )
                                                      .multiplier;
                                                  updateRateAndAmount();
                                                });
                                              },
                                              decoration: _inputDecoration(
                                                label: "Unit",
                                                icon: Icons.straighten,
                                                gradientColors: const [
                                                  Colors.purple,
                                                  Colors.deepPurpleAccent,
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: itemQuantityController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => updateRateAndAmount(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      decoration: _inputDecoration(
                                        label: "Quantity",
                                        icon: Icons.confirmation_num,
                                        gradientColors: const [
                                          Colors.green,
                                          Colors.lightGreen,
                                        ],
                                      ),
                                    ),

                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child: Visibility(
                                        visible: showRateField,
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 14),
                                            TextFormField(
                                              enabled: isRateFieldEnabled,
                                              controller: itemRateController,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: isRateFieldEnabled
                                                  ? (_) => updateAmount()
                                                  : null,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isRateFieldEnabled
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                              decoration: _currencyDecoration(
                                                label: "Rate",
                                                enabled: isRateFieldEnabled,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: itemAmountController,
                                      enabled: false,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      decoration: _currencyDecoration(
                                        label: "Amount",
                                        enabled: false,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        SafeArea(
                          top: false,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      /* setStateDialog(() {
                                        resetItemDialogFields();
                                      });*/

                                      _selectedledger = null;
                                      ledgerAmountController.clear();

                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.poppins(
                                        color: app_color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: app_color,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      "Add Item",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (_itemFormkey.currentState!
                                          .validate()) {
                                        addItem();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /*void _showLedgerDetailsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: Theme.of(context).colorScheme.onSurface,
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

                    /// Ledger Amount
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
  }*/

  void _showLedgerDetailsPopup(BuildContext context) {
    final TextEditingController _ledgerController = TextEditingController();

    _ledgerController.clear();
    _selectedledger = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final mediaQuery = MediaQuery.of(context);
            final screenHeight = mediaQuery.size.height;
            final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

            double sheetHeight;

            if (isKeyboardOpen) {
              if (screenHeight < 700) {
                sheetHeight = 0.95;
              } else if (screenHeight < 850) {
                sheetHeight = 0.88;
              } else {
                sheetHeight = 0.78;
              }
            } else {
              if (screenHeight < 700) {
                sheetHeight = 0.62;
              } else if (screenHeight < 850) {
                sheetHeight = 0.52;
              } else {
                sheetHeight = 0.42;
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: FractionallySizedBox(
                heightFactor: sheetHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (!isKeyboardOpen) ...[
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
                          child: const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      Text(
                        "Add Ledger",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.manual,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          child: Form(
                            key: _ledgerFormkey,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: TypeAheadField<String>(
                                      controller: _ledgerController,

                                      suggestionsCallback: (pattern) async {
                                        return ledgerdata
                                            .map<String>(
                                              (ledger) =>
                                                  ledger['name'].toString(),
                                            )
                                            .where(
                                              (item) =>
                                                  item.toLowerCase().contains(
                                                    pattern.toLowerCase(),
                                                  ),
                                            )
                                            .toList();
                                      },

                                      builder:
                                          (context, textController, focusNode) {
                                            return TextField(
                                              controller: textController,
                                              focusNode: focusNode,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              decoration: InputDecoration(
                                                hintText:
                                                    _selectedledger
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? _selectedledger
                                                    : "Select Ledger",
                                                labelText: "Ledger Name",
                                                hintStyle: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                labelStyle: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                prefixIcon: Container(
                                                  margin: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.blue,
                                                        Colors.lightBlueAccent,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .account_balance_wallet,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                suffixIcon: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (_ledgerController
                                                        .text
                                                        .isNotEmpty)
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.close,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _ledgerController
                                                                .clear();
                                                            _selectedledger =
                                                                "";
                                                          });
                                                        },
                                                      ),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                        width: 1,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: app_color,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                              ),
                                            );
                                          },

                                      decorationBuilder: (context, child) {
                                        return Material(
                                          elevation: 6,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          color: Theme.of(context).cardColor,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },

                                      itemBuilder:
                                          (context, String suggestion) {
                                            return ListTile(
                                              title: Text(
                                                suggestion,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                            );
                                          },

                                      onSelected: (String suggestion) {
                                        FocusScope.of(context).unfocus();

                                        setState(() {
                                          _selectedledger = suggestion;
                                          _ledgerController.text = suggestion;
                                        });
                                      },

                                      emptyBuilder: (context) => Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          "No ledger found",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                  child: TextFormField(
                                    controller: ledgerAmountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^-?\d*\.?\d*'),
                                      ),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter amount';
                                      } else if (double.tryParse(value) ==
                                          0.0) {
                                        return 'Amount cannot be 0';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Amount",
                                      hintText: "Enter Amount",
                                      prefix: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange,
                                              Colors.redAccent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
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
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).dividerColor,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();

                                    _selectedledger = ledgerdata.isNotEmpty
                                        ? ledgerdata[0]['name']
                                        : null;

                                    ledgerAmountController.clear();
                                  },
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.poppins(
                                      color: app_color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: app_color,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "Add Ledger",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_ledgerFormkey.currentState!
                                        .validate()) {
                                      _ledgerFormkey.currentState!.save();
                                      addLedger();
                                    }
                                  },
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
            );
          },
        );
      },
    );
  }

  void _recalculateTotals() {
    // Agar items empty hain to heading chhupao
    isVisibleItemHeading = saleItems.isNotEmpty;

    // Total items ka price
    totalPriceOfItems = saleItems.fold(0.0, (
      double previousAmount,
      SaleItem item,
    ) {
      return previousAmount +
          (double.parse(item.itemPrice.toStringAsFixed(decimal!)) *
              double.parse(item.itemQuantity));
    });

    // VAT calculation
    if (_selectedvatledger != 'Not Applicable') {
      double vatPerc = vatperc / 100;

      totalAmountForVatAppEntries = ledgerEntries
          .where((entry) => entry.vatApp)
          .fold(0.0, (double prev, LedgerEntry entry) {
            return prev + entry.ledgerAmount;
          });

      ledgerVatAmount = totalAmountForVatAppEntries * vatPerc;
      itemsVatAmount = double.parse(
        (totalPriceOfItems * vatPerc).toStringAsFixed(decimal!),
      );
      totalVatAmount = itemsVatAmount + ledgerVatAmount;

      roundedtotalVatAmount = double.parse(
        totalVatAmount.toStringAsFixed(decimal!),
      );

      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      controller_vatamt.text = formatter
          .format(roundedtotalVatAmount)
          .toString();
    } else {
      totalVatAmount = 0;
      roundedtotalVatAmount = double.parse(
        totalVatAmount.toStringAsFixed(decimal!),
      );
      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      controller_vatamt.text = formatter.format(0).toString();
    }

    // Ledger totals
    totalAmountOfLedgers = ledgerEntries.fold(
      0.0,
      (double prev, entry) => prev + entry.ledgerAmount,
    );

    // Final total
    totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
    roundedtotalAmount = double.parse(totalAmount.toStringAsFixed(decimal!));

    NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
    controller_totalamt.text = formatter.format(roundedtotalAmount).toString();
  }

  void addItem() {
    final itemName = _selecteditem;
    final itemQuantity = itemQuantityController.text;
    final itemPrice = itemRateController.text;
    final itemAmount = itemAmountController.text;
    final itemLocation = selectedLocation;
    final itemUnit = _selectedunit;

    final qty = double.tryParse(itemQuantity.replaceAll(',', '').trim()) ?? 0;

    if (itemQuantity.trim().isEmpty || qty <= 0) {
      Fluttertoast.showToast(
        msg: "Quantity must be greater than 0",
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
      return;
    }

    if (itemName.isNotEmpty && itemPrice.isNotEmpty) {
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
      int existingIndex = saleItems.indexWhere(
        (item) =>
            item.itemName == itemName &&
            double.parse(item.itemPrice.toStringAsFixed(decimal!)) ==
                parsedPrice &&
            item.itemUnit == itemUnit,
      );
      if (existingIndex != -1) {
        // Item already exists with the same name, price, and unit, update its quantity and amount
        SaleItem existingItem = saleItems[existingIndex];
        String newQuantity =
            (int.parse(existingItem.itemQuantity) + int.parse(parsedQuantity))
                .toString();
        double newAmount = parsedPrice * int.parse(newQuantity);
        saleItems[existingIndex] = existingItem
            .updateQuantity(newQuantity)
            .updateItemAmount(newAmount);
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
        } else {
          isVisibleItemHeading = true;
        }

        totalPriceOfItems = saleItems.fold(0.0, (
          double previousAmount,
          SaleItem item,
        ) {
          return previousAmount +
              (double.parse(item.itemPrice.toStringAsFixed(decimal!)) *
                  double.parse(item.itemQuantity));
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

          itemsVatAmount = double.parse(
            (totalPriceOfItems * vat_perc).toStringAsFixed(decimal!),
          );
          totalVatAmount = itemsVatAmount + ledgerVatAmount;

          roundedtotalVatAmount = double.parse(
            totalVatAmount.toStringAsFixed(decimal!),
          );

          NumberFormat formatter = NumberFormat(
            '#,##0.${'0' * decimal!}',
            'en_US',
          );
          String formattedVat = formatter.format(roundedtotalVatAmount);
          controller_vatamt.text = formattedVat.toString();
        } else {
          totalVatAmount = 0;
          roundedtotalVatAmount = double.parse(
            totalVatAmount.toStringAsFixed(decimal!),
          );
          NumberFormat formatter = NumberFormat(
            '#,##0.${'0' * decimal!}',
            'en_US',
          );
          String formattedVat = formatter.format(0);
          controller_vatamt.text = formattedVat.toString();
        }

        totalAmountOfLedgers = ledgerEntries.fold(0.0, (
          double previousAmount,
          LedgerEntry entry,
        ) {
          return previousAmount + entry.ledgerAmount;
        });

        totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
        roundedtotalAmount = double.parse(
          totalAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedtotal = formatter.format(roundedtotalAmount);
        controller_totalamt.text = formattedtotal.toString();

        _selecteditem = '${itemdata[0]['name']}';
        if (locationsdata.isNotEmpty) {
          selectedLocation = locationsdata[0];
          setState(() {
            isVisibleLocation = true;
          });
        } else {
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
      (ledger) => ledger['name'] == _selectedledger,
    );

    final ledgerName = specificLedger['name'];
    final ledgerAmount = ledgerAmountController.text;

    int vatApplicable = specificLedger['vatapplicable'];
    final vatApp = vatApplicable == 1 ? true : false;

    if (ledgerName.isNotEmpty && ledgerAmount.isNotEmpty) {
      // Create a new SaleItem object and add it to the list
      Navigator.of(context).pop();
      int existingIndex = ledgerEntries.indexWhere(
        (entry) => entry.ledgerName == ledgerName,
      );
      double parsedAmount = double.parse(ledgerAmount.replaceAll(',', ''));

      if (existingIndex != -1) {
        // Ledger already exists, update its amount
        LedgerEntry existingLedger = ledgerEntries[existingIndex];
        double newAmount = existingLedger.ledgerAmount + parsedAmount;

        // Update vatApp if necessary
        bool newVatApp =
            existingLedger.vatApp; // Initialize with the existing value
        newVatApp = vatApp;

        ledgerEntries[existingIndex] = existingLedger.updateAmount(
          newAmount,
          newVatApp,
        );
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
        } else {
          isVisibleLedgerHeading = true;
        }

        totalPriceOfItems = saleItems.fold(0.0, (
          double previousAmount,
          SaleItem item,
        ) {
          return previousAmount +
              (double.parse(item.itemPrice.toStringAsFixed(decimal!)) *
                  double.parse(item.itemQuantity));
        });

        if (_selectedvatledger != 'Not Applicable') {
          // Calculate the total ledger amount for entries with vatApp set to true
          totalAmountForVatAppEntries = ledgerEntries
              .where((entry) => entry.vatApp)
              .fold(0.0, (double previousAmount, LedgerEntry entry) {
                return previousAmount + entry.ledgerAmount;
              });

          double vat_perc = vatperc / 100;

          itemsVatAmount = double.parse(
            (totalPriceOfItems * vat_perc).toStringAsFixed(decimal!),
          );
          ledgerVatAmount = totalAmountForVatAppEntries * vat_perc;

          /*print('Total Ledger Amount for VAT-Applicable Entries: $totalAmountForVatAppEntries');
          print('5% VAT Amount: $ledgerVatAmount');*/

          totalVatAmount = itemsVatAmount + ledgerVatAmount;

          roundedtotalVatAmount = double.parse(
            totalVatAmount.toStringAsFixed(decimal!),
          );
          NumberFormat formatter = NumberFormat(
            '#,##0.${'0' * decimal!}',
            'en_US',
          );
          String formattedVat = formatter.format(roundedtotalVatAmount);
          controller_vatamt.text = formattedVat.toString();
        } else {
          totalVatAmount = 0;
          roundedtotalVatAmount = double.parse(
            totalVatAmount.toStringAsFixed(decimal!),
          );
          NumberFormat formatter = NumberFormat(
            '#,##0.${'0' * decimal!}',
            'en_US',
          );
          String formattedVat = formatter.format(0);
          controller_vatamt.text = formattedVat.toString();
        }
        totalAmountOfLedgers = ledgerEntries.fold(0.0, (
          double previousAmount,
          LedgerEntry entry,
        ) {
          return previousAmount + entry.ledgerAmount;
        });

        totalAmount = totalPriceOfItems + totalAmountOfLedgers + totalVatAmount;
        roundedtotalAmount = double.parse(
          totalAmount.toStringAsFixed(decimal!),
        );
        NumberFormat formatter = NumberFormat(
          '#,##0.${'0' * decimal!}',
          'en_US',
        );
        String formattedtotal = formatter.format(roundedtotalAmount);
        controller_totalamt.text = formattedtotal.toString();
        _selectedledger = ledgerdata.isNotEmpty ? ledgerdata[0]['name'] : null;
        ledgerAmountController.clear();
      });
    }
  }

  late String company_trn, company_address, company_emirate, company_country;

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
      startfrom =
          prefs.getString('startfrom') ??
          DateFormat('yyyyMMdd').format(yearStartDate);

      company_trn = prefs.getString("company_trn") ?? "null";
      company_address = prefs.getString("company_address") ?? "null";
      company_emirate = prefs.getString("company_emirate") ?? "null";
      company_country = prefs.getString("company_country") ?? "null";

      vatperc = prefs.getDouble('vatperc') ?? 5.0;

      decimal = prefs.getInt('decimalplace') ?? 2;

      saledate = DateTime.now();
      saledatestring = _dateFormat.format(saledate);
      saledatetxt = formatlastsaledate(saledatestring);
      _dateController.text = saledatetxt;

      refdate = DateTime.now();
      refdatestring = _dateFormat.format(refdate);
      refdatetxt = formatlastsaledate(refdatestring);
      _refdateController.text = refdatetxt;

      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      String? email_nav = prefs.getString('email_nav');
      String? name_nav = prefs.getString('name_nav');

      HttpURL_loadData =
          '$hostname/api/entry/getSalesData/$company_lowercase/$serial_no';
      /*HttpURL_loadData = 'http://192.168.2.110:4999/api/entry/getSalesData/$company_lowercase/$serial_no';*/

      HttpURL_loadLedgerData =
          '$hostname/api/ledger/getLedger/$company_lowercase/$serial_no';
      /*HttpURL_loadLedgerData = 'http://192.168.2.110:4999/api/ledger/getLedger/$company_lowercase/$serial_no';*/

      HttpURL_fetchvchnos =
          '$hostname/api/entry/nos/$company_lowercase/$serial_no';
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
      } else {
        isRolesVisible = false;
        isUserVisible = false;
      }
    });
    await loadData();
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initSharedPreferences();
  }

  @override
  void dispose() {
    _textFieldFocusNodeNarration
        .dispose(); // Dispose of the focus node when it's no longer needed.
    _animationController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    // Simple email validation pattern
    final RegExp emailRegex = RegExp(
      r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat(
      "#,##0.${'0' * decimal!}", // 👈 dynamically repeat '0' for decimal places
    );

    final bool canEditVoucherNo =
        SecuritybtnAcessHolder.toString().toLowerCase() == 'true';
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(
        activeTab: AppBottomNavTab.entries,
        activeEntryType: AppEntryType.sales,
      ),
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          backgroundColor: app_color,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PendingSalesEntry()),
              );
            },
          ),
          centerTitle: true,
          title: GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    "New Sales Entry" ?? '',
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
          actions: [
            IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () {
                themeController.setThemeMode(
                  Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
              },
            ),
          ],
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PendingSalesEntry()),
          );
          return false;
        },

        child: Stack(
          children: [
            ListView(
              children: [
                /*GestureDetector(
            onTap: () => _selectDateRangeVchNo(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.9),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

            Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    ),*/
                Container(
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: TextFormField(
                                controller: _dateController,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                readOnly: true,
                                enableInteractiveSelection: false,
                                decoration: InputDecoration(
                                  labelText: "Date",
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      (Theme.of(
                                            context,
                                          ).inputDecorationTheme.fillColor ??
                                          Theme.of(
                                            context,
                                          ).cardColor.withOpacity(0.95)),
                                  prefixIcon: GestureDetector(
                                    onTap: () => _selectsaleDate(context),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            app_color,
                                            app_color.withOpacity(0.7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).dividerColor,
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 14,
                                  ),
                                ),

                                //  onTap: () => _selectsaleDate(context),
                                onTap: () {},
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: TextFormField(
                                controller: _vchnoController,

                                // Editable only when security access is true
                                readOnly: !canEditVoucherNo,
                                enableInteractiveSelection: canEditVoucherNo,
                                onChanged: canEditVoucherNo
                                    ? (value) {
                                        checkVchNoExistence(value.trim());
                                      }
                                    : null,

                                keyboardType: TextInputType.text,

                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: canEditVoucherNo
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),

                                decoration: InputDecoration(
                                  labelText: "Voucher No.",
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),

                                  errorText: errorMessageVchNo.isNotEmpty
                                      ? errorMessageVchNo
                                      : null,

                                  filled: true,
                                  fillColor: canEditVoucherNo
                                      ? Theme.of(
                                          context,
                                        ).inputDecorationTheme.fillColor
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                            : Colors.grey.shade100),

                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: canEditVoucherNo
                                            ? [Colors.teal, Colors.tealAccent]
                                            : [
                                                Colors.deepOrangeAccent,
                                                Colors.orangeAccent,
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    child: Icon(
                                      canEditVoucherNo
                                          ? Icons.edit_note_rounded
                                          : Icons.confirmation_num_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),

                                  suffixIcon: canEditVoucherNo
                                      ? const Icon(
                                          Icons.edit,
                                          color: Colors.teal,
                                          size: 20,
                                        )
                                      : Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          size: 20,
                                        ),

                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: canEditVoucherNo
                                          ? Colors.teal.shade200
                                          : Theme.of(context).dividerColor,
                                      width: 1,
                                    ),
                                  ),

                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: canEditVoucherNo
                                          ? Colors.teal
                                          : Theme.of(context).dividerColor,
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

                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                      width: 1.5,
                                    ),
                                  ),

                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 14,
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(
                                top: 0,
                                left: 20,
                                right: 20,
                                bottom: 0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Duplicate voucher numbers in Tally will trigger automatic assignment of a new number.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                left: 20,
                                right: 20,
                                bottom: 0,
                              ),
                              child: IgnorePointer(
                                ignoring: isVoucherTypeLocked,
                                child: Opacity(
                                  opacity: isVoucherTypeLocked ? 0.7 : 1,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,

                                    decoration: InputDecoration(
                                      filled: true,

                                      fillColor: isVoucherTypeLocked
                                          ? (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                : Colors.grey.shade100)
                                          : (Theme.of(context)
                                                    .inputDecorationTheme
                                                    .fillColor ??
                                                Theme.of(
                                                  context,
                                                ).cardColor.withOpacity(0.95)),

                                      labelText: "Voucher Type",

                                      labelStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),

                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),

                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isVoucherTypeLocked
                                                ? [
                                                    Colors.grey,
                                                    Colors.grey.shade600,
                                                  ]
                                                : [
                                                    Colors.purpleAccent,
                                                    Colors.deepPurple,
                                                  ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),

                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),

                                        child: Icon(
                                          isVoucherTypeLocked
                                              ? Icons.lock_outline
                                              : Icons.discount_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).dividerColor,
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
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                    ),

                                    hint: Text(
                                      isVoucherTypeLocked
                                          ? "Voucher Type Locked"
                                          : "Voucher Type",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      );
                                    }).toList(),

                                    onChanged: isVoucherTypeLocked
                                        ? null
                                        : (value) async {
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
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                left: 20,
                                right: 20,
                                bottom: 0,
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: TypeAheadField<String>(
                                  controller: _partyLedgerController,
                                  suggestionsCallback: (pattern) async {
                                    return partyledgerdata
                                        .where(
                                          (item) => item.toLowerCase().contains(
                                            pattern.toLowerCase(),
                                          ),
                                        )
                                        .toList();
                                  },

                                  // 🔹 Modern text field builder
                                  builder: (context, textController, focusNode) {
                                    return TextField(
                                      controller: textController,
                                      focusNode: focusNode,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            _selectedpartyledger?.isNotEmpty ==
                                                true
                                            ? _selectedpartyledger
                                            : "Select Party Ledger",
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        labelText: "Party Ledger",
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        filled: true,
                                        fillColor:
                                            Theme.of(
                                              context,
                                            ).inputDecorationTheme.fillColor ??
                                            (Theme.of(context)
                                                    .inputDecorationTheme
                                                    .fillColor ??
                                                Theme.of(
                                                  context,
                                                ).cardColor.withOpacity(0.95)),

                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.greenAccent,
                                                Colors.teal,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),

                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_partyLedgerController
                                                .text
                                                .isNotEmpty)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _partyLedgerController
                                                        .clear();
                                                    _selectedpartyledger = "";
                                                    selectedPartyLedgerPriceLevel =
                                                        null;
                                                  });
                                                },
                                              ),

                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                        ),

                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).dividerColor,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: app_color,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                      ),
                                    );
                                  },

                                  // 🔹 Custom dropdown style
                                  decorationBuilder: (context, child) {
                                    return Material(
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(16),
                                      color: Theme.of(
                                        context,
                                      ).cardColor, // 👈 dropdown background white
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          16,
                                        ), // 👈 rounded corners
                                        child: child,
                                      ),
                                    );
                                  },

                                  // 🔹 Suggestion item UI
                                  itemBuilder: (context, String suggestion) {
                                    return ListTile(
                                      title: Text(
                                        suggestion,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },

                                  // 🔹 On item select
                                  onSelected: (String suggestion) {
                                    setState(() {
                                      _selectedpartyledger = suggestion;
                                      _partyLedgerController.text = suggestion;

                                      selectedPartyLedgerPriceLevel =
                                          partyLedgerPriceLevelMap[suggestion];

                                      debugPrint(
                                        'selected party ledger -> $_selectedpartyledger',
                                      );
                                      debugPrint(
                                        'selected price level -> $selectedPartyLedgerPriceLevel',
                                      );
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    });
                                  },

                                  // 🔹 Empty result text
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

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                left: 20,
                                right: 20,
                                bottom: 0,
                              ),
                              child: IgnorePointer(
                                ignoring: isSalesLedgerLocked,
                                child: Opacity(
                                  opacity: isSalesLedgerLocked ? 0.7 : 1,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,

                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isSalesLedgerLocked
                                          ? (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                : Colors.grey.shade100)
                                          : (Theme.of(context)
                                                    .inputDecorationTheme
                                                    .fillColor ??
                                                Theme.of(
                                                  context,
                                                ).cardColor.withOpacity(0.95)),

                                      labelText: "Sales Ledger",

                                      labelStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),

                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isSalesLedgerLocked
                                                ? [
                                                    Colors.grey,
                                                    Colors.grey.shade600,
                                                  ]
                                                : [
                                                    Colors.blueAccent,
                                                    Colors.indigo,
                                                  ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Icon(
                                          isSalesLedgerLocked
                                              ? Icons.lock_outline
                                              : Icons.sell_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).dividerColor,
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
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                    ),

                                    hint: Text(
                                      isSalesLedgerLocked
                                          ? "Sales Ledger Locked"
                                          : "Sales Ledger",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      );
                                    }).toList(),

                                    onChanged: isSalesLedgerLocked
                                        ? null
                                        : (value) async {
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
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 8,
                                top: 12,
                              ),
                              child: TextFormField(
                                controller: _refdateController,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Reference Date",
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      (Theme.of(
                                            context,
                                          ).inputDecorationTheme.fillColor ??
                                          Theme.of(
                                            context,
                                          ).cardColor.withOpacity(0.95)),

                                  // Prefix Icon with new gradient (pink → purple)
                                  prefixIcon: GestureDetector(
                                    onTap: () => _selectrefDate(context),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.pinkAccent,
                                            Colors.deepPurpleAccent,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.event, // changed icon for variety
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),

                                  // Borders
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).dividerColor,
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

                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 14,
                                  ),
                                ),
                                readOnly: true,
                                onTap: () => _selectrefDate(context),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              child: TextFormField(
                                enabled: true,
                                controller: controller_refno,
                                validator: (value) {
                                  return null;
                                },
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Reference No",
                                  hintText: "Enter reference no",
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _isFocused_refno
                                        ? app_color
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      (Theme.of(
                                            context,
                                          ).inputDecorationTheme.fillColor ??
                                          Theme.of(
                                            context,
                                          ).cardColor.withOpacity(0.95)),

                                  // Gradient Prefix Icon (Red → Orange)
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.redAccent,
                                          Colors.deepOrange,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.link,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),

                                  // Borders
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).dividerColor,
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 14,
                                  ),
                                ),

                                // Focus state handling
                                onChanged: (value) {
                                  setState(() {
                                    _isFocused_narration = false;
                                    _isFocused_totalamt = false;
                                    _isFocused_refno = true;
                                    _isFocused_vatamt = false;
                                    _isFocused_vchno = false;
                                  });
                                },
                                onFieldSubmitted: (value) {
                                  setState(() {
                                    _isFocused_refno = false;
                                  });
                                },
                                onTap: () {
                                  setState(() {
                                    _isFocused_narration = false;
                                    _isFocused_totalamt = false;
                                    _isFocused_refno = true;
                                    _isFocused_vatamt = false;
                                    _isFocused_vchno = false;
                                  });
                                },
                                onEditingComplete: () {
                                  setState(() {
                                    _isFocused_refno = false;
                                  });
                                },
                              ),
                            ),

                            Container(
                              margin: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 10,
                                bottom: 5,
                              ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      children: [
                                        // Gradient start icon
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.purple,
                                                Colors.blue,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.purple
                                                    .withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.shopping_cart,
                                            color: Colors.white,
                                            size: 20,
                                          ),
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
                                                colors: [
                                                  Colors.teal,
                                                  Colors.green,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.teal
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Items List with swipe-to-delete
                                  ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: saleItems.length,
                                    itemBuilder: (context, index) {
                                      final item = saleItems[index];

                                      return Dismissible(
                                        key: UniqueKey(),
                                        direction: DismissDirection
                                            .endToStart, // swipe left to delete
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          color: Colors.redAccent,
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        onDismissed: (direction) {
                                          _deleteSaleItem(index);
                                        },

                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 3,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Theme.of(
                                                context,
                                              ).dividerColor,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.03,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Item Name
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.shopping_bag,
                                                    color: Colors.teal,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      item.itemName,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                          ),
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: null,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 10),

                                              // Qty Row
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Qty",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  // Minus Button
                                                  InkWell(
                                                    onTap: () {
                                                      int currentQty =
                                                          int.tryParse(
                                                            item.itemQuantity,
                                                          ) ??
                                                          0;
                                                      if (currentQty > 1) {
                                                        setState(() {
                                                          item.itemQuantity =
                                                              (currentQty - 1)
                                                                  .toString();
                                                          _recalculateTotals();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          saleItems.removeAt(
                                                            index,
                                                          );
                                                          _recalculateTotals();
                                                        });
                                                      }
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.redAccent
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 18,
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 6),

                                                  // Qty Display (Non-editable)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6,
                                                          horizontal: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Theme.of(context)
                                                                .colorScheme
                                                                .surfaceContainerHighest
                                                          : Colors
                                                                .grey
                                                                .shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      item.itemQuantity,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                          ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 6),

                                                  // Plus Button
                                                  InkWell(
                                                    onTap: () {
                                                      int currentQty =
                                                          int.tryParse(
                                                            item.itemQuantity,
                                                          ) ??
                                                          0;
                                                      setState(() {
                                                        item.itemQuantity =
                                                            (currentQty + 1)
                                                                .toString();
                                                        _recalculateTotals();
                                                      });
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 18,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),

                                              // Rate Section
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Rate",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6,
                                                          horizontal: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Theme.of(context)
                                                                .colorScheme
                                                                .surfaceContainerHighest
                                                          : Colors
                                                                .grey
                                                                .shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "${getCurrencySymbol(currencycode)} ${currencyFormat.format(double.parse(item.itemPrice.toStringAsFixed(decimal!)))}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
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
                              margin: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 5,
                                bottom: 10,
                              ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      children: [
                                        // Gradient start icon
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.redAccent,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.purple
                                                    .withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.list,
                                            color: Colors.white,
                                            size: 20,
                                          ),
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
                                                colors: [
                                                  Colors.orange,
                                                  Colors.orange,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.teal
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Ledger List
                                  ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: ledgerEntries.length,
                                    itemBuilder: (context, index) {
                                      final item = ledgerEntries[index];

                                      return Dismissible(
                                        key: UniqueKey(),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        onDismissed: (direction) {
                                          _deleteLedger(index);
                                        },

                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 3,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: Theme.of(
                                                context,
                                              ).dividerColor,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.03,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Ledger Icon + Name
                                              Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                                color: app_color,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 6,
                                                child: Text(
                                                  item.ledgerName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                                  overflow:
                                                      TextOverflow.visible,
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
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
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
                                    padding: const EdgeInsets.only(
                                      top: 20,
                                      left: 20,
                                      right: 5,
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: "VAT Ledger",
                                        labelStyle: GoogleFonts.poppins(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        // 🌈 Gradient Icon Container
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.indigo,
                                                Colors.cyan,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_long_outlined,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: app_color,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
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
                                                prev +
                                                (double.parse(
                                                      item.itemPrice
                                                          .toStringAsFixed(
                                                            decimal!,
                                                          ),
                                                    ) *
                                                    double.parse(
                                                      item.itemQuantity,
                                                    )),
                                          );

                                          totalAmountOfLedgers = ledgerEntries
                                              .fold(
                                                0.0,
                                                (
                                                  double prev,
                                                  LedgerEntry entry,
                                                ) => prev + entry.ledgerAmount,
                                              );

                                          if (_selectedvatledger ==
                                              'Not Applicable') {
                                            totalVatAmount = 0;
                                            roundedtotalVatAmount =
                                                double.parse(
                                                  totalVatAmount
                                                      .toStringAsFixed(
                                                        decimal!,
                                                      ),
                                                );
                                            NumberFormat formatter =
                                                NumberFormat(
                                                  '#,##0.${'0' * decimal!}',
                                                  'en_US',
                                                );
                                            controller_vatamt.text = formatter
                                                .format(0);
                                          } else {
                                            double
                                            totalAmountForLedgerVatAppEntries =
                                                ledgerEntries
                                                    .where(
                                                      (entry) => entry.vatApp,
                                                    )
                                                    .fold(
                                                      0.0,
                                                      (
                                                        double prev,
                                                        LedgerEntry entry,
                                                      ) =>
                                                          prev +
                                                          entry.ledgerAmount,
                                                    );

                                            double vat_perc = vatperc / 100;
                                            itemsVatAmount = double.parse(
                                              (totalPriceOfItems * vat_perc)
                                                  .toStringAsFixed(decimal!),
                                            );
                                            ledgerVatAmount =
                                                totalAmountForLedgerVatAppEntries *
                                                vat_perc;
                                            totalVatAmount =
                                                itemsVatAmount +
                                                ledgerVatAmount;

                                            roundedtotalVatAmount =
                                                double.parse(
                                                  totalVatAmount
                                                      .toStringAsFixed(
                                                        decimal!,
                                                      ),
                                                );
                                            NumberFormat formatter =
                                                NumberFormat(
                                                  '#,##0.${'0' * decimal!}',
                                                  'en_US',
                                                );
                                            controller_vatamt.text = formatter
                                                .format(roundedtotalVatAmount);
                                          }

                                          totalAmount =
                                              totalPriceOfItems +
                                              totalAmountOfLedgers +
                                              totalVatAmount;
                                          roundedtotalAmount = double.parse(
                                            totalAmount.toStringAsFixed(
                                              decimal!,
                                            ),
                                          );
                                          NumberFormat formatter = NumberFormat(
                                            '#,##0.${'0' * decimal!}',
                                            'en_US',
                                          );
                                          controller_totalamt.text = formatter
                                              .format(roundedtotalAmount);
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 20,
                                      left: 5,
                                      right: 20,
                                    ),
                                    child: TextFormField(
                                      enabled: false,
                                      controller: controller_vatamt,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: "VAT Amount",
                                        labelStyle: GoogleFonts.poppins(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),

                                        // 🌈 Gradient Currency Symbol (inline instead of icon)
                                        prefix: Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.green,
                                                Colors.teal,
                                              ], // ✅ distinct from Ledger
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8),
                                            ),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: app_color,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: TextFormField(
                                controller: controller_narration,
                                focusNode: _textFieldFocusNodeNarration,
                                validator: (value) => null,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Narration",
                                  hintText: "Enter narration",
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  labelStyle: GoogleFonts.poppins(
                                    color: _isFocused_narration
                                        ? app_color
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),

                                  // 🌈 Gradient Icon (Notes)
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.pinkAccent,
                                          Colors.deepOrange,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.notes_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),

                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      (Theme.of(
                                            context,
                                          ).inputDecorationTheme.fillColor ??
                                          Theme.of(
                                            context,
                                          ).cardColor.withOpacity(0.95)),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),

                                  // Borders
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: app_color,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isFocused_narration = true;
                                    _isFocused_vchno = false;
                                    _isFocused_vatamt = false;
                                    _isFocused_totalamt = false;
                                    _isFocused_refno = false;
                                  });
                                },
                                onFieldSubmitted: (value) {
                                  setState(() {
                                    _isFocused_narration = false;
                                    _isFocused_vchno = false;
                                    _isFocused_vatamt = false;
                                    _isFocused_totalamt = false;
                                    _isFocused_refno = false;
                                  });
                                },
                                onTap: () {
                                  setState(() {
                                    _isFocused_narration = true;
                                    _isFocused_vchno = false;
                                    _isFocused_vatamt = false;
                                    _isFocused_totalamt = false;
                                    _isFocused_refno = false;
                                  });
                                },
                                onEditingComplete: () {
                                  setState(() {
                                    _isFocused_narration = false;
                                    _isFocused_vchno = false;
                                    _isFocused_vatamt = false;
                                    _isFocused_totalamt = false;
                                    _isFocused_refno = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                          top: 15,
                          left: 20,
                          right: 20,
                          bottom: 0,
                        ),
                        child: TextFormField(
                          enabled: false,
                          controller: controller_totalamt,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,4}'),
                            ),
                          ],
                          keyboardType: TextInputType.number,
                          validator: (value) => null,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Total Amount',
                            hintText: 'Enter total amount',

                            // 🌈 Gradient Currency Symbol (cool tone, unique)
                            prefix: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.indigo,
                                    Colors.blueAccent,
                                  ], // 🔵 unique from narration
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                getCurrencySymbol(
                                  currencycode,
                                ), // e.g. AED, $, ₹
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
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
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
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            labelStyle: GoogleFonts.poppins(
                              color: _isFocused_totalamt
                                  ? app_color
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest
                                      : Colors.grey.shade50),
                          ),

                          // Focus State
                          onTap: () {
                            setState(() {
                              _isFocused_totalamt = true;
                              _isFocused_narration = false;
                              _isFocused_refno = false;
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
                        margin: const EdgeInsets.only(
                          bottom: 30,
                          left: 20,
                          right: 20,
                        ),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // pill shape
                            ),
                            elevation: 8,
                            backgroundColor:
                                app_color, // ✅ always full app_color
                            disabledBackgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300, // disabled state
                            shadowColor: app_color.withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 🌟 Modern Save Icon (circular background inside button)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor
                                      .withOpacity(
                                        0.2,
                                      ), // soft white tint inside
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Visibility(
              visible: _isLoading,
              child: Center(child: AppLogoLoader()),
            ),
          ],
        ),
      ),
    );
  }
}
