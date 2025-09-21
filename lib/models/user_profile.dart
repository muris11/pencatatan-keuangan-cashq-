class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? status;
  final int monthlyBudget; // in IDR
  final String language; // 'id' or 'en'
  final bool darkMode;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.status,
    this.monthlyBudget = 0,
    this.language = 'id',
    this.darkMode = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'status': status,
    'monthly_budget': monthlyBudget,
    'language': language,
    'dark_mode': darkMode,
  };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) =>
      UserProfile(
        uid: uid,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'],
        photoUrl: map['photoUrl'],
        status: map['status'],
        monthlyBudget: (map['monthly_budget'] ?? 0) as int,
        language: (map['language'] ?? 'id') as String,
        darkMode: (map['dark_mode'] ?? false) as bool,
      );
}
