import 'dart:math';

import 'package:fincoremobile/SerialSelect.dart';
import 'package:fincoremobile/utils/number_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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


