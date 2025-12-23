import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/post_models.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  List<Post> posts = [];
  bool loading = true;
  bool refreshing = false;
  String error = '';

  // Card interaction states (similar to FixturesPage)
  final Map<int, Map<String, dynamic>> _cardStates = {};
  bool _isDisposed = false;

  // Caching keys
  static const String _cachedPostsKey = 'cached_posts';
  static const String _cacheTimestampKey = 'posts_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  final String apiBaseUrl = 'https://fanclash-api.onrender.com/api';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadPosts() async {
    _safeSetState(() {
      loading = true;
      error = '';
    });

    // Try to load from cache first
    final cachedPosts = await _getCachedPosts();
    if (cachedPosts.isNotEmpty && !await _isCacheExpired()) {
      _safeSetState(() {
        posts = cachedPosts;
        loading = false;
      });

      // Initialize card states for cached posts
      for (var i = 0; i < cachedPosts.length; i++) {
        _cardStates[i] = {
          'isTapped': false,
          'isLiked': false,
          'isFollowing': false,
          'likeCount': Random().nextInt(100) + 50,
          'commentCount': Random().nextInt(30) + 10,
          'shareCount': Random().nextInt(15) + 5,
        };
      }
    }

    // Always fetch fresh data in background
    await fetchPosts();
  }

  Future<List<Post>> _getCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString(_cachedPostsKey);
      if (postsJson != null && postsJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(postsJson);
        return jsonList.map((json) => Post.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading cached posts: $e');
    }
    return [];
  }

  Future<void> _cachePosts(List<Post> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = jsonEncode(posts.map((post) => post.toJson()).toList());
      await prefs.setString(_cachedPostsKey, postsJson);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error caching posts: $e');
    }
  }

  Future<bool> _isCacheExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      if (timestamp == 0) return true;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime) > _cacheDuration;
    } catch (e) {
      return true;
    }
  }

  Future<void> fetchPosts() async {
    try {
      if (posts.isEmpty) {
        _safeSetState(() {
          loading = true;
          error = '';
        });
      } else {
        _safeSetState(() {
          refreshing = true;
        });
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = ApiResponse.fromJson(jsonDecode(response.body));

        if (data.success) {
          final processedPosts = data.posts.map((post) {
            return post.copyWith(
              likesCount: Random().nextInt(100) + 50,
              commentsCount: Random().nextInt(30) + 10,
              sharesCount: Random().nextInt(15) + 5,
              isLiked: false,
              isSaved: false,
            );
          }).toList();

          final reversedPosts = processedPosts.reversed.toList();

          await _cachePosts(reversedPosts);

          _safeSetState(() {
            posts = reversedPosts;
            error = '';
          });

          // Initialize card states for new posts
          for (var i = 0; i < reversedPosts.length; i++) {
            if (!_cardStates.containsKey(i)) {
              _cardStates[i] = {
                'isTapped': false,
                'isLiked': false,
                'isFollowing': false,
                'likeCount':
                    reversedPosts[i].likesCount ?? Random().nextInt(100) + 50,
                'commentCount':
                    reversedPosts[i].commentsCount ?? Random().nextInt(30) + 10,
                'shareCount':
                    reversedPosts[i].sharesCount ?? Random().nextInt(15) + 5,
              };
            }
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error fetching posts: $e');
      _safeSetState(() {
        error = 'Failed to load posts: ${e.toString().split(':').first}';
      });

      final cachedPosts = await _getCachedPosts();
      if (cachedPosts.isNotEmpty) {
        _safeSetState(() {
          posts = cachedPosts;
          error = 'Using cached data - ${e.toString().split(':').first}';
        });
      }
    } finally {
      _safeSetState(() {
        loading = false;
        refreshing = false;
      });
    }
  }

  void handleLike(int index) {
    _safeSetState(() {
      final newLiked = !(_cardStates[index]!['isLiked'] as bool);
      final currentLikes = _cardStates[index]!['likeCount'] as int;
      _cardStates[index]!['isLiked'] = newLiked;
      _cardStates[index]!['likeCount'] = newLiked
          ? currentLikes + 1
          : currentLikes - 1;
    });
  }

  void handleSave(int index) {
    _safeSetState(() {
      final newSaved = !(_cardStates[index]!['isFollowing'] as bool);
      _cardStates[index]!['isFollowing'] = newSaved;
    });
  }

  void handleComment(int index) {
    print('Comment on post at index: $index');
  }

  void handleJoin(int index) {
    print('Join post at index: $index');
  }

  Widget _buildPostImage(Post post) {
    if (post.imageUrl.isEmpty ||
        post.imageUrl == 'null' ||
        !post.imageUrl.startsWith('http')) {
      return Container();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use the available width from parent
          final availableWidth = constraints.maxWidth;

          return SizedBox(
            width: availableWidth,
            child: Image.network(
              post.imageUrl,
              fit: BoxFit.fitWidth, // Fits width, adjusts height proportionally
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200, // Fixed height for loading state
                  color: Colors.grey[900],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[900],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[700],
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostHeader(Post post, int index) {
    final isFollowing = _cardStates[index]!['isFollowing'] as bool;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[900],
              radius: 20,
              child: Text(
                post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(post.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ],
        ),

        // Follow button (like in FixturesPage)
        GestureDetector(
          onTap: () => handleSave(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFollowing
                  ? Colors.grey[800]!.withOpacity(0.5)
                  : const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFollowing
                    ? Colors.grey[700]!
                    : const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFollowing ? Icons.check : Icons.add,
                  size: 12,
                  color: isFollowing
                      ? Colors.grey[400]
                      : const Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 10,
                    color: isFollowing
                        ? Colors.grey[400]
                        : const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m';
      if (difference.inHours < 24) return '${difference.inHours}h';
      if (difference.inDays < 7) return '${difference.inDays}d';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildPostCard(Post post, int index) {
    final cardState = _cardStates[index]!;
    final isTapped = cardState['isTapped'] as bool;
    final isLiked = cardState['isLiked'] as bool;
    final likeCount = cardState['likeCount'] as int;
    final commentCount = cardState['commentCount'] as int;
    final shareCount = cardState['shareCount'] as int;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _safeSetState(() {
          _cardStates[index]!['isTapped'] = true;
        });
      },
      onTapUp: (_) {
        _safeSetState(() {
          _cardStates[index]!['isTapped'] = false;
        });
        // Handle post tap
      },
      onTapCancel: () {
        _safeSetState(() {
          _cardStates[index]!['isTapped'] = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isTapped ? 0.98 : 1.0),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!.withOpacity(0.3),
              Colors.black.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTapped ? const Color(0xFF10B981) : Colors.grey[800]!,
            width: isTapped ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isTapped
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : Colors.black.withOpacity(0.5),
              blurRadius: isTapped ? 10 : 5,
              spreadRadius: 0,
              offset: Offset(0, isTapped ? 2 : 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and follow button
            _buildPostHeader(post, index),

            const SizedBox(height: 16),

            // Caption
            if (post.caption != null && post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  post.caption!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),

            // Image (only shows if imageUrl exists)
            if (post.imageUrl.isNotEmpty &&
                post.imageUrl != 'null' &&
                post.imageUrl.startsWith('http'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPostImage(post),
              ),

            // Stats and actions section (same style as FixturesPage)
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stats (like in FixturesPage)
                  Row(
                    children: [
                      // Like stats
                      GestureDetector(
                        onTap: () => handleLike(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLiked
                                ? const Color(0xFFEF4444).withOpacity(0.1)
                                : Colors.grey[900]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLiked
                                  ? const Color(0xFFEF4444).withOpacity(0.3)
                                  : Colors.grey[800]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked
                                    ? const Color(0xFFEF4444)
                                    : Colors.grey[400],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatCount(likeCount),
                                style: TextStyle(
                                  color: isLiked
                                      ? const Color(0xFFEF4444)
                                      : Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Comment stats (GREENISH like in FixturesPage)
                      GestureDetector(
                        onTap: () => handleComment(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 16,
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatCount(commentCount),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Share stats
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[900]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.share,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatCount(shareCount),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Join button (like in FixturesPage)
                  GestureDetector(
                    onTap: () => handleJoin(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Join',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading && posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: const Color(0xFF10B981)),
                  const SizedBox(height: 16),
                  Text(
                    'Loading posts...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              backgroundColor: const Color(0xFF10B981),
              color: Colors.white,
              onRefresh: fetchPosts,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 12,
                  right: 12,
                  bottom: 16,
                ),
                itemCount: posts.length + (error.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (error.isNotEmpty && index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(color: Colors.red, fontSize: 11),
                              maxLines: 2,
                            ),
                          ),
                          TextButton(
                            onPressed: fetchPosts,
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                color: const Color(0xFF10B981),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final postIndex = error.isNotEmpty ? index - 1 : index;
                  if (postIndex >= posts.length) return const SizedBox();

                  return _buildPostCard(posts[postIndex], postIndex);
                },
              ),
            ),
    );
  }
}
