import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_models.dart';
import '../widgets/post_card.dart';
import '../models/fixture_models.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({Key? key}) : super(key: key);

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  List<Post> posts = [];
  bool loading = true;
  bool refreshing = false;
  String error = '';
  String activeTab = 'all';
  String searchQuery = '';
  bool showSearch = false;

  final String apiBaseUrl = 'https://fanclash-api.onrender.com/api';
  final List<String> premierLeagueFootballers = [
    'Erling Haaland', 'Mohamed Salah', 'Kevin De Bruyne', 'Harry Kane', 'Bukayo Saka',
    'Son Heung-min', 'Marcus Rashford', 'Bruno Fernandes', 'Martin Ødegaard', 'Trent Alexander-Arnold',
    'Virgil van Dijk', 'Phil Foden', 'Jack Grealish', 'Declan Rice', 'Rodri',
    'Ederson', 'Allison Becker', 'Kyle Walker', 'Ruben Dias', 'Gabriel Martinelli',
    'Raheem Sterling', 'Mason Mount', 'Riyad Mahrez', 'Bernardo Silva', 'João Cancelo'
  ];

  final List<String> premierLeagueTeams = [
    'Manchester City', 'Liverpool', 'Arsenal', 'Manchester United', 'Chelsea',
    'Tottenham', 'Newcastle', 'Aston Villa', 'Brighton', 'West Ham',
    'Brentford', 'Fulham', 'Crystal Palace', 'Wolves', 'Everton',
    'Nottingham Forest', 'Leicester', 'Leeds', 'Southampton', 'Bournemouth'
  ];

  final List<String> footballEmojis = ['⚽', '🏆', '🔥', '💰', '🎯', '💪', '🚀', '👑', '💎', '✨'];
  final List<String> bettingHashtags = [
    '#PremierLeague', '#Betting', '#Win', '#Football', '#SportsBetting',
    '#Odds', '#Parlay', '#LiveBet', '#ValueBet', '#Tips'
  ];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      setState(() {
        loading = true;
        error = '';
      });
      
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
          final cleanedPosts = data.posts.map((post) {
            // Add random engagement counts
            return post.copyWith(
              likesCount: 50 + DateTime.now().millisecond % 150,
              commentsCount: DateTime.now().millisecond % 25,
              sharesCount: DateTime.now().millisecond % 15,
            );
          }).toList();
          
          setState(() {
            posts = cleanedPosts;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        error = 'Failed to load posts. Using demo data.';
      });
      useMockData();
    } finally {
      setState(() {
        loading = false;
        refreshing = false;
      });
    }
  }

  void useMockData() {
    final mockPosts = List.generate(10, (index) {
      final footballer = premierLeagueFootballers[
          DateTime.now().millisecond % premierLeagueFootballers.length];
      final outcome = ['win', 'loss', 'pending'][index % 3];
      
      return Post(
        id: '${index + 1}',
        imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&h=600&fit=crop',
        caption: _generateRandomCaption(),
        userName: footballer,
        userId: 'user${index + 100}',
        createdAt: DateTime.now()
            .subtract(Duration(hours: index * 2))
            .millisecondsSinceEpoch ~/ 1000,
        betAmount: 50.0 + (index * 100).toDouble(),
        betOutcome: outcome,
        odds: (1.1 + (index * 0.5)).toStringAsFixed(2),
        likesCount: 50 + index * 10,
        commentsCount: index * 2,
        sharesCount: index,
      );
    });
    
    setState(() {
      posts = mockPosts;
    });
  }

  String _generateRandomCaption() {
    final footballer = premierLeagueFootballers[
        DateTime.now().millisecond % premierLeagueFootballers.length];
    final team1 = premierLeagueTeams[
        DateTime.now().millisecond % premierLeagueTeams.length];
    var team2 = premierLeagueTeams[
        (DateTime.now().millisecond + 1) % premierLeagueTeams.length];
    while (team1 == team2) {
      team2 = premierLeagueTeams[
          (DateTime.now().millisecond + 2) % premierLeagueTeams.length];
    }
    final emoji = footballEmojis[DateTime.now().millisecond % footballEmojis.length];
    final hashtag1 = bettingHashtags[
        DateTime.now().millisecond % bettingHashtags.length];
    final hashtag2 = bettingHashtags[
        (DateTime.now().millisecond + 1) % bettingHashtags.length];
    final betAmount = 50 + DateTime.now().millisecond % 1000;
    final odds = (1.1 + (DateTime.now().millisecond % 100) * 0.05).toStringAsFixed(2);
    
    final captions = [
      '$emoji Just won Ksh $betAmount on $team1 vs $team2! The odds were $odds! $hashtag1 $hashtag2',
      '$footballer to score first - BANKER BET! 🎯 Put Ksh $betAmount at $odds odds. $team1 looking dangerous! $hashtag1',
      'EPIC COMEBACK! $team1 from 2-0 down to win 3-2! 🔥 Won Ksh $betAmount on this! $emoji $hashtag2',
      'Match of the season alert! $team1 vs $team2 - Over 2.5 goals at $odds is too good to miss! 💰 $hashtag1 $hashtag2',
      '$footballer masterclass today! 🏆 Bet Ksh $betAmount on him to score and assist. $odds odds paid out! $emoji'
    ];
    
    return captions[DateTime.now().millisecond % captions.length];
  }

  void handleLike(Post post) {
    setState(() {
      posts = posts.map((p) {
        if (p.id == post.id) {
          return p.copyWith(
            isLiked: !(p.isLiked ?? false),
            likesCount: (p.likesCount ?? 0) + (p.isLiked ?? false ? -1 : 1),
          );
        }
        return p;
      }).toList();
    });
  }

  void handleSave(Post post) {
    setState(() {
      posts = posts.map((p) {
        if (p.id == post.id) {
          return p.copyWith(isSaved: !(p.isSaved ?? false));
        }
        return p;
      }).toList();
    });
  }

  void handleComment(Post post) {
    // TODO: Implement comment functionality
    print('Comment on post: ${post.id}');
  }

  void handleShare(Post post) {
    // TODO: Implement share functionality
    print('Share post: ${post.id}');
  }

  List<Post> get filteredPosts {
    return posts.where((post) {
      if (searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        if (!post.userName.toLowerCase().contains(searchLower) &&
            !(post.caption?.toLowerCase().contains(searchLower) ?? false)) {
          return false;
        }
      }
      
      if (activeTab == 'wins') {
        return post.betOutcome == 'win';
      } else if (activeTab == 'live') {
        return post.betOutcome == 'pending';
      } else if (activeTab == 'trending') {
        return (post.likesCount ?? 0) > 100;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade800.withOpacity(0.5)),
              ),
            ),
            
              
            
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade800.withOpacity(0.5)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton('All', 'all'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton('Wins', 'wins'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton('Live', 'live'),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: loading
                ? _buildLoadingScreen()
                : error.isNotEmpty && posts.isEmpty
                    ? _buildErrorScreen()
                    : filteredPosts.isEmpty
                        ? _buildEmptyScreen()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              return PostCard(
                                post: filteredPosts[index],
                                index: index,
                                onLike: handleLike,
                                onSave: handleSave,
                                onComment: handleComment,
                                onShare: handleShare,
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isActive = activeTab == value;
    return GestureDetector(
      onTap: () => setState(() => activeTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFF10B981) : Colors.grey.shade800,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF10B981)),
          const SizedBox(height: 16),
          const Text(
            'Loading posts...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by FanClash API',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Icon(Icons.error, color: Colors.red, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: fetchPosts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: useMockData,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade800),
                ),
                child: const Text('Use Demo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'No posts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.grey.shade800.withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.trending_up, 'Trending', false),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 24, color: Colors.white),
              ),
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', false),
              _buildNavItem(Icons.person, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: active ? const Color(0xFF10B981) : Colors.grey.shade400,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? const Color(0xFF10B981) : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}