import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Constants.dart';

class FastMovingInactiveItemsCriteria extends StatefulWidget {

  final bool fastmoving_visible,slowmoving_visible ,inactive_visible ;

  const FastMovingInactiveItemsCriteria(
      {
        required this.fastmoving_visible,
        required this.slowmoving_visible,
        required this.inactive_visible
      });

  @override
  _FastMovingInactiveItemsState createState() => _FastMovingInactiveItemsState(fastmoving_visible: fastmoving_visible,slowmoving_visible: slowmoving_visible,inactive_visible: inactive_visible);
}

class _FastMovingInactiveItemsState extends State<FastMovingInactiveItemsCriteria> {
  late TextEditingController fastmovingitemsdayscontroller;
  late TextEditingController inactiveitemsdayscontroller;
  late TextEditingController fastmovingitemsqtycontroller;
  late TextEditingController fastmovingitemsvaluecontroller;
  late TextEditingController slowmovingitemsqtycontroller;
  late TextEditingController slowmovingitemsvaluecontroller;
  late TextEditingController slowmovingitemsdayscontroller;

  bool fastmoving_visible,slowmoving_visible,inactive_visible;

  String fastmovingitems = '';
  String slowmovingitems = '';

  String inactiveitems = '';
  String fastmovingqtyitems = '';
  String fastmovingvalueitems = '';
  String slowmovingvalueitems = '';
  String slowmovingqtyitems = '';

  _FastMovingInactiveItemsState (
      {required this.fastmoving_visible,
        required this.slowmoving_visible,
        required this.inactive_visible,});

  @override
  void initState() {
    super.initState();
    initializeControllers();
    loadPreferences();
  }

  void initializeControllers() {
    fastmovingitemsdayscontroller = TextEditingController();
    fastmovingitemsqtycontroller = TextEditingController();
    inactiveitemsdayscontroller = TextEditingController();
    fastmovingitemsvaluecontroller = TextEditingController();
    slowmovingitemsqtycontroller = TextEditingController();
    slowmovingitemsvaluecontroller = TextEditingController();
    slowmovingitemsdayscontroller = TextEditingController();
  }

  void loadPreferences() async {
    SharedPreferences criteria = await SharedPreferences.getInstance();
    setState(() {
      fastmovingitems = criteria.getString('fastmovingdays') ?? '180';
      fastmovingqtyitems = criteria.getString('fastmovingqty') ?? '1000';
      fastmovingvalueitems = criteria.getString('fastmovingvalue') ?? '10000';

      slowmovingitems = criteria.getString('slowmovingdays') ?? '181';
      slowmovingqtyitems = criteria.getString('slowmovingqty') ?? '1000';
      slowmovingvalueitems = criteria.getString('slowmovingvalue') ?? '10000';

      inactiveitems = criteria.getString('inactivedays') ?? '182';

    });
    setControllerValues();
  }

