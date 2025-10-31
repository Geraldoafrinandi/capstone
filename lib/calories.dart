import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// import 'model/UserCalories.dart';
import 'model/PredictionNutrition.dart';
import 'model/UserCalories.dart';

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  List<PredictionNutrition> nutritionList = [];

  bool isLoading = true;
  bool isError = false;

  double currentCalories = 0;
  double currentCarbs = 0;
  double currentProtein = 0;
  double currentFat = 50;

  double maxCalories = 1000;
  final double maxCarbs = 100;
  final double maxProtein = 75;
  final double maxFat = 50;

  @override
  void initState() {
    super.initState();
    fetchNutritionData();
  }

  Future<void> fetchNutritionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print("❌ userId tidak ditemukan di SharedPreferences.");
        setState(() {
          isError = true;
          isLoading = false;
        });
        return;
      }

      print("✅ userId ditemukan: $userId");

      final calorieResponse = await http
          .get(Uri.parse("http://10.0.2.2:3000/api/calories/$userId"))
          .timeout(const Duration(seconds: 5));

      final riwayatResponse = await http
          .get(Uri.parse("http://10.0.2.2:3000/api/riwayat-konsumsi/$userId"))
          .timeout(const Duration(seconds: 5));

      print("✔ Status Calories: ${calorieResponse.statusCode}");
      print("✔ Status Riwayat: ${riwayatResponse.statusCode}");

      if (calorieResponse.statusCode == 200 &&
          riwayatResponse.statusCode == 200) {
        final calorieBody = json.decode(calorieResponse.body);
        final riwayatBody = json.decode(riwayatResponse.body);

        if (calorieBody['data'] == null) {
          print("⚠️ calorieBody['data'] null: ${calorieBody.toString()}");
          setState(() {
            isError = true;
            isLoading = false;
          });
          return;
        }

        if (riwayatBody['data'] == null || !(riwayatBody['data'] is List)) {
          print("⚠️ riwayatBody['data'] invalid: ${riwayatBody.toString()}");
          setState(() {
            isError = true;
            isLoading = false;
          });
          return;
        }

        final userCalories = UserCalories.fromJson(calorieBody['data']);
        final List<dynamic> riwayatList = riwayatBody['data'];

        final List<PredictionNutrition> fetchedList = riwayatList
            .map((item) => PredictionNutrition.fromJson(item))
            .toList();

        final double sumCalories =
            fetchedList.fold(0.0, (sum, item) => sum + item.calories);
        final double sumProtein =
            fetchedList.fold(0.0, (sum, item) => sum + item.protein);
        final double sumFat =
            fetchedList.fold(0.0, (sum, item) => sum + item.fat);
        final double sumCarbs =
            fetchedList.fold(0.0, (sum, item) => sum + item.carbohydrates);

        setState(() {
          nutritionList = fetchedList;
          currentCalories = sumCalories;
          currentProtein = sumProtein;
          currentFat = sumFat;
          currentCarbs = sumCarbs;
          maxCalories = userCalories.kebutuhanKalori;

          isLoading = false;
          isError = false;
        });
      } else {
        print(
            "❌ Gagal mengambil data: ${calorieResponse.statusCode} / ${riwayatResponse.statusCode}");
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e, stack) {
      print("❌ Exception: $e");
      print(stack);
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> deleteNutritionItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'Konfirmasi Hapus',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin menghapus makanan ini dari riwayat?',
          style: TextStyle(color: Colors.black54),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.cancel, color: Colors.grey),
            label: const Text('Batal'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await http.delete(
      Uri.parse("http://10.0.2.2:3000/api/riwayat/delete/$id"),
    );

    if (response.statusCode == 200) {
      await fetchNutritionData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Berhasil menghapus data")),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget buildPie(String label, double value, double max, Color color) {
    final double percentage = (value / max * 100).clamp(0, 100);
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                dataMap: {
                  label: value,
                  "Sisa": (max - value).clamp(0, max),
                },
                chartType: ChartType.ring,
                ringStrokeWidth: 14,
                chartValuesOptions:
                    const ChartValuesOptions(showChartValues: false),
                legendOptions: const LegendOptions(showLegends: false),
                colorList: [color, Color.fromARGB(255, 200, 199, 199)],
                totalValue: max,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${percentage.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildNutritionBox(
      int id, String name, double calories, String? imageUrl) {
    final String finalImageUrl =
        (imageUrl != null && imageUrl.startsWith('http'))
            ? imageUrl
            : (imageUrl != null ? 'http://10.0.2.2:3000$imageUrl' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              finalImageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image,
                    size: 30, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 16)),
          ),
          Text(
            "${calories.toStringAsFixed(0)} kkal",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteNutritionItem(id),
          ),
        ],
      ),
    );
  }

  Widget buildNutritionChartSection() {
    final double caloriePercent =
        (currentCalories / maxCalories * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: const Text(
              'Today Nutrition',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildPie("Calories", currentCalories, maxCalories, Colors.blue),
              buildPie("Protein", currentProtein, maxProtein, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildPie("Fat", currentFat, maxFat, Colors.red),
              buildPie("Carbs", currentCarbs, maxCarbs, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  "Total Kalori Harian: ${currentCalories.toStringAsFixed(0)} / ${maxCalories.toStringAsFixed(0)} kkal",
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (caloriePercent >= 100)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "🎉 Kalori harian sudah tercukupi!",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isError
                ? const Center(
                    child: Text(
                      "❌ Gagal memuat data.\nSilakan cek koneksi atau backend.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildNutritionChartSection(),
                        const SizedBox(height: 24),
                        ...nutritionList
                            .where((item) => item.id != null)
                            .map((item) {
                          print('Item ID: ${item.id}, Food: ${item.foodName}');
                          return buildNutritionBox(item.id!, item.foodName,
                              item.calories, item.imageUrl);
                        })
                      ],
                    ),
                  ),
      ),
    );
  }
}
