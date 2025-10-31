class UserCalories {
  final String nama;
  final int usia;
  final String gender;
  final double kebutuhanKalori;
  final String? imageUrl; 

  UserCalories({
    required this.nama,
    required this.usia,
    required this.gender,
    required this.kebutuhanKalori,
    this.imageUrl
  });

  factory UserCalories.fromJson(Map<String, dynamic> json) {
    return UserCalories(
      nama: json['nama'],
      usia: json['usia'],
      gender: json['gender'],
      kebutuhanKalori: (json['kebutuhan_kalori'] as num).toDouble(),
      imageUrl: json['image_url'],
      
    );
  }
}