  void setControllerValues() {
    fastmovingitemsdayscontroller.text = fastmovingitems;
    fastmovingitemsqtycontroller.text = fastmovingqtyitems;
    fastmovingitemsvaluecontroller.text = fastmovingvalueitems;

    slowmovingitemsvaluecontroller.text = slowmovingvalueitems;
    slowmovingitemsqtycontroller.text = slowmovingqtyitems;
    slowmovingitemsdayscontroller.text = slowmovingitems;

    inactiveitemsdayscontroller.text = inactiveitems;
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void savePreferences() async {
    SharedPreferences criteria = await SharedPreferences.getInstance();
     if(!fastmovingitemsdayscontroller.text.isEmpty && !fastmovingitemsqtycontroller.text.isEmpty && !fastmovingitemsvaluecontroller.text.isEmpty
     && !slowmovingitemsdayscontroller.text.isEmpty && !slowmovingitemsqtycontroller.text.isEmpty && !slowmovingitemsvaluecontroller.text.isEmpty &&
     !inactiveitemsdayscontroller.text.isEmpty)
       {
         int fastmovingdays = int.parse(fastmovingitemsdayscontroller.text);
         int slowmovingdays = int.parse(slowmovingitemsdayscontroller.text);
         int inactivedays = int.parse(inactiveitemsdayscontroller.text);

         if(inactivedays <= slowmovingdays || inactivedays <= fastmovingdays)
           {
             showToast('Inactive days must be greater than fast/slow moving days');
           }
         else
           {
             String fastmovingitemsdays = fastmovingitemsdayscontroller.text;
             String fastmovingitemsqty = fastmovingitemsqtycontroller.text;
             String fastmovingitemsvalue = fastmovingitemsvaluecontroller.text;
             String slowmovingitemsvalue = slowmovingitemsvaluecontroller.text;
             String slowmovingitemsdays = slowmovingitemsdayscontroller.text;
             String slowmovingitemsqty = slowmovingitemsqtycontroller.text;
             String inactiveitemsdays = inactiveitemsdayscontroller.text;

             criteria
               ..setString('fastmovingdays', fastmovingitemsdays)
               ..setString('fastmovingqty', fastmovingitemsqty)
               ..setString('fastmovingvalue', fastmovingitemsvalue)
               ..setString('slowmovingdays', slowmovingitemsdays)
               ..setString('slowmovingqty', slowmovingitemsqty)
               ..setString('slowmovingvalue', slowmovingitemsvalue)
               ..setString('inactivedays', inactiveitemsdays)
               ..commit();

             print('$fastmovingitemsdays  $fastmovingitemsqty  $fastmovingitemsvalue  $slowmovingitemsdays  $slowmovingitemsqty  $slowmovingitemsvalue  $inactiveitemsdays');

             showToast('Criteria Saved');


           }
       }
     else
       {
         showToast('Fields cannot be empty');
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
                    "Items Criteria",
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

      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fastmoving_visible)
                  _buildCriteriaCard(
                    title: 'Fast Moving Criteria',
                    icon: Icons.flash_on_rounded,
                    color: Colors.teal,
                    isWide: isWide,
                    fields: [
                      _buildValidatedField(
                          label: 'No. of Days',
                          controller: fastmovingitemsdayscontroller,
                          errorText: fastmovingitemsdayscontroller.text.isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            fastmovingitems = val;
                          }),
                      _buildValidatedField(
                          label: 'Min Qty',
                          controller: fastmovingitemsqtycontroller,
                          errorText: fastmovingitemsqtycontroller.text.isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            fastmovingqtyitems = val;
                          }),
                      _buildValidatedField(
                          label: 'Min Value',
                          controller: fastmovingitemsvaluecontroller,
                          errorText: fastmovingitemsvaluecontroller.text.isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            fastmovingvalueitems = val;
                          }),
                    ],
                  ),

                if (slowmoving_visible)
                  _buildCriteriaCard(
                    title: 'Slow Moving Criteria',
                    icon: Icons.slow_motion_video_rounded,
                    color: Colors.orange,
                    isWide: isWide,
                    fields: [
                      _buildValidatedField(
                          label: 'No. of Days',
                          controller: slowmovingitemsdayscontroller,
                          errorText: slowmovingitemsdayscontroller.text.isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            slowmovingitems = val;
                          }),
                      _buildValidatedField(
                          label: 'Max Qty',
                          controller: slowmovingitemsqtycontroller,
                          errorText: slowmovingitemsqtycontroller.text.isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            slowmovingqtyitems = val;
                          }),
                      _buildValidatedField(
                          label: 'Max Value',
                          controller: slowmovingitemsvaluecontroller,
                          errorText: slowmovingitemsvaluecontroller.text.isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            slowmovingvalueitems = val;
                          }),
                    ],
                  ),

                if (inactive_visible)
                  _buildCriteriaCard(
                    title: 'Inactive Criteria',
                    icon: Icons.block_rounded,
                    color: Colors.redAccent,
                    isWide: isWide,
                    fields: [
                      _buildValidatedField(
                          label: 'No. of Days',
                          controller: inactiveitemsdayscontroller,
                          errorText: inactiveitemsdayscontroller.text.isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            inactiveitems = val;
                          }),
                    ],
                  ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {}); // triggers validation
                      savePreferences();
                    },
                    icon: const Icon(Icons.save_alt_rounded,color:Colors.white),
                    label:  Text(
                      'Save',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600,color:Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: app_color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),

    );
  }

  Widget _buildCriteriaCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> fields,
    required bool isWide,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(title,
                    style:  GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 0,

              children: fields.map((e) => isWide ? SizedBox(width: 250, child: e) : e).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildValidatedField({
    required String label,
    required TextEditingController controller,
    required String? errorText,
    required ValueChanged<String> onChanged,
    String? tooltipText,
    int maxLength = 10,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style:  GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            if (tooltipText != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: tooltipText,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                textStyle:  GoogleFonts.poppins(color: Colors.white),
                child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: TextInputType.number,


          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),

                borderSide: BorderSide(color: Colors.black12)),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:  BorderSide(color: app_color, width: 1.4),
            ),

            errorText: errorText,
            counterStyle:  GoogleFonts.poppins(height: 0),
          ),
          style:  GoogleFonts.poppins(fontSize: 15),
        ),
      ],
    );
  }


}