import 'tally_api_client.dart';

/// `tally-data/companies/:companyId/voucher-entry-dropdowns` - server-side
/// classified dropdown option lists for building a Sales/Receipt
/// voucher-entry form, replacing the old pattern of fetching every
/// `/ledgers`/`/groups`/`/voucher-types`/`/godowns`/stock-items list and
/// re-classifying it client-side by `GroupReservedName`/`VoucherReservedName`
/// (see the doc-comments this replaced on `SalesRegistration.loadData()`/
/// `ReceiptRegistration.loadData()`). Ported server-side from the legacy
/// `tally-server` app's `getSalesData`/`getReceiptData` endpoints - see
/// tally-api's `voucher-entry-dropdowns.service.ts`.
///
/// Every list here is already scoped to the caller's master-restrictions
/// (Van Allocation) - a company-user locked to one godown/voucher type gets
/// exactly one row back for that list, same as the individual master-list
/// endpoints did before.
class VoucherEntryDropdownsRepository {
  VoucherEntryDropdownsRepository._();
  static final VoucherEntryDropdownsRepository instance =
      VoucherEntryDropdownsRepository._();

  final TallyApiClient _client = TallyApiClient();

  /// `{vchTypes, partyLedgers, salesLedgers, vatLedgers, otherLedgers,
  /// items, godowns}` - everything needed to build a Sales/Sales-Order/
  /// Delivery-Note voucher-entry form. No `currencies` - fetch that
  /// separately. [type] selects which `VoucherReservedName`(s) `vchTypes`
  /// is filtered to server-side (`'sales' | 'salesOrder' | 'deliveryNote'`,
  /// defaults to `'sales'`) - the other fields (`partyLedgers`/
  /// `salesLedgers`/`vatLedgers`/`otherLedgers`/`godowns`) are not
  /// type-dependent.
  ///
  /// [godownMasterId] is a separate, opt-in narrowing from the GODOWN
  /// master-restriction allow-list mentioned above: passing it switches
  /// `items` to one row per item+batch actually in stock at that specific
  /// godown (positive `closingQuantity` only) instead of every stock item
  /// company-wide - an item with no positive-quantity batch there
  /// disappears entirely, and an item can appear as multiple rows (one per
  /// qualifying batch). Existence-checked server-side first, so an
  /// unknown/restricted godownMasterId 404s rather than silently returning
  /// an empty item list.
  Future<Map<String, dynamic>> salesData({
    String? type,
    int? godownMasterId,
  }) async {
    final params = <String>[
      if (type != null) 'type=$type',
      if (godownMasterId != null) 'godownMasterId=$godownMasterId',
    ];
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final result = await _client.getForCompany(
      '/voucher-entry-dropdowns/sales-data$query',
    );
    return result.data as Map<String, dynamic>;
  }

  /// `{vchTypes, partyLedgers, cashLedgers}` - everything needed to build a
  /// Receipt voucher-entry form. No `currencies` - fetch that separately.
  Future<Map<String, dynamic>> receiptData() async {
    final result = await _client.getForCompany(
      '/voucher-entry-dropdowns/receipt-data',
    );
    return result.data as Map<String, dynamic>;
  }

  /// `{voucherTypes, ledgers, stockItems, units, costCentres, godowns,
  /// currencies}` - the generic, unfiltered-by-classification bundle
  /// covering every master a voucher-entry form for any voucher type could
  /// need (unlike [salesData]/[receiptData], not restricted to
  /// Sales/Receipt group-reservedName sets). Not yet wired into any screen.
  Future<Map<String, dynamic>> dropdowns() async {
    final result = await _client.getForCompany('/voucher-entry-dropdowns');
    return result.data as Map<String, dynamic>;
  }
}
