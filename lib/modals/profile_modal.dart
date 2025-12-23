import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  final String username;
  final String phone;
  final String clubFan;
  final String nickname;
  final String countryFan;
  final double balance;
  final int numberOfBets;
  final String userId;

  UserData({
    required this.username,
    required this.phone,
    required this.clubFan,
    required this.nickname,
    required this.countryFan,
    required this.balance,
    required this.numberOfBets,
    required this.userId,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      clubFan: json['club_fan'] ?? '',
      nickname: json['nickname'] ?? '',
      countryFan: json['country_fan'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      numberOfBets: json['number_of_bets'] ?? 0,
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'phone': phone,
      'club_fan': clubFan,
      'nickname': nickname,
      'country_fan': countryFan,
      'balance': balance,
      'number_of_bets': numberOfBets,
      'user_id': userId,
    };
  }
}

class ProfileModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String apiBaseUrl;
  final Function(UserData)? onUserLoggedIn;

  const ProfileModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.onUserLoggedIn,
    this.apiBaseUrl = 'https://fanclash-api.onrender.com',
  });

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  bool _isSyncing = false;
  bool _isNewUser = false;
  bool _isLoading = true;
  UserData _userData = UserData(
    username: '',
    phone: '',
    clubFan: '',
    nickname: '',
    countryFan: '',
    balance: 0,
    numberOfBets: 0,
    userId: '',
  );

  // Emerald color theme
  final Color _emeraldPrimary = Color(0xFF10B981);
  final Color _emeraldLight = Color(0xFF34D399);
  final Color _emeraldDark = Color(0xFF059669);

  final _glassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF10B981).withOpacity(0.3),
        Color(0xFF059669).withOpacity(0.2),
      ],
    ),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
    border: Border.all(color: Color(0xFF10B981).withOpacity(0.25), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 30,
        spreadRadius: -8,
      ),
    ],
  );

  final _glassCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF10B981).withOpacity(0.25),
        Color(0xFF059669).withOpacity(0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Color(0xFF10B981).withOpacity(0.2), width: 1),
  );

  final _accentGlassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF10B981).withOpacity(0.4),
        Color(0xFF059669).withOpacity(0.25),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Color(0xFF10B981).withOpacity(0.35), width: 1.5),
  );

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      setState(() => _isSyncing = true);

      // Check if user exists in local storage
      final prefs = await SharedPreferences.getInstance();
      final isForcedNewUser = prefs.getBool('forceNewUser') ?? false;
      final sessionToken = prefs.getString('sessionToken');
      final userProfile = prefs.getString('userProfile');

      if (isForcedNewUser || sessionToken == null || userProfile == null) {
        setState(() {
          _isNewUser = true;
        });
        await prefs.remove('forceNewUser');
        return;
      }

      await _loadUserFromBackend();
    } catch (error) {
      print('Session check error: $error');
      setState(() {
        _isNewUser = true;
      });
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadUserFromBackend() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('userProfile');
      String localPhone = '';

      if (saved != null) {
        try {
          final localData = jsonDecode(saved);
          localPhone = localData['phone'] ?? '';
        } catch (error) {
          print('Error parsing local data: $error');
        }
      }

      if (localPhone.isNotEmpty) {
        final backendUser = await _findUserByPhone(localPhone);

        if (backendUser != null) {
          setState(() {
            _userData = backendUser;
            _isNewUser = false;
          });

          await _saveUserToLocal(backendUser);
          await prefs.setString(
            'sessionToken',
            'session_${DateTime.now().millisecondsSinceEpoch}',
          );

          return;
        }
      }

      setState(() {
        _isNewUser = true;
      });
    } catch (error) {
      print('Error loading user: $error');
      setState(() {
        _isNewUser = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<UserData?> _findUserByPhone(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final phoneFormats = <String>[cleanPhone];

      if (cleanPhone.startsWith('0')) phoneFormats.add(cleanPhone.substring(1));
      if (cleanPhone.length == 9) {
        phoneFormats.add('254$cleanPhone');
      } else if (cleanPhone.length == 10 && cleanPhone.startsWith('0'))
        phoneFormats.add('254${cleanPhone.substring(1)}');

      for (final phoneFormat in phoneFormats) {
        try {
          final response = await http.get(
            Uri.parse(
              '${widget.apiBaseUrl}/api/profile/profile/phone/$phoneFormat',
            ),
          );

          if (response.statusCode == 200) {
            final backendUser = jsonDecode(response.body);
            return UserData.fromJson(backendUser);
          }
        } catch (error) {
          print('Format $phoneFormat not found: $error');
        }
      }
      return null;
    } catch (error) {
      print('Error finding user by phone: $error');
      return null;
    }
  }

  Future<void> _saveUserToLocal(UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userProfile', jsonEncode(userData.toJson()));
      await prefs.setBool('isLoggedIn', true);
    } catch (error) {
      print('Error saving user locally: $error');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.all(12),
          child: Text(
            message,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMainProfileView() {
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: widget.onClose,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // User profile section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: _accentGlassDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Balance',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Ksh ${_userData.balance.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: _glassCardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Bets',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _userData.numberOfBets.toString(),
                                      style: TextStyle(
                                        color: _emeraldLight,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Icon(
                                      Icons.sports_soccer,
                                      color: _emeraldLight.withOpacity(0.7),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: _glassCardDecoration,
                          child: Column(
                            children: [
                              _buildInfoItem(
                                'Username',
                                _userData.username,
                                Icons.person,
                              ),
                              SizedBox(height: 12),
                              _buildInfoItem(
                                'Phone',
                                _userData.phone,
                                Icons.phone,
                              ),
                              SizedBox(height: 12),
                              _buildInfoItem(
                                'Nickname',
                                _userData.nickname,
                                Icons.tag,
                              ),
                              SizedBox(height: 12),
                              _buildInfoItem(
                                'Club Fan',
                                _userData.clubFan,
                                Icons.sports_soccer,
                              ),
                              SizedBox(height: 12),
                              _buildInfoItem(
                                'Country Fan',
                                _userData.countryFan,
                                Icons.public,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _emeraldPrimary.withOpacity(0.25),
                _emeraldDark.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _emeraldPrimary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'Not set',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoUserView() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 60,
              color: Colors.white.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No user profile found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Please sign in to view your profile',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return SizedBox.shrink();

    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: _glassDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              if (_isLoading) ...[
                SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: _emeraldPrimary),
                  ),
                ),
              ] else if (_isNewUser) ...[
                _buildNoUserView(),
              ] else ...[
                _buildMainProfileView(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
