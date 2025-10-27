import 'dart:math';
import 'package:FincoreGo/utils/number_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lineChartData;
  final List<String> months;
  final Map<int, Color> yearColors;
  final List<Map<String, dynamic>> pieSalesList;
  final List<Map<String, dynamic>> piePurchaseList;
  final bool isVisibleLineChart;
  final bool isVisiblePieChart;
  final bool isSalesPieChartVisible;
  final bool isPurchasePieChartVisible;
  final int decimalPlaces;
  final bool isBarChartVisible;
  final List<double> salesDataList;
  final List<double> recDataList;
  final NumberScale selectedScale;
  final String startDateString;
  final String endDateString;



  const AnalyticsScreen({
    super.key,
    required this.lineChartData,
    required this.months,
    required this.yearColors,
    required this.pieSalesList,
    required this.piePurchaseList,
    required this.isVisibleLineChart ,
    required this.isVisiblePieChart,
    required this.isSalesPieChartVisible,
    required this.isPurchasePieChartVisible,
    required this.decimalPlaces,
    required this.isBarChartVisible,
    required this.salesDataList,
    required this.recDataList,
    required this.selectedScale,
    required this.startDateString,
    required this.endDateString,


  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}


class _AnalyticsScreenState extends State<AnalyticsScreen> {



  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",SecuritybtnAcessHolder= "";
  late SharedPreferences prefs;

  NumberScale selectedScale = NumberScale.million;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }
  double calculateContainerWidthBarGraph() {
    int totalMonths = getMonthsList().length; // ✅ now dynamic
    double averageLabelWidth = 60.0; // Adjust as needed

    double screensize = MediaQuery.of(context).size.width - 20.0;

    // Calculate the total width needed for all month labels
    double totalLabelWidth = totalMonths * averageLabelWidth;

    // Add extra width for margins, padding, and other elements
    double extraWidth = 100.0;

    // Calculate the final container width
    double containerWidth = totalLabelWidth + extraWidth;
    if(containerWidth < screensize)
    {
      containerWidth = screensize;
    }

    return containerWidth;
  }
  List<String> getMonthsList() {
    List<String> months = [];

    try {
      DateTime startDate = DateTime.parse(widget.startDateString);
      DateTime endDate = DateTime.parse(widget.endDateString);

      // Ensure valid date range
      while (startDate.isBefore(endDate) || startDate.isAtSameMomentAs(endDate)) {
        String monthLabel = DateFormat('MMM-yy').format(startDate);
        months.add(monthLabel);

        // Move to next month safely
        startDate = DateTime(startDate.year, startDate.month + 1, 1);
      }
    } catch (e) {
      debugPrint("Error generating months list: $e");
    }

    return months;
  }

  Future<void> _loadNumberScale() async {
    String? scale = prefs.getString("number_scale");
    if (scale != null) {
      switch (scale) {
        case "thousand":
          selectedScale = NumberScale.thousand;
          break;
        case "million":
          selectedScale = NumberScale.million;
          break;
        case "billion":
          selectedScale = NumberScale.billion;
          break;
        default:
          selectedScale = NumberScale.thousand;
      }
    }
    setState(() {});
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {

      company  = prefs.getString('company_name');
      company_lowercase = company!.replaceAll(' ', '').toLowerCase();
      serial_no = prefs.getString('serial_no');
      username = prefs.getString('username');

      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      _loadNumberScale();
  });
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  "Analytics",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),


      body: SingleChildScrollView(
        child: Column(
          children: [

            Visibility(
              visible: widget.isBarChartVisible,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Header with Icon
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.teal.shade400, Colors.teal.shade700],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.bar_chart_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Sales vs Receipts",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 🔹 Chart
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: calculateContainerWidthBarGraph(),
                        height: MediaQuery.of(context).size.height / 3.5,
                        child: BarChartWidget(
                          salesData: widget.salesDataList,
                          receiptData: widget.recDataList,
                          selectedScale: widget.selectedScale,
                          decimalPlaces: widget.decimalPlaces,
                          months: getMonthsList(), // ✅ pass months

                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend(app_color, 'Sales'),
                        const SizedBox(width: 20),
                        _buildLegend(Colors.deepOrange, 'Receipt'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            /// 📈 Line Chart Section
            Visibility(
              visible: widget.isVisibleLineChart,
              child: Container(
                margin: EdgeInsets.only(left: 16,right:16, bottom: 0,top:10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Monthly Sales Trends",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: MediaQuery.of(context).size.width -40,
                        height: MediaQuery.of(context).size.height / 3.5,
                        padding: const EdgeInsets.only(top: 5),
                        child: LineChart(
                          LineChartData(
                            extraLinesData: ExtraLinesData(horizontalLines: []),
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: MediaQuery.of(context).size.width/8,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      formatNumberAbbreviation(
                                        value,
                                        scale: selectedScale,
                                        decimalPlaces: widget.decimalPlaces,
                                        showSuffix: false,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black54,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < widget.months.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          widget.months[index],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: false,)),
                                topTitles: AxisTitles(sideTitles: SideTitles(
                                  showTitles: false,))
                            ),

                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: widget.months.length.toDouble() - 1,
                            lineBarsData: widget.lineChartData.map((yearData) {
                              final yearIndex = widget.lineChartData.indexOf(yearData);
                              final spots = yearData['value'].map<FlSpot>((monthEntry) {
                                final monthIndex = widget.months
                                    .indexOf(monthEntry['month']);
                                final monthSales = monthEntry['sales'] as int;
                                return FlSpot(monthIndex.toDouble(), -monthSales.toDouble());
                              }).toList();

                              final color = widget.yearColors.putIfAbsent(
                                yearIndex,
                                    () => getRandomColor(),
                              );
                              return LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: color, // ✅ single color instead of 'colors: [color]'
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color.withOpacity(0.35),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              );

                            }).toList(),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(

                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((LineBarSpot spot) {
                                    return LineTooltipItem(
                                      formatNumberAbbreviation(
                                        spot.y,
                                        scale: selectedScale,
                                        decimalPlaces: widget.decimalPlaces,
                                        showSuffix: false,
                                      ),
                                      GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.lineChartData.map((yearData) {
                            final yearIndex = widget.lineChartData.indexOf(yearData);
                            final color = widget.yearColors[yearIndex] ?? Colors.black;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    yearData['year'].toString(),
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🥧 Pie Chart Section
            Visibility(
              visible: widget.isVisiblePieChart,
              child: Container(
                margin: EdgeInsets.only(left: 16,right:16, bottom: 0,top:10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Sales Pie Chart
                      Visibility(
                        visible: widget.isSalesPieChartVisible,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sales",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: MediaQuery.of(context).size.width - 40,
                              height: 190,
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: _buildPieChart_Sales(widget.pieSalesList),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    flex: 1,
                                    child: SingleChildScrollView(
                                      child: _buildLegend_Sales(widget.pieSalesList),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      /// Purchase Pie Chart
                      Visibility(
                        visible: widget.isPurchasePieChartVisible,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Purchase",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: MediaQuery.of(context).size.width - 40,
                              height: 190,
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: _buildPieChart_Purchase(widget.piePurchaseList),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    flex: 1,
                                    child: SingleChildScrollView(
                                      child: _buildLegend_Purchase(widget.piePurchaseList),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Color getRandomColor() {
    return Color.fromARGB(
      255,
      Random().nextInt(200),
      Random().nextInt(200),
      Random().nextInt(200),
    );
  }
}

Widget _buildLegend(Color color, String title) {
  return Row(
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      SizedBox(width: 6),
      Text(title, style: GoogleFonts.poppins(fontSize: 12)),
    ],
  );
}

List<Color> pieChartColors_sales = [];
List<Color> pieChartColors_purchase =[];
Widget _buildLegend_Sales(List<dynamic> data) {
  return ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: 180,
    ),
    child: SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: data.map<Widget>((item) {
          String title = item['name'] ?? '';
          Color color = pieChartColors_sales[data.indexOf(item)];

          return Container(
            constraints: const BoxConstraints(
              maxWidth: 220, // ✅ wrap width limit per chip
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.95),
                        color.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.75),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}

Widget _buildLegend_Purchase(List<dynamic> data) {
  return ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: 180,
    ),
    child: SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: data.map<Widget>((item) {
          String title = item['name'] ?? '';
          Color color = pieChartColors_purchase[data.indexOf(item)];

          return Container(
            constraints: const BoxConstraints(
              maxWidth: 220, // ✅ keeps long text nicely wrapped
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.95),
                        color.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.75),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}
Widget _buildPieChart_Purchase(List<dynamic> purchaseData) {
  pieChartColors_purchase.clear();
  pieChartColors_purchase = generateRandomColors(purchaseData.length);

  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: PieChart(
          PieChartData(
            centerSpaceRadius: 0, // ✅ full solid center
            startDegreeOffset: -90,
            sectionsSpace: 1.5,
            borderData: FlBorderData(show: false),
            sections: _generateChartData_Purchase(purchaseData),
          ),
        ),
      ),
    ),
  );
}

List<PieChartSectionData> _generateChartData_Purchase(List<dynamic> purchaseData) {
  return purchaseData.map((data) {
    final color = pieChartColors_purchase[purchaseData.indexOf(data)];

    return PieChartSectionData(
      value: (data['amount'] ?? 0).toDouble().abs(), // ✅ safe conversion
      title: '',
      color: color,
      radius: 85, // ✅ balanced slice thickness
      borderSide: BorderSide.none,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.65),
        ],
      ),
    );
  }).toList();
}

List<Color> generateRandomColors(int count) {
  List<Color> colors = [];
  for (int i = 0; i < count; i++) {
    Color randomColor;
    do {
      randomColor = getRandomColor();
    } while (colors.contains(randomColor)); // Ensure distinct colors
    colors.add(randomColor);
  }
  return colors;
}
Color getRandomColor() {
  final random = Random();
  return Color.fromARGB(
    255,
    random.nextInt(255),
    random.nextInt(255),
    random.nextInt(255),
  );
}
class BarChartWidget extends StatelessWidget {
  final List<double> salesData;
  final List<double> receiptData;
  final NumberScale selectedScale;
  final int decimalPlaces;
  final List<String> months; // 👈 add this


  const BarChartWidget({
    super.key,
    required this.salesData,
    required this.receiptData,
    required this.selectedScale,
    required this.decimalPlaces,
    required this.months, // 👈 add this

  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 12, bottom: 0), // 👈 added bottom space
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: getMaxValue() + (getMaxValue() * 0.1),
            groupsSpace: 18,
            barGroups: generateBars(),

            // 🔹 Tooltip
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final label = rodIndex == 0 ? "Sales" : "Receipt";
                  return BarTooltipItem(
                    '$label\n${formatNumberAbbreviation(
                      rod.toY,
                      scale: selectedScale,
                      decimalPlaces: decimalPlaces,
                      showSuffix: false,
                    )}',
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },

              ),
            ),

            // 🔹 Axis Titles
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40, // 👈 ensures full visibility

                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < months.length) {
                      return Transform.rotate( // 👈 tilt for readability
                        angle: -0.0, // about -30 degrees
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            months[index],
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 62, // 👈 more room for long values
                  maxIncluded: false,
                  minIncluded: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        formatNumberAbbreviation(
                          value,
                          scale: selectedScale,
                          decimalPlaces: decimalPlaces,
                          showSuffix: false,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  },
                ),
              ),

              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false,
                ),

              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),




            // 🔹 Grid & Border
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
          ),
        ));
  }


  double getMaxValue() {
    List<double> combinedData = salesData + receiptData;
    combinedData.removeWhere((value) => value.isNaN || value.isInfinite);
    if (combinedData.isEmpty) return 0;
    return combinedData.reduce(max);
  }

  List<BarChartGroupData> generateBars() {
    return List.generate(salesData.length, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 8,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: salesData[i],
            width: 14,
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                app_color.withOpacity(0.9),
                app_color.withOpacity(0.6),
              ],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: getMaxValue() + 10,
              color: Colors.grey.shade100,
            ),
          ),
          BarChartRodData(
            fromY: 0,
            toY: receiptData[i],
            width: 14,
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Colors.deepOrange,
                Colors.deepOrangeAccent,
              ],
            ),

            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: getMaxValue() + 10,
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    });
  }
}


Widget _buildPieChart_Sales(List<dynamic> salesData) {
  pieChartColors_sales.clear();
  pieChartColors_sales = generateRandomColors(salesData.length);

  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: PieChart(
          PieChartData(
            centerSpaceRadius: 0, // ✅ full solid center (filled look)
            startDegreeOffset: -90,
            sectionsSpace: 1.5,
            borderData: FlBorderData(show: false),
            sections: _generateChartData_Sales(salesData),
          ),
        ),
      ),
    ),
  );
}

List<PieChartSectionData> _generateChartData_Sales(List<dynamic> salesData) {
  return salesData.map((data) {
    final color = pieChartColors_sales[salesData.indexOf(data)];

    return PieChartSectionData(
      value: (data['amount'] ?? 0).toDouble().abs(), // ✅ cleaner & safe
      title: '',
      color: color,
      radius: 85, // ✅ balanced slice thickness
      borderSide: BorderSide.none,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.65),
        ],
      ),
    );
  }).toList();
}


