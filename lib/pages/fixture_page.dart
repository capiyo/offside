import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import '../models/fixture_models.dart';
import '../modals/clashRoomModal.dart';

class FixturesPage extends StatefulWidget {
  const FixturesPage({super.key});

  @override
  State<FixturesPage> createState() => _FixturesPageState();
}

class _FixturesPageState extends State<FixturesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep tab alive in memory

  static const String API_BASE_URL =
      'https://fanclash-api.onrender.com/api/games';

  // Database related
  static Database? _database;
  static const String _dbName = 'fixtures.db';
  static const String _tableName = 'fixtures';
  static const int _cacheDurationHours = 1; // Cache duration in hours

  List<Fixture> _fixtures = [];
  bool _loading = true;
  String _error = '';
  String _activeFilter = 'all';
  String _sortBy = 'date';
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isDisposed = false;

  // Modal state
  bool _isModalOpen = false;
  Fixture? _selectedFixture;

  // Card interaction states
  final Map<int, Map<String, dynamic>> _cardStates = {};

  @override
  void initState() {
    super.initState();
    print('DEBUG: FixturesPage initState called');
    _initDatabase();
    _loadFixtures();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    closeDatabase();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // Database Methods
  Future<void> _initDatabase() async {
    try {
      _database = await openDatabase(
        path_helper.join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName(
              id TEXT PRIMARY KEY,
              homeTeam TEXT,
              awayTeam TEXT,
              league TEXT,
              date TEXT,
              homeWin REAL,
              awayWin REAL,
              draw REAL,
              isLive INTEGER,
              homeScore INTEGER,
              awayScore INTEGER,
              lastUpdated TEXT,
              data TEXT
            )
          ''');
        },
        version: 1,
      );
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
  }

  bool _isCacheValid(String lastUpdated) {
    try {
      final lastUpdateTime = DateTime.parse(lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);
      return difference.inHours < _cacheDurationHours;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadFixtures() async {
    print('DEBUG: _loadFixtures called');

    // Step 1: Try to load from cache IMMEDIATELY
    try {
      final cachedFixtures = await _loadFromCache();

      if (cachedFixtures.isNotEmpty) {
        // IMMEDIATELY display cached data (like PostsPage does)
        _safeSetState(() {
          _fixtures = cachedFixtures;
          _loading = false; // NO loading spinner if we have cache
          _error = '';
        });

        // Initialize card states for cached fixtures
        for (var i = 0; i < cachedFixtures.length; i++) {
          if (!_cardStates.containsKey(i)) {
            _cardStates[i] = {
              'isTapped': false,
              'isLiked': false,
              'isFollowing': false,
              'likeCount': Random().nextInt(100) + 50,
              'commentCount': Random().nextInt(30) + 10,
              'shareCount': Random().nextInt(15) + 5,
              'selectedOdds': null,
              'homeVotes': Random().nextInt(100) + 20,
              'drawVotes': Random().nextInt(100) + 10,
              'awayVotes': Random().nextInt(100) + 15,
            };
          }
        }

        print(
          'DEBUG: Displayed ${_fixtures.length} cached fixtures immediately',
        );
      } else {
        // No cache, show loading
        _safeSetState(() {
          _loading = true;
          _error = '';
        });
        print('DEBUG: No cache found, showing loading spinner');
      }
    } catch (e) {
      print('Cache error: $e');
      _safeSetState(() {
        _loading = true;
      });
    }

    // Step 2: ALWAYS fetch fresh data in background
    // This won't block UI if we already have cache
    print('DEBUG: Starting background API fetch');
    try {
      await _fetchFixtures();
    } catch (e) {
      print('Background fetch failed: $e');
      // Only show error if we have NO data at all
      if (_fixtures.isEmpty) {
        _safeSetState(() {
          _error = 'Failed to load: ${e.toString().split(':').first}';
          _loading = false;
        });
      }
    }
  }

  Future<List<Fixture>> _loadFromCache() async {
    if (_database == null) {
      await _initDatabase();
    }

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        orderBy: 'date ASC',
      );

      if (maps.isEmpty) {
        return [];
      }

      final fixtures = <Fixture>[];
      List<String> outdatedIds = [];

      for (var map in maps) {
        try {
          final lastUpdated = map['lastUpdated'] as String?;

          // Check if cache is still valid
          if (lastUpdated != null && _isCacheValid(lastUpdated)) {
            final data = map['data'] as String?;
            if (data != null) {
              final fixtureJson = json.decode(data);
              final fixture = Fixture.fromJson(fixtureJson);
              fixtures.add(fixture);
            }
          } else {
            // Mark outdated cache for cleanup
            final id = map['id'] as String?;
            if (id != null) {
              outdatedIds.add(id);
            }
          }
        } catch (e) {
          print('Error parsing cached fixture: $e');
        }
      }

      // Clean up outdated cache entries
      if (outdatedIds.isNotEmpty) {
        await _cleanupCache(outdatedIds);
      }

      return fixtures;
    } catch (e) {
      print('Error loading from cache: $e');
      return [];
    }
  }

  Future<void> _saveToCache(List<Fixture> fixtures) async {
    if (_database == null) {
      await _initDatabase();
    }

    try {
      // Start a transaction for batch operations
      await _database!.transaction((txn) async {
        for (var fixture in fixtures) {
          try {
            // Create a unique ID for each fixture
            final id = '${fixture.homeTeam}_${fixture.awayTeam}_${fixture.date}'
                .replaceAll(' ', '_')
                .toLowerCase();

            final fixtureJson = fixture.toJson();
            final data = json.encode(fixtureJson);
            final now = DateTime.now().toIso8601String();

            await txn.insert(_tableName, {
              'id': id,
              'homeTeam': fixture.homeTeam,
              'awayTeam': fixture.awayTeam,
              'league': fixture.league,
              'date': fixture.date,
              'homeWin': fixture.homeWin,
              'awayWin': fixture.awayWin,
              'draw': fixture.draw,
              'isLive': fixture.isLive ? 1 : 0,
              'homeScore': fixture.homeScore,
              'awayScore': fixture.awayScore,
              'lastUpdated': now,
              'data': data,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (e) {
            print('Error saving fixture to cache: $e');
          }
        }
      });
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> _cleanupCache(List<String> ids) async {
    if (_database == null) return;

    try {
      for (var id in ids) {
        await _database!.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      }
    } catch (e) {
      print('Error cleaning up cache: $e');
    }
  }

  Future<void> _clearCache() async {
    if (_database == null) return;

    try {
      await _database!.delete(_tableName);
      _safeSetState(() {
        _fixtures = [];
      });
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> _fetchFixtures({bool forceRefresh = false}) async {
    print('DEBUG: _fetchFixtures called, forceRefresh: $forceRefresh');

    // Don't make unnecessary API calls if we already have data (unless force refresh)
    if (!forceRefresh && _fixtures.isNotEmpty) {
      print(
        'DEBUG: Skipping fetch, using existing ${_fixtures.length} fixtures',
      );
      return;
    }

    // Only show loading if we truly have NO data
    if (_fixtures.isEmpty && !_loading) {
      _safeSetState(() {
        _loading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(API_BASE_URL),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<Fixture> fixtures = [];

        if (jsonData is Map<String, dynamic>) {
          if (jsonData['success'] == true) {
            if (jsonData['data'] != null && jsonData['data'] is List) {
              final List<dynamic> dataList = jsonData['data'];
              fixtures = _parseFixtures(dataList);
            }
          }
        } else if (jsonData is List) {
          fixtures = _parseFixtures(jsonData);
        }

        if (fixtures.isNotEmpty) {
          // Save to cache
          await _saveToCache(fixtures);

          _safeSetState(() {
            _fixtures = fixtures;
            _loading = false;
            _error = '';
          });

          // Initialize card states for new fixtures
          for (var i = 0; i < fixtures.length; i++) {
            if (!_cardStates.containsKey(i)) {
              _cardStates[i] = {
                'isTapped': false,
                'isLiked': false,
                'isFollowing': false,
                'likeCount': Random().nextInt(100) + 50,
                'commentCount': Random().nextInt(30) + 10,
                'shareCount': Random().nextInt(15) + 5,
                'selectedOdds': null,
                'homeVotes': Random().nextInt(100) + 20,
                'drawVotes': Random().nextInt(100) + 10,
                'awayVotes': Random().nextInt(100) + 15,
              };
            }
          }

          print('DEBUG: Updated with ${fixtures.length} fresh fixtures');
        } else {
          // Keep existing data if API returns empty
          if (_fixtures.isEmpty) {
            _safeSetState(() {
              _error = 'No fixtures data available';
              _loading = false;
            });
          }
        }
      } else {
        // Keep existing data on API error
        if (_fixtures.isEmpty) {
          _safeSetState(() {
            _error =
                'HTTP Error ${response.statusCode}: ${response.reasonPhrase}';
            _loading = false;
          });
        } else {
          print('DEBUG: API error but using cached data');
        }
      }
    } catch (e) {
      print('Network error: $e');
      // Keep existing data on network error
      if (_fixtures.isEmpty) {
        _safeSetState(() {
          _error = 'Network error: ${e.toString()}';
          _loading = false;
        });
      } else {
        print('DEBUG: Network error but using cached data');
      }
    }
  }

  List<Fixture> _parseFixtures(List<dynamic> dataList) {
    final fixtures = <Fixture>[];
    for (var i = 0; i < dataList.length; i++) {
      try {
        final item = dataList[i] as Map<String, dynamic>;
        final fixture = Fixture.fromJson(item);
        fixtures.add(fixture);
      } catch (e) {
        print('Error parsing fixture $i: $e');
      }
    }
    return fixtures;
  }

  Future<void> _refreshFixtures() async {
    print('DEBUG: Manual refresh triggered');
    await _fetchFixtures(forceRefresh: true);
  }

  List<Fixture> get _filteredFixtures {
    return _fixtures.where((fixture) {
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!fixture.homeTeam.toLowerCase().contains(searchLower) &&
            !fixture.awayTeam.toLowerCase().contains(searchLower) &&
            !fixture.league.toLowerCase().contains(searchLower)) {
          return false;
        }
      }

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
        print('Error parsing date ${fixture.date}: $e');
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
      return 'TBD';
    }
  }

  String _formatFullDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, HH:mm').format(date);
    } catch (e) {
      return 'Date TBD';
    }
  }

  void _openClashRoomModal(Fixture fixture) {
    _safeSetState(() {
      _selectedFixture = fixture;
      _isModalOpen = true;
    });
  }

  void _closeModal() {
    _safeSetState(() {
      _isModalOpen = false;
      _selectedFixture = null;
    });
  }

  Map<String, double> _calculateVotingPercentages(
    int homeVotes,
    int drawVotes,
    int awayVotes,
  ) {
    final totalVotes = homeVotes + drawVotes + awayVotes;
    if (totalVotes == 0) {
      return {'home': 0.0, 'draw': 0.0, 'away': 0.0};
    }
    return {
      'home': (homeVotes / totalVotes) * 100,
      'draw': (drawVotes / totalVotes) * 100,
      'away': (awayVotes / totalVotes) * 100,
    };
  }

  Widget _buildMatchCard(
    BuildContext buildContext,
    Fixture fixture,
    int index,
  ) {
    final isLive = fixture.isLive;
    final cardState = _cardStates[index]!;
    final isTapped = cardState['isTapped'] as bool;
    final isLiked = cardState['isLiked'] as bool;
    final isFollowing = cardState['isFollowing'] as bool;
    final likeCount = cardState['likeCount'] as int;
    final commentCount = cardState['commentCount'] as int;
    final shareCount = cardState['shareCount'] as int;
    final selectedOdds = cardState['selectedOdds'] as String?;
    final homeVotes = cardState['homeVotes'] as int;
    final drawVotes = cardState['drawVotes'] as int;
    final awayVotes = cardState['awayVotes'] as int;
    final percentages = _calculateVotingPercentages(
      homeVotes,
      drawVotes,
      awayVotes,
    );
    final totalVotes = homeVotes + drawVotes + awayVotes;

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
        _openClashRoomModal(fixture);
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
          children: [
            // Header with league and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                        ),
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
                    GestureDetector(
                      onTap: () {
                        _safeSetState(() {
                          _cardStates[index]!['isFollowing'] = !isFollowing;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                ),

                Text(
                  _formatFullDate(fixture.date),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Match title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${fixture.homeTeam} vs ${fixture.awayTeam}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Live status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFFEF4444).withOpacity(0.2)
                        : Colors.grey[800]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLive
                          ? const Color(0xFFEF4444).withOpacity(0.3)
                          : Colors.grey[700]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Text(
                        isLive ? 'LIVE' : _formatDate(fixture.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isLive
                              ? const Color(0xFFEF4444)
                              : Colors.grey[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Teams and scores section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
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
                            fixture.homeTeam
                                .substring(0, min(2, fixture.homeTeam.length))
                                .toUpperCase(),
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

                  // VS
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
                        style: TextStyle(fontSize: 10, color: Colors.grey),
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
                            fixture.awayTeam
                                .substring(0, min(2, fixture.awayTeam.length))
                                .toUpperCase(),
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
            ),

            const SizedBox(height: 16),

            // Odds section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Match Odds',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildOddsButton(
                        '1',
                        fixture.homeWin.toStringAsFixed(2),
                        'home',
                        selectedOdds == 'home',
                        index,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOddsButton(
                        'X',
                        fixture.draw.toStringAsFixed(2),
                        'draw',
                        selectedOdds == 'draw',
                        index,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOddsButton(
                        '2',
                        fixture.awayWin.toStringAsFixed(2),
                        'away',
                        selectedOdds == 'away',
                        index,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Voting progress bars section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fan Votes',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Total: $totalVotes',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Home Team Votes
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fixture.homeTeam.length > 12
                              ? '${fixture.homeTeam.substring(0, 12)}...'
                              : fixture.homeTeam,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${homeVotes} (${percentages['home']!.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            width:
                                MediaQuery.of(buildContext).size.width *
                                (percentages['home']! / 100),
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981).withOpacity(0.8),
                                  const Color(0xFF10B981),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Draw Votes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Draw',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${drawVotes} (${percentages['draw']!.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            width:
                                MediaQuery.of(buildContext).size.width *
                                (percentages['draw']! / 100),
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981).withOpacity(0.6),
                                  const Color(0xFF10B981).withOpacity(0.8),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Away Team Votes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fixture.awayTeam.length > 12
                              ? '${fixture.awayTeam.substring(0, 12)}...'
                              : fixture.awayTeam,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${awayVotes} (${percentages['away']!.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            width:
                                MediaQuery.of(buildContext).size.width *
                                (percentages['away']! / 100),
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981).withOpacity(0.4),
                                  const Color(0xFF10B981).withOpacity(0.6),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Vote buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _safeSetState(() {
                            _cardStates[index]!['homeVotes'] = homeVotes + 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: const Center(
                            child: Text(
                              'Vote Home',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _safeSetState(() {
                            _cardStates[index]!['drawVotes'] = drawVotes + 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: const Center(
                            child: Text(
                              'Vote Draw',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _safeSetState(() {
                            _cardStates[index]!['awayVotes'] = awayVotes + 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: const Center(
                            child: Text(
                              'Vote Away',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stats and actions section
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
                  // Stats
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${Random().nextInt(200) + 50}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble,
                            size: 14,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            commentCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${Random().nextInt(1000) + 200}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Quick actions
                  Row(
                    children: [
                      // Like button
                      GestureDetector(
                        onTap: () {
                          _safeSetState(() {
                            final newLiked = !isLiked;
                            _cardStates[index]!['isLiked'] = newLiked;
                            _cardStates[index]!['likeCount'] = newLiked
                                ? likeCount + 1
                                : likeCount - 1;
                          });
                        },
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
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                likeCount.toString(),
                                style: TextStyle(
                                  color: isLiked
                                      ? const Color(0xFFEF4444)
                                      : Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Join button
                      GestureDetector(
                        onTap: () => _openClashRoomModal(fixture),
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
                          child: const Row(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOddsButton(
    String label,
    String odds,
    String type,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        _safeSetState(() {
          _cardStates[index]!['selectedOdds'] =
              _cardStates[index]!['selectedOdds'] == type ? null : type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981)
              : Colors.grey[900]!.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey[800]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              odds,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _fixtures.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: const Color(0xFF10B981)),
              const SizedBox(height: 16),
              const Text(
                'Loading fixtures...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty && _fixtures.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _refreshFixtures,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await _clearCache();
                    _refreshFixtures();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  child: const Text(
                    'Clear Cache & Retry',
                    style: TextStyle(color: Colors.white),
                  ),
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
              const Icon(Icons.sports_soccer, color: Colors.grey, size: 50),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matches found for "$_searchQuery"'
                    : 'No fixtures available',
                style: const TextStyle(color: Colors.white),
              ),
              if (_searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _safeSetState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  child: const Text(
                    'Clear search',
                    style: TextStyle(color: Color(0xFF10B981)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        backgroundColor: const Color(0xFF10B981),
        color: Colors.white,
        onRefresh: _refreshFixtures,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _sortedFixtures.length,
          itemBuilder: (context, index) {
            return _buildMatchCard(context, _sortedFixtures[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Fixtures',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Row(
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  _safeSetState(() {
                    _activeFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Matches')),
                  const PopupMenuItem(value: 'live', child: Text('Live')),
                  const PopupMenuItem(
                    value: 'upcoming',
                    child: Text('Upcoming'),
                  ),
                ],
                icon: Icon(Icons.filter_list, color: const Color(0xFF10B981)),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  _safeSetState(() {
                    _sortBy = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'date',
                    child: Text('Sort by Date'),
                  ),
                  const PopupMenuItem(
                    value: 'odds',
                    child: Text('Sort by Odds'),
                  ),
                  const PopupMenuItem(
                    value: 'league',
                    child: Text('Sort by League'),
                  ),
                ],
                icon: Icon(Icons.sort, color: const Color(0xFF10B981)),
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
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content area - no SafeArea, no padding
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch to fill width
            mainAxisSize: MainAxisSize.max,
            children: [
              // Content - expands to fill remaining space
              Expanded(child: _buildContent()),
            ],
          ),

          // Modal Overlay
          if (_isModalOpen && _selectedFixture != null)
            Container(color: Colors.black.withOpacity(0.5)),

          // Modal Content
          if (_isModalOpen && _selectedFixture != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: ClashRoomModal(
                isOpen: true,
                onClose: _closeModal,
                fixture: _selectedFixture!,
              ),
            ),
        ],
      ),
    );
  }
}
