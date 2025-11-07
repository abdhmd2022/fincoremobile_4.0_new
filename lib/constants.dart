import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'currencyFormat.dart';

const String BASE_URL_config = "http://fincorego.ddns.net:5999";
/*const String BASE_URL_config = "http://192.168.2.185:5000";*/
const String authTokenBase = 'KSgqL2FzZGFzZGlvQ0VEQUZfX19fIUBBUyQlYXMxOTI4MzdfX18=';

const Color app_color = Colors.teal;



String formatAmount(String amount)
{
  String amount_string = "";
  if(amount.contains("-"))
  {
    amount = amount.replaceAll("-", "");
    double amount_double = double.parse(amount);
    amount_string = CurrencyFormatter.formatCurrency_double(amount_double);
    amount_string = amount_string + " DR";
  }
  else
  {
    if(amount == "null")
    {
      amount = "0";
    }
    double amount_double = double.parse(amount);
    amount_string = CurrencyFormatter.formatCurrency_double(amount_double);
    amount_string = amount_string + " CR";
  }
  return amount_string;
}

String formatNullto0(String value)
{
  String value_string = '0';
  if(value != 'null')
  {
      value_string = value;
  }
  else
  {
      value_string = '0';
  }
  return value_string;
}

String formatdate(String saledate)
{
  String formated_saledate = "";

  if(saledate == '' || saledate == 'null')
  {
     formated_saledate = 'N/A';
  }
  else
  {
      DateTime saledate_date = DateTime.parse(saledate);
      formated_saledate = DateFormat("dd-MMM-yyyy").format(saledate_date);
  }

  return formated_saledate;
}