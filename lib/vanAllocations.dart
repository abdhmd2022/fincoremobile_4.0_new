import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants.dart';

class VanAllocationScreen extends StatefulWidget {
  const VanAllocationScreen({super.key});

  @override
  State<VanAllocationScreen> createState() => _VanAllocationScreenState();
}

class UserModel {
  final String role_name;
  final String name;
  final String email;

  UserModel({
    required this.role_name,
    required this.name,
    required this.email
  });

  factory UserModel.fromJson(Map<String, dynamic> json)
  {
    return UserModel
      (
        role_name: json['role_name'],
        name: json['customer_name'],
        email: json['user_name']
    );
  }
}


class _VanAllocationScreenState extends State<VanAllocationScreen> {
  final Color primaryColor = app_color;
  final Color secondaryColor = const Color(0xFF14B8A6);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color textColor = const Color(0xFF1F2937);

  final TextEditingController searchController = TextEditingController();
  final TextEditingController serialController = TextEditingController();

  String? selectedLocation;
  String? selectedVchType;
  String? selectedSalesLedger;
  String? selectedCashLedger;

  String? selectedUser;
  String? selectedCompany;


  List<UserModel> users = [];

  List<String> locations = [];

  List<String> vchTypes = [];

  List<String> salesLedgers = [];

  List<String> cashLedgers = [];

  List<Map<String, dynamic>> allocations = [];

  bool isLoading = true;
  late SharedPreferences prefs;
  String serial_no= "",email= "";



