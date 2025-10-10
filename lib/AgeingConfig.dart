import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants.dart';

class AgeingConfig extends StatefulWidget {

  @override
  _AgeingConfigState createState() => _AgeingConfigState();
}

class _AgeingConfigState extends State<AgeingConfig> {
  late TextEditingController heading1txtController;
  late TextEditingController heading2txtController;
  late TextEditingController heading3txtController;
  late TextEditingController heading4txtController;
  late TextEditingController heading5txtController;

  String heading1 = '';
  String heading2 = '';
  String heading3 = '';
  String heading4 = '';
  String heading5 = '';

  @override
  void initState() {
    super.initState();
    initializeControllers();
    loadPreferences();
  }

  void initializeControllers() {
    heading1txtController = TextEditingController();
    heading2txtController = TextEditingController();
    heading3txtController = TextEditingController();
    heading4txtController = TextEditingController();
    heading5txtController = TextEditingController();
  }

  void loadPreferences() async {
    SharedPreferences ageingPref = await SharedPreferences.getInstance();
    setState(() {
      heading1 = ageingPref.getString('heading1') ?? '30';
      heading2 = ageingPref.getString('heading2') ?? '60';
      heading3 = ageingPref.getString('heading3') ?? '90';
      heading4 = ageingPref.getString('heading4') ?? '120';
      heading5 = ageingPref.getString('heading5') ?? '180';
    });
    setControllerValues();
  }

  void setControllerValues()
  {
    heading1txtController.text = heading1;
    heading2txtController.text = heading2;
    heading3txtController.text = heading3;
    heading4txtController.text = heading4;
    heading5txtController.text = heading5;
  }

  void showToast(String message)
  {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  void savePreferences() async
  {
    SharedPreferences ageingPref = await SharedPreferences.getInstance();

    if(!heading1txtController.text.isEmpty && !heading2txtController.text.isEmpty && !heading3txtController.text.isEmpty && !heading4txtController.text.isEmpty && !heading5txtController.text.isEmpty )
      {
        int heading1_int = int.parse(heading1);
        int heading2_int = int.parse(heading2);
        int heading3_int = int.parse(heading3);
        int heading4_int = int.parse(heading4);
        int heading5_int = int.parse(heading5);

        if(heading1_int >0 && heading2_int>heading1_int && heading3_int>heading2_int && heading4_int>heading3_int && heading5_int>heading4_int)
          {
            ageingPref
              ..setString('heading1', heading1)
              ..setString('heading2', heading2)
              ..setString('heading3', heading3)
              ..setString('heading4', heading4)
              ..setString('heading5', heading5)
              ..commit();
            showToast('Ageing Configuration Saved');

            print('$heading1  $heading2  $heading3  $heading4  $heading5');
          }
        else
          {
            showToast('Ageing Value should be greater than lower limit');
          }
      }
    else
      {
        showToast('Ageing Field Cannot be Empty');
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
              Navigator.of(context).pop();
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
                    "Ageing Config",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(
              child: Text(
                'Configure Ageing Brackets',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 30),

            _buildAgeingRow(() => 'From: 0', 'To', heading1txtController, (value) {
              if (value.isNotEmpty) {
                heading1 = value;
                final base = int.tryParse(value) ?? 0;
                heading2txtController.text = heading2 = '${base + base}';
                heading3txtController.text = heading3 = '${base + base * 2}';
                heading4txtController.text = heading4 = '${base + base * 3}';
                heading5txtController.text = heading5 = '${base + base * 4}';
                setState(() {});
              }
            }),

            _buildAgeingRow(() => 'From: ${heading1txtController.text}', 'To', heading2txtController, (value) {
              if (value.isNotEmpty) {
                heading2 = value;
                final base = int.tryParse(value) ?? 0;
                heading3txtController.text = heading3 = '${base + base}';
                heading4txtController.text = heading4 = '${base + base * 2}';
                heading5txtController.text = heading5 = '${base + base * 3}';
                setState(() {});
              }
            }),

            _buildAgeingRow(() => 'From: ${heading2txtController.text}', 'To', heading3txtController, (value) {
              if (value.isNotEmpty) {
                heading3 = value;
                final base = int.tryParse(value) ?? 0;
                heading4txtController.text = heading4 = '${base + base}';
                heading5txtController.text = heading5 = '${base + base * 2}';
                setState(() {});
              }
            }),

            _buildAgeingRow(() => 'From: ${heading3txtController.text}', 'To', heading4txtController, (value) {
              if (value.isNotEmpty) {
                heading4 = value;
                final base = int.tryParse(value) ?? 0;
                heading5txtController.text = heading5 = '${base + base}';
                setState(() {});
              }
            }),

            _buildAgeingRow(() => 'From: ${heading4txtController.text}', 'To', heading5txtController, (value) {
              if (value.isNotEmpty) {
                heading5 = value;
                setState(() {});
              }
            }),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.save_alt_outlined, color: Colors.white),
                label:  Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                onPressed: savePreferences,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeingRow(
      String Function() fromValue,
      String toLabel,
      TextEditingController controller,
      ValueChanged<String> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              fromValue(),
              style:  GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:  BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: app_color, width: 1.4),
                ),
              ),
              style:  GoogleFonts.poppins(color: Colors.black87, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }


}