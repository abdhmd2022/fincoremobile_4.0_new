import 'dart:convert';
import 'dart:io';
import 'package:FincoreGo/viewVanAllocations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Constants.dart';

class ModifyVanAllocationScreen extends StatefulWidget {
  final Map<String, dynamic> allocation;

  const ModifyVanAllocationScreen({
    super.key,
    required this.allocation,
  });

  @override
  State<ModifyVanAllocationScreen> createState() =>
      _ModifyVanAllocationScreenState();
}

class _ModifyVanAllocationScreenState
    extends State<ModifyVanAllocationScreen> {
  final Color primaryColor = app_color;
  final Color backgroundColor =
  const Color(0xFFF5F7FA);
  final Color textColor =
  const Color(0xFF1F2937);

  bool isLoading = true;
  bool isSaving = false;

  String token = "";
  String serial_no = "";

  String? selectedLocation;
  String? selectedVchType;
  String? selectedSalesLedger;
  String? selectedCashLedger;

  List<String> locations = [];
  List<String> vchTypes = [];
  List<String> salesLedgers = [];
  List<String> cashLedgers = [];

  Widget _searchableDropdownField({
    required String title,
    required String? value,
    required List<String> items,
    required IconData icon,
    required String hint,
    required Function(String?) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),

        const SizedBox(height: 8),

        Autocomplete<String>(
          optionsBuilder:
              (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return items;
            }

            return items.where(
                  (item) => item
                  .toLowerCase()
                  .contains(
                textEditingValue.text
                    .toLowerCase(),
              ),
            );
          },

          initialValue:
          TextEditingValue(text: value ?? ''),

          onSelected: onSelected,

          fieldViewBuilder:
              (context,
              controller,
              focusNode,
              onEditingComplete) {
            controller.text =
                value ?? controller.text;

            return TextField(
              controller: controller,
              focusNode: focusNode,

              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),

              decoration: InputDecoration(
                hintText: hint,

                hintStyle: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.grey.shade500,
                ),

                prefixIcon: Icon(
                  icon,
                  color: primaryColor,
                  size: 20,
                ),

                suffixIcon: (controller.text.isNotEmpty || value != null)
                    ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();

                    onSelected(null);

                    setState(() {});
                  },
                )
                    : null,

                filled: true,
                fillColor: backgroundColor,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 1.4,
                  ),
                ),
              ),

            );
          },

          optionsViewBuilder:
              (context,
              onSelected,
              options) {
            return Align(
              alignment: Alignment.topLeft,

              child: Material(
                color: Colors.transparent,

                child: Container(
                  margin:
                  const EdgeInsets.only(
                      top: 8),

                  constraints:
                  const BoxConstraints(
                    maxHeight: 260,
                  ),

                  width:
                  MediaQuery.of(context)
                      .size
                      .width *
                      0.9,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                        18),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.08),
                        blurRadius: 18,
                        offset:
                        const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: ListView.builder(
                    padding:
                    const EdgeInsets.all(
                        10),

                    shrinkWrap: true,

                    itemCount:
                    options.length,

                    itemBuilder:
                        (context, index) {
                      final option =
                      options.elementAt(
                          index);

                      return InkWell(
                        borderRadius:
                        BorderRadius
                            .circular(14),

                        onTap: () =>
                            onSelected(option),

                        child: Container(
                          margin:
                          const EdgeInsets
                              .only(
                            bottom: 8,
                          ),

                          padding:
                          const EdgeInsets
                              .all(12),

                          decoration:
                          BoxDecoration(
                            color:
                            backgroundColor,
                            borderRadius:
                            BorderRadius
                                .circular(
                                14),
                          ),

                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,

                                decoration:
                                BoxDecoration(
                                  color: primaryColor
                                      .withOpacity(
                                      0.12),

                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      12),
                                ),

                                child: Icon(
                                  icon,
                                  color:
                                  primaryColor,
                                  size: 20,
                                ),
                              ),

                              const SizedBox(
                                  width: 12),

                              Expanded(
                                child: Text(
                                  option,

                                  style:
                                  GoogleFonts
                                      .poppins(
                                    fontSize:
                                    12.5,
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                    color:
                                    textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    final prefs =
    await SharedPreferences.getInstance();

    token = prefs.getString('token') ?? '';
    serial_no =
        prefs.getString('serial_no') ?? '';

    selectedLocation =
    widget.allocation['godown_name'];

    selectedVchType =
    widget.allocation[
    'voucher_type_name'];

    selectedSalesLedger =
    widget.allocation['sales_ledger'];

    selectedCashLedger =
    widget.allocation['cash_ledger'];

    await fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    try {
      final hostname =
      await SharedPreferences.getInstance();

      final company =
      hostname.getString('company_name');

      final company_lowercase = company!
          .replaceAll(' ', '')
          .toLowerCase();

      final host =
      hostname.getString('hostname');

      final response = await http.post(
        Uri.parse(
          '$host/api/entry/getSpectra/$company_lowercase/$serial_no',
        ),
        headers: {
          'Authorization':
          'Bearer $token',
          'Content-Type':
          'application/json',
        },
        body: jsonEncode({
          "type": "delivery note",
        }),
      );

      if (response.statusCode == 200) {
        final data =
        jsonDecode(response.body);

        locations = List<String>.from(
          data['locations'] ?? [],
        );

        vchTypes = List<String>.from(
          data['vchTypes'] ?? [],
        );

        salesLedgers =
        List<String>.from(
          data['salesLedgers'] ?? [],
        );

        cashLedgers = List<String>.from(
          data['cashLedgers'] ?? [],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateAllocation() async {
    try {
      setState(() {
        isSaving = true;
      });

      final response = await http.put(
        Uri.parse(
          '$BASE_URL_config/api/spectra/Allocations',
        ),

        headers: {
          'Authorization':
          'Bearer $authTokenBase',
          'Content-Type':
          'application/json',
        },

        body: jsonEncode({
          "user_name":
          widget.allocation[
          'user_name'],

          "serial_no":
          widget.allocation[
          'serial_no'],

          "company_name":
          widget.allocation[
          'company_name'],

          "godown_name":
          selectedLocation,

          "voucher_type_name":
          selectedVchType,

          "sales_ledger":
          selectedSalesLedger,

          "cash_ledger":
          selectedCashLedger,
        }),
      );

      debugPrint(
        "UPDATE RESPONSE: ${response.body}",
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Allocation updated successfully',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ViewVanAllocationScreen(
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              response.body,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,

        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const ViewVanAllocationScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),

        title: Row(
          children: [
            Container(
              padding:
              const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(
                    12),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Modify Allocation',
                  style:
                  GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                Text(
                  'Update allocation details',
                  style:
                  GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white
                        .withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: isLoading
          ? Center(
        child:
        CircularProgressIndicator
            .adaptive(
        ),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),

        child: Container(
          padding:
          const EdgeInsets.all(18),

          decoration:
          _cardDecoration(),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              _sectionTitle(),

              const SizedBox(
                  height: 24),

              _searchableDropdownField(
                title: 'Location',
                value: selectedLocation,
                items: locations,
                icon: Icons.location_on_outlined,
                hint: 'Search and select location',
                onSelected: (val) {
                  setState(() {
                    selectedLocation = val;
                  });
                },
              ),

              const SizedBox(
                  height: 16),

              _searchableDropdownField(
                title: 'Voucher Type',
                value: selectedVchType,
                items: vchTypes,
                icon: Icons.receipt_long_outlined,
                hint: 'Search and select voucher type',
                onSelected: (val) {
                  setState(() {
                    selectedVchType = val;
                  });
                },
              ),

              const SizedBox(
                  height: 16),

              _searchableDropdownField(
                title: 'Sales Ledger',
                value: selectedSalesLedger,
                items: salesLedgers,
                icon: Icons.account_balance_wallet_outlined,
                hint: 'Search and select sales ledger',
                onSelected: (val) {
                  setState(() {
                    selectedSalesLedger = val;
                  });
                },
              ),

              const SizedBox(
                  height: 16),

              _searchableDropdownField(
                title: 'Cash Ledger',
                value: selectedCashLedger,
                items: cashLedgers,
                icon: Icons.payments_outlined,
                hint: 'Search and select cash ledger',
                onSelected: (val) {
                  setState(() {
                    selectedCashLedger = val;
                  });
                },
              ),

              const SizedBox(
                  height: 28),

              SizedBox(
                width:
                double.infinity,
                child:
                ElevatedButton.icon(
                  onPressed:
                  isSaving
                      ? null
                      : updateAllocation,

                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    primaryColor,
                    elevation: 0,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 15,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                          16),
                    ),
                  ),

                  icon: isSaving
                      ?  SizedBox(
                    height: 18,
                    width: 18,
                    child: Platform.isIOS
                        ?  CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 10,
                    )
                        :  CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(
                    Icons
                        .save_outlined,
                    color: Colors
                        .white,
                  ),

                  label: Text(
                    isSaving
                        ? "Updating..."
                        : "Update Allocation",
                    style:
                    GoogleFonts
                        .poppins(
                      color: Colors
                          .white,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String title,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,

          icon: Icon(
            Icons.keyboard_arrow_down,
            color: primaryColor,
          ),

          style: GoogleFonts.poppins(
            color: textColor,
          ),

          decoration: InputDecoration(
            hintText: 'Select $title',

            prefixIcon: Icon(
              icon,
              color: primaryColor,
            ),

            filled: true,
            fillColor: backgroundColor,

            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                  16),
              borderSide: BorderSide
                  .none,
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                  16),
              borderSide: BorderSide(
                color:
                Colors.grey.shade200,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                  16),
              borderSide: BorderSide(
                color: primaryColor,
                width: 1.4,
              ),
            ),
          ),

          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _sectionTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
            primaryColor.withOpacity(
                0.1),
            borderRadius:
            BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_outlined,
            color: primaryColor,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          'Allocation Details',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color:
          Colors.black.withOpacity(
              0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}