import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

class RecipeDetail {
  final String judul, deskripsi, kategori;
  final String? gambar;
  final int kalori, protein, lemak, karbohidrat;
  final List<Bahan> bahan;
  final List<Langkah> langkah;

  RecipeDetail({
    required this.judul, this.deskripsi = '', this.kategori = '', this.gambar,
    this.kalori = 0, this.protein = 0, this.lemak = 0, this.karbohidrat = 0,
    required this.bahan, required this.langkah,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> bahanList = json['bahan'] as List? ?? [];
    final List<dynamic> langkahList = json['langkah'] as List? ?? [];

    return RecipeDetail(
      judul: json['judul'] ?? 'Tanpa Judul',
      deskripsi: json['deskripsi'] ?? 'Tidak ada deskripsi.',
      kategori: json['kategori'] ?? 'Lainnya',
      gambar: json['gambar'],
      kalori: (json['kalori'] as num? ?? 0).toInt(),
      protein: (json['protein'] as num? ?? 0).toInt(),
      lemak: (json['lemak'] as num? ?? 0).toInt(),
      karbohidrat: (json['karbohidrat'] as num? ?? 0).toInt(),
      bahan: bahanList.map((i) => Bahan.fromJson(i)).toList(),
      langkah: langkahList.map((i) => Langkah.fromJson(i)).toList(),
    );
  }
}

class Bahan {
  final String nama;
  Bahan({required this.nama});
  factory Bahan.fromJson(Map<String, dynamic> json) {
    return Bahan(
      nama: json['nama_bahan'] ?? 'N/A',
    );
  }
}

class Langkah {
  final int urutan;
  final String deskripsi;
  Langkah({required this.urutan, required this.deskripsi});
  factory Langkah.fromJson(Map<String, dynamic> json) {
    return Langkah(
      urutan: json['urutan'] ?? 0,
      deskripsi: json['deskripsi'] ?? 'N/A'
    );
  }
}

class ResepDetailPage extends StatefulWidget {
  final int recipeId;
  const ResepDetailPage({super.key, required this.recipeId});

  @override
  State<ResepDetailPage> createState() => _ResepDetailPageState();
}

class _ResepDetailPageState extends State<ResepDetailPage> {
  late Future<RecipeDetail> _recipeDetailFuture;

  @override
  void initState() {
    super.initState();
    _recipeDetailFuture = _fetchRecipeDetail();
  }

  Future<RecipeDetail> _fetchRecipeDetail() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/recipe/${widget.recipeId}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return RecipeDetail.fromJson(json.decode(response.body)['data']);
      } else {
        throw Exception('Gagal memuat detail resep. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: FutureBuilder<RecipeDetail>(
        future: _recipeDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Data resep tidak ditemukan."));
          }

          final recipe = snapshot.data!;
          final imageUrl = (recipe.gambar != null && recipe.gambar!.startsWith("http"))
              ? recipe.gambar!
              : 'http://10.0.2.2:3000/${recipe.gambar ?? ''}';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                foregroundColor: Colors.white,
                // Warna AppBar saat di-scroll ke atas
                backgroundColor: Colors.green, 
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    recipe.judul, 
                    style: const TextStyle(
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 1))]
                    )
                  ),
                  background: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.restaurant_menu, color: Colors.white, size: 80)),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.deskripsi, style: TextStyle(color: Colors.grey.shade800, fontSize: 15, height: 1.5)),
                        const SizedBox(height: 20),
                        _buildNutritionInfo(recipe),
                        const Divider(height: 32, thickness: 0.8),
                        _buildSectionTitle('Bahan-bahan'),
                        const SizedBox(height: 12),
                        ...recipe.bahan.map((b) => _buildIngredientItem(b)).toList(),
                        const Divider(height: 32, thickness: 0.8),
                        _buildSectionTitle('Langkah-langkah'),
                        const SizedBox(height: 12),
                        ...recipe.langkah.map((l) => _buildStepItem(l)).toList(),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87));
  }
  
  Widget _buildIngredientItem(Bahan bahan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3.0),
            // child: Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bahan.nama,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(Langkah langkah) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CircleAvatar(
          //   radius: 14,
          //   backgroundColor: Colors.green.shade600,
          //   child: Text(langkah.urutan.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          // ),
          const SizedBox(width: 12),
          Expanded(child: Text(langkah.deskripsi, style: const TextStyle(fontSize: 16, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo(RecipeDetail recipe) {
    return Row(
      children: [
        _infoChip("Kalori", "${recipe.kalori} kcal", Icons.local_fire_department_outlined),
        const SizedBox(width: 10),
        _infoChip("Protein", "${recipe.protein} g", Icons.fitness_center_outlined),
        const SizedBox(width: 10),
        _infoChip("Lemak", "${recipe.lemak} g", Icons.oil_barrel_outlined),
        const SizedBox(width: 10),
        _infoChip("Karbo", "${recipe.karbohidrat} g", Icons.rice_bowl_outlined),
      ],
    );
  }

  Widget _infoChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200, width: 1)
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 28),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}