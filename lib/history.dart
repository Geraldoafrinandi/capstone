import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'model/PredictionNutrition.dart'; 
import 'package:intl/intl.dart';


// class PredictionNutrition {
//   final int? id;
//   final String? filename;
//   final String? label;
//   final DateTime createdAt; 
//   final String foodName;
//   final double calories;
//   final double protein;
//   final double fat;
//   final double carbohydrates;
//   final String takaran;
//   final String? imageUrl;

//   PredictionNutrition({
//     this.id,
//     this.filename,
//     this.label,
//     required this.createdAt,
//     required this.foodName,
//     required this.calories,
//     required this.protein,
//     required this.fat,
//     required this.carbohydrates,
//     required this.takaran,
//     this.imageUrl,
//   });

//   factory PredictionNutrition.fromJson(Map<String, dynamic> json) {
//     final parsedDate = DateTime.parse(json['created_at']);

//     return PredictionNutrition(
//       id: json['id'] as int?,
//       filename: json['filename'],
//       label: json['label'],
      
   
//       createdAt: parsedDate.toLocal(), 
      
//       foodName: json['food_name'] ?? 'Nama Makanan Tidak Tersedia',
//       calories: (json['calories'] as num).toDouble(),
//       protein: (json['protein'] as num).toDouble(),
//       fat: (json['fat'] as num).toDouble(),
//       carbohydrates: (json['carbohydrates'] as num).toDouble(),
//       takaran: json['takaran'] ?? '',
//       imageUrl: json['image_url'],
//     );
//   }
// }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<PredictionNutrition>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchNutritionHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = fetchNutritionHistory();
    });
  }

  Future<List<PredictionNutrition>> fetchNutritionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        throw Exception('User ID tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/riwayat-konsumsi/$userId'),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((item) => PredictionNutrition.fromJson(item)).toList();
      } else {
        throw Exception('Gagal memuat data: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Map<String, List<PredictionNutrition>> _groupHistoryByDate(
      List<PredictionNutrition> historyList) {
    final Map<String, List<PredictionNutrition>> groupedHistory = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in historyList) {
      final itemDate = DateTime(
          item.createdAt.year, item.createdAt.month, item.createdAt.day);
      String dateKey;

      if (itemDate == today) {
        dateKey = 'Hari Ini';
      } else if (itemDate == yesterday) {
        dateKey = 'Kemarin';
      } else {
        dateKey = DateFormat('d MMMM yyyy', 'id_ID').format(item.createdAt);
      }

      if (groupedHistory[dateKey] == null) {
        groupedHistory[dateKey] = [];
      }
      groupedHistory[dateKey]!.add(item);
    }
    return groupedHistory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: FutureBuilder<List<PredictionNutrition>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Gagal memuat riwayat.\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text("Belum ada riwayat konsumsi.",
                      style: TextStyle(fontSize: 16, color: Colors.grey)));
            }

            final groupedData = _groupHistoryByDate(snapshot.data!);
            final dateKeys = groupedData.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              itemCount: dateKeys.length,
              itemBuilder: (context, index) {
                final dateKey = dateKeys[index];
                final itemsForDate = groupedData[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 16.0),
                      child: Text(
                        dateKey,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    ...itemsForDate
                        .map((item) => HistoryCard(item: item))
                        .toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final PredictionNutrition item;

  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
   final imageUrl = (item.imageUrl != null && item.imageUrl!.isNotEmpty && item.imageUrl!.startsWith("http"))
    ? item.imageUrl!
    : (item.imageUrl != null && item.imageUrl!.isNotEmpty)
        ? 'http://10.0.2.2:3000${item.imageUrl}'
        : 'https://via.placeholder.com/50'; 

    
    final formattedTime = DateFormat('HH:mm').format(item.createdAt);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Padding(
            padding: EdgeInsets.only(top: value * 8.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Icon(Icons.fastfood_outlined, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.foodName,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Pukul $formattedTime • ${item.takaran}",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24.0, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NutritionDetailChip(
                    label: 'Karbo',
                    value: '${item.carbohydrates.toStringAsFixed(1)}g',
                    color: Colors.orange.shade400,
                  ),
                  _NutritionDetailChip(
                    label: 'Protein',
                    value: '${item.protein.toStringAsFixed(1)}g',
                    color: Colors.red.shade400,
                  ),
                  _NutritionDetailChip(
                    label: 'Lemak',
                    value: '${item.fat.toStringAsFixed(1)}g',
                    color: Colors.blue.shade400,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade300, Colors.green.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      "${item.calories.toStringAsFixed(0)} kkal",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionDetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionDetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
