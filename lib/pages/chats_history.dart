import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  List<ChatHistory> _chatHistory = [];
  bool _loading = true;
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  // Card interaction states
  final Map<int, Map<String, dynamic>> _cardStates = {};

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));

    final mockHistory = [
      ChatHistory(
        id: '1',
        matchTitle: 'Manchester United vs Liverpool',
        league: 'Premier League',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        participants: 124,
        messages: 356,
        matchStatus: 'Finished',
        homeScore: 2,
        awayScore: 1,
        homeTeam: 'Manchester United',
        awayTeam: 'Liverpool',
        lastMessage: 'What a goal by Rashford!',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
        isPinned: true,
      ),
      ChatHistory(
        id: '2',
        matchTitle: 'Barcelona vs Real Madrid',
        league: 'La Liga',
        date: DateTime.now().subtract(const Duration(days: 1)),
        participants: 98,
        messages: 245,
        matchStatus: 'Finished',
        homeScore: 3,
        awayScore: 2,
        homeTeam: 'Barcelona',
        awayTeam: 'Real Madrid',
        lastMessage: 'Classico never disappoints!',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
        isPinned: false,
      ),
      ChatHistory(
        id: '3',
        matchTitle: 'Bayern Munich vs Dortmund',
        league: 'Bundesliga',
        date: DateTime.now().subtract(const Duration(days: 2)),
        participants: 87,
        messages: 198,
        matchStatus: 'Finished',
        homeScore: 4,
        awayScore: 0,
        homeTeam: 'Bayern Munich',
        awayTeam: 'Dortmund',
        lastMessage: 'Der Klassiker was one-sided',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        isPinned: false,
      ),
      ChatHistory(
        id: '4',
        matchTitle: 'AC Milan vs Inter Milan',
        league: 'Serie A',
        date: DateTime.now().subtract(const Duration(days: 3)),
        participants: 76,
        messages: 167,
        matchStatus: 'Finished',
        homeScore: 1,
        awayScore: 1,
        homeTeam: 'AC Milan',
        awayTeam: 'Inter Milan',
        lastMessage: 'Great derby, both teams played well',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
        isPinned: true,
      ),
      ChatHistory(
        id: '5',
        matchTitle: 'PSG vs Marseille',
        league: 'Ligue 1',
        date: DateTime.now().subtract(const Duration(days: 4)),
        participants: 65,
        messages: 143,
        matchStatus: 'Finished',
        homeScore: 2,
        awayScore: 3,
        homeTeam: 'PSG',
        awayTeam: 'Marseille',
        lastMessage: 'Upset of the season!',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
        isPinned: false,
      ),
    ];

    setState(() {
      _chatHistory = mockHistory;
      _loading = false;

      // Initialize card states
      for (var i = 0; i < _chatHistory.length; i++) {
        _cardStates[i] = {
          'isTapped': false,
          'isLiked': false,
          'likeCount': Random().nextInt(50) + 10,
          'isBookmarked': false,
        };
      }
    });
  }

  List<ChatHistory> get _filteredHistory {
    if (_searchQuery.isEmpty) {
      return _chatHistory;
    }

    final searchLower = _searchQuery.toLowerCase();
    return _chatHistory.where((chat) {
      return chat.matchTitle.toLowerCase().contains(searchLower) ||
          chat.league.toLowerCase().contains(searchLower) ||
          chat.homeTeam.toLowerCase().contains(searchLower) ||
          chat.awayTeam.toLowerCase().contains(searchLower);
    }).toList();
  }

  String _formatTimeDifference(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  Widget _buildChatCard(ChatHistory chat, int index) {
    final cardState = _cardStates[index]!;
    final isTapped = cardState['isTapped'] as bool;
    final isLiked = cardState['isLiked'] as bool;
    final isBookmarked = cardState['isBookmarked'] as bool;
    final likeCount = cardState['likeCount'] as int;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() {
          _cardStates[index]!['isTapped'] = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _cardStates[index]!['isTapped'] = false;
        });
        // Navigate to chat details
        _openChatDetails(chat);
      },
      onTapCancel: () {
        setState(() {
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
            // Header with pin and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // League badge
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
                        chat.league,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (chat.isPinned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.push_pin, size: 10, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                Text(
                  DateFormat('MMM d, HH:mm').format(chat.date),
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
                    chat.matchTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chat.matchStatus == 'Finished'
                        ? Colors.grey[800]!.withOpacity(0.5)
                        : const Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: chat.matchStatus == 'Finished'
                          ? Colors.grey[700]!
                          : const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    chat.matchStatus,
                    style: TextStyle(
                      fontSize: 10,
                      color: chat.matchStatus == 'Finished'
                          ? Colors.grey[400]
                          : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

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
                          chat.homeTeam
                              .substring(0, min(2, chat.homeTeam.length))
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
                        chat.homeTeam,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat.homeScore.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                          chat.awayTeam
                              .substring(0, min(2, chat.awayTeam.length))
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
                        chat.awayTeam,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat.awayScore.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Chat stats and last message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Participants
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${chat.participants}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Messages
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble,
                        size: 14,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${chat.messages}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Last message preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          chat.lastMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimeDifference(chat.lastMessageTime),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Revisit button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openChatDetails(chat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Revisit Chat',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Like button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final newLiked = !isLiked;
                      _cardStates[index]!['isLiked'] = newLiked;
                      _cardStates[index]!['likeCount'] = newLiked
                          ? likeCount + 1
                          : likeCount - 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? const Color(0xFFEF4444)
                              : Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _cardStates[index]!['likeCount'].toString(),
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

                // Bookmark button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _cardStates[index]!['isBookmarked'] = !isBookmarked;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? Colors.amber.withOpacity(0.1)
                          : Colors.grey[900]!.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isBookmarked
                            ? Colors.amber.withOpacity(0.3)
                            : Colors.grey[800]!,
                      ),
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.amber : Colors.grey[400],
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openChatDetails(ChatHistory chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Chat details
              Text(
                chat.matchTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('MMM d, yyyy').format(chat.date)} • ${chat.league}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${chat.participants}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Participants',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${chat.messages}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Messages',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${chat.homeScore}-${chat.awayScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Final Score',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to full chat
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'View Full Chat',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: const Color(0xFF10B981)),
              const SizedBox(height: 16),
              const Text(
                'Loading chat history...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredHistory.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, color: Colors.grey, size: 50),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No chats found for "$_searchQuery"'
                    : 'No chat history available',
                style: const TextStyle(color: Colors.white),
              ),
              if (_searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
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
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredHistory.length,
        itemBuilder: (context, index) {
          return _buildChatCard(_filteredHistory[index], index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        // Removed SafeArea wrapper
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),

                IconButton(
                  onPressed: () {
                    setState(() {
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
          ),

          // Content
          Expanded(
            // Added Expanded to fill remaining space
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}

class ChatHistory {
  final String id;
  final String matchTitle;
  final String league;
  final DateTime date;
  final int participants;
  final int messages;
  final String matchStatus;
  final int homeScore;
  final int awayScore;
  final String homeTeam;
  final String awayTeam;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isPinned;

  ChatHistory({
    required this.id,
    required this.matchTitle,
    required this.league,
    required this.date,
    required this.participants,
    required this.messages,
    required this.matchStatus,
    required this.homeScore,
    required this.awayScore,
    required this.homeTeam,
    required this.awayTeam,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isPinned,
  });
}
