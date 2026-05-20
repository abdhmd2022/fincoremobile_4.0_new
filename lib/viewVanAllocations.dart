import 'dart:convert';
import 'package:FincoreGo/addVanAllocations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Constants.dart';
import 'ModifyVanAllocation.dart';

class ViewVanAllocationScreen extends StatefulWidget {
  const ViewVanAllocationScreen({super.key});

  @override
  State<ViewVanAllocationScreen> createState() =>
      _ViewVanAllocationScreenState();
}

class _ViewVanAllocationScreenState
    extends State<ViewVanAllocationScreen> {
  final Color primaryColor = app_color;
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color textColor = const Color(0xFF1F2937);

  bool isLoading = true;

  String hostname = "";
  String token = "";

  final TextEditingController searchController =
  TextEditingController();

  List<Map<String, dynamic>> allocations = [];
  List<Map<String, dynamic>> filteredAllocations = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    hostname = prefs.getString('hostname') ?? '';
    token = prefs.getString('token') ?? '';

    await fetchAllocations();
  }

  Future<void> fetchAllocations() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        Uri.parse(
          '$BASE_URL_config/api/spectra/Allocations',
        ),
        headers: {
          'Authorization': 'Bearer $authTokenBase',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
          "VIEW ALLOCATION RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        allocations = List<Map<String, dynamic>>.from(data);

        filteredAllocations = allocations;
      }
    } catch (e) {
      debugPrint("VIEW ALLOCATION ERROR: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterAllocations(String query) {
    if (query.isEmpty) {
      filteredAllocations = allocations;
    } else {
      filteredAllocations = allocations.where((allocation) {
        return allocation
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    }

    setState(() {});
  }

  Future<void> deleteAllocation(
      Map<String, dynamic> allocation,
      ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$BASE_URL_config/api/spectra/Allocations',
        ),

        headers: {
          'Authorization': 'Bearer $authTokenBase',
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          "user_name": allocation['user_name'],
          "serial_no": allocation['serial_no'],
          "company_name": allocation['company_name'],
        }),
      );

      debugPrint(
        "DELETE RESPONSE: ${response.body}",
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allocation deleted successfully',
            ),
          ),
        );

        fetchAllocations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Delete failed: ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("DELETE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  void showDeleteDialog(
      Map<String, dynamic> allocation,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: Text(
            "Delete Allocation",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
            ),
          ),

          content: Text(
            "Are you sure you want to delete this allocation?",
            style: GoogleFonts.poppins(),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: Colors.grey
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),

              onPressed: () {
                Navigator.pop(context);

                deleteAllocation(allocation);
              },

              child: Text(
                "Delete",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        iconTheme:
        const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.visibility_outlined,
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
                  'View Allocations',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage allocations',

                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color:
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: isLoading
          ? Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(
            primaryColor,
          ),
        ),
      )
          : RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchAllocations,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),

                    const SizedBox(height: 18),

                    _buildStatsRow(),

                    const SizedBox(height: 18),

                    filteredAllocations.isEmpty
                        ? SizedBox(
                      height:
                      constraints.maxHeight *
                          0.55,
                      child: Center(
                        child: _emptyState(),
                      ),
                    )
                        : ListView.separated(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount:
                      filteredAllocations
                          .length,
                      separatorBuilder:
                          (_, __) =>
                      const SizedBox(
                        height: 14,
                      ),
                      itemBuilder:
                          (context, index) {
                        final allocation =
                        filteredAllocations[
                        index];

                        return _allocationCard(
                          allocation,
                        );
                      },
                    ),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButton: filteredAllocations.isEmpty
          ? null
          : FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 6,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const VanAllocationScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: Text(
          "Create Allocation",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.98),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.14),
          width: 1.3,
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: filterAllocations,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'Search allocations...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 12.8,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),

          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.search_rounded,
              color: primaryColor,
              size: 22,
            ),
          ),

          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            splashRadius: 20,
            onPressed: () {
              searchController.clear();
              filterAllocations('');
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.grey.shade700,
              ),
            ),
          )
              : null,

          filled: true,
          fillColor: Colors.transparent,

          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: primaryColor.withOpacity(0.10),
              width: 1.2,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        /*Expanded(
          child: _statCard(
            'Total',
            allocations.length.toString(),
            Icons.list_alt_outlined,
          ),
        ),

        const SizedBox(width: 12),*/

        Expanded(
          child: _statCard(
            'Vans',
            allocations
                .map((e) =>
            e['godown_name'])
                .toSet()
                .length
                .toString(),
            Icons.location_on_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            'Users',
            allocations
                .map((e) => e['user_name'])
                .toSet()
                .length
                .toString(),
            Icons.people_outline,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
              primaryColor.withOpacity(0.1),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _allocationCard(
      Map<String, dynamic> allocation) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                primaryColor.withOpacity(0.12),
                child: Icon(
                  Icons.person_outline,
                  color: primaryColor,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      allocation['user_name'] ??
                          '',
                      style:
                      GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      allocation['company_name'] ??
                          '',
                      style:
                      GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                      16),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    showDeleteDialog(allocation);
                  }

                  if (value == 'edit') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModifyVanAllocationScreen(
                          allocation: allocation,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Modify'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(
                Icons.location_on_outlined,
                allocation['godown_name'] ??
                    '',
              ),
              _infoChip(
                Icons.receipt_long_outlined,
                allocation[
                'voucher_type_name'] ??
                    '',
              ),
              _infoChip(
                Icons.account_balance_wallet_outlined,
                allocation['sales_ledger'] ??
                    '',
              ),
              _infoChip(
                Icons.payments_outlined,
                allocation['cash_ledger'] ??
                    '',
              ),
            ],
          ),

          /*const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  "Modify",
                  Icons.edit_outlined,
                  Colors.blue,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _actionButton(
                  "Delete",
                  Icons.delete_outline,
                  Colors.red,
                  onTap: () {
                    showDeleteDialog(
                      allocation
                    );
                  },
                ),
              ),
            ],
          ),*/
        ],
      ),
    );
  }

  Widget _actionButton(
      String title,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
      }) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius:
          BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),

            const SizedBox(width: 6),

            Text(
              title,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight:
                FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(
      IconData icon, String value) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryColor,
          ),

          const SizedBox(width: 6),

          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),

      decoration: _cardDecoration(),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,

        children: [
          Container(
            height: 90,
            width: 90,

            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.inbox_outlined,
              size: 42,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            "No Allocations Found",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20),

            child: Text(
              "There are currently no allocations available. Tap the button below to create a new allocation.",
              textAlign: TextAlign.center,

              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const VanAllocationScreen(),
                ),
              );
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(16),
              ),
            ),

            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white,
            ),

            label: Text(
              "Create Allocation",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
          Colors.black.withOpacity(0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}