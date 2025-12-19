class Post {
  final String id;
  final String imageUrl;
  final String? caption;
  final String userName;
  final String userId;
  final int createdAt;
  final int? updatedAt;
  final double? betAmount;
  final String? betOutcome;
  final String? odds;
  final bool? isLiked;
  final bool? isSaved;
  final int? likesCount;
  final int? commentsCount;
  final int? sharesCount;

  Post({
    required this.id,
    required this.imageUrl,
    this.caption,
    required this.userName,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.betAmount,
    this.betOutcome,
    this.odds,
    this.isLiked = false,
    this.isSaved = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      caption: json['caption'],
      userName: json['user_name'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'],
      betAmount: (json['bet_amount'] ?? 0).toDouble(),
      betOutcome: json['bet_outcome'],
      odds: json['odds'] ?? '1.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'caption': caption,
      'user_name': userName,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'bet_amount': betAmount,
      'bet_outcome': betOutcome,
      'odds': odds,
    };
  }

  Post copyWith({
    String? id,
    String? imageUrl,
    String? caption,
    String? userName,
    String? userId,
    int? createdAt,
    int? updatedAt,
    double? betAmount,
    String? betOutcome,
    String? odds,
    bool? isLiked,
    bool? isSaved,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
  }) {
    return Post(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      betAmount: betAmount ?? this.betAmount,
      betOutcome: betOutcome ?? this.betOutcome,
      odds: odds ?? this.odds,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
    );
  }
}

class ApiResponse {
  final bool success;
  final List<Post> posts;
  final String? message;

  ApiResponse({
    required this.success,
    required this.posts,
    this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      posts: (json['posts'] as List? ?? [])
          .map((post) => Post.fromJson(post))
          .toList(),
      message: json['message'],
    );
  }
}