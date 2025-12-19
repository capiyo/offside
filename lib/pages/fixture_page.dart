import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/fixture_models.dart';

class FixturesPage extends StatefulWidget {
  const FixturesPage({Key? key}) : super(key: key);

  @override
  State<FixturesPage> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesPage> {
  static const String API_BASE_URL = 'https://fanclash-api.onrender.com/api/games';
  
  List<Fixture> _fixtures = [];
  bool _loading = true;
  String _error = '';
  String _activeFilter = 'all';
  String _sortBy = 'date';
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    print('🚀 FixturesScreen initState');
    _fetchFixtures();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
    print('🛑 FixturesScreen disposed');
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _fetchFixtures() async {
    print('⚽ _fetchFixtures called');
    
    _safeSetState(() {
      _loading = true;
      _error = '';
    });

    try {
      print('🌐 Making API call to: $API_BASE_URL');
      
      final response = await http.get(
        Uri.parse(API_BASE_URL),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('📝 Response length: ${responseBody.length} characters');
        
        if (responseBody.length > 500) {
          print('📝 First 500 chars: ${responseBody.substring(0, 500)}...');
        } else {
          print('📝 Full response: $responseBody');
        }
        
        final jsonData = json.decode(responseBody);
        print('📊 JSON type: ${jsonData.runtimeType}');
        
        if (jsonData is Map<String, dynamic>) {
          print('🗺️ Map keys: ${jsonData.keys}');
          
          // Check for ApiResponse structure
          if (jsonData['success'] == true) {
            print('✅ Success response from API');
            
            if (jsonData['data'] != null) {
              print('📦 Data type: ${jsonData['data'].runtimeType}');
              
              if (jsonData['data'] is List) {
                final List<dynamic> dataList = jsonData['data'];
                print('📋 Number of fixtures: ${dataList.length}');
                
                final fixtures = <Fixture>[];
                for (var i = 0; i < dataList.length; i++) {
                  try {
                    final item = dataList[i] as Map<String, dynamic>;
                    print('🔍 Fixture $i: ${item['home_team']} vs ${item['away_team']}');
                    final fixture = Fixture.fromJson(item);
                    fixtures.add(fixture);
                  } catch (e) {
                    print('❌ Error parsing fixture $i: $e');
                    print('❌ Problematic data: ${dataList[i]}');
                  }
                }
                
                _safeSetState(() {
                  _fixtures = fixtures;
                  _loading = false;
                });
                print('✅ Loaded ${fixtures.length} fixtures');
              } else {
                _safeSetState(() {
                  _error = 'Data is not a list';
                  _loading = false;
                });
              }
            } else {
              _safeSetState(() {
                _error = 'No data in response';
                _loading = false;
              });
            }
          } else {
            _safeSetState(() {
              _error = 'API returned success: false';
              _loading = false;
            });
          }
        } else if (jsonData is List) {
          // Direct array response (without ApiResponse wrapper)
          print('📋 Direct list response with ${jsonData.length} items');
          
          final fixtures = <Fixture>[];
          for (var i = 0; i < jsonData.length; i++) {
            try {
              final item = jsonData[i] as Map<String, dynamic>;
              print('🔍 Fixture $i: ${item['home_team'] ?? 'Unknown'} vs ${item['away_team'] ?? 'Unknown'}');
              final fixture = Fixture.fromJson(item);
              fixtures.add(fixture);
            } catch (e) {
              print('❌ Error parsing fixture $i: $e');
              print('❌ Raw data: ${jsonData[i]}');
            }
          }
          
          _safeSetState(() {
            _fixtures = fixtures;
            _loading = false;
          });
          print('✅ Loaded ${fixtures.length} fixtures directly');
        } else {
          _safeSetState(() {
            _error = 'Unexpected response format: ${jsonData.runtimeType}';
            _loading = false;
          });
        }
      } else {
        _safeSetState(() {
          _error = 'HTTP Error ${response.statusCode}: ${response.reasonPhrase}';
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ _fetchFixtures error: $e');
      _safeSetState(() {
        _error = 'Network error: ${e.toString()}';
        _loading = false;
      });
    }
  }

  List<Fixture> get _filteredFixtures {
    print('🔍 Filtering ${_fixtures.length} fixtures');
    
    return _fixtures.where((fixture) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!fixture.homeTeam.toLowerCase().contains(searchLower) &&
            !fixture.awayTeam.toLowerCase().contains(searchLower) &&
            !fixture.league.toLowerCase().contains(searchLower)) {
          return false;
        }
      }
      
      // Date filter
      try {
        final matchDate = DateTime.parse(fixture.date);
        final now = DateTime.now();
        final diffHours = matchDate.difference(now).inHours.toDouble();
        
        if (_activeFilter == 'live') {
          return fixture.isLive || (diffHours >= -2 && diffHours <= 2);
        } else if (_activeFilter == 'upcoming') {
          return matchDate.isAfter(now) && !fixture.isLive;
        }
      } catch (e) {
        print('❌ Error parsing date ${fixture.date}: $e');
      }
      
      return true;
    }).toList();
  }

  List<Fixture> get _sortedFixtures {
    final fixtures = [..._filteredFixtures];
    
    fixtures.sort((a, b) {
      if (_sortBy == 'date') {
        try {
          final dateA = DateTime.parse(a.date);
          final dateB = DateTime.parse(b.date);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      } else if (_sortBy == 'odds') {
        final maxOddsA = max(max(a.homeWin, a.awayWin), a.draw);
        final maxOddsB = max(max(b.homeWin, b.awayWin), b.draw);
        return maxOddsB.compareTo(maxOddsA);
      } else if (_sortBy == 'league') {
        return a.league.compareTo(b.league);
      }
      
      return 0;
    });
    
    return fixtures;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diffHours = date.difference(now).inHours.toDouble();
      
      if (diffHours <= 2 && diffHours >= -2) {
        return 'LIVE';
      }
      
      if (date.isAfter(now)) {
        return 'In ${diffHours.round()}h';
      }
      
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      print('❌ Error formatting date $dateString: $e');
      return 'TBD';
    }
  }

 @override
Widget build(BuildContext context) {
  print('🎨 Building FixturesScreen UI');
  
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Column(
        children: [
          // Header
         // _buildHeader(),
          
          // Search Bar
          //_buildSearchBar(),
          
          // Filters
         // _buildFilters(),
          
          // Main content
          _buildContent(),
          
          // Bottom Navigation
          _buildBottomNavigation(),
        ],
      ),
    ),
  );
}

Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fixtures',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_sortedFixtures.length} matches',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            _safeSetState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: _fetchFixtures,
          icon: Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
        ),
      ],
    ),
  );
}



