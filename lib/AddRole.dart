import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RolesView.dart';
import 'Sidebar.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;

class Roles
{
  final String serial;
  final String role_id;
  final String license_expiry;
  final String hostname;
  final String hostpass;
  final String hostuser;
  final String dbname;

  Roles({
        required this.serial,
        required this.role_id,
        required this.license_expiry,
        required this.hostname,
        required this.hostpass,
        required this.hostuser,
        required this.dbname
      });
}

class AddRole extends StatefulWidget {

  const AddRole({Key? key}) : super(key: key);
  @override
  _AddRolePageState createState() => _AddRolePageState();
}

class _AddRolePageState extends State<AddRole> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String rolename = "";

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late String  SalesDashHolder,ReceiptsDashHolder,PurchaseDashHolder,PaymentsDashHolder,OutstandingReceivablesDashHolder
  ,OutstandingPayablesDashHolder,CashDashHolder,AllitemsHolder,InActiveitemsHolder,ActiveitemsHolder
  ,RateHolder,AmountHolder,ItemSalesHolder,ItemPurchaseHolder,SalesPartyHolder,ReceiptPartyHolder,PurchasePartyHolder,PaymentPartyHolder,CreditNotePartyHolder
  ,DebitNotePartyHolder,JournalPartyHolder,ReceivablePartyHolder,PayablePartyHolder,PendingSalesOrderPartyHolder,PartySuppliersHolder,PartyCustomersHolder
  ,PendingPurchaseOrderPartyHolder,LedgerEntriesHolder,BillsEntriesHolder,InventoryEntriesHolder,PostDatedTransactionsHolder,CostCentreEntriesHolder,BarChartDashHolder,LineChartDashHolder,PieChartDashHolder,SalesEntryHolder,ReceiptEntryHolder,SalesOrderEntryHolder;

  late String salesdashcheck,barchartdashcheck,linechartdashcheck,piechartdashcheck,receiptsdashcheck,purchasedashcheck
  ,paymentsdashcheck,outstandingreceivabledashcheck,outstandingpayabledashcheck,cashdashcheck,allitemscheck,inactiveitemscheck,activeitemscheck,ratecheck
  ,salespartycheck,receiptpartycheck,purchasepartycheck,paymentpartycheck,creditnotepartycheck,debitnotepartycheck,journalpartycheck,receivablepartycheck
  ,payablepartycheck,pendingsalesorderpartycheck,pendingpurchaseorderpartycheck,ledgerentriescheck,billentriescheck,
      inventoryentriescheck,postdatedtransactionscheck, costcentrecheck,salesentrycheck,receiptentrycheck,salesorderentrycheck,amountcheck,item_salescheck,item_purchasecheck,party_supplierscheck,party_customerscheck;


  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isRolesEnable = true,
      showSavedRoles = false,
      isUserVisible = true,

      _isLoading = false,
      isDashAccessCheck = false,
      isSalesAccessCheck = false,
      isBarChartDashAccessCheck = false,
      isLineChartDashAccessCheck = false,
      isPieChartDashAccessCheck = false,

      isReceiptsAccessCheck = false,
      isPurchaseAccessCheck = false,
      isPaymentsAccessCheck = false,
      isOutstandingReceivableAccessCheck = false,
      isOutstandingPayableAccessCheck = false,
      isCashAccessCheck = false,
  isItemsAccessCheck = false,
  isAllItemsAccessCheck = false,
  isInactiveItemsAccessCheck = false,
  isItemsRateAccessCheck = false,
  isFastMovingItemsAccessCheck = false,
  isItemsAmountAccessCheck = false,
  isItemsSalesAccessCheck = false,
  isItemsPurchaseAccessCheck = false,
  isPartyAccessCheck = false,
  isPartySalesAccess = false,
  isPartyPurchaseAccess = false,
  isPartyCreditNoteAccess = false,
  isPartyJournalAccess = false,
  isPartyPayableAccess = false,
  isPartyPendingPurchaseOrderAccess = false,
  isPartySuppliersAccess = false,
  isPartyCustomersAccess = false,
  isPartyReceiptAccess = false,
  isPartyPaymentAccess = false,
  isPartyDebitNoteAccess = false,
  isPartyReceivableAccess = false,
  isPartyPendingSalesOrderAccess = false,
  isTransactionAccessCheck = false,
  isTransactionLedgerEntryAccess = false,
  isTransactionBillsEntryAccess = false,
  isTransactionInventoryEntryAccess = false,
  IsPostDatedTransactionsEntryAccess = false,
  isTransactionCostCentreEntryAccess = false,
  isEntryAccessCheck = false,
  isSalesEntryAccess = false,
  isReceiptEntryAccess = false,
  isSalesOrderEntryAccess = false;

  String name = "",email = "",selectedRole = "";
  late SharedPreferences prefs;
  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";
  List<dynamic> saved_roles_list = [];
  List<dynamic> saved_roles_data_list = [];

  TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }


  List<Map<String, dynamic>> get dashboardPermissions => [
    {'label': 'Sales', 'value': isSalesAccessCheck, 'onChanged': (v) => _updateAccess('sales', v)},
    {'label': 'Purchase', 'value': isPurchaseAccessCheck, 'onChanged': (v) => _updateAccess('purchase', v)},
    {'label': 'Receipts', 'value': isReceiptsAccessCheck, 'onChanged': (v) => _updateAccess('receipts', v)},
    {'label': 'Payments', 'value': isPaymentsAccessCheck, 'onChanged': (v) => _updateAccess('payments', v)},
    {'label': 'Payable', 'value': isOutstandingPayableAccessCheck, 'onChanged': (v) => _updateAccess('payable', v)},
    {'label': 'Receivable', 'value': isOutstandingReceivableAccessCheck, 'onChanged': (v) => _updateAccess('receivable', v)},
    {'label': 'Cash/Bank', 'value': isCashAccessCheck, 'onChanged': (v) => _updateAccess('cash', v)},
    {'label': 'Bar Chart', 'value': isBarChartDashAccessCheck, 'onChanged': (v) => _updateAccess('barchart', v)},
    {'label': 'Line Chart', 'value': isLineChartDashAccessCheck, 'onChanged': (v) => _updateAccess('linechart', v)},
    {'label': 'Pie Chart', 'value': isPieChartDashAccessCheck, 'onChanged': (v) => _updateAccess('piechart', v)},
  ];

  List<Map<String, dynamic>> get itemsPermissions => [
    {'label': 'All Items', 'value': isAllItemsAccessCheck, 'onChanged': (v) => _updateItems('all', v)},
    {'label': 'Inactive Items', 'value': isInactiveItemsAccessCheck, 'onChanged': (v) => _updateItems('inactive', v)},
    {'label': 'Rate', 'value': isItemsRateAccessCheck, 'onChanged': (v) => _updateItems('rate', v)},
    {'label': 'Fast Moving', 'value': isFastMovingItemsAccessCheck, 'onChanged': (v) => _updateItems('fast', v)},
    {'label': 'Amount', 'value': isItemsAmountAccessCheck, 'onChanged': (v) => _updateItems('amount', v)},
    {'label': 'Sales', 'value': isItemsSalesAccessCheck, 'onChanged': (v) => _updateItems('sales', v)},
    {'label': 'Purchase', 'value': isItemsPurchaseAccessCheck, 'onChanged': (v) => _updateItems('purchase', v)},
  ];

  List<Map<String, dynamic>> get partyPermissions => [
    {'label': 'Sales', 'value': isPartySalesAccess, 'onChanged': (v) => _updateParty('sales', v)},
    {'label': 'Purchase', 'value': isPartyPurchaseAccess, 'onChanged': (v) => _updateParty('purchase', v)},
    {'label': 'Credit Note', 'value': isPartyCreditNoteAccess, 'onChanged': (v) => _updateParty('creditnote', v)},
    {'label': 'Journal', 'value': isPartyJournalAccess, 'onChanged': (v) => _updateParty('journal', v)},
    {'label': 'Payable', 'value': isPartyPayableAccess, 'onChanged': (v) => _updateParty('payable', v)},
    {'label': 'Pending Purchase Order', 'value': isPartyPendingPurchaseOrderAccess, 'onChanged': (v) => _updateParty('pendingpurchase', v)},
    {'label': 'Pending Sales Order', 'value': isPartyPendingSalesOrderAccess, 'onChanged': (v) => _updateParty('pendingsales', v)},
    {'label': 'Receipt', 'value': isPartyReceiptAccess, 'onChanged': (v) => _updateParty('receipt', v)},
    {'label': 'Payment', 'value': isPartyPaymentAccess, 'onChanged': (v) => _updateParty('payment', v)},
    {'label': 'Debit Note', 'value': isPartyDebitNoteAccess, 'onChanged': (v) => _updateParty('debitnote', v)},
    {'label': 'Receivable', 'value': isPartyReceivableAccess, 'onChanged': (v) => _updateParty('receivable', v)},
    {'label': 'Suppliers', 'value': isPartySuppliersAccess, 'onChanged': (v) => _updateParty('suppliers', v)},
    {'label': 'Customers', 'value': isPartyCustomersAccess, 'onChanged': (v) => _updateParty('customers', v)},
  ];

  List<Map<String, dynamic>> get transactionPermissions => [
    {'label': 'Ledger', 'value': isTransactionLedgerEntryAccess, 'onChanged': (v) => _updateTransaction('ledger', v)},
    {'label': 'Bills', 'value': isTransactionBillsEntryAccess, 'onChanged': (v) => _updateTransaction('bills', v)},
    {'label': 'Inventory', 'value': isTransactionInventoryEntryAccess, 'onChanged': (v) => _updateTransaction('inventory', v)},
    {'label': 'Cost Centre', 'value': isTransactionCostCentreEntryAccess, 'onChanged': (v) => _updateTransaction('costcentre', v)},
    {'label': 'Post Dated', 'value': IsPostDatedTransactionsEntryAccess, 'onChanged': (v) => _updateTransaction('postdated', v)},
  ];

  List<Map<String, dynamic>> get entryPermissions => [
    {'label': 'Sales Entry', 'value': isSalesEntryAccess, 'onChanged': (v) => _updateEntry('sales', v)},
    {'label': 'Receipt Entry', 'value': isReceiptEntryAccess, 'onChanged': (v) => _updateEntry('receipt', v)},
    {'label': 'Sales Order Entry', 'value': isSalesOrderEntryAccess, 'onChanged': (v) => _updateEntry('salesorder', v)},
  ];

  void _updateAccess(String key, bool? value) {
    setState(() {
      switch (key) {
        case 'sales': isSalesAccessCheck = value!; break;
        case 'purchase': isPurchaseAccessCheck = value!; break;
        case 'receipts': isReceiptsAccessCheck = value!; break;
        case 'payments': isPaymentsAccessCheck = value!; break;
        case 'payable': isOutstandingPayableAccessCheck = value!; break;
        case 'receivable': isOutstandingReceivableAccessCheck = value!; break;
        case 'cash': isCashAccessCheck = value!; break;
        case 'barchart': isBarChartDashAccessCheck = value!; break;
        case 'linechart': isLineChartDashAccessCheck = value!; break;
        case 'piechart': isPieChartDashAccessCheck = value!; break;
      }
      _syncDashMasterToggle();
    });
  }

  void _syncDashMasterToggle() {
    isDashAccessCheck = isSalesAccessCheck &&
        isPurchaseAccessCheck &&
        isReceiptsAccessCheck &&
        isPaymentsAccessCheck &&
        isOutstandingPayableAccessCheck &&
        isOutstandingReceivableAccessCheck &&
        isCashAccessCheck &&
        isBarChartDashAccessCheck &&
        isLineChartDashAccessCheck &&
        isPieChartDashAccessCheck;
  }

  void _updateItems(String key, bool? value) {
    setState(() {
      switch (key) {
        case 'all': isAllItemsAccessCheck = value!; break;
        case 'inactive': isInactiveItemsAccessCheck = value!; break;
        case 'rate': isItemsRateAccessCheck = value!; break;
        case 'fast': isFastMovingItemsAccessCheck = value!; break;
        case 'amount': isItemsAmountAccessCheck = value!; break;
        case 'sales': isItemsSalesAccessCheck = value!; break;
        case 'purchase': isItemsPurchaseAccessCheck = value!; break;
      }
      _syncItemsMasterToggle();
    });
  }

  void _syncItemsMasterToggle() {
    isItemsAccessCheck = isAllItemsAccessCheck &&
        isInactiveItemsAccessCheck &&
        isItemsRateAccessCheck &&
        isFastMovingItemsAccessCheck &&
        isItemsAmountAccessCheck &&
        isItemsSalesAccessCheck &&
        isItemsPurchaseAccessCheck;
  }

  void _updateParty(String key, bool? value) {
    setState(() {
      switch (key) {
        case 'sales': isPartySalesAccess = value!; break;
        case 'purchase': isPartyPurchaseAccess = value!; break;
        case 'creditnote': isPartyCreditNoteAccess = value!; break;
        case 'journal': isPartyJournalAccess = value!; break;
        case 'payable': isPartyPayableAccess = value!; break;
        case 'pendingpurchase': isPartyPendingPurchaseOrderAccess = value!; break;
        case 'pendingsales': isPartyPendingSalesOrderAccess = value!; break;
        case 'receipt': isPartyReceiptAccess = value!; break;
        case 'payment': isPartyPaymentAccess = value!; break;
        case 'debitnote': isPartyDebitNoteAccess = value!; break;
        case 'receivable': isPartyReceivableAccess = value!; break;
        case 'suppliers': isPartySuppliersAccess = value!; break;
        case 'customers': isPartyCustomersAccess = value!; break;
      }
      _syncPartyMasterToggle();
    });
  }

  void _syncPartyMasterToggle() {
    isPartyAccessCheck = isPartySalesAccess &&
        isPartyPurchaseAccess &&
        isPartyCreditNoteAccess &&
        isPartyJournalAccess &&
        isPartyPayableAccess &&
        isPartyPendingPurchaseOrderAccess &&
        isPartyPendingSalesOrderAccess &&
        isPartyReceiptAccess &&
        isPartyPaymentAccess &&
        isPartyDebitNoteAccess &&
        isPartyReceivableAccess &&
        isPartySuppliersAccess &&
        isPartyCustomersAccess;
  }
  void _updateTransaction(String key, bool? value) {
    setState(() {
      switch (key) {
        case 'ledger': isTransactionLedgerEntryAccess = value!; break;
        case 'bills': isTransactionBillsEntryAccess = value!; break;
        case 'inventory': isTransactionInventoryEntryAccess = value!; break;
        case 'costcentre': isTransactionCostCentreEntryAccess = value!; break;
        case 'postdated': IsPostDatedTransactionsEntryAccess = value!; break;
      }
      _syncTransactionMasterToggle();
    });
  }

  void _syncTransactionMasterToggle() {
    isTransactionAccessCheck = isTransactionLedgerEntryAccess &&
        isTransactionBillsEntryAccess &&
        isTransactionInventoryEntryAccess &&
        isTransactionCostCentreEntryAccess &&
        IsPostDatedTransactionsEntryAccess;
  }

  void _updateEntry(String key, bool? value) {
    setState(() {
      switch (key) {
        case 'sales': isSalesEntryAccess = value!; break;
        case 'receipt': isReceiptEntryAccess = value!; break;
        case 'salesorder': isSalesOrderEntryAccess = value!; break;
      }
      _syncEntryMasterToggle();
    });
  }

  void _syncEntryMasterToggle() {
    isEntryAccessCheck = isSalesEntryAccess &&
        isReceiptEntryAccess &&
        isSalesOrderEntryAccess;
  }



  Future<void> addrolefunction (final String role_namee,final String serialno,final String salesdashcheck,final String barchartdashcheck,final String linechartdashcheck,
  final String piechartdashcheck, final String receiptsdashcheck, final String purchasedashcheck, final String paymentsdashcheck, final String outstandingreceivabledashcheck
      ,final String outstandingpayabledashcheck, final String cashdashcheck, final String allitemscheck, final String inactiveitemscheck
      ,final String activeitemscheck, final String ratecheck,final String amountcheck,final String item_salescheck,final String item_purchasecheck
      , final String salespartycheck, final String receiptpartycheck
      , final String purchasepartycheck, final String paymentpartycheck, final String creditnotepartycheck,
      final String debitnotepartycheck
      ,final String journalpartycheck, final String receivablepartycheck, final String payablepartycheck,
      final String pendingsalesorderpartycheck
      ,final String pendingpurchaseorderpartycheck,final String party_supplierscheck,final String party_customerscheck,
      final String ledgerentriescheck, final String billentriescheck
      ,final String inventoryentriescheck,final String postdatedtransactionscheck, final String costcentrecheck,final salesentrycheck, final receiptentrycheck, final salesorderentrycheck) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/roles/add');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': serialno,
      'rolename': role_namee,
      'salesdash': salesdashcheck,
      'barchartdash': barchartdashcheck,
      'linechartdash': linechartdashcheck,
      'piechartdash': piechartdashcheck,
      "receiptdash": receiptsdashcheck,
      "purchasedash": purchasedashcheck,
      "paymentdash" : paymentsdashcheck,
      "outstandingreceivabledash" : outstandingreceivabledashcheck,
      "outstandingpayablesdash" : outstandingpayabledashcheck,
      "cashdash" : cashdashcheck,
      "allitems" : allitemscheck,
      "inactiveitems" : inactiveitemscheck,
      "activeitems" : activeitemscheck,
      "rate" : ratecheck,
      "amount" : amountcheck,
      "item_sales" : item_salescheck,
      "item_purchase" : item_purchasecheck,
      "salesparty" : salespartycheck,
      "receiptparty" : receiptpartycheck,
      "purchaseparty" : purchasepartycheck,
      "paymentparty" : paymentpartycheck,
      "creditnoteparty" : creditnotepartycheck,
      "debitnoteparty" : debitnotepartycheck,
      "journalparty": journalpartycheck,
      "receivableparty" : receivablepartycheck,
      "payableparty" : payablepartycheck,
      "pendingsalesorderparty" : pendingsalesorderpartycheck,
      "pendingpurchaseorderparty" : pendingpurchaseorderpartycheck,
      "party_suppliers" : party_supplierscheck,
      "party_customers" : party_customerscheck,
      "ledgerentries" : ledgerentriescheck,
      "billsentries" : billentriescheck,
      "inventoryentries" : inventoryentriescheck,
      "postdatedtransactions":  postdatedtransactionscheck,
      "costcentreentries" : costcentrecheck,
      "salesEntry" : salesentrycheck,
      "receiptsEntry" : receiptentrycheck,
      "salesOrderEntry" : salesorderentrycheck
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final responsee = response.body;
      if (responsee != null) {

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responsee),
              ),
            );
            if(responsee == "Role already exists")
            {
              // DO NOTHING
            }
            else
            {
              WidgetsBinding.instance.addPostFrameCallback((_)
              {
                SchedulerBinding.instance.addPostFrameCallback((_)
                {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RolesView())
                  );});}); }
      }
      else
      {
        throw Exception('Failed to fetch data');
      }
      setState(()
      {
        _isLoading = false;
      });
    }
    else
    {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });}
      else
      {
        error = 'Something went wrong!!!';
      }

      Fluttertoast.showToast(msg: error);
    }
    setState(()
    {
      _isLoading = false;
    });
  }

  Future<void> _showConfirmationDialogAndNavigate(BuildContext context) async {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Role Confirmation",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: controller..forward(), curve: Curves.easeOutBack),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🟢 Icon Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: app_color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_task_rounded,
                      size: 42,
                      color: app_color,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 🧾 Title
                  Text(
                    'Add Role Confirmation',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // 💬 Description
                  Text(
                    'Are you sure you want to add this new role?\n'
                        'Please confirm to proceed.',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 26),

                  // 🔘 Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: app_color, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: app_color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Confirm
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            addrolefunction(
                              rolename,
                              serial_no!,
                              salesdashcheck,
                              barchartdashcheck,
                              linechartdashcheck,
                              piechartdashcheck,
                              receiptsdashcheck,
                              purchasedashcheck,
                              paymentsdashcheck,
                              outstandingreceivabledashcheck,
                              outstandingpayabledashcheck,
                              cashdashcheck,
                              allitemscheck,
                              inactiveitemscheck,
                              activeitemscheck,
                              ratecheck,
                              amountcheck,
                              item_salescheck,
                              item_purchasecheck,
                              salespartycheck,
                              receiptpartycheck,
                              purchasepartycheck,
                              paymentpartycheck,
                              creditnotepartycheck,
                              debitnotepartycheck,
                              journalpartycheck,
                              receivablepartycheck,
                              payablepartycheck,
                              pendingsalesorderpartycheck,
                              pendingpurchaseorderpartycheck,
                              party_supplierscheck,
                              party_customerscheck,
                              ledgerentriescheck,
                              billentriescheck,
                              inventoryentriescheck,
                              postdatedtransactionscheck,
                              costcentrecheck,
                              salesentrycheck,
                              receiptentrycheck,
                              salesorderentrycheck,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: app_color,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Add Role',
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
            ),
          ),
        );
      },
    );
  }

  Future<void> addrolefn() async
  {
    rolename = _textEditingController.text;
    if (rolename.isEmpty)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Enter Role Name"),
        ),
      );
    }
    else {
     setState(() {
       if (isSalesAccessCheck)
       {
         salesdashcheck = "True";
       }
       else
       {
         salesdashcheck = "False";

       }
       if (isBarChartDashAccessCheck)
       {
         barchartdashcheck = "True";
       }
       else
       {
         barchartdashcheck = "False";

       }
       if (isLineChartDashAccessCheck)
       {
         linechartdashcheck = "True";
       }
       else
       {
         linechartdashcheck = "False";

       }
       if (isPieChartDashAccessCheck)
       {
         piechartdashcheck = "True";
       }
       else
       {
         piechartdashcheck = "False";

       }
       if (isReceiptsAccessCheck)
       {
         receiptsdashcheck = "True";
       }
       else
       {
         receiptsdashcheck = "False";
       }
       if (isPurchaseAccessCheck)
       {
         purchasedashcheck = "True";
       }
       else
       {
         purchasedashcheck = "False";
       }
       if (isPaymentsAccessCheck)
       {
         paymentsdashcheck = "True";
       }
       else
       {
         paymentsdashcheck = "False";
       }
       if (isOutstandingReceivableAccessCheck)
       {
         outstandingreceivabledashcheck = "True";
       }
       else
       {
         outstandingreceivabledashcheck = "False";
       }
       if (isOutstandingPayableAccessCheck)
       {
         outstandingpayabledashcheck = "True";
       }
       else
       {
         outstandingpayabledashcheck = "False";
       }
       if (isAllItemsAccessCheck)
       {
         allitemscheck = "True";
       }
       else
       {
         allitemscheck = "False";
       }
       if (isInactiveItemsAccessCheck)
       {
         inactiveitemscheck = "True";
       }
       else
       {
         inactiveitemscheck = "False";
       }
       if (isFastMovingItemsAccessCheck)
       {
         activeitemscheck = "True";
       }
       else
       {
         activeitemscheck = "False";
       }
       if (isPartySalesAccess)
       {
         salespartycheck = "True";
       }
       else
       {
         salespartycheck = "False";
       }
       if (isPartyReceiptAccess)
       {
         receiptpartycheck = "True";
       }
       else
       {
         receiptpartycheck = "False";
       }
       if (isPartyPurchaseAccess)
       {
         purchasepartycheck = "True";
       }
       else
       {
         purchasepartycheck = "False";
       }
       if (isPartyPaymentAccess)
       {
         paymentpartycheck = "True";
       }
       else
       {
         paymentpartycheck = "False";
       }
       if (isPartyCreditNoteAccess)
       {
         creditnotepartycheck = "True";
       }
       else
       {
         creditnotepartycheck = "False";
       }
       if (isPartyDebitNoteAccess)
       {
         debitnotepartycheck = "True";
       }
       else
       {
         debitnotepartycheck = "False";
       }
       if (isPartyJournalAccess)
       {
         journalpartycheck = "True";
       }
       else
       {
         journalpartycheck = "False";
       }
       if (isPartyReceivableAccess)
       {
         receivablepartycheck = "True";
       }
       else
       {
         receivablepartycheck = "False";
       }
       if (isPartyPayableAccess)
       {
         payablepartycheck = "True";
       }
       else
       {
         payablepartycheck = "False";
       }
       if (isPartyPendingSalesOrderAccess)
       {
         pendingsalesorderpartycheck = "True";
       }
       else
       {
         pendingsalesorderpartycheck = "False";
       }
       if (isPartyPendingPurchaseOrderAccess)
       {
         pendingpurchaseorderpartycheck = "True";
       }
       else
       {
         pendingpurchaseorderpartycheck = "False";
       }
       if (isItemsRateAccessCheck)
       {
         ratecheck = "True";
       }
       else
       {
         ratecheck = "False";
       }
       if (isCashAccessCheck)
       {
         cashdashcheck = "True";
       }
       else
       {
         cashdashcheck = "False";
       }
       if (isTransactionLedgerEntryAccess)
       {
         ledgerentriescheck = "True";
       }
       else
       {
         ledgerentriescheck = "False";
       }
       if (isTransactionBillsEntryAccess)
       {
         billentriescheck = "True";
       }
       else
       {
         billentriescheck = "False";
       }
       if (isTransactionInventoryEntryAccess)
       {
         inventoryentriescheck = "True";
       }
       else
       {
         inventoryentriescheck = "False";
       }

       if(IsPostDatedTransactionsEntryAccess)
       {
           postdatedtransactionscheck = "True";
       }
       else
         {
           postdatedtransactionscheck = "False";
         }

       if (isSalesEntryAccess)
       {
         salesentrycheck = "True";
       }
       else
       {
         salesentrycheck = "False";

       }

       if (isReceiptEntryAccess)
       {
         receiptentrycheck = "True";
       }
       else
       {
         receiptentrycheck = "False";

       }

       if (isSalesOrderEntryAccess)
       {
         salesorderentrycheck = "True";
       }
       else
       {
         salesorderentrycheck = "False";

       }


       if (isTransactionCostCentreEntryAccess)
       {
         costcentrecheck = "True";
       }
       else
       {
         costcentrecheck = "False";

       }

       if (isItemsAmountAccessCheck)
       {
         amountcheck = "True";
       }
       else
       {
         amountcheck = "False";

       }
       if (isItemsSalesAccessCheck)
       {
         item_salescheck = "True";
       }
       else
       {
         item_salescheck = "False";

       }
       if (isItemsPurchaseAccessCheck)
       {
         item_purchasecheck = "True";
       }
       else
       {
         item_purchasecheck = "False";

       }

       if (isPartySuppliersAccess)
       {
         party_supplierscheck = "True";
       }
       else
       {
         party_supplierscheck = "False";

       }
       if (isPartyCustomersAccess)
       {
         party_customerscheck = "True";
       }
       else
       {
         party_customerscheck = "False";
       }
     });
      _showConfirmationDialogAndNavigate(context);
    }
  }

  Future<void> fetchRolesData(String selectedrole,String serial_no) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/roles/get');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'rolename': selectedrole,
      'serialno': serial_no,
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final roles_data = jsonDecode(response.body);
      if (roles_data != null) {
        setState(() {
          saved_roles_data_list = roles_data;
        });

        SalesDashHolder = saved_roles_data_list[0]["isSaleDash"] ;
        BarChartDashHolder = saved_roles_data_list[0]["isBarChartDash"] ;
        LineChartDashHolder = saved_roles_data_list[0]["isLineChartDash"] ;
        PieChartDashHolder = saved_roles_data_list[0]["isPieChartDash"] ;

        ReceiptsDashHolder = saved_roles_data_list[0]["isReceiptsDash"] ;
        PurchaseDashHolder = saved_roles_data_list[0]["isPurchaseDash"];
        PaymentsDashHolder = saved_roles_data_list[0]["isPaymentsDash"];
        OutstandingReceivablesDashHolder = saved_roles_data_list[0]["isOutstandingReceivableDash"] ;
        OutstandingPayablesDashHolder = saved_roles_data_list[0]["isOutstandingPayableDash"];
        CashDashHolder = saved_roles_data_list[0]["isCashDash"];
        AllitemsHolder = saved_roles_data_list[0]["isAllItems"] ;
        InActiveitemsHolder = saved_roles_data_list[0]["isInactiveItems"] ;
        ActiveitemsHolder = saved_roles_data_list[0]["isActiveItems"];
        RateHolder = saved_roles_data_list[0]["isRate"] ;
        AmountHolder = saved_roles_data_list[0]["isItemAmount"] ;
        ItemSalesHolder = saved_roles_data_list[0]["isItemSales"] ;
        ItemPurchaseHolder = saved_roles_data_list[0]["isItemPurchase"] ;
        SalesPartyHolder = saved_roles_data_list[0]["isSalesParty"] ;
        ReceiptPartyHolder = saved_roles_data_list[0]["isReceiptParty"] ;
        PurchasePartyHolder = saved_roles_data_list[0]["isPurchaseParty"];
        PaymentPartyHolder = saved_roles_data_list[0]["isPaymentParty"] ;
        CreditNotePartyHolder = saved_roles_data_list[0]["isCreditNoteParty"] ;
        DebitNotePartyHolder = saved_roles_data_list[0]["isDebitNoteParty"] ;
        JournalPartyHolder = saved_roles_data_list[0]["isJournalParty"];
        ReceivablePartyHolder = saved_roles_data_list[0]["isReceivableParty"] ;
        PayablePartyHolder = saved_roles_data_list[0]["isPayableParty"];
        PendingSalesOrderPartyHolder = saved_roles_data_list[0]["isPendingSalesOrderParty"] ;
        PendingPurchaseOrderPartyHolder = saved_roles_data_list[0]["isPendingPurchaseOrderParty"] ;
        PartySuppliersHolder = saved_roles_data_list[0]["isParty_Suppliers"] ;
        PartyCustomersHolder = saved_roles_data_list[0]["isParty_Customers"];
        LedgerEntriesHolder = saved_roles_data_list[0]["isLedgerEntries"] ;
        BillsEntriesHolder = saved_roles_data_list[0]["isBillsEntries"] ;
        InventoryEntriesHolder = saved_roles_data_list[0]["isInventoryEntries"] ;
        PostDatedTransactionsHolder = saved_roles_data_list[0]["isPostDatedTransactions"] ?? "True";
        CostCentreEntriesHolder = saved_roles_data_list[0]["isCostCentreEntries"];
        SalesEntryHolder = saved_roles_data_list[0]["isSalesEntry"];
        ReceiptEntryHolder = saved_roles_data_list[0]["isReceiptsEntry"];
        SalesOrderEntryHolder = saved_roles_data_list[0]["isSalesOrderEntry"];

        setState(() {
          _isLoading = true;

          if(SalesDashHolder == "True")
          {
            isSalesAccessCheck = true;
          }
          else if (SalesDashHolder == "False")
          {
            isSalesAccessCheck = false;
          }

          if(BarChartDashHolder == "True")
          {
            isBarChartDashAccessCheck = true;
          }
          else if (BarChartDashHolder == "False")
          {
            isBarChartDashAccessCheck = false;
          }

          if(LineChartDashHolder == "True")
          {
            isLineChartDashAccessCheck = true;
          }
          else if (LineChartDashHolder == "False")
          {
            isLineChartDashAccessCheck = false;
          }
          if(PieChartDashHolder == "True")
          {
            isPieChartDashAccessCheck = true;
          }
          else if (PieChartDashHolder == "False")
          {
            isPieChartDashAccessCheck = false;
          }

          if(ReceiptsDashHolder == "True")
          {
            isReceiptsAccessCheck = true;
          }
          else if (ReceiptsDashHolder == "False")
          {
            isReceiptsAccessCheck = false;
          }
          if(PurchaseDashHolder == "True")
          {
            isPurchaseAccessCheck = true;
          }
          else if (PurchaseDashHolder == "False")
          {
            isPurchaseAccessCheck = false;
          }
          if(PaymentsDashHolder == "True")
          {
            isPaymentsAccessCheck = true;
          }
          else if (PaymentsDashHolder == "False")
          {
            isPaymentsAccessCheck = false;
          }
          if(OutstandingReceivablesDashHolder == "True")
          {
            isOutstandingReceivableAccessCheck = true;
          }
          else if (OutstandingReceivablesDashHolder == "False")
          {
            isOutstandingReceivableAccessCheck = false;
          }
          if(OutstandingPayablesDashHolder == "True")
          {
            isOutstandingPayableAccessCheck= true;
          }
          else if (OutstandingPayablesDashHolder == "False")
          {
            isOutstandingPayableAccessCheck= false;
          }
          if(CashDashHolder == "True")
          {
            isCashAccessCheck= true;
          }
          else if (CashDashHolder == "False")
          {
            isCashAccessCheck= false;
          }
          if(isSalesAccessCheck && isPurchaseAccessCheck && isReceiptsAccessCheck &&
              isPaymentsAccessCheck && isOutstandingPayableAccessCheck && isOutstandingReceivableAccessCheck
              && isCashAccessCheck && isBarChartDashAccessCheck && isLineChartDashAccessCheck && isPieChartDashAccessCheck)
          {
            isDashAccessCheck = true;
          }
          else
          {
            isDashAccessCheck = false;
          }

          if(AllitemsHolder == "True")
          {
            isAllItemsAccessCheck = true;
          }
          else if (AllitemsHolder == "False")
          {
            isAllItemsAccessCheck = false;
          }
          if(InActiveitemsHolder == "True")
          {
            isInactiveItemsAccessCheck = true;
          }
          else if (InActiveitemsHolder == "False")
          {
            isInactiveItemsAccessCheck = false;
          }
          if(ActiveitemsHolder == "True")
          {
            isFastMovingItemsAccessCheck = true;
          }
          else if (ActiveitemsHolder == "False")
          {
            isFastMovingItemsAccessCheck = false;
          }
          if(RateHolder == "True")
          {
            isItemsRateAccessCheck = true;
          }
          else if (RateHolder == "False")
          {
            isItemsRateAccessCheck = false;
          }
          if(AmountHolder == "True")
          {
            isItemsAmountAccessCheck = true;
          }
          else if (AmountHolder == "False")
          {
            isItemsAmountAccessCheck = false;
          }
          if(ItemSalesHolder == "True")
          {
            isItemsSalesAccessCheck = true;
          }
          else if (ItemSalesHolder == "False")
          {
            isItemsSalesAccessCheck = false;
          }
          if(ItemPurchaseHolder == "True")
          {
            isItemsPurchaseAccessCheck = true;
          }
          else if (ItemPurchaseHolder == "False")
          {
            isItemsPurchaseAccessCheck = false;
          }

          if(isAllItemsAccessCheck && isInactiveItemsAccessCheck && isItemsRateAccessCheck &&
              isFastMovingItemsAccessCheck && isItemsAmountAccessCheck && isItemsSalesAccessCheck
              && isItemsPurchaseAccessCheck)
          {
            isItemsAccessCheck = true;
          }
          else
          {
            isItemsAccessCheck = false;
          }

          if(SalesEntryHolder == "True")
          {
            isSalesEntryAccess = true;
          }
          else if (SalesEntryHolder == "False")
          {
            isSalesEntryAccess = false;
          }

          if(ReceiptEntryHolder == "True")
          {
            isReceiptEntryAccess = true;
          }
          else if (ReceiptEntryHolder == "False")
          {
            isReceiptEntryAccess = false;
          }

          if(SalesOrderEntryHolder == "True")
          {
            isSalesOrderEntryAccess = true;
          }
          else if (SalesOrderEntryHolder == "False")
          {
            isSalesOrderEntryAccess = false;
          }

          if(isSalesEntryAccess && isReceiptEntryAccess && isSalesOrderEntryAccess)
          {
            isEntryAccessCheck = true;
          }
          else
          {
              isEntryAccessCheck = false;
          }

          if(SalesPartyHolder == "True")
          {
            isPartySalesAccess = true;
          }
          else if (SalesPartyHolder == "False")
          {
            isPartySalesAccess = false;
          }
          if(ReceiptPartyHolder == "True")
          {
            isPartyReceiptAccess = true;
          }
          else if (ReceiptPartyHolder == "False")
          {
            isPartyReceiptAccess = false;
          }
          if(PurchasePartyHolder == "True")
          {
            isPartyPurchaseAccess = true;
          }
          else if (PurchasePartyHolder == "False")
          {
            isPartyPurchaseAccess = false;
          }
          if(PaymentPartyHolder == "True")
          {
            isPartyPaymentAccess = true;
          }
          else if (PaymentPartyHolder == "False")
          {
            isPartyPaymentAccess = false;
          }
          if(CreditNotePartyHolder == "True")
          {
            isPartyCreditNoteAccess = true;
          }
          else if (CreditNotePartyHolder == "False")
          {
            isPartyCreditNoteAccess = false;
          }
          if(DebitNotePartyHolder == "True")
          {
              isPartyDebitNoteAccess = true;
          }
          else if (DebitNotePartyHolder == "False")
          {
            isPartyDebitNoteAccess = false;
          }
          if(JournalPartyHolder == "True")
          {
            isPartyJournalAccess = true;
          }
          else if (JournalPartyHolder == "False")
          {
            isPartyJournalAccess = false;
          }
          if(ReceivablePartyHolder == "True")
          {
            isPartyReceivableAccess = true;
          }
          else if (ReceivablePartyHolder == "False")
          {
            isPartyReceivableAccess = false;
          }
          if(PayablePartyHolder == "True")
          {
            isPartyPayableAccess = true;
          }
          else if (PayablePartyHolder == "False")
          {
            isPartyPayableAccess = false;
          }
          if(PendingSalesOrderPartyHolder == "True")
          {
            isPartyPendingSalesOrderAccess = true;
          }
          else if (PendingSalesOrderPartyHolder == "False")
          {
            isPartyPendingSalesOrderAccess = false;
          }
          if(PendingPurchaseOrderPartyHolder == "True")
          {
            isPartyPendingPurchaseOrderAccess = true;
          }
          else if (PendingPurchaseOrderPartyHolder == "False")
          {
            isPartyPendingPurchaseOrderAccess = false;
          }
          if(PartySuppliersHolder == "True")
          {
            isPartySuppliersAccess = true;
          }
          else if (PartySuppliersHolder == "False")
          {
            isPartySuppliersAccess = false;
          }
          if(PartyCustomersHolder == "True")
          {
            isPartyCustomersAccess = true;
          }
          else if (PartyCustomersHolder == "False")
          {
            isPartyCustomersAccess = false;
          }

          if(isPartySalesAccess && isPartyPurchaseAccess && isPartyCreditNoteAccess &&
              isPartyJournalAccess && isPartyPayableAccess && isPartyPendingPurchaseOrderAccess
              && isPartySuppliersAccess && isPartyCustomersAccess && isPartyReceiptAccess && isPartyPaymentAccess
              && isPartyDebitNoteAccess && isPartyReceivableAccess && isPartyPendingSalesOrderAccess)
          {
            isPartyAccessCheck = true;
          }
          else
          {
            isPartyAccessCheck = false;
          }

          if(LedgerEntriesHolder == "True")
          {
              isTransactionLedgerEntryAccess = true;
          }
          else if (LedgerEntriesHolder == "False")
          {
            isTransactionLedgerEntryAccess = false;
          }
          if(BillsEntriesHolder == "True")
          {
            isTransactionBillsEntryAccess = true;
          }
          else if (BillsEntriesHolder == "False")
          {
            isTransactionBillsEntryAccess = false;
          }
          if(InventoryEntriesHolder == "True")
          {
            isTransactionInventoryEntryAccess = true;
          }
          else if (InventoryEntriesHolder == "False")
          {
            isTransactionInventoryEntryAccess = false;
          }
          if(PostDatedTransactionsHolder == "True")
          {
            IsPostDatedTransactionsEntryAccess = true;
          }
          else if (PostDatedTransactionsHolder == "False")
          {
            IsPostDatedTransactionsEntryAccess = false;
          }
          if(CostCentreEntriesHolder == "True")
          {
            isTransactionCostCentreEntryAccess = true;
          }
          else if (CostCentreEntriesHolder == "False")
          {
            isTransactionCostCentreEntryAccess = false;
          }
          if(isTransactionLedgerEntryAccess && isTransactionInventoryEntryAccess && isTransactionBillsEntryAccess &&
              isTransactionCostCentreEntryAccess && IsPostDatedTransactionsEntryAccess)
          {
            isTransactionAccessCheck = true;
          }
          else
          {
            isTransactionAccessCheck = false;
          }

          _isLoading = false;
        });
      }
      else
      {
        throw Exception('Failed to fetch data');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchRolesName(String selectedserial) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/roles/get');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode( {
      'serialno': selectedserial,

    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final roles_data = jsonDecode(response.body);
      if (roles_data != null) {
        setState(() {
          saved_roles_list = roles_data;
          try
          {
            selectedRole = saved_roles_list[0]['role_name'] as String;
            showSavedRoles = true;

            fetchRolesData(selectedRole,serial_no!);
          }
          catch(e)
          {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("No Role Found"),
              ),
            );
          }
        });
      } 
      else
      {
        throw Exception('Failed to fetch data');
      }
    }
  }

  void _toggleParty(bool value) {
    setState(() {
      isPartyAccessCheck = value;

      isPartySalesAccess = value;
      isPartyPurchaseAccess = value;
      isPartyCreditNoteAccess = value;
      isPartyJournalAccess = value;
      isPartyPayableAccess = value;
      isPartyPendingPurchaseOrderAccess = value;
      isPartyPendingSalesOrderAccess = value;
      isPartyReceiptAccess = value;
      isPartyPaymentAccess = value;
      isPartyDebitNoteAccess = value;
      isPartyReceivableAccess = value;
      isPartySuppliersAccess = value;
      isPartyCustomersAccess = value;
    });
  }
  void _toggleDashboard(bool value) {
    setState(() {
      isDashAccessCheck = value;

      isSalesAccessCheck = value;
      isPurchaseAccessCheck = value;
      isReceiptsAccessCheck = value;
      isPaymentsAccessCheck = value;
      isOutstandingPayableAccessCheck = value;
      isOutstandingReceivableAccessCheck = value;
      isCashAccessCheck = value;
      isBarChartDashAccessCheck = value;
      isLineChartDashAccessCheck = value;
      isPieChartDashAccessCheck = value;
    });
  }
  void _toggleItems(bool value) {
    setState(() {
      isItemsAccessCheck = value;

      isAllItemsAccessCheck = value;
      isInactiveItemsAccessCheck = value;
      isItemsRateAccessCheck = value;
      isFastMovingItemsAccessCheck = value;
      isItemsAmountAccessCheck = value;
      isItemsSalesAccessCheck = value;
      isItemsPurchaseAccessCheck = value;
    });
  }
  void _toggleTransactions(bool value) {
    setState(() {
      isTransactionAccessCheck = value;

      isTransactionLedgerEntryAccess = value;
      isTransactionBillsEntryAccess = value;
      isTransactionInventoryEntryAccess = value;
      isTransactionCostCentreEntryAccess = value;
      IsPostDatedTransactionsEntryAccess = value;
    });
  }
  void _toggleEntry(bool value) {
    setState(() {
      isEntryAccessCheck = value;

      isSalesEntryAccess = value;
      isReceiptEntryAccess = value;
      isSalesOrderEntryAccess = value;
    });
  }


  Future<void> _initSharedPreferences() async {
  prefs = await SharedPreferences.getInstance();

  setState(() {

  hostname = prefs.getString('hostname');

  company  = prefs.getString('company_name');
  company_lowercase = company!.replaceAll(' ', '').toLowerCase();
  serial_no = prefs.getString('serial_no');
  username = prefs.getString('username');

  HttpURL =  hostname! + "/api/dashboard/home/" + company_lowercase! + "/" + serial_no!;

  SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

  String? email_nav = prefs.getString('email_nav');
  String? name_nav = prefs.getString('name_nav');
  
  if (email_nav!=null && name_nav!= null)
  {
    name = name_nav;
    email = email_nav;
  }

  if(SecuritybtnAcessHolder == "True")
  {
    isRolesVisible = true;
    isUserVisible = true;
  }
  else
  {
    isRolesVisible = false;
    isUserVisible = false;
  }
});
  }

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RolesView()),
        );
        return true;
      },
      child: Scaffold(

        key: _scaffoldKey,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RolesView()),
                );              },
            ),
            title: GestureDetector(
              onTap: () {

              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      "Role Registration",
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

        drawer: Sidebar(
          isDashEnable: isDashEnable,
          isRolesVisible: isRolesVisible,
          isRolesEnable: isRolesEnable,
          isUserEnable: isUserEnable,
          isUserVisible: isUserVisible,
          Username: name,
          Email: email,
          tickerProvider: this,
        ),
        body: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator.adaptive()),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [



                  // Copy Role Section
                  _buildCopyRoleCard(icon: Icons.import_contacts_outlined),

                  const SizedBox(height: 10),

                  // New Role TextField
                  _buildTextFieldCard(),

                  const SizedBox(height: 10),

                  // Dashboard Access
                  _buildPermissionCard(
                    title: 'Dashboard Access',
                    isChecked: isDashAccessCheck,
                    onToggle: (val) => _toggleDashboard(val!),
                    icon: Icons.dashboard,
                    children: _buildPermissionList(dashboardPermissions),
                  ),


                  const SizedBox(height: 10),

                  // Items Access
                  _buildPermissionCard(
                    title: 'Items Access',
                    isChecked: isItemsAccessCheck,
                    icon: Icons.inventory_outlined,

                    onToggle: (val) => _toggleItems(val!),
                    children: _buildPermissionList(itemsPermissions),
                  ),

                  const SizedBox(height: 10),

                  // Party Access
                  _buildPermissionCard(
                    title: 'Party Access',
                    isChecked: isPartyAccessCheck,
                    icon: Icons.person,
                    onToggle: (val) => _toggleParty(val!),
                    children: _buildPermissionList(partyPermissions),
                  ),

                  const SizedBox(height: 10),

                  // Transactions Access
                  _buildPermissionCard(
                    title: 'Transactions Access',
                    isChecked: isTransactionAccessCheck,
                    icon: Icons.app_registration,

                    onToggle: (val) => _toggleTransactions(val!),
                    children: _buildPermissionList(transactionPermissions),
                  ),

                  const SizedBox(height: 10),

                  // Entry Access
                  _buildPermissionCard(
                    title: 'Entry Access',
                    icon: Icons.type_specimen,

                    isChecked: isEntryAccessCheck,
                    onToggle: (val) => _toggleEntry(val!),
                    children: _buildPermissionList(entryPermissions),
                  ),

                  const SizedBox(height: 22),

                  Center(
                    child: ElevatedButton(
                      onPressed: addrolefn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      ),
                      child: Text(
                        'REGISTER',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRoleCard({IconData icon = Icons.copy_all}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: app_color.withOpacity(0.1),
                radius: 22,
                child: Icon(icon, size: 24, color: app_color),
              ),
              title: Text(
                'Copy Role from Existing',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Load and select from previously saved roles.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Tap to Load Button — hidden once showSavedRoles is true
            if (!showSavedRoles)
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Tap to Load Roles',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: app_color),
                    foregroundColor: app_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    fetchRolesName(serial_no!);
                    setState(() {
                      showSavedRoles = true;
                    });
                  },
                ),
              ),

            // Dropdown — shown only when showSavedRoles is true
            if (showSavedRoles) ...[
              const SizedBox(height: 0),
              Text(
                'Select Role',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedRole,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: const SizedBox(),
                  items: saved_roles_list.map<DropdownMenuItem<String>>((role) {
                    final roleName = role['role_name'] as String?;
                    return DropdownMenuItem<String>(
                      value: roleName,
                      child: Text(
                        roleName!,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                    fetchRolesData(selectedRole, serial_no!);
                  },
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Tip: This will overwrite current permissions.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({IconData icon = Icons.edit_note}) {
    return Container(
      margin: EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: app_color.withOpacity(0.1),
                radius: 22,
                child: Icon(icon, size: 24, color: app_color),
              ),
              title: Text(
                'Create New Role',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Give a name to your custom role.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Text Field Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),

              ),
              padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: _textEditingController,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter new role name',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  border: InputBorder.none,

                  icon: Icon(Icons.badge_outlined, color: Colors.grey),
                ),
              ),
            ),

            SizedBox(height: 8),

            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Tip: Role name should be unique.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required bool isChecked,
    required void Function(bool?)? onToggle,
    required List<Widget> children,
    IconData icon = Icons.shield_outlined,
    Color iconColor = app_color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      radius: 18,
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: isChecked,
                  activeColor: iconColor,
                  onChanged: onToggle,
                )
              ],
            ),

            const SizedBox(height: 16),

            // Children Permissions
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSubPermission(String label, bool value, Function(bool?) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: value ? app_color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: value ? app_color : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: value ? app_color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value ? app_color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPermissionList(List<Map<String, dynamic>> list) {
    return list
        .map((perm) => _buildSubPermission(
      perm['label'],
      perm['value'],
      perm['onChanged'],
    ))
        .toList();
  }



}