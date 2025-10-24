import 'package:FincoreGo/FastMovingInactiveItemsCriteria.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AgeingConfig.dart';
import 'Constants.dart';
import 'Dashboard.dart';
import 'SerialSelect.dart';

class Settings extends StatefulWidget {
   Settings({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

  class _MyHomePageState extends State<Settings> with TickerProviderStateMixin
  {
  String groupvalue = '';
  double vatValue = 0.0;
  int inactiveparties_days = 0;
  String dateRangeOption = 'This Month';
  DateTime? customStartDate;
  DateTime? customEndDate;
  int? decimal = 1;
  String sort = '';
  final TextEditingController vatController = TextEditingController();
  final TextEditingController inactivedaysController = TextEditingController();

  GlobalKey<FormState> _vatFormkey = GlobalKey<FormState>();
  GlobalKey<FormState> _inactivepartydaysFormkey = GlobalKey<FormState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  late SharedPreferences prefs;

  void _showVatInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🏷️ Title & Close
                Row(
                  children: [
                     Icon(Icons.percent, color: app_color),
                     SizedBox(width: 8),
                     Expanded(
                      child: Text(
                        'VAT Percentage',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon:  Icon(Icons.close_rounded, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                 SizedBox(height: 16),

                // 🧾 VAT Input Form
                Form(
                  key: _vatFormkey,
                  child: TextFormField(
                    controller: vatController,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter VAT (%)';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'VAT (%)',
                      hintText: 'Enter VAT (%)',
                      prefixIcon: Icon(Icons.edit_note_outlined, color: app_color),
                      labelStyle:  GoogleFonts.poppins(color: Colors.black54),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: app_color),
                      ),
                    ),

                  ),
                ),

                 SizedBox(height: 24),

                // ✅ Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: app_color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding:  EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon:  Icon(Icons.save_alt_outlined, color: Colors.white),
                    label:  Text(
                      'Save',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      if (_vatFormkey.currentState?.validate() ?? false) {
                        _vatFormkey.currentState!.save();
                        double vat = double.tryParse(vatController.text) ?? 0.0;
                        prefs.setDouble('vatperc', vat);
                        print('VAT: $vat%');
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDateRangeDialog(BuildContext context) {
    final options = [
      'Today',
      'Yesterday',
      'This Month',
      'Last Month',
      'This Year',
      'Last Year',
      'Year To Date',
      // 'Custom Date'
    ];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
          child: Column(
            children: [
              // 🏷️ Title + Close
              Row(
                children: [
                  Icon(Icons.date_range_rounded, color: app_color),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select Date Range',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Selected: $dateRangeOption',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

              // 📋 Options List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: 8),
                  children: options.map((option) {
                    return RadioListTile<String>(
                      title: Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontWeight: dateRangeOption == option
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      value: option,
                      groupValue: dateRangeOption,
                      activeColor: app_color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: dateRangeOption == option
                          ? app_color.withOpacity(0.05)
                          : null,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4),
                      onChanged: (val) async {
                        Navigator.pop(context);

                        if (val == 'Custom Date') {
                          await _showCustomDatePicker(context);
                        } else {
                          setState(() {
                            dateRangeOption = val!;
                          });
                          prefs.setString('dateRangeOption', dateRangeOption);
                          prefs.remove('startdate');
                          prefs.remove('enddate');
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),

      initialDateRange: customStartDate != null && customEndDate != null
          ? DateTimeRange(start: customStartDate!, end: customEndDate!)
          : null,
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

    if (picked != null) {
      setState(() {
        dateRangeOption = 'Custom Date';
        customStartDate = picked.start;
        customEndDate = picked.end;
      });
      prefs.setString('dateRangeOption', 'Custom Date');
      prefs.setString('startdate', picked.start.toIso8601String());
      prefs.setString('enddate', picked.end.toIso8601String());
    }
  }

  void _showInactivedaysInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🏷️ Title + Close
                Row(
                  children: [
                     Icon(Icons.calendar_today_rounded, color: Colors.teal),
                     SizedBox(width: 8),
                     Expanded(
                      child: Text(
                        'Inactive Parties Days',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon:  Icon(Icons.close_rounded, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                 SizedBox(height: 16),

                // 📝 Form Input
                Form(
                  key: _inactivepartydaysFormkey,
                  child: TextFormField(
                    controller: inactivedaysController,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter day(s)';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Day(s)',
                      hintText: 'Enter number of day(s)',
                      prefixIcon: Icon(Icons.timer_outlined, color: Colors.teal),
                      labelStyle:  GoogleFonts.poppins(color: Colors.black54),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: app_color),
                      ),
                    ),
                  ),
                ),

                 SizedBox(height: 24),

                // ✅ Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: app_color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding:  EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon:  Icon(Icons.save_alt_outlined, color: Colors.white),
                    label:  Text(
                      'Save',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      if (_inactivepartydaysFormkey.currentState?.validate() ?? false) {
                        _inactivepartydaysFormkey.currentState!.save();

                        int days = int.tryParse(inactivedaysController.text) ?? 30;
                        prefs.setInt('inactiveparties_days', days);

                        print('Inactive Days: $days');
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initSharedPreferences() async {
      prefs = await SharedPreferences.getInstance();
      vatValue = prefs.getDouble('vatperc')??5;
      inactiveparties_days = prefs.getInt('inactiveparties_days')?? 30;


      vatController.text = vatValue.toString();
      inactivedaysController.text = inactiveparties_days.toString();
      dateRangeOption = prefs.getString('dateRangeOption') ?? 'This Month';

      String? start = prefs.getString('startdate');
      String? end = prefs.getString('enddate');
      if (start != null && end != null) {
        customStartDate = DateTime.tryParse(start);
        customEndDate = DateTime.tryParse(end);
      }

      try
      {
        groupvalue = prefs.getString('currencycode')!;

        if(groupvalue == 'null')
          {
            groupvalue = 'AED';
          }
      }
      catch (e)
    {
      groupvalue = 'AED';
    }

      try
      {
        sort = prefs.getString('sort')!;

        if(sort == 'null')
        {
          sort = 'Default';
        }
      }
      catch (e)
      {
        sort = 'Default';
      }

    try
        {
          decimal = prefs.getInt('decimalplace');
          if(decimal == null || decimal == 'null')
          {
            decimal = 2;
          }
        }
        catch(e)
    {
      decimal = 2;
    }
  }

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  String getCurrencySymbol(String currencyCode) {
    NumberFormat format;
    Locale locale = Localizations.localeOf(context);

    try {
      if (currencyCode == 'INR' || currencyCode == 'EUR' || currencyCode == 'PKR')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard()));
            },
          ),
          title: GestureDetector(
            onTap: () {

            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    "Settings" ?? '',

                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,

                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),
      ),

      body: ListView.separated(
        itemCount: 7,
        separatorBuilder: (_, __) =>  Divider(height: 1, thickness: 0.5),
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _buildTile(
                icon: Icons.attach_money_rounded,
                title: 'Currency',
                subtitle: 'Select currency for the app',
                onTap: () => _showCurrencyDialog(context),
              );
            case 1:
              return _buildTile(
                icon: Icons.numbers,
                title: 'Amount in Decimals',
                subtitle: 'Customize number of decimal points',
                onTap: () => _showDecimalDialog(context),
              );
            case 2:
              return _buildTile(
                icon: Icons.percent,
                title: 'VAT Percentage',
                subtitle: 'Set VAT percentage for the app',
                onTap: () => _showVatInputDialog(context),
              );
            case 3:
              return _buildTile(
                icon: Icons.calendar_today_outlined,
                title: 'Inactive Parties Days',
                subtitle: 'Set no. of inactive party days',
                onTap: () => _showInactivedaysInputDialog(context),
              );
            case 4:
              return _buildTile(
                icon: Icons.sort,
                title: 'Sort Type',
                subtitle: 'Default sorting selection for the app',
                onTap: () => _showSortDialog(context),
              );
            case 5:
              return _buildTile(
                icon: Icons.date_range_rounded,
                title: 'Default Date Range',
                subtitle: 'Select default report period',
                onTap: () => _showDateRangeDialog(context),
              );
            case 6:
              return _buildTile(
                icon: Icons.access_time,
                title: 'Ageing Configuration',
                subtitle: 'Customize ageing range',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgeingConfig())),
              );
            case 7:
              return _buildTile(
                icon: Icons.stacked_bar_chart_rounded,
                title: 'Fast/Slow/Inactive Items',
                subtitle: 'Customize Fast/Slow/Inactive Items Criteria',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FastMovingInactiveItemsCriteria(
                        fastmoving_visible: true,
                        slowmoving_visible: true,
                        inactive_visible: true,
                      ),
                    ),
                  );
                },
              );
            default:
              return  SizedBox();
          }
        },
      ),);}


  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: app_color),
      title: Text(title, style:  GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing:  Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding:  EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
          child: Column(
            children: [
              // 🧩 Title + Close Button
              Row(
                children: [
                   Icon(Icons.attach_money_rounded, color: app_color),
                   SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Currency',
                      style:  GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(

                    icon:  Icon(Icons.close_rounded, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              // ✅ Selected label
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:  EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Selected: $groupvalue',
                    style:  GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

              // 🧾 Currency list
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView(
                    padding:  EdgeInsets.only(bottom: 8),
                    children: [
                      _buildCurrencyOption(context, 'USD', 'USD (\$)'),
                      _buildCurrencyOption(context, 'AED', 'UAE Dirhams (${getCurrencySymbol('AED')})'),
                      _buildCurrencyOption(context, 'INR', 'Indian Rupees (${getCurrencySymbol('INR')})'),
                      _buildCurrencyOption(context, 'PKR', 'Pakistani Rupees (${getCurrencySymbol('PKR')})'),
                      _buildCurrencyOption(context, 'EUR', 'Euro (${getCurrencySymbol('EUR')})'),
                      _buildCurrencyOption(context, 'LKR', 'SriLankan Rupees (${getCurrencySymbol('LKR')})'),
                      _buildCurrencyOption(context, 'SAR', 'Saudi Riyal (${getCurrencySymbol('SAR')})'),
                      _buildCurrencyOption(context, 'OMR', 'Omani Riyal (${getCurrencySymbol('OMR')})'),
                      _buildCurrencyOption(context, 'BHD', 'Bahraini Dinar (${getCurrencySymbol('BHD')})'),
                      _buildCurrencyOption(context, 'QAR', 'Qatari Riyal (${getCurrencySymbol('QAR')})'),
                      _buildCurrencyOption(context, 'KWD', 'Kuwaiti Dinar (${getCurrencySymbol('KWD')})'),
                      _buildCurrencyOption(context, 'SLE', 'Sierra Leonean Leone (${getCurrencySymbol('SLE')})'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(BuildContext context, String value, String label) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupvalue,
      activeColor: app_color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: groupvalue == value ? app_color.withOpacity(0.05) : null,
      contentPadding:  EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: groupvalue == value ? FontWeight.w600 : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
      onChanged: (selected) {
        groupvalue = selected!;
        prefs.setString('currencycode', groupvalue);
        Navigator.pop(context);
      },
    );
  }


  void _showDecimalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          padding:  EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
          child: Column(
            children: [
              // 🧩 Title + Close
              Row(
                children: [
                   Icon(Icons.numbers_rounded, color: app_color),
                   SizedBox(width: 8),
                   Expanded(
                    child: Text(
                      'Amount in Decimals',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon:  Icon(Icons.close_rounded, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // 📌 Selected decimal
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:  EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Selected: $decimal Decimal${decimal != 1 ? 's' : ''}',
                    style:  GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                ),
              ),

              // 🔘 Decimal options
              Expanded(
                child: ListView(
                  padding:  EdgeInsets.only(bottom: 8),
                  children: List.generate(4, (index) {
                    int value = index + 1;
                    return RadioListTile<int>(
                      value: value,
                      groupValue: decimal,
                      activeColor: app_color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: decimal == value ? app_color.withOpacity(0.05) : null,
                      contentPadding:  EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        '$value Decimal${value > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontWeight: decimal == value ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      onChanged: (val) {
                        decimal = val!;
                        prefs.setInt('decimalplace', decimal!);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    final options = [
      'Default',
      'Newest to Oldest',
      'Oldest to Newest',
      'A->Z',
      'Z->A',
      'Amount High to Low',
      'Amount Low to High'
    ];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding:  EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
          child: Column(
            children: [
              // 🏷️ Title + Close
              Row(
                children: [
                   Icon(Icons.sort, color: app_color),
                   SizedBox(width: 8),
                   Expanded(
                    child: Text(
                      'Sort Options',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon:  Icon(Icons.close_rounded, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // ✅ Selected sort text
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:  EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Selected: $sort',
                    style:  GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                ),
              ),

              // 📋 Sort options
              Expanded(
                child: ListView(
                  padding:  EdgeInsets.only(bottom: 8),
                  children: options.map((s) {
                    return RadioListTile<String>(
                      title: Text(
                        s,
                        style: GoogleFonts.poppins(
                          fontWeight: sort == s ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      value: s,
                      groupValue: sort,
                      activeColor: app_color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: sort == s ? app_color.withOpacity(0.05) : null,
                      contentPadding:  EdgeInsets.symmetric(horizontal: 4),
                      onChanged: (val) {
                        sort = val!;
                        prefs.setString('sort', sort!);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  }

