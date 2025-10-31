class UserData {
  String? name;
  String? gender;
  DateTime? birthday;
  double? height;
  double? weight;
  Duration? breakfastTime;
  Duration? dinnerTime;
  String email;      
  String password;

  UserData({
    this.name,
    this.gender,
    this.birthday,
    this.height,
    this.weight,
    this.breakfastTime,
    this.dinnerTime,
    this.email = '',
    this.password = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'birthday': birthday?.toIso8601String(), 
      'height': height,
      'weight': weight,
      'breakfast_time': _durationToString(breakfastTime),
      'dinner_time': _durationToString(dinnerTime),
      'email': email,
      'password': password,
    };
  }

  String? _durationToString(Duration? duration) {
    if (duration == null) return null;
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
