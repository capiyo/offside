class Fixture {
  final String? id;
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String league;
  final double homeWin;
  final double awayWin;
  final double draw;
  final String date;
  final String time;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final bool isLive;
  final String lastUpdated;
  final String? createdAt;
  final String? scrapedAt;

  Fixture({
    this.id,
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.homeWin,
    required this.awayWin,
    required this.draw,
    required this.date,
    required this.time,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.isLive,
    required this.lastUpdated,
    this.createdAt,
    this.scrapedAt,
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      id: json['_id']?.toString(),
      matchId: json['match_id']?.toString() ?? '',
      homeTeam: json['home_team']?.toString() ?? '',
      awayTeam: json['away_team']?.toString() ?? '',
      league: json['league']?.toString() ?? '',
      homeWin: _parseDouble(json['home_win']),
      awayWin: _parseDouble(json['away_win']),
      draw: _parseDouble(json['draw']),
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      homeScore: _parseNullableInt(json['home_score']),
      awayScore: _parseNullableInt(json['away_score']),
      status: json['status']?.toString() ?? 'upcoming',
      isLive: json['is_live'] is bool ? json['is_live'] as bool : false,
      lastUpdated: json['last_updated']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      scrapedAt: json['scraped_at']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'match_id': matchId,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'league': league,
      'home_win': homeWin,
      'away_win': awayWin,
      'draw': draw,
      'date': date,
      'time': time,
      'home_score': homeScore,
      'away_score': awayScore,
      'status': status,
      'is_live': isLive,
      'last_updated': lastUpdated,
      'created_at': createdAt,
      'scraped_at': scrapedAt,
    };
  }
}
