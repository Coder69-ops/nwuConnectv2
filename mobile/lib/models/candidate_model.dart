class Candidate {
  final String userId;
  final String name;
  final String department;
  final String? bio;
  final List<String> photos;
  // final int age; // Add age if we track birthdate later

  Candidate({
    required this.userId,
    required this.name,
    required this.department,
    this.bio,
    this.photos = const [],
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Unknown',
      department: json['department'] ?? 'General',
      bio: json['bio'],
      photos: List<String>.from(json['photos'] ?? []),
    );
  }
}
