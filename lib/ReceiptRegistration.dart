import 'dart:convert';
import 'dart:io';
import 'package:FincoreGo/Items.dart';
import 'package:FincoreGo/PendingReceiptEntry.dart';
import 'package:FincoreGo/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptRegistration extends StatefulWidget
{
  const ReceiptRegistration({Key? key}) : super(key: key);
  @override
  _ReceiptRegistrationPageState createState() => _ReceiptRegistrationPageState();
}

class Bills {
  final String billName;
  final double billAmount;
  final String? billNo;
  final String? billDueDate;

  Bills({
    required this.billName,
    required this.billAmount,
    required this.billNo,
    required this.billDueDate,
  });
}

class Cheque {

  final String instno;
  final String? instdate;
  final String? bankname;
  final double chequeAmount;
  final String paymentMode;

  Cheque({
    required this.instno,
    required this.instdate,
    required this.bankname,
    required this.chequeAmount,
    required this.paymentMode,
  });
}

class _ReceiptRegistrationPageState extends State<ReceiptRegistration> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false;

  late DateTime now = DateTime.now();

  // Current year start date
  late DateTime yearStartDate = DateTime(now.year, 1, 1);

  // Current year end date
  late DateTime yearEndDate = DateTime(now.year, 12, 31);

  TextEditingController _partyController = TextEditingController();

  TextEditingController _bankcashnameController = TextEditingController();

  final TextEditingController _vchnoController = TextEditingController();

  TextEditingController billNoController = TextEditingController();

  TextEditingController _banknameController = TextEditingController();

  late final TextEditingController controller_narration = TextEditingController();

  final FocusNode _textFieldFocusNodeNarration = FocusNode();

  double totalBillAmount = 0;

  double totalChequeAmount = 0;

  late List<String> vchtypenamedata = [];


  void _deleteBill(int index) {
    setState(() {
      bills.removeAt(index);
      // Calculate the total price of items
      totalBillAmount = bills
          .fold(
          0.0, (double previousAmount,
          Bills bill) {
        return previousAmount + bill.billAmount;
      });

      roundedtotalBillAmount = double.parse(totalBillAmount.toStringAsFixed(decimal!));
      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      String formattedtotal = formatter.format(roundedtotalBillAmount);
      controller_totalamt.text = formattedtotal.toString();

      if (bills.isEmpty) {
        isVisibleBillHeading = false;
        isChequeVisible = false;
        _selectedpaymentmode = paymentmode_data.first;
        cheque.clear();
        updateChequeAmount();
        instNoController.clear();
        selectedbankname = bankname_data.first;
        _banknameController.text = selectedbankname;
        chequeAmountController.clear();
        instdate = DateTime.now();
        instdatestring = _dateFormat.format(instdate);
        instdatetxt = formatlastsaledate(instdatestring);
        instDateController.text = instdatetxt;
        isVisibleChequeHeading = false;
        isPaymentModeVisible = false;
      }
      else
      {
        isVisibleBillHeading = true;
        if (_selectedbankcashname != null && _selectedbankcashname!['type'] == 'Cash-in-Hand') {

          isPaymentModeVisible = false;
          _selectedpaymentmode = paymentmode_data.first;
          cheque.clear();
          updateChequeAmount();
          isVisibleChequeHeading = false;
          isChequeVisible = false;
        }
        else
        {
          if(bills.isNotEmpty)
          {
            if(cheque.isNotEmpty)
            {
              isPaymentModeVisible = true;
              isChequeVisible = true;
              isVisibleChequeHeading = true;
            }
            else
            {
              isPaymentModeVisible = true;
              _selectedpaymentmode = paymentmode_data.first;
              cheque.clear();
              updateChequeAmount();

              isVisibleChequeHeading = false;
              isChequeVisible = true;
            }
          }
          else
          {
            isPaymentModeVisible = true;
            _selectedpaymentmode = paymentmode_data.first;
            cheque.clear();
            updateChequeAmount();

            isVisibleChequeHeading = false;
            isChequeVisible = false;
          }
        }
      }
      if(roundedtotalBillAmount < roundedtotalChequeAmount)
      {
        cheque.clear();
        updateChequeAmount();
        isVisibleChequeHeading = false;
      }
    });
  }

  Map<String, dynamic> jsonEntryData =
  {
    "DATE": "",
    "VOUCHERTYPENAME": "",
    "PARTYLEDGERNAME": "",
    "VOUCHERNUMBER" : "",
    "ENTEREDBY": "",
    "NARRATION": "",
    "ALLLEDGERENTRIES.LIST": [],
  };

  bool isVisibleBillHeading = false,isVisibleChequeHeading = false,isChequeVisible = false;

  final _formKey = GlobalKey<FormState>();

  late String _selectedvchtypename = '';

  String selectedbankname = '';

  String errorMessageVchNo = '';

  List<String> vchnos = [];

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

  bool isInstNoRepeated(String instNo, List<Cheque> cheques) {
    if(instNo.isNotEmpty)
      {
        for (var cheque in cheques)
        {
          if (cheque.instno == instNo)
          {
            return true; // Found a match, instno is repeated
          }
        }
      }
    return false; // No match found
  }

  GlobalKey<FormState> _billsFormkey = GlobalKey<FormState>();

  GlobalKey<FormState> _chequedetailsFormkey = GlobalKey<FormState>();

  double roundedtotalVatAmount = 0.0;

  double roundedtotalBillAmount = 0.0;

  double roundedtotalChequeAmount = 0.0;

  List<Map<String, String>> bankcashname_data = [];

  List<String> paymentmode_data = [];

  bool isPaymentModeVisible = false;

  late int? decimal;

  late List<String> partydata = [];

  List<String> bankname_data = ['Not Applicable',"RAK Bank (UAE)", "Mashreq Bank (UAE)", "National Bank of Abu Dhabi (UAE)", "ADCB (UAE)", "Arab Bank (UAE)", "Commercial Bank of Dubai (UAE)", "Emirates NBD (UAE)", "Habib Bank AG Zurich (UAE)", "National Bank of Fujairah (UAE)", "Standard Chartered Bank (UAE)", "Bank of Baroda (UAE)", "HSBC Bank (UAE)", "Union National Bank (UAE)", "United Arab Bank (UAE)", "Al Ahli Bank of Kuwait (UAE)", "Noor Islamic Bank (UAE)", "Emirates Bank (UAE)", "Emirates Islamic Bank (UAE)", "United Bank Ltd. (UAE)", "Dubai Islamic Bank (UAE)", "ADIB (UAE)", "Bank of Sharjah (UAE)", "Blom Bank France (UAE)", "First Gulf Bank (UAE)", "Invest Bank (UAE)", "Habib Bank Limited (UAE)", "Oman Arab Bank (UAE)", "NBAD(UAE)", "NCB Bank(UAE)", "NBQ Bank (UAE)", "HBL Bank (UAE)", "Al Hilal Bank(UAE)", "FGB (UAE)", "Sharjah Islamic Bank(UAE)", "Noor Bank(UAE)", "CBI - Commercial Bank International (UAE)", "Janata Bank Ltd (UAE)", "Ajman Bank (UAE)", "Bank Melli Iran (UAE)", "FAB - First Abu Dhabi Bank (UAE)", "Citi Bank (UAE)", "The Saudi British Bank (UAE)", "BNP Paribas (UAE)", "Arab African International Bank (UAE)", "AL Masraf (UAE)", "Banque Misr (UAE)", "Samba Financial Group (UAE)"];

  List<String> billsdata = ['On Account', 'New Ref', 'Agst Ref'];

  String user_email_fetched = "",token = '';

  bool isVisibleDueDate = false, isVisibleBillNo = false;

  String name = "", email = "", receiptdatestring = '', receiptdatetxt = '',instdatestring = '', instdatetxt = '',currencycode = '',billduedatestring = '', billduedatetxt = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late SharedPreferences prefs;

  dynamic _selectedbill, _selectedparty;

  Map<String, String>? _selectedbankcashname;

  late dynamic _selectedpaymentmode = '';

  late final TextEditingController controller_totalamt = TextEditingController();

  String formatAmountVoucher(String amount) {
    int? decimal = prefs?.getInt('decimalplace') ?? 2;

    String amount_string = "";
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

  void showReceiptVoucherBottomSheet(BuildContext context) {
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
                  'Do you want to share the receipt voucher?',
                  textAlign: TextAlign.center,

                  style: GoogleFonts.poppins(fontSize: 18.0),
                ),
                SizedBox(height: 10),
                Text(
                  'Receipt Voucher Created Successfully',
                  textAlign: TextAlign.center,

                  style: GoogleFonts.poppins(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                // Add your sales invoice details here
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          controller_narration.clear();
                          _textFieldFocusNodeNarration.unfocus(); // Unfocus the TextField

                          receiptdate = DateTime.now();
                          receiptdatestring = _dateFormat.format(receiptdate);
                          receiptdatetxt = formatlastsaledate(receiptdatestring);
                          _dateController.text = receiptdatetxt;
                          _selectedvchtypename = vchtypenamedata.first;
                          fetchvchnos(_selectedvchtypename);
                          _selectedparty = partydata.first;
                          _partyController.text = _selectedparty;

                          _selectedbankcashname = bankcashname_data.first;
                          _bankcashnameController.text = _selectedbankcashname!=null ? _selectedbankcashname!['name']! : "" ;

                          bills.clear();
                          cheque.clear();

                          updateChequeAmount();

                          totalBillAmount = bills.fold(0.0,(double previousAmount, Bills bill) {
                            return previousAmount + bill.billAmount;
                          },
                          );
                          roundedtotalBillAmount = double.parse(totalBillAmount.toStringAsFixed(decimal!));
                          NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
                          String formattedtotal = formatter.format(roundedtotalBillAmount);
                          controller_totalamt.text = formattedtotal.toString();

                          if (bills.isEmpty)
                          {
                            isVisibleBillHeading = false;
                          }
                          else
                          {
                            isVisibleBillHeading = true;
                          }

                          if (cheque.isEmpty)
                          {
                            isVisibleChequeHeading = false;
                          }
                          else
                          {
                            isVisibleChequeHeading = true;
                          }
                        });
                        Navigator.pop(context); // Close the bottom sheet
                        // Action when "No Thanks" button is clicked
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        'No, Thanks',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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
                        await generateVoucherPDF();
                      },
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
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
                        backgroundColor: app_color, // ✅ your theme color
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // pill style
                        ),
                        elevation: 4,
                        shadowColor: app_color.withOpacity(0.3), // subtle shadow
                      ),
                    )

                  ],
                ),

                
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> generateVoucherPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Header Section
                  pw.Header(
                    level: 0,
                    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide.none)),
                    child: pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(company!, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18)),
                          pw.SizedBox(height: 20),
                          pw.Text('Receipt Voucher', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Voucher Info Row
                  pw.Table(
                    border: pw.TableBorder(horizontalInside: pw.BorderSide.none, verticalInside: pw.BorderSide.none, bottom: pw.BorderSide.none),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: pw.EdgeInsets.all(5),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Row(
                                children: [
                                  pw.Text('No. : ', style: pw.TextStyle(fontSize: 12)),
                                  pw.Text(_vchnoController.text, style: pw.TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: pw.EdgeInsets.all(5),
                              alignment: pw.Alignment.centerRight,
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text('Dated : ', style: pw.TextStyle(fontSize: 12)),
                                  pw.Text(formatlastsaledate(receiptdatestring), style: pw.TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 5),

                  // Remarks
                  pw.Table(
                    border: pw.TableBorder(horizontalInside: pw.BorderSide.none, verticalInside: pw.BorderSide.none, bottom: pw.BorderSide.none),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: pw.EdgeInsets.fromLTRB(5, 5, 5, 15),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Row(
                                children: [
                                  pw.Text('Remarks : ', style: pw.TextStyle(fontSize: 12)),
                                  pw.Text(controller_narration.text, style: pw.TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  // Table Header
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColor.fromHex('#050400')),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Expanded(
                            flex: 7,
                            child: pw.Container(
                              padding: pw.EdgeInsets.fromLTRB(10, 2, 5, 2),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Text('Particulars', style: pw.TextStyle(fontSize: 11)),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Container(
                              padding: pw.EdgeInsets.fromLTRB(5, 2, 10, 2),
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text('Amount', style: pw.TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Party Info Row
                  pw.Table(
                    border: pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColor.fromHex('#050400'))),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Expanded(
                            flex: 7,
                            child: pw.Container(
                              padding: pw.EdgeInsets.fromLTRB(15, 3, 5, 2),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Text(_selectedparty, style: pw.TextStyle(fontSize: 11)),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Container(
                              padding: pw.EdgeInsets.fromLTRB(5, 2, 5, 2),
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(formatAmountVoucher(roundedtotalBillAmount.toString()), style: pw.TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Bill Entries
                  for (var bill in bills.asMap().entries)
                    pw.Table(
                      border: pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColor.fromHex('#050400'))),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Expanded(
                              flex: 7,
                              child: pw.Container(
                                padding: pw.EdgeInsets.fromLTRB(20, 2, 10, 2),
                                alignment: pw.Alignment.centerLeft,
                                child: pw.Row(
                                  children: [
                                    pw.Text(bill.value.billName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                    pw.SizedBox(width: 2),
                                    pw.Text(formatAmountVoucher(bill.value.billAmount.toString()), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            pw.Expanded(flex: 3, child: pw.SizedBox()),
                          ],
                        ),
                      ],
                    ),

                  // Through Bank
                  pw.Table(
                    border: pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColor.fromHex('#050400'))),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Expanded(
                            flex: 7,
                            child: pw.Container(
                              padding: pw.EdgeInsets.fromLTRB(5, 2, 5, 2),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Text('Through : ${_selectedbankcashname!['name']!}', style: pw.TextStyle(fontSize: 11)),
                            ),
                          ),
                          pw.Expanded(flex: 3, child: pw.SizedBox()),
                        ],
                      ),
                    ],
                  ),

                  // Cheque Details
                  if (cheque.isNotEmpty)
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 10),
                        pw.Text('Bank Transaction Details:', style: pw.TextStyle(fontSize: 11)),
                        for (var c in cheque.asMap().entries)
                          pw.Padding(
                            padding: pw.EdgeInsets.only(top: 2),
                            child: pw.Text('${c.value.paymentMode} — ${formatlastsaledate(c.value.instdate.toString())}', style: pw.TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),

                  // Amount in Words + Total
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Amount (in words): ${convertAmountToWords(totalBillAmount)}', style: pw.TextStyle(fontSize: 11)),
                      pw.Text(formatAmountVoucher(totalBillAmount.toString()), style: pw.TextStyle(fontSize: 11)),
                    ],
                  ),

                  pw.SizedBox(height: 50),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('Authorised Signatory', style: pw.TextStyle(fontSize: 11)),
                  ),
                ],
              ),

              // Footer
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Created by https://tallyuae.ae/',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFFCCCCCC)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfData = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/$_selectedparty.pdf';
    await File(tempFilePath).writeAsBytes(pdfData);

    await Share.shareXFiles(
      [XFile(tempFilePath)],
      text: 'Sharing Receipt Voucher for $_selectedparty',
    );

    // Reset form state
    setState(() {
      controller_narration.clear();
      _textFieldFocusNodeNarration.unfocus();

      receiptdate = DateTime.now();
      receiptdatestring = _dateFormat.format(receiptdate);
      receiptdatetxt = formatlastsaledate(receiptdatestring);
      _dateController.text = receiptdatetxt;
      _selectedvchtypename = vchtypenamedata.first;
      fetchvchnos(_selectedvchtypename);
      _selectedparty = partydata.first;
      _partyController.text = _selectedparty;
      _selectedbankcashname = bankcashname_data.first;
      _bankcashnameController.text = _selectedbankcashname != null ? _selectedbankcashname!['name']! : "";

      bills.clear();
      cheque.clear();

      updateChequeAmount();

      totalBillAmount = bills.fold(0.0, (double previousAmount, Bills bill) => previousAmount + bill.billAmount);
      roundedtotalBillAmount = double.parse(totalBillAmount.toStringAsFixed(decimal!));
      NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
      String formattedtotal = formatter.format(roundedtotalBillAmount);
      controller_totalamt.text = formattedtotal.toString();

      isVisibleBillHeading = bills.isNotEmpty;
      isVisibleChequeHeading = cheque.isNotEmpty;
    });
  }

  void updateChequeAmount () {
    totalChequeAmount = cheque.fold(
      0.0, (double previousAmount, Cheque cheque) {
        return previousAmount + cheque.chequeAmount;
      },
    );
    // Update formatted total amount
    roundedtotalChequeAmount = double.parse(totalChequeAmount.toStringAsFixed(decimal!));
  }

  String getCurrencySymbol(String currencyCode) {
    NumberFormat format;

    Locale locale = Localizations.localeOf(context);

    try {
      if (currencyCode == 'INR' || currencyCode == 'EUR' || currencyCode == 'PKR' || currencyCode == 'USD')
      {
        format =  NumberFormat.simpleCurrency(locale: locale.toString(), name: currencyCode);
      }
      else
      {
        format =  NumberFormat.currency(locale: locale.toString(), name: currencyCode);
      }
      return format.currencySymbol;
    }
    catch (e)
    {
      return 'AED';
    }
  }

  bool isNumeric(String s) {
    if(s == null) {
      return false;
    }
     return double.tryParse(s) != null;
  }

  String? hostname = "",
      company = "",
      company_lowercase = "",
      serial_no = "",
      username = "",
      HttpURL = "",
      SecuritybtnAcessHolder = "";

  late DateTime receiptdate;
  late DateTime billduedate;
  late DateTime instdate;

  String? HttpURL_loadData,HttpURL_receiptEntry,HttpURL_fetchvchnos;

  final DateFormat _dateFormat = DateFormat('yyyyMMdd');

  List<Bills> bills = [];

  List<Cheque> cheque = [];

  final TextEditingController billAmountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _billduedateController = TextEditingController();
  final TextEditingController instDateController = TextEditingController();
  final TextEditingController instNoController = TextEditingController();
  final TextEditingController chequeAmountController = TextEditingController();

  Future<void> saveEntry() async {

    if (bills.isEmpty)
    {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atleast add 1 bill')));
    }
    else {
      setState(() {
        _isLoading = true;
      });
      jsonEntryData.clear();
      String narrationValue = controller_narration.text;
      String vchnoValue = _vchnoController.text;


      jsonEntryData["DATE"] = receiptdatestring;
      jsonEntryData["VOUCHERTYPENAME"] = _selectedvchtypename;
      jsonEntryData["PARTYLEDGERNAME"] = _selectedparty;
      jsonEntryData["ENTEREDBY"] = name;
      jsonEntryData["VOUCHERNUMBER"] = vchnoValue;
      jsonEntryData["NARRATION"] = narrationValue;

      final List<Map<String, dynamic>> allLedgerEntriesList = [];

      // Get the list of non-"On Account" bills
      final List<Map<String, dynamic>> nonOnAccountBills = bills.where((bill) => bill.billName != "On Account").map((bill) {
        final Map<String, dynamic> billData = {
          "BILLTYPE": bill.billName,
          "AMOUNT": bill.billAmount,
        };

        // Conditionally add BILLNO and BILL CREDIT PERIOD if BILLTYPE is not "On Account"
        if (bill.billName != "On Account") {
          billData["NAME"] = bill.billNo;
          billData["BILLCREDITPERIOD"] = bill.billDueDate ?? ""; // Assuming billDueDate is part of the bill object
        }

        return billData;
      }).toList();

// Get the list of "On Account" bills
      final List<Map<String, dynamic>> onAccountBills = bills.where((bill) => bill.billName == "On Account").map((bill) {
        final Map<String, dynamic> billData = {
          "BILLTYPE": bill.billName,
          "AMOUNT": bill.billAmount,
        };
        return billData;
      }).toList();

// Combine the lists, placing "On Account" bills at the end
      final List<Map<String, dynamic>> allBillAllocations = [...nonOnAccountBills, ...onAccountBills];

      final Map<String, dynamic> allLedgerEntry = {
        "LEDGERNAME": _selectedparty,
        "AMOUNT": totalBillAmount,
        "ISPARTYLEDGER": "Yes",
        "ISDEEMEDPOSITIVE": "No",
        "BILLALLOCATIONS.LIST": allBillAllocations,
      };
      allLedgerEntriesList.add(allLedgerEntry);

      // Add bank allocation details
      final Map<String, dynamic> bankAllocation = {
        "LEDGERNAME": _selectedbankcashname!['name'], // Assuming you're getting bank name dynamically
        "AMOUNT": -totalBillAmount, // Assuming you have totalBankAmount calculated
        "ISPARTYLEDGER": "No",
        "ISDEEMEDPOSITIVE": "Yes",
        "BANKALLOCATIONS.LIST": [] // Conditionally empty list based on the type of selected bank/cash
      };
      allLedgerEntriesList.add(bankAllocation);

      // If the selected bank/cash type is not 'Cash-in-Hand', add cheque details to bank allocation list
      if (_selectedbankcashname!['type'] != 'Cash-in-Hand') {
        bankAllocation["BANKALLOCATIONS.LIST"] = cheque.map((cheque) {
          return {

            "DATE": receiptdatestring,
            "INSTRUMENTDATE": cheque.instdate ?? receiptdatestring,
            "TRANSACTIONTYPE": cheque.paymentMode,
            "BANKNAME": (cheque.bankname != "Not Applicable") ? cheque.bankname : "",
            "PAYMENTFAVOURING": _selectedparty,
            "INSTRUMENTNUMBER": cheque.instno,
            "BANKPARTYNAME": _selectedparty,
            "AMOUNT": -cheque.chequeAmount,
          };
        }).toList();
      }

      jsonEntryData['ALLLEDGERENTRIES.LIST'] = allLedgerEntriesList;

      Map<String, dynamic> jsonData = {
        'type' : 'receipt',
        'data' : jsonEntryData
      };

      final jsonString = json.encode(jsonData);

      print(jsonString);
      try
      {
        final url_receiptentry = Uri.parse(HttpURL_receiptEntry!);
        Map<String,String> headers_receiptentry = {
          'Authorization' : 'Bearer $token',
          "Content-Type": "application/json"
        };

        var body_receiptentry = jsonString;

        final response_receiptentry = await http.post(
            url_receiptentry,
            body: body_receiptentry,
            headers:headers_receiptentry
        );

        if (response_receiptentry.statusCode == 200) {
          if(response_receiptentry.body == 'Entry created successfully') {

            showReceiptVoucherBottomSheet(context);

          }
          else
          {
            Fluttertoast.showToast(msg: 'an error occoured');
          }
        }
        else {
          Map<String, dynamic> data = json.decode(response_receiptentry.body);
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


  Future<void> loadData() async {
    vchtypenamedata.clear();
    partydata.clear();
    bankcashname_data.clear();
    bills.clear();
    totalBillAmount = bills.fold(0.0,
          (double previousAmount, Bills bill) {
        return previousAmount + bill.billAmount;
      },
    );
    // Update formatted total amount
    roundedtotalBillAmount = double.parse(totalBillAmount.toStringAsFixed(decimal!));
    NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
    String formattedtotal = formatter.format(roundedtotalBillAmount);
    controller_totalamt.text = formattedtotal.toString();
    cheque.clear();
    updateChequeAmount();

    billAmountController.clear();
    chequeAmountController.clear();
    instNoController.clear();
    selectedbankname = bankname_data.first;
    _banknameController.text = selectedbankname;
    controller_totalamt.text = '0';

    setState(() {
      _isLoading = true;
    });

    // data fetching
    try {
      final url = Uri.parse(HttpURL_loadData!);
      Map<String,String> headers =
      {
        'Authorization' : 'Bearer $token',
        "Content-Type": "application/json"
      };
      final response = await http.post
        (
          url,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        /*print(response.body);*/
        setState(() {
          vchtypenamedata = List<String>.from(jsonResponse['vchTypes']);
          _selectedvchtypename = vchtypenamedata.first;
          fetchvchnos(_selectedvchtypename);
          partydata = List<String>.from(jsonResponse['partyLedgers']);
          partydata.sort();
          _selectedparty = partydata.first;
          _partyController.text = _selectedparty;

          bankcashname_data = List<Map<String, String>>.from(jsonResponse['cashLedgers']?.map((cashLedger) => Map<String, String>.from(cashLedger)) ?? []);

          _selectedbankcashname = (bankcashname_data.isNotEmpty ? bankcashname_data.first : null)!;
          _bankcashnameController.text = _selectedbankcashname!=null ? _selectedbankcashname!['name']! : "" ;

          if (_selectedbankcashname != null && _selectedbankcashname!['type'] == 'Cash-in-Hand') {

            isPaymentModeVisible = false;
            _selectedpaymentmode = paymentmode_data.first;
            cheque.clear();
            updateChequeAmount();

            isVisibleChequeHeading = false;
            isChequeVisible = false;
          }
          else
          {
            if(bills.isNotEmpty)
            {
              if(cheque.isNotEmpty)
              {
                isPaymentModeVisible = true;
                isChequeVisible = true;
                isVisibleChequeHeading = true;
              }
              else
              {
                isPaymentModeVisible = true;
                _selectedpaymentmode = paymentmode_data.first;
                cheque.clear();
                updateChequeAmount();

                isVisibleChequeHeading = false;
                isChequeVisible = true;
              }
            }
            else
            {
              isPaymentModeVisible = false;
              _selectedpaymentmode = paymentmode_data.first;
              cheque.clear();
              updateChequeAmount();

              isVisibleChequeHeading = false;
              isChequeVisible = false;
            }
          }

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
      /*print(e);*/
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectreceiptDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: receiptdate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:  ColorScheme.light().copyWith(
              primary:  app_color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != receiptdate)
      {
        setState(() {
          receiptdate = picked;
          receiptdatestring = _dateFormat.format(receiptdate);
          receiptdatetxt = formatlastsaledate(receiptdatestring);
          _dateController.text = receiptdatetxt;
        });
      }

  } // main receipt date

  Future<void> _selectinstDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: instdate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:  ColorScheme.light().copyWith(
              primary:  app_color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != instdate)
      {
        setState(() {
          instdate = picked;
          instdatestring = _dateFormat.format(instdate);
          instdatetxt = formatlastsaledate(instdatestring);
          instDateController.text = instdatetxt;
        });
      }

  }

  Future<void> _selectbilldueDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: billduedate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:  ColorScheme.light().copyWith(
              primary:  app_color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != receiptdate)
      {
        setState(() {
          billduedate = picked;
          billduedatestring = _dateFormat.format(billduedate);
          billduedatetxt = formatlastsaledate(billduedatestring);
          _billduedateController.text = billduedatetxt;
        });
      }

  } // bill due date selection

  Future<void> _showBillsDetailsPopup(BuildContext context) async {
    setState(() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: EdgeInsets.zero,
            title:
            Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: app_color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.receipt_long, color: app_color, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add Bill",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),


            content: SingleChildScrollView(
              child: Form(
                key: _billsFormkey,
                child: Column(
                  children: <Widget>[
                    // 🔹 Bill Type Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Bill Type",
                        hintText: "Select Bill Type",
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.grey[700],
                        ),
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.grey[400],
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8), // 👈 smaller margin
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.indigo, Colors.cyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.book, color: Colors.white, size: 16), // 👈 smaller icon
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), // 👈 slightly tighter radius
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: app_color, width: 1.3),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10, // 👈 tighter padding
                        ),
                      ),
                      value: _selectedbill,
                      items: billsdata.map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedbill = newValue!;
                          if (_selectedbill == 'New Ref' || _selectedbill == 'Agst Ref') {
                            isVisibleDueDate = true;
                            isVisibleBillNo = true;
                          } else {
                            isVisibleDueDate = false;
                            isVisibleBillNo = false;
                            billNoController.clear();
                            _billduedateController.clear();
                          }
                          Navigator.of(context).pop();
                          _billsFormkey = GlobalKey<FormState>();
                          _showBillsDetailsPopup(context);
                        });
                      },
                    ),


                    // 🔹 Bill No
                    Visibility(
                      visible: isVisibleBillNo,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: billNoController,
                          validator: (value) => value!.isEmpty ? 'Please enter bill no' : null,
                          decoration: InputDecoration(
                            labelText: "Bill No",
                            hintText: "Enter Bill No",
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.grey[700],
                            ),
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrangeAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.confirmation_num_outlined, color: Colors.white, size: 20),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: app_color, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                          ),
                        ),
                      ),
                    ),

                    // 🔹 Due Date
                    Visibility(
                      visible: isVisibleDueDate,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: _billduedateController,
                          validator: (value) {
                            if (value!.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Invalid input, please enter a number';
                              } else if (double.parse(value) < 0) {
                                return 'Due date days cannot be negative';
                              }
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: "Due Date (days)",
                            hintText: "Enter due date",
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.pinkAccent, Colors.redAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: app_color, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                          ),
                        ),
                      ),
                    ),

                    // 🔹 Amount
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextFormField(
                        controller: billAmountController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter amount';
                          if (!isNumeric(value)) return 'Enter valid amount';
                          if (double.parse(value) == 0) return 'Amount should not be 0';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Amount",
                          hintText: "0",
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectedbill = billsdata.first;
                  isVisibleDueDate = _selectedbill == 'New Ref' || _selectedbill == 'Agst Ref';
                  isVisibleBillNo = isVisibleDueDate;
                  _billduedateController.clear();
                  billAmountController.clear();
                },
                child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),

              // ✅ Premium Add Bill button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  if (_billsFormkey.currentState!.validate()) {
                    _billsFormkey.currentState!.save();
                    addBill();
                  }
                },
                child: Text("Add Bill",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _showChequeDetailsPopup(BuildContext context) async {
    setState(() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            titlePadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

            title:

            Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: app_color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.payment, color: app_color, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_selectedpaymentmode Details",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),



            content: SingleChildScrollView(
              child: Form(
                key: _chequedetailsFormkey,
                child: Column(
                  children: <Widget>[

                    // 🔹 Inst No
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextFormField(
                        controller: instNoController,
                        decoration: InputDecoration(
                          labelText: 'Inst No',
                          hintText: 'Enter Inst No',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10, // 👈 tighter padding
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.deepOrangeAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 20),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: app_color, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    // 🔹 Inst Date
                    Padding(
                      padding:  EdgeInsets.symmetric(vertical: 4),
                      child: TextFormField(
                        controller: instDateController,
                        readOnly: true,
                        onTap: () => _selectinstDate(context),
                        decoration: InputDecoration(
                          labelText: 'Inst Date',
                          hintText: 'Select Date',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10, // 👈 tighter padding
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.teal, Colors.cyan],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: app_color, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    // 🔹 Bank Name
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TypeAheadField<String>(
                        suggestionsCallback: (pattern) {
                          return bankname_data.where((item) {
                            final name = item.toString().toLowerCase();
                            return name.contains(pattern.toLowerCase());
                          }).toList();
                        },

                        builder: (context, controller, focusNode) {
                          _banknameController = controller;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Bank",
                              hintText: 'Search Bank',
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.95),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple, Colors.deepPurpleAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                child: const Icon(Icons.account_balance_outlined,
                                    color: Colors.white, size: 20),
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (controller.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          controller.clear();
                                          selectedbankname = "";
                                        });
                                      },
                                      child:
                                      const Icon(Icons.close, color: Colors.grey, size: 20),
                                    ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, color: Colors.black87),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                BorderSide(color: app_color, width: 1.5),
                              ),
                            ),
                          );
                        },

                        itemBuilder: (context, String suggestion) {
                          return ListTile(
                            title: Text(
                              suggestion,
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          );
                        },

                        onSelected: (String suggestion) {
                          setState(() {
                            selectedbankname = suggestion;
                            _banknameController.text = suggestion;
                          });

                          Navigator.of(context).pop();
                          _chequedetailsFormkey = GlobalKey<FormState>();
                          _showChequeDetailsPopup(context);
                        },

                        // ✅ New API uses EmptyBuilder instead of noItemsFoundBuilder
                        emptyBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No matching bank found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )



                    ),

                    // 🔹 Amount
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TextFormField(
                        controller: chequeAmountController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter amount';
                          if (double.parse(value) == 0) return 'Amount should not be 0';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10, // 👈 tighter padding
                          ),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          prefixIcon: Container(
                            margin:  EdgeInsets.all(8),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient:  LinearGradient(
                                colors: [Colors.grey, Colors.brown],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              getCurrencySymbol('$currencycode'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),


                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: app_color, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Actions
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    selectedbankname = bankname_data.first;
                    _banknameController.text = selectedbankname;
                    instNoController.clear();
                    instdate = DateTime.now();
                    instdatestring = _dateFormat.format(instdate);
                    instdatetxt = formatlastsaledate(instdatestring);
                    instDateController.text = instdatetxt;
                    chequeAmountController.clear();
                  });
                },
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: () {
                  if (_chequedetailsFormkey.currentState != null &&
                      _chequedetailsFormkey.currentState!.validate()) {
                    _chequedetailsFormkey.currentState!.save();
                    addCheque();
                  }
                },
                child: Text(
                  'Add $_selectedpaymentmode',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  void addBill() {
    final billAmount = billAmountController.text;
    final billName = _selectedbill;
    final billNo = billNoController.text;

    String dueDateString = '';
    if (billName == "New Ref" || billName == "Agst Ref") {
      String billDueDateinDaysString = _billduedateController.text;
      if(billDueDateinDaysString.isNotEmpty)
        {
          int billDueDateinDaysint = int.parse(billDueDateinDaysString);

          DateTime currentDate = DateTime.now();
          DateTime finalDate = currentDate.add(Duration(days: billDueDateinDaysint));
          dueDateString = DateFormat('yyyyMMdd').format(finalDate);
        }
      else
        {
          DateTime currentDate = DateTime.now();
          DateTime finalDate = currentDate;
          dueDateString = DateFormat('yyyyMMdd').format(finalDate);
        }
    }

    if (billAmount.isNotEmpty) {
      // Check if a bill with name "On Account" already exists
      if (billName == "On Account" && bills.any((bill) => bill.billName == "On Account")) {
        // Show message that the bill already exists
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Duplicate Bill"),
              content: Text("A bill with the name 'On Account' already exists."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )]);});
        return; // Exit the function without adding the bill
      }

      // Create a new bill
      Navigator.of(context).pop();
      double parsedAmount = double.parse(billAmount.replaceAll(',', '')) ;
      final newBill = Bills(
        billName: billName,
        billAmount: parsedAmount,
        billNo: (billName == "New Ref" || billName == "Agst Ref") ? billNo : null,
        billDueDate: (billName == "New Ref" || billName == "Agst Ref") ? dueDateString : null,
      );

      // Add the new bill to the list and update the total bill amount
      setState(()
      {
        bills.add(newBill);
        // Update visibility of bill heading
        isVisibleBillHeading = bills.isNotEmpty;
        totalBillAmount = bills.fold(
          0.0,
              (double previousAmount, Bills bill) {
            return previousAmount + bill.billAmount;
          },
        );
        // Update formatted total amount
        roundedtotalBillAmount = double.parse(totalBillAmount.toStringAsFixed(decimal!));
        NumberFormat formatter = NumberFormat('#,##0.${'0' * decimal!}', 'en_US');
        String formattedtotal = formatter.format(roundedtotalBillAmount);
        controller_totalamt.text = formattedtotal.toString();
      });

      // Reset selected bill and visibility of due date and bill number
      setState(() {
        _selectedbill = billsdata.first;
        isVisibleDueDate = (_selectedbill == 'New Ref' || _selectedbill == "Agst Ref");
        isVisibleBillNo = (_selectedbill == "Agst Ref" || _selectedbill == 'New Ref');
        if (_selectedbankcashname != null && _selectedbankcashname!['type'] == 'Cash-in-Hand')
        {
          isPaymentModeVisible = false;
          _selectedpaymentmode = paymentmode_data.first;
          cheque.clear();
          updateChequeAmount();
          isVisibleChequeHeading = false;
          isChequeVisible = false;
        }
        else
        {
          if(bills.isNotEmpty)
          {
            if(cheque.isNotEmpty)
            {
              isPaymentModeVisible = true;
              isChequeVisible = true;
              isVisibleChequeHeading = true;
            }
            else
            {
              isPaymentModeVisible = true;
              _selectedpaymentmode = paymentmode_data.first;
              cheque.clear();
              updateChequeAmount();
              isVisibleChequeHeading = false;
              isChequeVisible = true;
            }
          }
          else
          {
            isPaymentModeVisible = true;
            _selectedpaymentmode = paymentmode_data.first;
            cheque.clear();
            updateChequeAmount();
            isVisibleChequeHeading = false;
            isChequeVisible = false;
          }
        }
      });

      // Clear input fields
      billAmountController.clear();
      _billduedateController.clear();

      /*if(_selectedpaymentmode == 'Cheque/DD')
        {
          setState(() {
            isChequeVisible = true;
          });
        }
      else
        {
          setState(() {
            isChequeVisible = false;
          });
        }*/
    }
  } // add bill function

  void addCheque() {
    final instNo = instNoController.text;
    final instDate = instdate;
    final bankName = selectedbankname;
    final chequeAmount = chequeAmountController.text;
    final paymentMode = _selectedpaymentmode;

    double parsedAmount = double.parse(chequeAmount.replaceAll(',', ''));

    String formattedAmount = parsedAmount.toStringAsFixed(decimal!);

    double formattedAmountDouble = double.parse(formattedAmount);

    String instDateString = DateFormat('yyyyMMdd').format(instDate);

    bool hasRepeatedInstNo = isInstNoRepeated(instNo, cheque);

    double remainingchequeamount = roundedtotalBillAmount - roundedtotalChequeAmount;

    print('before processing cheque amount $chequeAmount and roundedbillamount $roundedtotalBillAmount and roundedchequeAmount $roundedtotalChequeAmount and entered cheque amount $formattedAmountDouble and remaining cheque amount $remainingchequeamount');

    if (chequeAmount.isNotEmpty && roundedtotalChequeAmount <= roundedtotalBillAmount && roundedtotalChequeAmount !=roundedtotalBillAmount  && !hasRepeatedInstNo && formattedAmountDouble <= roundedtotalBillAmount && formattedAmountDouble <= remainingchequeamount)
    {

      Navigator.of(context).pop();

      final newCheque = Cheque(
        instno: instNo,
        instdate: instDateString,
        bankname: bankName,
        chequeAmount: parsedAmount,
        paymentMode: paymentMode
      );

      // Add the new bill to the list and update the total bill amount
      setState(() {
        cheque.add(newCheque);
        // Update visibility of bill heading
        isVisibleChequeHeading = cheque.isNotEmpty;
        updateChequeAmount();
      });
      print('after processing cheque amount $chequeAmount and roundedbillamount $roundedtotalBillAmount and roundedchequeAmount $roundedtotalChequeAmount and entered cheque amount $formattedAmountDouble and remaining cheque amount $remainingchequeamount');

      // Reset selected bill and visibility of due date and bill number
      setState(() {
        instNoController.clear();
        instdate = DateTime.now();
        instdatestring = _dateFormat.format(instdate);
        instdatetxt = formatlastsaledate(instdatestring);
        instDateController.text = instdatetxt;
        selectedbankname = bankname_data.first;
        _banknameController.text = selectedbankname;
        chequeAmountController.clear();
      });
    }
    else if (formattedAmountDouble > remainingchequeamount)
      {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Alert"),
              content: Text("Entered $_selectedpaymentmode amount exceeds remaining total amount"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK",
                      style: GoogleFonts.poppins(
                          color: app_color
                      )))]);});
        return;
      }
    else if (hasRepeatedInstNo)
    {
        showDialog(
          context: context,
          builder: (context)
          {
            return AlertDialog(
              title: Text("Alert"),
              content: Text("A cheque with the inst no '$instNo' already exists."),
              actions: [
                TextButton (
                  onPressed: ()
                  {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK",
                      style: GoogleFonts.poppins(
                          color: app_color
                      )))]);});
        return;
      }
    else if (roundedtotalBillAmount < 0 || roundedtotalBillAmount == 0)
      {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Alert"),
              content: Text("First add bills then proceed for payment details"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK",
                      style: GoogleFonts.poppins(
                          color: app_color
                      )))]);});
        return;
      }
    else if (roundedtotalChequeAmount ==roundedtotalBillAmount)
      {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Alert"),
              content: Text("Cheques for the total amount already added"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK",
                      style: GoogleFonts.poppins(
                          color: app_color
                      )))]);});
        return; // Exit the function without adding the bill
      }
    else if (formattedAmountDouble > roundedtotalBillAmount)
      {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Alert"),
              content: Text("Entered $_selectedpaymentmode amount should not be greater than total amount"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK",
                      style: GoogleFonts.poppins(
                          color: app_color
                      )))]);});
        return;
      }
  } // add cheque function

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
       bankname_data.sort((a, b) {
        if (a == 'Not Applicable') {
          return -1; // 'Not Applicable' comes before everything else
        } else if (b == 'Not Applicable') {
          return 1; // 'Not Applicable' comes before everything else
        } else {
          return a.compareTo(b); // Compare other elements alphabetically
        }
      });

      decimal = prefs.getInt('decimalplace') ?? 2;

      paymentmode_data.add("ATM");
      paymentmode_data.add("Card");
      paymentmode_data.add('Cheque/DD');
      _selectedpaymentmode = paymentmode_data.first;

      billAmountController.clear();

      receiptdate = DateTime.now();
      receiptdatestring = _dateFormat.format(receiptdate);
      receiptdatetxt = formatlastsaledate(receiptdatestring);
      _dateController.text = receiptdatetxt;

      instdate = DateTime.now();
      instdatestring = _dateFormat.format(instdate);
      instdatetxt = formatlastsaledate(instdatestring);
      instDateController.text = instdatetxt;

      _billduedateController.clear();

      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      String? email_nav = prefs.getString('email_nav');
      String? name_nav = prefs.getString('name_nav');

      /*print('hostname: $hostname');*/

      HttpURL_fetchvchnos = '$hostname/api/entry/nos/$company_lowercase/$serial_no';
      /*HttpURL_fetchvchnos = 'http://192.168.2.110:4999/api/entry/nos/$company_lowercase/$serial_no';*/

      HttpURL_loadData = '$hostname/api/entry/getReceiptData/$company_lowercase/$serial_no';
      /*HttpURL_loadData = 'http://192.168.2.110:4999/api/entry/getReceiptData/$company_lowercase/$serial_no';*/

      HttpURL_receiptEntry = '$hostname/api/entry/create/$company/$serial_no';
      /*HttpURL_receiptEntry = 'http://192.168.2.110:4999/api/entry/create/demonewformobilepp/767060064';*/

      controller_totalamt.text = 0.toString();

      if (email_nav != null && name_nav != null) {
        name = name_nav;
        email = email_nav;
      }
      if (SecuritybtnAcessHolder == "True")
      {
        isRolesVisible = true;
        isUserVisible = true;
      }
      else
      {
        isRolesVisible = false;
        isUserVisible = false;
      }});
    loadData();
  }
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


  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat(
      "#,##0.${'0' * decimal!}",  // 👈 dynamically repeat '0' for decimal places
    );

    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
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
                MaterialPageRoute(builder: (context) => PendingReceiptEntry()),
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
                    "New Receipts Entry" ?? '',
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
              MaterialPageRoute(builder: (context) => PendingReceiptEntry()),
            );
            return true;
          },
          child:Stack(children: [

            ListView(children: [

              GestureDetector(
                onTap: () => _selectDateRangeVchNo(context),
                child: Container(
                  margin: const EdgeInsets.only(top:8,bottom:4, left: 12, right : 12),
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
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

                                    // 🌈 Gradient Calendar Icon
                                    prefixIcon: GestureDetector(
                                      onTap: () => _selectreceiptDate(context),
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
                                  onTap: () => _selectreceiptDate(context),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
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
                                          style: GoogleFonts.poppins(
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

                                    // 🌈 Gradient Icon
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
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

                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: app_color, width: 1.5),
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  hint: const Text("Voucher Type Name"),
                                  value: _selectedvchtypename,
                                  items: vchtypenamedata.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
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
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 0),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: TypeAheadField<String>(
                                    suggestionsCallback: (pattern) {
                                      return partydata.where((item) {
                                        final name = item.toString().toLowerCase();
                                        return name.contains(pattern.toLowerCase());
                                      }).toList();
                                    },

                                    builder: (context, controller, focusNode) {
                                      _partyController = controller;

                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: "Party",
                                          hintText: 'Search',
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.95),

                                          // 🌈 Gradient Prefix Icon
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.purple, Colors.deepOrange],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            child: const Icon(Icons.person_outline,
                                                color: Colors.white, size: 20),
                                          ),

                                          // ✖️ Cross + ⬇ Dropdown in suffix
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (controller.text.isNotEmpty)
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      controller.clear();
                                                      _selectedparty = "";
                                                    });
                                                  },
                                                  child:
                                                  const Icon(Icons.close, color: Colors.grey, size: 20),
                                                ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_drop_down, color: Colors.black87),
                                              const SizedBox(width: 8),
                                            ],
                                          ),

                                          // Borders
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide:
                                            BorderSide(color: Colors.grey.shade300, width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide:
                                            BorderSide(color: app_color, width: 1.5),
                                          ),
                                          contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        ),
                                      );
                                    },

                                    itemBuilder: (context, String suggestion) {
                                      return ListTile(
                                        title: Text(
                                          suggestion,
                                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                                        ),
                                      );
                                    },

                                    onSelected: (String suggestion) {
                                      setState(() {
                                        _selectedparty = suggestion;
                                        _partyController.text = _selectedparty;
                                      });
                                    },

                                    // ✅ new API → emptyBuilder replaces noItemsFoundBuilder
                                    emptyBuilder: (context) => const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'No matching party found',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )

                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 0),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: TypeAheadField<String>(
                                    suggestionsCallback: (pattern) {
                                      return bankcashname_data
                                          .where((ledger) {
                                        final name = ledger['name']!.toLowerCase();
                                        return name.contains(pattern.toLowerCase());
                                      })
                                          .map((ledger) => '${ledger['name']} (${ledger['type']})')
                                          .toList();
                                    },

                                    builder: (context, controller, focusNode) {
                                      _bankcashnameController = controller;

                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Bank/Cash Name',
                                          hintText: _selectedbankcashname != null
                                              ? _selectedbankcashname!['name'] ?? ''
                                              : 'Search',
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.95),

                                          // 🌈 Gradient Prefix Icon
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.teal, Colors.blueAccent],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            child: const Icon(
                                              Icons.account_balance_wallet,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),

                                          // ✖️ Clear + ⬇ Dropdown
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (controller.text.isNotEmpty)
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      controller.clear();
                                                      _selectedbankcashname = null;
                                                    });
                                                  },
                                                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                                                ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_drop_down, color: Colors.black87),
                                              const SizedBox(width: 8),
                                            ],
                                          ),

                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
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

                                    itemBuilder: (context, String suggestion) {
                                      return ListTile(
                                        title: Text(
                                          suggestion,
                                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                                        ),
                                      );
                                    },

                                    onSelected: (String suggestion) {
                                      setState(() {
                                        _selectedbankcashname = bankcashname_data.firstWhere(
                                              (ledger) =>
                                          '${ledger['name']} (${ledger['type']})' == suggestion,
                                        );
                                        _bankcashnameController.text =
                                            _selectedbankcashname!['name'] ?? '';
                                      });

                                      // 👇 your original cheque/payment logic preserved
                                      if (_selectedbankcashname != null &&
                                          _selectedbankcashname!['type'] == 'Cash-in-Hand') {
                                        isPaymentModeVisible = false;
                                        _selectedpaymentmode = paymentmode_data.first;
                                        cheque.clear();
                                        updateChequeAmount();
                                        isVisibleChequeHeading = false;
                                        isChequeVisible = false;
                                      } else {
                                        if (bills.isNotEmpty) {
                                          if (cheque.isNotEmpty) {
                                            isPaymentModeVisible = true;
                                            isChequeVisible = true;
                                            isVisibleChequeHeading = true;
                                          } else {
                                            isPaymentModeVisible = true;
                                            _selectedpaymentmode = paymentmode_data.first;
                                            cheque.clear();
                                            updateChequeAmount();
                                            isVisibleChequeHeading = false;
                                            isChequeVisible = true;
                                          }
                                        } else {
                                          isPaymentModeVisible = true;
                                          _selectedpaymentmode = paymentmode_data.first;
                                          cheque.clear();
                                          updateChequeAmount();
                                          isVisibleChequeHeading = false;
                                          isChequeVisible = false;
                                        }
                                      }
                                    },

                                    // ✅ Replaces old `noItemsFoundBuilder`
                                    emptyBuilder: (context) => const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'No matching Bank/Cash name found',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )

                                ),
                              ),


                              Container(
                              margin: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 5),
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
                              // 🔹 Header Row
                              Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: Row(
                              children: [
                              // Gradient start icon
                              Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.blueGrey, Colors.grey],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                              BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                              )
                              ],
                              ),
                              child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),

                              // Title
                              Expanded(
                              child: Text(
                              "Bills",
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
                              _selectedbill = billsdata.first;
                              if (_selectedbill == 'New Ref' || _selectedbill == 'Agst Ref') {
                              setState(() {
                              isVisibleDueDate = true;
                              isVisibleBillNo = true;
                              });
                              } else {
                              setState(() {
                              isVisibleDueDate = false;
                              isVisibleBillNo = false;
                              });
                              }

                              billAmountController.clear();
                              billNoController.clear();
                              _billduedateController.clear();
                              _showBillsDetailsPopup(context);
                              },
                              child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                              BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
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


                                // 🔹 Bills List (Ledger style cards)
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: bills.length,
                                  itemBuilder: (context, index) {
                                    final bill = bills[index];
                                    final bool showBillNo = (bill.billName == "Agst Ref" ||
                                        bill.billName == "New Ref") &&
                                        bill.billNo != 'null' &&
                                        bill.billNo != '';

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
                                        _deleteBill(index);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 16,right:16, bottom: 6,top:2),
                                        padding: const EdgeInsets.all(14),
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  flex: 5,
                                                  child: Text(
                                                    bill.billName,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 5,
                                                  child: Text(
                                                    "Bill No: ${showBillNo ? bill.billNo ?? "N/A" : "N/A"}",
                                                    textAlign: TextAlign.end,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),

                                            // Amount Row (Gradient currency icon + Amount)
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: const LinearGradient(
                                                      colors: [Colors.teal, Colors.cyan],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.cyan.withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 3),
                                                      )
                                                    ],
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    getCurrencySymbol(currencycode),
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  currencyFormat.format(bill.billAmount),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
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

                              Visibility(
                                visible: isPaymentModeVisible,
                                child:  Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 20, right: 20, bottom: 0),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedpaymentmode,
                                    hint: Text(
                                      'Select Payment Mode',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),

                                    items: paymentmode_data.map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item.toString(),
                                        child: Text(
                                          item.toString(),
                                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      setState(() {
                                        _selectedpaymentmode = value!;
                                      });

                                      if (bills.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('At least add 1 bill')),
                                        );

                                        isChequeVisible = false;
                                        selectedbankname = bankname_data.first;
                                        _banknameController.text = selectedbankname;
                                        instNoController.clear();
                                        instdate = DateTime.now();
                                        instdatestring = _dateFormat.format(instdate);
                                        instdatetxt = formatlastsaledate(instdatestring);
                                        instDateController.text = instdatetxt;
                                        chequeAmountController.clear();
                                        cheque.clear();
                                        updateChequeAmount();
                                      } else {
                                        setState(() {
                                          isChequeVisible = true;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Payment Mode",
                                      labelStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.95),
                                      contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

                                      // 🌈 Gradient Prefix Icon
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.teal, Colors.indigo],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.payment_outlined,
                                            color: Colors.white, size: 20),
                                      ),

                                      // Borders
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: app_color, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Visibility(
                                visible: isChequeVisible,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 0),
                                  padding: const EdgeInsets.only(bottom: 0),
                                  decoration: BoxDecoration(
                                    color: app_color.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(20),
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
                                      // 🔹 Header Row with PaymentMode + Add Icon
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient:  LinearGradient(
                                                  colors: [Colors.purpleAccent, Colors.deepPurple],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.teal.withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.payment, color: Colors.white, size: 20),
                                            ),
                                            const SizedBox(width: 12),

                                            Expanded(
                                              child: Text(
                                                _selectedpaymentmode,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: app_color,
                                                ),
                                              ),
                                            ),

                                            GestureDetector(
                                              onTap: () => _showChequeDetailsPopup(context),
                                              child: Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: const LinearGradient(
                                                    colors: [Colors.orange, Colors.deepOrangeAccent],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.orange.withOpacity(0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 🔹 Cheque List
                                      ListView.builder(
                                        physics: const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: cheque.length,
                                        itemBuilder: (context, index) {
                                          final cheques = cheque[index];
                                          final bool showInstNo = !(cheques.instno == "null" ||
                                              cheques.instno.isEmpty ||
                                              cheques.instno == "");

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
                                              setState(() {
                                                cheque.removeAt(index);
                                                updateChequeAmount();
                                                isVisibleChequeHeading = cheque.isNotEmpty;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(left: 16,right:16, bottom: 6,top:2),
                                              padding:
                                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // 🔹 First row → Inst No + Inst Date
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.confirmation_num_outlined,
                                                              color: Colors.deepPurple, size: 18),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            "Inst No: ${showInstNo ? cheques.instno : "N/A"}",
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w500,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.date_range,
                                                              color: Colors.teal, size: 18),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            formatdate(cheques.instdate ?? ''),
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w500,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 8),

                                                  // 🔹 Amount row
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 26,
                                                        height: 26,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          gradient:  LinearGradient(
                                                            colors: [Colors.deepPurple.shade400, Colors.blue.shade600],

                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            getCurrencySymbol(currencycode),
                                                            style: GoogleFonts.poppins(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 11),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        currencyFormat.format(cheques.chequeAmount),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black87,
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
                              ),


                            ],),),

                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 20, right: 20, bottom: 0),
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
                              labelText: 'Narration',
                              hintText: 'Enter narration',

                              // 🌈 Gradient Icon (different decent color from vchtype)
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.deepPurple, Colors.indigo], // decent gradient
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notes_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),

                              filled: true,
                              fillColor: Colors.white.withOpacity(0.95),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

                              // Borders
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.black),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: app_color, width: 1.5),
                              ),

                              labelStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 0),
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
                              labelText: 'Amount',
                              hintText: 'Enter Amount',

                              // 🌈 Gradient Currency Symbol
                              prefix: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey, Colors.brown], // 🔵 unique from narration
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
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.black54),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: app_color, width: 1.5),
                              ),

                              // Label
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              filled: true,
                              fillColor: Colors.white,
                            ),
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
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
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
                        )
                      ]

                  ))],),

            Visibility(
              visible: _isLoading,
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            )
          ],)
      ),
    );}}