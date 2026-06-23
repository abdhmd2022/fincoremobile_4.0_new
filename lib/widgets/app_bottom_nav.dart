import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../Items.dart';
import '../Party.dart';
import '../Transactions.dart';

class AppBottomNav extends StatelessWidget {
  final BuildContext parentContext;
  final bool showItems;
  final bool showParty;
  final bool showRegister;
  final bool showEntries;
  final VoidCallback onEntriesTap;

  const AppBottomNav({
    super.key,
    required this.parentContext,
    required this.showItems,
    required this.showParty,
    required this.showRegister,
    required this.showEntries,
    required this.onEntriesTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _tile("Items", Icons.inventory_outlined, showItems, () {
              Navigator.push(parentContext, MaterialPageRoute(builder: (_) => Items()));
            }),
            _tile("Parties", Icons.groups_outlined, showParty, () {
              Navigator.push(parentContext, MaterialPageRoute(builder: (_) => Party()));
            }),
            _tile("Transactions", Icons.payment_outlined, showRegister, () {
              Navigator.push(parentContext, MaterialPageRoute(builder: (_) => Transactions()));
            }),
            _tile("Entries", Icons.receipt_long, showEntries, onEntriesTap),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, IconData icon, bool visible, VoidCallback onTap) {
    if (!visible) return const SizedBox.shrink();

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 23, color: app_color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}