  Future<void> fetchUsers(String selectedserial) async {

    final url = Uri.parse('$BASE_URL_config/api/login/getRole');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial,
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      users.clear();
      try
      {
        final List<dynamic> jsonList = json.decode(response.body);


        users.addAll(jsonList.map((json) => UserModel.fromJson(json)).toList());


      }
      catch (e)
      {
        print(e);
      }
    }
  }


  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    prefs = await SharedPreferences.getInstance();

    try {
      setState(() {
        isLoading = true;
      });
      serial_no = prefs.getString('serial_no')!;
      email = prefs.getString('username')!;

      await Future.wait([

        fetchUsers(serial_no),
        fetchLocations(),
        fetchVchTypes(),
        fetchSalesLedgers(),
        fetchCashLedgers(),
        fetchAllocations(),
      ]);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('YOUR_LOCATIONS_API'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          locations = List<String>.from(
            (data['data'] ?? []).map((e) => e['location_name']),
          );
        });
      }
    } catch (e) {
      debugPrint('LOCATION ERROR: $e');
    }
  }

  Future<void> fetchVchTypes() async {
    try {
      final response = await http.get(Uri.parse('YOUR_VCHTYPE_API'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          vchTypes = List<String>.from(
            (data['data'] ?? []).map((e) => e['name']),
          );
        });
      }
    } catch (e) {
      debugPrint('VCHTYPE ERROR: $e');
    }
  }

  Future<void> fetchSalesLedgers() async {
    try {
      final response = await http.get(Uri.parse('YOUR_SALES_LEDGER_API'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          salesLedgers = List<String>.from(
            (data['data'] ?? []).map((e) => e['ledger_name']),
          );
        });
      }
    } catch (e) {
      debugPrint('SALES LEDGER ERROR: $e');
    }
  }

  Future<void> fetchCashLedgers() async {
    try {
      final response = await http.get(Uri.parse('YOUR_CASH_LEDGER_API'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          cashLedgers = List<String>.from(
            (data['data'] ?? []).map((e) => e['ledger_name']),
          );
        });
      }
    } catch (e) {
      debugPrint('CASH LEDGER ERROR: $e');
    }
  }

  Future<void> fetchAllocations() async {
    try {
      final response = await http.get(Uri.parse('YOUR_VIEW_ALLOCATION_API'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          allocations = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('ALLOCATION ERROR: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    serialController.dispose();
    super.dispose();
  }

  bool get isFormValid =>
      selectedUser != null &&
          selectedLocation != null &&
          selectedVchType != null &&
          selectedSalesLedger != null &&
          selectedCashLedger != null;

  void _resetForm() {
    setState(() {
      selectedUser = null;
      selectedLocation = null;
      selectedVchType = null;
      selectedSalesLedger = null;
      selectedCashLedger = null;
    });
  }

  void _saveAllocation() {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all allocation fields')),
      );
      return;
    }

    final body = {
      'user_name': selectedUser,
      'serial_no': '767060064',
      'company_name': 'ABC LLC',
      'location_name': selectedLocation,
      'vchtype_name': selectedVchType,
      'sales_ledger': selectedSalesLedger,
      'cash_ledger': selectedCashLedger,
    };

    debugPrint('ADD ALLOCATION BODY: $body');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allocation body is ready for API')),
    );
  }

  @override
  Widget build(BuildContext context) {
   /* if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }*/

    return Scaffold(
      backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Van Allocation',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Manage user allocations',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          )),
      body: isLoading ? Center(
        child: CircularProgressIndicator.adaptive(),
      ) : LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 700;

          return Column(
            children: [

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 14 : 22),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //  _buildSearchBar(),
                          /*const SizedBox(height: 14),
                            _buildSummaryCards(isMobile),*/

                          const SizedBox(height: 16),
                          _buildAllocationForm(isMobile),

                          const SizedBox(height: 16),
                          _buildAllocationList(isMobile),
                          const SizedBox(height: 30),


                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'Search user, location, voucher type...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),

          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: primaryColor,
              size: 22,
            ),
          ),

          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              searchController.clear();
              setState(() {});
            },
            icon: Icon(
              Icons.close_rounded,
              color: Colors.grey.shade500,
            ),
          )
              : null,

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: primaryColor.withOpacity(0.4),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAllocationForm(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.settings_outlined, 'Allocation Configuration'),
          const SizedBox(height: 18),
          _responsiveWrap(
            isMobile: isMobile,
            children: [
              _searchableUserDropdown(),
              _searchableDropdownField(
                title: 'Location',
                value: selectedLocation,
                items: locations,
                icon: Icons.location_on_outlined,
                hint: 'Search and select location',
                onSelected: (val) => setState(() => selectedLocation = val),
              ),
              _searchableDropdownField(
                title: 'Voucher Type',
                value: selectedVchType,
                items: vchTypes,
                icon: Icons.receipt_long_outlined,
                hint: 'Search and select voucher type',
                onSelected: (val) => setState(() => selectedVchType = val),
              ),
              _searchableDropdownField(
                title: 'Sales Ledger',
                value: selectedSalesLedger,
                items: salesLedgers,
                icon: Icons.account_balance_wallet_outlined,
                hint: 'Search and select sales ledger',
                onSelected: (val) => setState(() => selectedSalesLedger = val),
              ),
              _searchableDropdownField(
                title: 'Cash Ledger',
                value: selectedCashLedger,
                items: cashLedgers,
                icon: Icons.payments_outlined,
                hint: 'Search and select cash ledger',
                onSelected: (val) => setState(() => selectedCashLedger = val),
              ),




            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.poppins(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveAllocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.save_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Save Allocation',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildAllocationList(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.list_alt_outlined, 'Allocation List'),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allocations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final allocation = allocations[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: primaryColor.withOpacity(0.12),
                          child: Icon(Icons.person_outline, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allocation['user'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Serial: ${allocation['serial']}',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (value) {},
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('View')),
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _infoChip(Icons.location_on_outlined, 'Dubai Main Van Area'),
                        _infoChip(Icons.receipt_long_outlined, 'Sales'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _miniActionButton('View', Icons.visibility_outlined, primaryColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniActionButton('Edit', Icons.edit_outlined, Colors.blue),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniActionButton('Delete', Icons.delete_outline, Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _responsiveWrap({required bool isMobile, required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = isMobile
            ? constraints.maxWidth
            : (constraints.maxWidth - 18) / 2;

        return Wrap(
          spacing: 18,
          runSpacing: 16,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }

  Widget _searchableUserDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('User Name'),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return users.map((e) => e.name.toString());
            }

            return users
                .map((e) => e.name.toString())
                .where(
                  (user) => user
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()),
            );
          },
          initialValue: TextEditingValue(text: selectedUser ?? ''),
          onSelected: (value) {
            setState(() {
              selectedUser = value;
            });
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            controller.text = selectedUser ?? controller.text;

            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: _inputDecoration(
                Icons.person_search_outlined,
                'Search and select user',
              ).copyWith(
                suffixIcon: selectedUser != null
                    ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Selected',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                )
                    : null,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 300),
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);

                      /*final matchedUser = users.firstWhere(
                            (e) => e.name == option,
                        orElse: () => UserModel(
                          role_name: '',
                          name: '',
                          email: '',
                        ),
                      );*/

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 42,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    /*const SizedBox(height: 5),
                                    _statusPill(
                                      matchedUser.role_name.isNotEmpty
                                          ? 'Configured'
                                          : 'Pending Setup',
                                        matchedUser.role_name.isNotEmpty
                                    ),*/
                                  ],
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
        _fieldLabel(title),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return items;
            }

            return items.where(
                  (item) => item
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()),
            );
          },
          initialValue: TextEditingValue(text: value ?? ''),
          onSelected: onSelected,
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            controller.text = value ?? controller.text;

            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: _inputDecoration(icon, hint),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 260),
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelected(option),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
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

  Widget _textField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(title),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _inputDecoration(icon, hint),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(title),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
          decoration: _inputDecoration(icon, 'Select $title'),
          style: GoogleFonts.poppins(fontSize: 13, color: textColor),
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _disabledField(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(title),
        const SizedBox(height: 8),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coming Soon',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade500),
      prefixIcon: Icon(icon, color: primaryColor, size: 21),
      filled: true,
      fillColor: backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryColor, width: 1.4),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
    );
  }

  Widget _statusPill(String text, bool success) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: success ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: success ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _quickFilterChip(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor
            : primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _miniActionButton(String title, IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 5),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.045),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}