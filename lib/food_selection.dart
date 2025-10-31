import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

class FoodListItem {
  final int id;
  final String name;
  final String? imageUrl;
  final String takaran;
  final double calories;

  FoodListItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.takaran,
    required this.calories,
  });

  factory FoodListItem.fromJson(Map<String, dynamic> json) {
    return FoodListItem(
      id: json['id'],
      name: json['name'] ?? 'Tanpa Nama',
      imageUrl: json['image_url'],
      takaran: json['takaran'] ?? 'N/A',
      calories: (json['calories'] as num? ?? 0.0).toDouble(),
    );
  }
}

class FoodSelectionPage extends StatefulWidget {
  final String mealType;
  final DateTime selectedDate;

  const FoodSelectionPage({super.key, required this.mealType, required this.selectedDate});

  @override
  State<FoodSelectionPage> createState() => _FoodSelectionPageState();
}

class _FoodSelectionPageState extends State<FoodSelectionPage> {
  List<FoodListItem> _foodList = [];
  List<FoodListItem> _filteredFoodList = [];
  bool _isLoading = true;
  String _error = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFoodList();
    _searchController.addListener(_filterFoodList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFoodList() async {
    try {
      final Uri uri = Uri.parse('http://10.0.2.2:3000/api/makanan');
      final response = await http.get(uri);

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body)['data'];
        setState(() {
          _foodList = data.map((item) => FoodListItem.fromJson(item)).toList();
          _filteredFoodList = _foodList;
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat daftar makanan');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filterFoodList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFoodList = _foodList.where((food) {
        return food.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  String _getMealTypeByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour < 10) {
      return 'Sarapan';
    } else if (hour >= 12 && hour < 15) {
      return 'Makan Siang';
    } else if (hour >= 18 && hour < 22) {
      return 'Makan Malam';
    } else {
      return 'Snack';
    }
  }

  Future<void> _addFoodToDiary(int nutritionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        throw Exception(
            '❌ User ID tidak ditemukan di SharedPreferences. Silakan login ulang.');
      }

      final String currentMealType = widget.mealType;

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/add-food'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'nutrition_id': nutritionId,
          'waktu_makan': currentMealType,
          'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final serverMessage =
            responseData['message'] ?? 'Makanan berhasil ditambahkan';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.fastfood, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      serverMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pop(context, true); 
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMsg = errorData['message'] ??
            'Gagal menambahkan makanan. Status: ${response.statusCode}';

        throw Exception('❌ $errorMsg');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Makanan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari makanan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error.isNotEmpty)
            Expanded(child: Center(child: Text(_error)))
          else
            Expanded(
              child: _filteredFoodList.isEmpty
                  ? const Center(child: Text('Tidak ada makanan ditemukan.'))
                  : ListView.builder(
                      itemCount: _filteredFoodList.length,
                      itemBuilder: (context, index) {
                        final item = _filteredFoodList[index];
                        final imageUrl = (item.imageUrl != null &&
                                item.imageUrl!.startsWith("http"))
                            ? item.imageUrl!
                            : 'http://10.0.2.2:3000${item.imageUrl ?? ''}';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(imageUrl),
                            onBackgroundImageError: (_, __) {},
                            backgroundColor: Colors.grey.shade200,
                          ),
                          title: Text(item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${item.calories.toStringAsFixed(0)} kcal • ${item.takaran}'),
                          onTap: () => _addFoodToDiary(item.id),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
