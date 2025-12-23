import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fixture_models.dart';

class ClashRoomModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Fixture fixture;

  const ClashRoomModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.fixture,
  });

  @override
  State<ClashRoomModal> createState() => _ClashRoomModalState();
}

class _ClashRoomModalState extends State<ClashRoomModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'username': 'RedDevil99',
      'team': 'Man United',
      'message': 'We\'re gonna destroy Chelsea today! 💪🔴',
      'time': '14:23',
      'isSupporter': true,
    },
    {
      'username': 'BluesPride',
      'team': 'Chelsea',
      'message': 'In your dreams mate 😂 We\'ve got this! 💙',
      'time': '14:24',
      'isSupporter': false,
    },
    {
      'username': 'OldTrafford',
      'team': 'Man United',
      'message': 'Bruno Fernandes masterclass incoming! ⚡',
      'time': '14:25',
      'isSupporter': true,
    },
    {
      'username': 'StamfordLion',
      'team': 'Chelsea',
      'message': 'Palmer gonna cook your defense 🔥🍳',
      'time': '14:26',
      'isSupporter': false,
    },
    {
      'username': 'TheReds',
      'team': 'Man United',
      'message': '3-1 United, mark my words 📝',
      'time': '14:27',
      'isSupporter': true,
    },
    {
      'username': 'ChelseaFC',
      'team': 'Chelsea',
      'message': 'Your defense is swiss cheese 🧀😭',
      'time': '14:28',
      'isSupporter': false,
    },
    {
      'username': 'Rashy10',
      'team': 'Man United',
      'message': 'Garnacho on fire today! 🔥',
      'time': '14:29',
      'isSupporter': true,
    },
    {
      'username': 'BlueArmy',
      'team': 'Chelsea',
      'message': 'Where\'s your trophy cabinet? 🤣',
      'time': '14:30',
      'isSupporter': false,
    },
    {
      'username': 'MUFC_4Life',
      'team': 'Man United',
      'message': '20 times, never forget! 🏆',
      'time': '14:31',
      'isSupporter': true,
    },
    {
      'username': 'ChelseaForever',
      'team': 'Chelsea',
      'message': 'Champions of Europe 2021! ⭐',
      'time': '14:32',
      'isSupporter': false,
    },
    {
      'username': 'TenHagBall',
      'team': 'Man United',
      'message': 'ETH masterclass today 👨‍🏫',
      'time': '14:33',
      'isSupporter': true,
    },
    {
      'username': 'PochMagic',
      'team': 'Chelsea',
      'message': 'Pochettino cooking something special 🧑‍🍳',
      'time': '14:34',
      'isSupporter': false,
    },
    {
      'username': 'OnanaSave',
      'team': 'Man United',
      'message': 'Clean sheet incoming! 🧤',
      'time': '14:35',
      'isSupporter': true,
    },
    {
      'username': 'SanchezWall',
      'team': 'Chelsea',
      'message': 'Our keeper is unbeatable today 🧱',
      'time': '14:36',
      'isSupporter': false,
    },
    {
      'username': 'HojlundTime',
      'team': 'Man United',
      'message': 'Hojlund brace today! ⚽⚽',
      'time': '14:37',
      'isSupporter': true,
    },
    {
      'username': 'JacksonSpeed',
      'team': 'Chelsea',
      'message': 'Jackson too fast for Maguire 🏃💨',
      'time': '14:38',
      'isSupporter': false,
    },
    {
      'username': 'CasemiroCDM',
      'team': 'Man United',
      'message': 'Casemiro controlling midfield 🛡️',
      'time': '14:39',
      'isSupporter': true,
    },
    {
      'username': 'EnzoVision',
      'team': 'Chelsea',
      'message': 'Enzo with the perfect through ball 🎯',
      'time': '14:40',
      'isSupporter': false,
    },
    {
      'username': 'MainooFuture',
      'team': 'Man United',
      'message': 'Mainoo is class! Future star 🌟',
      'time': '14:41',
      'isSupporter': true,
    },
    {
      'username': 'CaicedoBeast',
      'team': 'Chelsea',
      'message': 'Caicedo dominating midfield 💪',
      'time': '14:42',
      'isSupporter': false,
    },
    {
      'username': 'Shawberto',
      'team': 'Man United',
      'message': 'Luke Shaw crosses are dangerous 🎯',
      'time': '14:43',
      'isSupporter': true,
    },
    {
      'username': 'JamesCaptain',
      'team': 'Chelsea',
      'message': 'Reece James on the overlap! 🏃',
      'time': '14:44',
      'isSupporter': false,
    },
    {
      'username': 'DalotEnergy',
      'team': 'Man United',
      'message': 'Dalot running all day! 🔄',
      'time': '14:45',
      'isSupporter': true,
    },
    {
      'username': 'SterlingSkill',
      'team': 'Chelsea',
      'message': 'Sterling taking on defenders! ⚡',
      'time': '14:46',
      'isSupporter': false,
    },
    {
      'username': 'AntonyLeft',
      'team': 'Man United',
      'message': 'Antony cutting inside...GOAL! 🚀',
      'time': '14:47',
      'isSupporter': true,
    },
    {
      'username': 'MudrykMagic',
      'team': 'Chelsea',
      'message': 'Mudryk with the pace! 🇺🇦',
      'time': '14:48',
      'isSupporter': false,
    },
    {
      'username': 'MartinezWarrior',
      'team': 'Man United',
      'message': 'Licha clearing everything! 🧹',
      'time': '14:49',
      'isSupporter': true,
    },
    {
      'username': 'SilvaClass',
      'team': 'Chelsea',
      'message': 'Thiago Silva still world class! 👑',
      'time': '14:50',
      'isSupporter': false,
    },
    {
      'username': 'VaraneRock',
      'team': 'Man United',
      'message': 'Varane unbeatable in the air! ✈️',
      'time': '14:51',
      'isSupporter': true,
    },
    {
      'username': 'ColwillFuture',
      'team': 'Chelsea',
      'message': 'Colwill is a star in making! ⭐',
      'time': '14:52',
      'isSupporter': false,
    },
    {
      'username': 'MountReturn',
      'team': 'Man United',
      'message': 'Mount scoring against his old club! 😈',
      'time': '14:53',
      'isSupporter': true,
    },
    {
      'username': 'GallagherHeart',
      'team': 'Chelsea',
      'message': 'Gallagher running his heart out! ❤️',
      'time': '14:54',
      'isSupporter': false,
    },
    {
      'username': 'McTominayLate',
      'team': 'Man United',
      'message': 'McTominay with a late winner! ⏰',
      'time': '14:55',
      'isSupporter': true,
    },
    {
      'username': 'MaduekeImpact',
      'team': 'Chelsea',
      'message': 'Madueke off the bench! 🔄',
      'time': '14:56',
      'isSupporter': false,
    },
    {
      'username': 'PellistriYoung',
      'team': 'Man United',
      'message': 'Pellistri with fresh legs! 🌱',
      'time': '14:57',
      'isSupporter': true,
    },
    {
      'username': 'BrojaTarget',
      'team': 'Chelsea',
      'message': 'Broja winning headers! 💪',
      'time': '14:58',
      'isSupporter': false,
    },
    {
      'username': 'AmrabatSteel',
      'team': 'Man United',
      'message': 'Amrabat adding steel! ⚔️',
      'time': '14:59',
      'isSupporter': true,
    },
    {
      'username': 'UgochukwuPower',
      'team': 'Chelsea',
      'message': 'Ugochukwu physical presence! 💥',
      'time': '15:00',
      'isSupporter': false,
    },
    {
      'username': 'GoreTech',
      'team': 'Man United',
      'message': 'Gore with technical ability! 🎨',
      'time': '15:01',
      'isSupporter': true,
    },
    {
      'username': 'MatosEnergy',
      'team': 'Chelsea',
      'message': 'Matos bringing energy! ⚡',
      'time': '15:02',
      'isSupporter': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'username': 'You',
        'team': widget.fixture.homeTeam,
        'message': _messageController.text.trim(),
        'time': DateTime.now().toString().substring(11, 16),
        'isSupporter': true,
      });
    });

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getTeamAbbreviation(String teamName) {
    if (teamName.toLowerCase().contains('united')) return 'MUN';
    if (teamName.toLowerCase().contains('city')) return 'MCI';
    if (teamName.toLowerCase().contains('chelsea')) return 'CHE';
    if (teamName.toLowerCase().contains('liverpool')) return 'LIV';
    if (teamName.toLowerCase().contains('arsenal')) return 'ARS';
    if (teamName.toLowerCase().contains('tottenham')) return 'TOT';

    return teamName.substring(0, min(3, teamName.length)).toUpperCase();
  }

  Color _getTeamColor(String teamName) {
    if (teamName.toLowerCase().contains('united')) return Colors.red;
    if (teamName.toLowerCase().contains('city')) return const Color(0xFF6CABDD);
    if (teamName.toLowerCase().contains('chelsea'))
      return const Color(0xFF034694);
    if (teamName.toLowerCase().contains('liverpool'))
      return const Color(0xFFC8102E);
    if (teamName.toLowerCase().contains('arsenal'))
      return const Color(0xFFEF0107);
    if (teamName.toLowerCase().contains('tottenham')) return Colors.white;

    return Colors.grey.shade400;
  }

  // Speech bubble colors - TWO SEPARATE COLORS
  Color _getHomeTeamBubbleColor() {
    return const Color(0xFF1A5D2C); // Dark green for home team
  }

  Color _getAwayTeamBubbleColor() {
    return const Color(0xFF216E4E); // Medium green for away team
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final homeTeamColor = _getTeamColor(widget.fixture.homeTeam);
    final awayTeamColor = _getTeamColor(widget.fixture.awayTeam);
    final homeAbbr = _getTeamAbbreviation(widget.fixture.homeTeam);
    final awayAbbr = _getTeamAbbreviation(widget.fixture.awayTeam);

    final homeBubbleColor = _getHomeTeamBubbleColor();
    final awayBubbleColor = _getAwayTeamBubbleColor();

    return Material(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      color: Colors.transparent, // Changed to transparent
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9), // Semi-transparent black
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(
            color: const Color(0xFF10B981), // Green border
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Green handle
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),

            // Ultra Compact Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Home Team
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: homeTeamColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: homeTeamColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            homeAbbr,
                            style: TextStyle(
                              color: homeTeamColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fixture.homeTeam,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: const Color(0xFF10B981).withOpacity(0.8),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // VS
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'VS',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Away Team
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.fixture.awayTeam,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Away',
                            style: TextStyle(
                              color: const Color(0xFF10B981).withOpacity(0.8),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: awayTeamColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: awayTeamColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            awayAbbr,
                            style: TextStyle(
                              color: awayTeamColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Close Button
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Chat Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'CHAT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${_messages.length}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_alt_outlined,
                    color: const Color(0xFF10B981).withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_messages.length ~/ 2} online',
                    style: TextStyle(
                      color: const Color(0xFF10B981).withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages
            Expanded(
              child: Container(
                color: Colors.transparent, // Transparent background
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatMessage(
                      username: msg['username'],
                      team: msg['team'],
                      message: msg['message'],
                      time: msg['time'],
                      isSupporter: msg['isSupporter'],
                      bubbleColor: msg['isSupporter']
                          ? homeBubbleColor
                          : awayBubbleColor,
                    );
                  },
                ),
              ),
            ),

            // Message Input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type message...',
                                hintStyle: TextStyle(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.emoji_emotions_outlined,
                              color: const Color(0xFF10B981),
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
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

  Widget _buildChatMessage({
    required String username,
    required String team,
    required String message,
    required String time,
    required bool isSupporter,
    required Color bubbleColor,
  }) {
    final teamColor = _getTeamColor(team);
    final isYou = username == 'You';
    final isRight = isYou || isSupporter;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isRight) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: teamColor, width: 1),
              ),
              child: Center(
                child: Text(
                  username.substring(0, min(1, username.length)).toUpperCase(),
                  style: TextStyle(
                    color: teamColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Speech Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Column(
                crossAxisAlignment: isRight
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: isRight
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: teamColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: teamColor, width: 0.5),
                        ),
                        child: Text(
                          team
                              .split(' ')
                              .last
                              .substring(0, min(3, team.length))
                              .toUpperCase(),
                          style: TextStyle(
                            color: teamColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: const Color(0xFF10B981).withOpacity(0.8),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: isRight
                            ? const Radius.circular(8)
                            : const Radius.circular(2),
                        topRight: isRight
                            ? const Radius.circular(2)
                            : const Radius.circular(8),
                        bottomLeft: const Radius.circular(8),
                        bottomRight: const Radius.circular(8),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isRight) ...[
            const SizedBox(width: 6),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isYou
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [
                          teamColor.withOpacity(0.2),
                          teamColor.withOpacity(0.1),
                        ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isYou ? const Color(0xFF10B981) : teamColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  username.substring(0, min(1, username.length)).toUpperCase(),
                  style: TextStyle(
                    color: isYou ? Colors.white : teamColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
