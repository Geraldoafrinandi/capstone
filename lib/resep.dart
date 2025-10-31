import 'package:aplikasi_makanan/resep_detail.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Recipe {
  final int id;
  final String judul;
  final String kategori;
  final String? gambar;
  final int kalori;

  Recipe({
    required this.id,
    required this.judul,
    required this.kategori,
    this.gambar,
    required this.kalori,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id_resep'],
      judul: json['judul'] ?? 'Tanpa Judul',
      kategori: json['kategori'] ?? 'Lainnya',
      gambar: json['gambar'],
      kalori: (json['kalori'] as num? ?? 0).toInt(),
    );
  }
}

class ResepPage extends StatefulWidget {
  const ResepPage({super.key});

  @override
  State<ResepPage> createState() => _ResepPageState();
}

class _ResepPageState extends State<ResepPage> {
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _recipesFuture = _fetchRecipes();
  }

  Future<List<Recipe>> _fetchRecipes() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/recipes'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat daftar resep dari server.');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resep Makanan Sehat'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada resep yang tersedia.'));
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final imageUrl =
                  (recipe.gambar != null && recipe.gambar!.startsWith("http"))
                      ? recipe.gambar!
                      : 'http://10.0.2.2:3000/${recipe.gambar ?? ''}';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant_menu,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Text(recipe.judul,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${recipe.kategori} • ${recipe.kalori} kcal'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResepDetailPage(recipeId: recipe.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
