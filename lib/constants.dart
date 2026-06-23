import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'currencyFormat.dart';

const String prodServer = "https://fincorego.duckdns.org";
const String devServer = "http://192.168.2.185";

// Production Environment
const String  BASE_URL_config = "$prodServer/main";

// uni gas serial number
const String uniGasSerialNumber = '772976358';

// Dev Environment
// const String BASE_URL_config = "$devServer:5000";
const String authTokenBase =
    'KSgqL2FzZGFzZGlvQ0VEQUZfX19fIUBBUyQlYXMxOTI4MzdfX18=';

// production socket url
const String SOCKET_URL = prodServer;
// development socket url
// const String SOCKET_URL = devServer;

const String serialNumbersConfigUrl =
    'https://mobile.chaturvedigroup.com/serial_no/serial_numbers.json';

/// Default/fallback serial numbers.
/// If internet/API fails, app will still use these values.
Set<String> vanSalesSerialNo = {
 /* '725463756',
  '767060064',*/
};


Future<void> fetchvanSalesSerialNumbers() async {
  try {
    debugPrint('Fetching serial numbers from cloud...');

    final url =
        'https://raw.githubusercontent.com/saadancsh/fincore-config/main/serial_numbers.json?v=${DateTime.now().millisecondsSinceEpoch}';


    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 45));

    debugPrint('Serial config status -> ${response.statusCode}');
    debugPrint('Serial config body -> ${response.body}');

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);

      final dynamic rawSerialList =
      decodedData['serial_no_van_deliverynote'];

      if (rawSerialList is List) {
        final Set<String> fetchedSerialNos = rawSerialList
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet();

        if (fetchedSerialNos.isNotEmpty) {
          vanSalesSerialNo = fetchedSerialNos;

          debugPrint(
            'Updated vanSalesSerialNo -> $vanSalesSerialNo',
          );


        }
      }
    }
  } catch (e) {
    debugPrint('Error fetching serial numbers -> $e');
  }
}

bool hasVanDeliveryNoteAccess(String? serialNo) {
  return serialNo != null && vanSalesSerialNo.contains(serialNo.trim());
}

void closeKeyboard(BuildContext context) {
  FocusScope.of(context).unfocus();
}
const Color app_color = Colors.teal;

String formatAmount(String amount) {
  String amount_string = "";

  if (amount.contains("-")) {
    amount = amount.replaceAll("-", "");
    double amount_double = double.parse(amount);
    amount_string = CurrencyFormatter.formatCurrency_double(amount_double);
    amount_string = "$amount_string DR";
  } else {
    if (amount == "null") {
      amount = "0";
    }

    double amount_double = double.parse(amount);
    amount_string = CurrencyFormatter.formatCurrency_double(amount_double);
    amount_string = "$amount_string CR";
  }

  return amount_string;
}

String formatNullto0(String value) {
  String value_string = '0';

  if (value != 'null') {
    value_string = value;
  } else {
    value_string = '0';
  }

  return value_string;
}

String formatdate(String saledate) {
  String formated_saledate = "";

  if (saledate == '' || saledate == 'null') {
    formated_saledate = 'N/A';
  } else {
    DateTime saledate_date = DateTime.parse(saledate);
    formated_saledate = DateFormat("dd-MMM-yyyy").format(saledate_date);
  }

  return formated_saledate;
}