import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CalorieSummary {
  final int latest;
  final int average;
  final int goal;
  final int highest;
  final int lowest;

  CalorieSummary({
    this.latest = 0,
    this.average = 0,
    this.goal = 2000,
    this.highest = 0,
    this.lowest = 0,
  });
}

class NutritionProgressPage extends StatefulWidget {
  const NutritionProgressPage({super.key});

  @override
  State<NutritionProgressPage> createState() => _NutritionProgressPageState();
}

class _NutritionProgressPageState extends State<NutritionProgressPage> {
  bool _isLoading = true;
  String? _error;
  CalorieSummary _weeklySummary = CalorieSummary();
  CalorieSummary _monthlySummary = CalorieSummary();
  Map<String, double> _todayDataMap = {};

  double _proteinTarget = 0;
  double _carbsTarget = 0;
  double _fatTarget = 0;
  double _todayProtein = 0;
  double _todayCarbs = 0;
  double _todayFat = 0;

  @override
  void initState() {
    super.initState();
    _fetchProgressData();
  }

  Future<void> _fetchProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        setState(() {
          _error = 'User belum login.';
          _isLoading = false;
        });
        return;
      }

      final summaryUrl = Uri.parse('http://10.0.2.2:3000/api/summary/$userId');
      final goalUrl = Uri.parse('http://10.0.2.2:3000/api/goal/$userId');

      final summaryResponse = await http.get(summaryUrl);
      final goalResponse = await http.get(goalUrl);

      if (summaryResponse.statusCode != 200) {
        setState(() {
          _error = 'Gagal memuat data ringkasan (kode: ${summaryResponse.statusCode})';
          _isLoading = false;
        });
        return;
      }

      int goalCalories = 2000;
      if (goalResponse.statusCode == 200) {
        final goalJson = json.decode(goalResponse.body);
        if (goalJson is Map<String, dynamic>) {
          if (goalJson.containsKey('goal') && goalJson['goal'] is int) {
            goalCalories = goalJson['goal'];
          } else if (goalJson.containsKey('data') &&
              goalJson['data'] is Map<String, dynamic> &&
              goalJson['data']['kebutuhan_kalori'] is int) {
            goalCalories = goalJson['data']['kebutuhan_kalori'];
          }
        }
        debugPrint("💡 Goal kalori dari backend: $goalCalories");
      }

      final jsonData = json.decode(summaryResponse.body);
      final today = jsonData['data']['today'] ?? {};
      final weekly = jsonData['data']['weekly'] ?? {};
      final monthly = jsonData['data']['monthly'] ?? {};

      final newWeeklySummary = CalorieSummary(
        latest: weekly['latest'] ?? 0,
        average: weekly['average'] ?? 0,
        goal: goalCalories,
      );

      final newMonthlySummary = CalorieSummary(
        average: monthly['average'] ?? 0,
        highest: monthly['highest'] ?? 0,
        lowest: monthly['lowest'] ?? 0,
      );

      final Map<String, double> todayMap = {
        "Calories": 0.0,
        "Protein": 0.0,
        "Fat": 0.0,
        "Carbs": 0.0,
      };

      if (today['by_meal'] != null && today['by_meal'] is Map<String, dynamic>) {
        (today['by_meal'] as Map<String, dynamic>).forEach((key, value) {
          todayMap[key] = (value as num).toDouble();
        });
      }

      final double proteinTarget = (goalCalories * 0.20) / 4;
      final double carbsTarget = (goalCalories * 0.50) / 4;
      final double fatTarget = (goalCalories * 0.30) / 9;

      final double todayProtein = todayMap['Protein'] ?? 0;
      final double todayCarbs = todayMap['Carbs'] ?? 0;
      final double todayFat = todayMap['Fat'] ?? 0;

      if (mounted) {
        setState(() {
          _weeklySummary = newWeeklySummary;
          _monthlySummary = newMonthlySummary;
          _todayDataMap = todayMap;
          _proteinTarget = proteinTarget;
          _carbsTarget = carbsTarget;
          _fatTarget = fatTarget;
          _todayProtein = todayProtein;
          _todayCarbs = todayCarbs;
          _todayFat = todayFat;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayProgressCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Calories Summary (Week)'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryCard(Icons.history_toggle_off, 'Latest', '${_weeklySummary.latest} Kcal'),
              const SizedBox(width: 12),
              _buildSummaryCard(Icons.show_chart_rounded, 'Average', '${_weeklySummary.average} Kcal'),
              const SizedBox(width: 12),
              _buildSummaryCard(Icons.flag_outlined, 'Goal', '${_weeklySummary.goal} Kcal'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Calories Summary (Month)'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryCard(Icons.show_chart_rounded, 'Average', '${_monthlySummary.average} Kcal'),
              const SizedBox(width: 12),
              _buildSummaryCard(Icons.arrow_upward, 'Highest', '${_monthlySummary.highest} Kcal'),
              const SizedBox(width: 12),
              _buildSummaryCard(Icons.arrow_downward, 'Lowest', '${_monthlySummary.lowest} Kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgressCard() {
    const colorList = <Color>[
      Colors.lightBlueAccent, // Calories
      Colors.orangeAccent,    // Protein
      Colors.redAccent,       // Fat
      Color.fromARGB(255, 224, 224, 224), // Carbs
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          children: [
            const Text(
              "Today Goal Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _todayDataMap.isEmpty
                ? const Text("Tidak ada data hari ini")
                : PieChart(
                    dataMap: _todayDataMap,
                    chartType: ChartType.ring,
                    ringStrokeWidth: 35,
                     chartRadius: MediaQuery.of(context).size.width / 1.8,
                     
                    colorList: colorList,
                    legendOptions: const LegendOptions(showLegends: false),
                    chartValuesOptions: const ChartValuesOptions(showChartValues: false),
                  ),
            const SizedBox(height: 16),
            // Legend Warna
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _ColorLegend(color: Colors.lightBlueAccent, label: "Calories"),
                _ColorLegend(color: Colors.orangeAccent, label: "Protein"),
                _ColorLegend(color: Colors.redAccent, label: "Fat"),
                _ColorLegend(color: Color.fromARGB(255, 224, 224, 224), label: "Carbs"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionLabel("Calories", "${_weeklySummary.latest}/${_weeklySummary.goal}"),
                _buildNutritionLabel("Protein", "${_todayProtein.toStringAsFixed(0)}/${_proteinTarget.toStringAsFixed(0)} g"),
                _buildNutritionLabel("Carbs", "${_todayCarbs.toStringAsFixed(0)}/${_carbsTarget.toStringAsFixed(0)} g"),
                _buildNutritionLabel("Fat", "${_todayFat.toStringAsFixed(0)}/${_fatTarget.toStringAsFixed(0)} g"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildSummaryCard(IconData icon, String label, String value) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.green, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionLabel(String name, String value) {
    return Column(
      children: [
        Text(name, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ✅ Widget legend warna
class _ColorLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
