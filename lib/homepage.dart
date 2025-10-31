// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  Uint8List? selectedImageBytes;

  String message = '';
  bool isLoading = false;

  String? foodName;
  int calories = 0;

  List<dynamic> nutritionList = [];

  Map<String, dynamic> totalNutrition = {};

  Future<void> tanyaSimpanRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null || nutritionList.isEmpty) return;

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Simpan Riwayat Gambar?'),
          content: const Text(
              'Apakah kamu ingin menyimpan makanan ini ke riwayat konsumsi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Lanjut tanpa simpan',
                style: TextStyle(color: Colors.green),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final nutritionId = nutritionList[0]['id'];
                final jumlahKalori = nutritionList[0]['calories'];
                final waktuMakan = _tentukanWaktuMakan();

                final response = await http.post(
                  Uri.parse('http://10.0.2.2:3000/api/simpan-riwayat'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'user_id': userId,
                    'nutrition_id': nutritionId,
                    'jumlah_kalori': jumlahKalori,
                    'waktu_makan': waktuMakan,
                  }),
                );

                if (response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(child: Text("Berhasil menyimpan data")),
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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:  const Row(
                        children:  [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(child: Text("Gagal menyimpan data")),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickImageAndPredict() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      String fileExtension = pickedFile.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        setState(() {
          message = 'Hanya file JPG, JPEG, atau PNG yang diperbolehkan!';
        });
        return;
      }

      setState(() {
        selectedImageBytes = bytes;
        isLoading = true;
        message = '';
      });

      const serverUrl = 'http://10.0.2.2:3000/api/predict';
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
      request.headers.addAll({'Connection': 'keep-alive'});
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      print('userId: $userId');
      request.fields['user_id'] = userId.toString();

      final mediaType = fileExtension == 'png'
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'upload.$fileExtension',
        contentType: mediaType,
      ));

      final response =
          await request.send().timeout(const Duration(seconds: 10));
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        print('🔁 Respons dari server: ${responseData.body}');

        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }

        setState(() {
          message = data['message'] ?? 'Berhasil';
          foodName = data['label'] ?? 'Unknown Food';
          totalNutrition = data['totalNutrition'] ?? {};
          calories = (totalNutrition['calories'] ?? 0).toInt();
          nutritionList = data['nutrition'] ?? [];
        });
        await tanyaSimpanRiwayat();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        message = 'Error: ${e.toString()}';
        foodName = null;
        calories = 0;
        nutritionList = [];
        totalNutrition = {};
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _tentukanWaktuMakan() {
    final now = DateTime.now().hour;

    if (now >= 5 && now < 10) {
      return 'Sarapan';
    } else if (now >= 10 && now < 15) {
      return 'Makan Siang';
    } else if (now >= 15 && now < 21) {
      return 'Makan Malam';
    } else {
      return 'Lainnya';
    }
  }

  Widget buildNutritionItem(Map<String, dynamic> nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nutrition['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("Kalori: ${nutrition['calories']} kcal"),
        Text("Protein: ${nutrition['protein']} g"),
        Text("Lemak: ${nutrition['fat']} g"),
        Text("Karbohidrat: ${nutrition['carbohydrates']} g"),
        Text("Takaran: ${nutrition['takaran'] ?? '-'}"),
        const Divider(),
      ],
    );
  }

  Widget buildTotalNutrition() {
    if (totalNutrition.isEmpty || totalNutrition['calories'] == null) {
      return const SizedBox();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Kandungan Gizi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text("Kalori: ${totalNutrition['calories']} kcal"),
          Text("Protein: ${totalNutrition['protein']} g"),
          Text("Lemak: ${totalNutrition['fat']} g"),
          Text("Karbohidrat: ${totalNutrition['carbohydrates']} g"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Snap & analyze your meal !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Get instant nutritional insight from a photo',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: selectedImageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: Colors.green, size: 50),
                          SizedBox(height: 10),
                          Text(
                            'Tap button to upload your food',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          selectedImageBytes!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : pickImageAndPredict,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
              ),
              child: Text(
                isLoading ? 'Processing...' : 'Upload Photo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // if (message.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 20.0),
            //     child: Text(
            //       message,
            //       style: TextStyle(
            //         color: message.toLowerCase().contains('error') ? Colors.red : Colors.green,
            //         fontWeight: FontWeight.bold,
            //       ),
            //       textAlign: TextAlign.center,
            //     ),
            //   ),
            const SizedBox(height: 10),

            if (foodName != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Detection : $foodName',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // const Text(
                    //   'Calories:',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    const SizedBox(height: 6),
                    ...nutritionList.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "Calories: "
                          "${item['name']} (${item['takaran'] ?? '-'} → ${item['calories']} kcal",
                        ),
                      );
                    }).toList(),

                    const Divider(thickness: 2, height: 20),

                    const Text(
                      'Total Nutritions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    // Text("Calories               : ${totalNutrition['calories'] ?? 0} kcal"),
                    Text(
                        "Protein                 : ${totalNutrition['protein'] ?? 0} g"),
                    Text(
                        "Fat                        : ${totalNutrition['fat'] ?? 0} g"),
                    Text(
                        "Carbohydrates   : ${totalNutrition['carbohydrates'] ?? 0} g"),
                  ],
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