Widget _buildContent() {
  if (_loading) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text(
              'Loading fixtures...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  if (_error.isNotEmpty) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 50),
              SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchFixtures,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                ),
                child: Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  if (_sortedFixtures.isEmpty) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, color: Colors.grey, size: 50),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                ? 'No matches found for "$_searchQuery"'
                : 'No fixtures available',
              style: TextStyle(color: Colors.white),
            ),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  _safeSetState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: Text('Clear search', style: TextStyle(color: Color(0xFF10B981))),
              ),
          ],
        ),
      ),
    );
  }

  return Expanded(
    child: RefreshIndicator(
      backgroundColor: Color(0xFF10B981),
      color: Colors.white,
      onRefresh: _fetchFixtures,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sortedFixtures.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(_sortedFixtures[index], index);
        },
      ),
    ),
  );
}

  

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '8 Live',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                
                
                GestureDetector(
                  onTap: () {
                    print('🔄 Sort button pressed');
                    _safeSetState(() {
                      _sortBy = _sortBy == 'date' ? 'odds' : 'date';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.swap_vert, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Sort',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                //_buildFilterButton('Filter', 'filter'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
    
   

// REPLACE your existing _buildMatchCard method with this complete version

Widget _buildMatchCard(Fixture fixture, int index) {
  final isLive = fixture.isLive;
  
  // Track interaction states
  bool isLiked = false;
  bool isFollowing = false;
  int likeCount = 145;
  int commentCount = 23;
  int shareCount = 8;
  
  return StatefulBuilder(
    builder: (context, setState) {
      return Container(
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
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            // Header with league, follow button and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // League badge with follow button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
                      ),
                      child: Text(
                        fixture.league,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Follow button
                    InkWell(
                      onTap: () {
                        setState(() {
                          isFollowing = !isFollowing;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFollowing 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFollowing 
                                ? Colors.grey[700]! 
                                : Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFollowing ? Icons.check : Icons.add,
                              size: 12,
                              color: isFollowing ? Colors.grey[400] : Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                fontSize: 10,
                                color: isFollowing ? Colors.grey[400] : Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Time and status
                Row(
                  children: [
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFEF4444).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFEF4444).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    Text(
                      _formatDate(fixture.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isLive ? Color(0xFFEF4444) : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Teams and scores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home team
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[900],
                        radius: 20,
                        child: Text(
                          fixture.homeTeam.substring(0, min(2, fixture.homeTeam.length)).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fixture.homeTeam,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (fixture.homeScore != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          fixture.homeScore.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // VS and time
                const Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                // Away team
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[900],
                        radius: 20,
                        child: Text(
                          fixture.awayTeam.substring(0, min(2, fixture.awayTeam.length)).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fixture.awayTeam,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (fixture.awayScore != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          fixture.awayScore.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Odds buttons
            Row(
              children: [
                Expanded(
                  child: _buildOddsButton('1', fixture.homeWin.toStringAsFixed(2), 'home'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOddsButton('X', fixture.draw.toStringAsFixed(2), 'draw'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOddsButton('2', fixture.awayWin.toStringAsFixed(2), 'away'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Social interaction bar
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Comment button
                  InkWell(
                    onTap: () => _showCommentDialog(context, fixture),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            commentCount.toString(),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Share button
                  InkWell(
                    onTap: () {
                      setState(() {
                        shareCount++;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Shared ${fixture.homeTeam} vs ${fixture.awayTeam}'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            shareCount.toString(),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Like button
                  InkWell(
                    onTap: () {
                      setState(() {
                        isLiked = !isLiked;
                        likeCount += isLiked ? 1 : -1;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Color(0xFFEF4444) : Colors.grey[400],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            likeCount.toString(),
                            style: TextStyle(
                              color: isLiked ? Color(0xFFEF4444) : Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bookmark button
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Match bookmarked'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.bookmark_border,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Comment input field at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(),
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          setState(() {
                            commentCount++;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Comment posted: $text'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        commentCount++;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comment posted!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    child: const Text(
                      'Post',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ADD this helper method for the comment dialog at the end of your class
void _showCommentDialog(BuildContext context, Fixture fixture) {
  final TextEditingController commentController = TextEditingController();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Match info
              Text(
                '${fixture.homeTeam} vs ${fixture.awayTeam}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // Comment input
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF10B981).withOpacity(0.2),
                    child: const Icon(
                      Icons.person, 
                      color: Color(0xFF10B981), 
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add your comment...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF10B981)),
                        ),
                        filled: true,
                        fillColor: Colors.grey[850],
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      autofocus: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.image_outlined, 
                          color: Color(0xFF10B981),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.emoji_emotions_outlined, 
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Comment posted!'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Post',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildOddsButton(String label, String odds, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            odds,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(Icons.home, 'Home', true),
          _buildNavButton(Icons.trending_up, 'Trending', false),
          _buildNavButton(Icons.emoji_events, '', true, isCenter: true),
          _buildNavButton(Icons.people, 'Bets', false),
          _buildNavButton(Icons.account_balance_wallet, 'Wallet', false),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, bool isActive, {bool isCenter = false}) {
    if (isCenter) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      );
    }
    
    return Column(
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF10B981) : Colors.grey[400],
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFF10B981) : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}