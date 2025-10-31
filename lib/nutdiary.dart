import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'model/PredictionNutrition.dart';
import 'model/UserCalories.dart';
import 'model/diary_data.dart';
import 'package:aplikasi_makanan/food_selection.dart';

class NutritionDiaryPage extends StatefulWidget {
  const NutritionDiaryPage({super.key});

  @override
  State<NutritionDiaryPage> createState() => _NutritionDiaryPageState();
}

class _NutritionDiaryPageState extends State<NutritionDiaryPage> {
  late Future<DiaryData> _diaryDataFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _diaryDataFuture = fetchAllData(_selectedDate);
    // _selectedDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _diaryDataFuture = fetchAllData(_selectedDate);
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _diaryDataFuture = fetchAllData(_selectedDate);
    });
  }

  // Future<void> _selectDate(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: _selectedDate,
  //     firstDate: DateTime(2025),
  //     lastDate: DateTime.now(),
  //     locale: const Locale('id', 'ID'),
  //   );
  //   if (picked != null && picked != _selectedDate) {
  //     setState(() {
  //       _selectedDate = picked;
  //       _diaryDataFuture = fetchAllData(_selectedDate);
  //     });
  //   }
  // }

  Future<DiaryData> fetchAllData(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        throw Exception("User ID tidak ditemukan. Silakan login kembali.");
      }

      // Ambil data user (ini tidak bergantung tanggal)
      final userResponse = await http.get(
        Uri.parse("http://10.0.2.2:3000/api/calories/$userId"),
      );
      if (userResponse.statusCode != 200) {
        throw Exception("Gagal mengambil data user.");
      }
      final userData = json.decode(userResponse.body)['data'];
      final userCalories = UserCalories.fromJson(userData);

      await prefs.setString('nama', userCalories.nama);
      await prefs.setInt('usia', userCalories.usia);
      await prefs.setString('gender', userCalories.gender);
      await prefs.setDouble('kebutuhan_kalori', userCalories.kebutuhanKalori);

      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final riwayatResponse = await http.get(
        Uri.parse(
            "http://10.0.2.2:3000/api/makan-user/$userId?date=$formattedDate"),
      );

      if (riwayatResponse.statusCode != 200) {
        throw Exception("Gagal mengambil riwayat makan.");
      }

      final historyData = json.decode(riwayatResponse.body)['data'];
      List<PredictionNutrition> historyList = [];

      if (historyData != null && historyData is List) {
        historyList = historyData
            .map((item) => PredictionNutrition.fromJson(item))
            .toList();
      }

      final double sumCalories =
          historyList.fold(0.0, (sum, item) => sum + item.calories);
      final double sumProtein =
          historyList.fold(0.0, (sum, item) => sum + item.protein);
      final double sumFat =
          historyList.fold(0.0, (sum, item) => sum + item.fat);
      final double sumCarbs =
          historyList.fold(0.0, (sum, item) => sum + item.carbohydrates);

      return DiaryData(
        userCalories: userCalories,
        history: historyList,
        consumedCalories: sumCalories,
        consumedProtein: sumProtein,
        consumedCarbs: sumCarbs,
        consumedFat: sumFat,
      );
    } catch (e) {
      print("❌ Error fetchAllData: $e");
      rethrow;
    }
  }

  Future<void> deleteNutritionItem(int historyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:3000/api/makan-user/delete/$historyId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Riwayat berhasil dihapus';

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Berhasil menghapus data",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );

        _refreshData();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Gagal menghapus riwayat dari server.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _navigateAndAddFood(String mealType, DateTime date) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodSelectionPage(
          mealType: mealType,
          selectedDate: date,
        ),
      ),
    );

    if (result == true && mounted) {
      _refreshData();
    }
  }

  Map<String, List<PredictionNutrition>> _groupHistoryByMeal(
      List<PredictionNutrition> history) {
    Map<String, List<PredictionNutrition>> grouped = {
      'Sarapan': [],
      'Makan Siang': [],
      'Makan Malam': [],
      'Snack': [],
    };

    for (var item in history) {
      String mealRaw = item.waktuMakan ?? 'Snack';
      String mealKey = _normalizeMealType(mealRaw);

      if (grouped.containsKey(mealKey)) {
        grouped[mealKey]!.add(item);
      } else {
        grouped['Snack']!.add(item); // fallback
      }
    }
    return grouped;
  }

  String _normalizeMealType(String input) {
    switch (input.toLowerCase()) {
      case 'sarapan':
        return 'Sarapan';
      case 'makan siang':
        return 'Makan Siang';
      case 'makan malam':
        return 'Makan Malam';
      case 'snack':
      default:
        return 'Snack';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder<DiaryData>(
        future: _diaryDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Gagal memuat data.\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Data tidak tersedia."));
          }

          final data = snapshot.data!;
          final groupedHistory = _groupHistoryByMeal(data.history);

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              slivers: [
                _SummaryHeader(
                  data: data,
                  selectedDate: _selectedDate,
                  onSelectDate: () => _selectDate(context),
                ),
                _MealSection(
                    title: 'Sarapan',
                    icon: Icons.free_breakfast_outlined,
                    items: groupedHistory['Sarapan']!,
                    onDeleteItem: deleteNutritionItem,
                    onAddItem: () =>
                        _navigateAndAddFood('Sarapan', _selectedDate)),
                _MealSection(
                    title: 'Makan Siang',
                    icon: Icons.lunch_dining_outlined,
                    items: groupedHistory['Makan Siang']!,
                    onDeleteItem: deleteNutritionItem,
                    onAddItem: () =>
                        _navigateAndAddFood('Makan Siang', _selectedDate)),
                _MealSection(
                    title: 'Makan Malam',
                    icon: Icons.dinner_dining_outlined,
                    items: groupedHistory['Makan Malam']!,
                    onDeleteItem: deleteNutritionItem,
                    onAddItem: () =>
                        _navigateAndAddFood('Makan Malam', _selectedDate)),
                _MealSection(
                    title: 'Snack',
                    icon: Icons.fastfood_outlined,
                    items: groupedHistory['Snack']!,
                    onDeleteItem: deleteNutritionItem,
                    onAddItem: () =>
                        _navigateAndAddFood('Snack', _selectedDate)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeleteDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Konfirmasi Hapus'),
      content: const Text('Yakin ingin menghapus item ini dari riwayat?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Hapus'),
        ),
      ],
    );
  }

  SnackBar _buildSuccessSnackBar() => SnackBar(
        content: const Text("Berhasil menghapus data"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      );

  SnackBar _buildErrorSnackBar(String message) => SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      );
}

