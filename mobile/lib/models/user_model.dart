
class User {
  final String firebaseUid;
  final String email;
  final String status; // 'pending', 'approved', 'banned', 'admin'
  final bool onboardingCompleted;
  final bool welcomeSeen;
  final String? name;
  final String? photoUrl; // Added
  final String? department;
  final String? bio;
  final Map<String, dynamic> verification;

  final String? studentId;
  final String? year;
  final String? section;
  final String? coverPhoto;
  final List<String> friendIds;

  User({
    required this.firebaseUid,
    required this.email,
    required this.status,
    this.onboardingCompleted = false,
    this.welcomeSeen = false,
    this.name,
    this.photoUrl,
    this.department,
    this.bio,
    this.verification = const {},
    this.studentId,
    this.year,
    this.section,
    this.coverPhoto,
    this.friendIds = const [],
  });

  // Alias for photoUrl to match typical Profile map usage
  String? get photo => photoUrl;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firebaseUid: json['firebaseUid'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'pending',
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      welcomeSeen: json['welcomeSeen'] ?? false,
      name: json['name'],
      photoUrl: json['photoUrl'], // Backend returns photoUrl
      department: json['department'],
      bio: json['bio'],
      verification: json['verification'] ?? {},
      studentId: json['studentId'],
      year: json['year'],
      section: json['section'],
      coverPhoto: json['coverPhoto'],
      friendIds: (json['friendIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
