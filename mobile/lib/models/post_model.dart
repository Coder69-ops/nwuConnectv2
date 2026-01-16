class Post {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final String visibility;
  final String authorDepartment;
  final List<String> likes;
  // Ignoring comments for now in the simple feed view, but good to have in model
  // final List<Map<String, dynamic>> comments; 
  final DateTime createdAt;
  
  // Optional: We might want author details (name/photo) joined in the backend.
  // For now, let's assume the backend might populate this or we'll fetch separately.
  // Looking at feed.service.ts, the backend performs a look up and returns a combined object?
  // Let's verify what the feed endpoint returns. 
  // Wait, I should check the FeedService response format first.
  // However, based on schema, these are the fields.
  
  final String authorName;
  final String authorPhoto;
  final int commentsCount;
  final bool isArchived;
  final List<dynamic> editHistory; // Keeping it dynamic or a simple custom class

  bool get isEdited => editHistory.isNotEmpty;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.visibility,
    required this.authorDepartment,
    required this.likes,
    required this.createdAt,
    this.authorName = 'User',
    this.authorPhoto = '',
    this.commentsCount = 0,
    this.isArchived = false,
    this.editHistory = const [],
  });

  Post copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? imageUrls,
    String? visibility,
    String? authorDepartment,
    List<String>? likes,
    DateTime? createdAt,
    String? authorName,
    String? authorPhoto,
    int? commentsCount,
    bool? isArchived,
    List<dynamic>? editHistory,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      visibility: visibility ?? this.visibility,
      authorDepartment: authorDepartment ?? this.authorDepartment,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      commentsCount: commentsCount ?? this.commentsCount,
      isArchived: isArchived ?? this.isArchived,
      editHistory: editHistory ?? this.editHistory,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      visibility: json['visibility'] ?? 'public',
      authorDepartment: json['authorDepartment'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      authorName: json['authorName'] ?? 'User',
      authorPhoto: json['authorPhoto'] ?? '',
      commentsCount: (json['comments'] as List?)?.fold<int>(0, (sum, c) => sum + 1 + ((c['replies'] as List?)?.length ?? 0)) ?? 0,
      isArchived: json['isArchived'] ?? false,
      editHistory: json['editHistory'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'visibility': visibility,
      'authorDepartment': authorDepartment,
    };
  }
}