class _SummaryHeader extends StatelessWidget {
  final DiaryData data;
  final DateTime selectedDate;
  final VoidCallback onSelectDate;

  const _SummaryHeader({
    required this.data,
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final totalCalories = data.userCalories.kebutuhanKalori;
    final maxCarbs = (totalCalories * 0.40) / 4;
    final maxProtein = (totalCalories * 0.30) / 4;
    final maxFat = (totalCalories * 0.30) / 9;
    final String displayDate = DateFormat.yMMMMd('id_ID').format(selectedDate);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 40), // Spacer untuk menyeimbangkan tombol
                  Column(
                    children: [
                      const Text("Ringkasan Harian",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(displayDate,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.green),
                    onPressed: onSelectDate,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryCircle(
                      label: 'Calories',
                      value: data.consumedCalories,
                      maxValue: totalCalories,
                      unit: 'kcal'),
                  _SummaryCircle(
                      label: 'Protein',
                      value: data.consumedProtein,
                      maxValue: maxProtein,
                      unit: 'g'),
                  _SummaryCircle(
                      label: 'Carbs',
                      value: data.consumedCarbs,
                      maxValue: maxCarbs,
                      unit: 'g'),
                  _SummaryCircle(
                      label: 'Fat',
                      value: data.consumedFat,
                      maxValue: maxFat,
                      unit: 'g'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<PredictionNutrition> items;
  final Function(int) onDeleteItem;
  final VoidCallback onAddItem;

  const _MealSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.onDeleteItem,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    int totalCalories =
        items.fold(0, (sum, item) => sum + item.calories.toInt());

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('$totalCalories kcal',
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Belum ada makanan ditambahkan',
                style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          ...items.map((item) => _FoodItemCard(
                item: item,
                onDelete: () => onDeleteItem(item.id!),
                mealType: title,
              )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Tambah $title'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        )
      ]),
    );
  }
}

class _SummaryCircle extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final String unit;

  const _SummaryCircle(
      {required this.label,
      required this.value,
      required this.maxValue,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: PieChart(
            dataMap: {
              "value": value,
              "empty": (maxValue - value).clamp(0, maxValue)
            },
            chartType: ChartType.ring,
            ringStrokeWidth: 6,
            initialAngleInDegree: -90,
            chartValuesOptions:
                const ChartValuesOptions(showChartValues: false),
            legendOptions: const LegendOptions(showLegends: false),
            colorList: [Colors.green, Colors.grey.shade200],
            totalValue: maxValue,
          ),
        ),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final PredictionNutrition item;
  final VoidCallback onDelete;
  final String mealType;

  const _FoodItemCard(
      {required this.item, required this.onDelete, required this.mealType});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        (item.imageUrl != null && item.imageUrl!.startsWith("http"))
            ? item.imageUrl!
            : 'http://10.0.2.2:3000${item.imageUrl ?? ''}';

    String displayTime;
    switch (mealType) {
      case 'Sarapan':
        displayTime = '07:00';
        break;
      case 'Makan Siang':
        displayTime = '12:00';
        break;
      case 'Makan Malam':
        displayTime = '19:00';
        break;
      default: 
        displayTime = item.createdAt != null
            ? DateFormat('HH:mm').format(item.createdAt!)
            : '-';
        break;
    }
    final nutritionSummary =
        '${item.protein.toStringAsFixed(0)}g P - ${item.carbohydrates.toStringAsFixed(0)}g C - ${item.fat.toStringAsFixed(0)}g F';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.restaurant,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.foodName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            '${item.calories.toStringAsFixed(0)} kcal - $nutritionSummary',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pukul $displayTime',
                      style: TextStyle(color: Colors.grey.shade600)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
