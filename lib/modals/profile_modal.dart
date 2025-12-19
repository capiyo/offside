import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final VoidCallback? onLogout;
  final String apiBaseUrl;

  const ProfileModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.onLogout,
    this.apiBaseUrl = 'https://fanclash-api.onrender.com',
  });

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  
  bool _isProcessing = false;
  bool _isSyncing = false;
  bool _isNewUser = false;
  
  TextEditingController _depositAmountController = TextEditingController();
  TextEditingController _depositPhoneController = TextEditingController();
  TextEditingController _withdrawAmountController = TextEditingController();
  TextEditingController _withdrawPhoneController = TextEditingController();
  
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _nicknameController = TextEditingController();
  TextEditingController _clubFanController = TextEditingController();
  TextEditingController _countryFanController = TextEditingController();
  
  double? _recentTransaction;
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

  // Glass morphism styling constants (without ImageFilter)
  final _glassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.05),
      ],
    ),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
    border: Border.all(
      color: Colors.white.withOpacity(0.15),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 40,
        spreadRadius: -10,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  final _glassCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.03),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.12),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 25,
        spreadRadius: 0,
      ),
    ],
  );

  final _glassInputDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.12),
        Colors.white.withOpacity(0.04),
      ],
    ),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Colors.white.withOpacity(0.18),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 0,
      ),
    ],
  );

  final _glassButtonDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        Colors.white.withOpacity(0.06),
      ],
    ),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Colors.white.withOpacity(0.22),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 15,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.05),
        blurRadius: 5,
        spreadRadius: 1,
        offset: Offset(-2, -2),
      ),
    ],
  );

  final _accentGlassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF10B981).withOpacity(0.35),
        Color(0xFF059669).withOpacity(0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Color(0xFF10B981).withOpacity(0.25),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF10B981).withOpacity(0.25),
        blurRadius: 25,
        spreadRadius: 0,
      ),
    ],
  );

  final _blueGlassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.blue.withOpacity(0.35),
        Colors.blueAccent.withOpacity(0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.blue.withOpacity(0.25),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.25),
        blurRadius: 25,
        spreadRadius: 0,
      ),
    ],
  );

  final _redGlassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.red.withOpacity(0.35),
        Colors.redAccent.withOpacity(0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.red.withOpacity(0.25),
      width: 1,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      _checkUserSession();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _checkUserSession();
    }
  }

  Future<void> _checkUserSession() async {
    try {
      setState(() => _isSyncing = true);
      
      // Simulating SharedPreferences check
      final isForcedNewUser = false;
      final sessionToken = '';
      final userProfile = '';
      
      if (isForcedNewUser || sessionToken.isEmpty || userProfile.isEmpty) {
        setState(() {
          _isNewUser = true;
          _currentPage = 1;
        });
        return;
      }
      
      await _loadUserFromBackend();
    } catch (error) {
      print('Session check error: $error');
      setState(() {
        _isNewUser = true;
        _currentPage = 1;
      });
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<UserData?> _findUserByPhone(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      
      final phoneFormats = <String>[cleanPhone];
      
      if (cleanPhone.startsWith('0')) {
        phoneFormats.add(cleanPhone.substring(1));
      }
      
      if (cleanPhone.length == 9) {
        phoneFormats.add('254$cleanPhone');
      } else if (cleanPhone.length == 10 && cleanPhone.startsWith('0')) {
        phoneFormats.add('254${cleanPhone.substring(1)}');
      }
      
      for (final phoneFormat in phoneFormats) {
        try {
          final response = await http.get(
            Uri.parse('${widget.apiBaseUrl}/api/profile/profile/phone/$phoneFormat'),
          );
          
          if (response.statusCode == 200) {
            final backendUser = jsonDecode(response.body);
            
            return UserData(
              userId: backendUser['user_id'] ?? '',
              username: backendUser['username'] ?? '',
              phone: phone,
              nickname: backendUser['nickname'] ?? '',
              clubFan: backendUser['club_fan'] ?? '',
              countryFan: backendUser['country_fan'] ?? '',
              balance: (backendUser['balance'] ?? 0).toDouble(),
              numberOfBets: backendUser['number_of_bets'] ?? 0,
            );
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

  Future<void> _loadUserFromBackend() async {
    try {
      setState(() => _isSyncing = true);
      
      String localPhone = '';
      
      if (localPhone.isNotEmpty) {
        final backendUser = await _findUserByPhone(localPhone);
        
        if (backendUser != null) {
          setState(() {
            _userData = backendUser;
            _depositPhoneController.text = backendUser.phone;
            _withdrawPhoneController.text = backendUser.phone;
          });
          
          _currentPage = 0;
          return;
        }
      }
      
      setState(() {
        _isNewUser = true;
        _currentPage = 1;
      });
    } catch (error) {
      print('Error loading user: $error');
      setState(() {
        _isNewUser = true;
        _currentPage = 1;
      });
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _syncFromBackend() async {
    if (_userData.phone.isEmpty) return;
    
    try {
      setState(() => _isSyncing = true);
      final backendUser = await _findUserByPhone(_userData.phone);
      
      if (backendUser != null) {
        setState(() => _userData = backendUser);
        _showSnackBar('Synced with server!', Colors.green);
      } else {
        print('No data from backend');
        _showSnackBar('Failed to sync with server', Colors.red);
      }
    } catch (error) {
      print('Error syncing from backend: $error');
      _showSnackBar('Failed to sync with server', Colors.red);
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleSave() async {
    if (_usernameController.text.trim().isEmpty && _phoneController.text.trim().isEmpty) {
      _showSnackBar('Please enter at least username or phone', Colors.red);
      return;
    }

    try {
      setState(() => _isProcessing = true);

      final formattedPhone = _formatPhoneTo254(_phoneController.text);
      final userId = _userData.userId.isNotEmpty 
          ? _userData.userId 
          : 'user_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
      
      final profileData = {
        'user_id': userId,
        'username': _usernameController.text.isNotEmpty ? _usernameController.text : "User",
        'phone': formattedPhone,
        'nickname': _nicknameController.text,
        'club_fan': _clubFanController.text,
        'country_fan': _countryFanController.text,
        'balance': _userData.balance,
        'number_of_bets': _userData.numberOfBets,
      };

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/profile/create_profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        final updatedData = UserData(
          username: _usernameController.text,
          phone: formattedPhone,
          clubFan: _clubFanController.text,
          nickname: _nicknameController.text,
          countryFan: _countryFanController.text,
          balance: (result['balance'] ?? _userData.balance).toDouble(),
          numberOfBets: result['number_of_bets'] ?? _userData.numberOfBets,
          userId: result['user_id'] ?? userId,
        );
        
        setState(() {
          _userData = updatedData;
          _depositPhoneController.text = updatedData.phone;
          _withdrawPhoneController.text = updatedData.phone;
          _isNewUser = false;
        });
        
        _showSnackBar('Profile saved successfully!', Colors.green);
        setState(() => _currentPage = 0);
      } else {
        final updateResponse = await http.put(
          Uri.parse('${widget.apiBaseUrl}/api/profile/profiles/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(profileData),
        );
        
        if (updateResponse.statusCode == 200) {
          final result = jsonDecode(updateResponse.body);
          
          final updatedData = UserData(
            username: _usernameController.text,
            phone: formattedPhone,
            clubFan: _clubFanController.text,
            nickname: _nicknameController.text,
            countryFan: _countryFanController.text,
            balance: (result['balance'] ?? _userData.balance).toDouble(),
            numberOfBets: result['number_of_bets'] ?? _userData.numberOfBets,
            userId: result['user_id'] ?? userId,
          );
          
          setState(() {
            _userData = updatedData;
            _depositPhoneController.text = updatedData.phone;
            _withdrawPhoneController.text = updatedData.phone;
            _isNewUser = false;
          });
          
          _showSnackBar('Profile updated successfully!', Colors.green);
          setState(() => _currentPage = 0);
        } else {
          throw Exception('Failed to save profile');
        }
      }
    } catch (error) {
      print('Save error: $error');
      _showSnackBar('Failed to save profile', Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDeposit() async {
    final amount = double.tryParse(_depositAmountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Enter valid amount', Colors.red);
      return;
    }

    try {
      setState(() => _isProcessing = true);

      String userId = _userData.userId;
      if (userId.isEmpty) {
        final backendUser = await _findUserByPhone(_depositPhoneController.text);
        if (backendUser != null) {
          userId = backendUser.userId;
          setState(() => _userData = backendUser);
        } else {
          throw Exception('User not found. Please save your profile first.');
        }
      }

      final cleanPhone = _depositPhoneController.text.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = cleanPhone.startsWith('0') 
          ? '254${cleanPhone.substring(1)}'
          : cleanPhone.length == 9 
              ? '254$cleanPhone'
              : cleanPhone;

      final stkResponse = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/mpesa/stk-push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': formattedPhone,
          'amount': amount.toString(),
          'account_reference': userId,
          'transaction_desc': "FanClash Deposit"
        }),
      );

      if (stkResponse.statusCode != 200) {
        throw Exception('Failed to initiate payment');
      }

      final stkResult = jsonDecode(stkResponse.body);
      final checkoutRequestID = stkResult['checkout_request_id'];
      
      if (checkoutRequestID == null) {
        throw Exception('Payment initiation failed');
      }

      bool paymentConfirmed = false;
      int attempts = 0;
      const maxAttempts = 30;
      
      while (!paymentConfirmed && attempts < maxAttempts) {
        attempts++;
        await Future.delayed(const Duration(seconds: 3));
        
        try {
          final statusResponse = await http.post(
            Uri.parse('${widget.apiBaseUrl}/api/mpesa/check-payment-status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'checkout_request_id': checkoutRequestID}),
          );
          
          if (statusResponse.statusCode == 200) {
            final statusData = jsonDecode(statusResponse.body);
            
            if (statusData['status'] == 'completed') {
              paymentConfirmed = true;
              
              final updateResponse = await http.post(
                Uri.parse('${widget.apiBaseUrl}/api/profile/update-balance'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'user_id': userId,
                  'balance': _userData.balance + amount
                }),
              );
              
              if (updateResponse.statusCode == 200) {
                final updatedUser = jsonDecode(updateResponse.body);
                setState(() {
                  _userData = UserData(
                    username: _userData.username,
                    phone: _userData.phone,
                    clubFan: _userData.clubFan,
                    nickname: _userData.nickname,
                    countryFan: _userData.countryFan,
                    balance: updatedUser['balance'] ?? (_userData.balance + amount),
                    numberOfBets: _userData.numberOfBets,
                    userId: _userData.userId,
                  );
                });
                
                _showSnackBar('Deposit successful! +Ksh ${amount.toStringAsFixed(0)} added!', Colors.green);
                _depositAmountController.clear();
                setState(() => _currentPage = 0);
                return;
              }
            } else if (statusData['status'] == 'failed') {
              throw Exception(statusData['result_desc'] ?? 'Payment failed');
            }
          }
        } catch (pollError) {
          print('Poll error: $pollError');
        }
      }
      
      if (!paymentConfirmed) {
        throw Exception('Payment timeout. Please check if payment was completed.');
      }
      
    } catch (error) {
      print('Deposit error: $error');
      _showSnackBar(error.toString(), Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleWithdraw() async {
    final amount = double.tryParse(_withdrawAmountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Enter valid amount', Colors.red);
      return;
    }

    if (amount < 50) {
      _showSnackBar('Minimum withdrawal is Ksh 50', Colors.red);
      return;
    }

    if (_userData.balance < amount) {
      _showSnackBar('Insufficient balance. You have Ksh ${_userData.balance.toStringAsFixed(0)}', Colors.red);
      return;
    }

    final phoneNumber = _withdrawPhoneController.text.isNotEmpty 
        ? _withdrawPhoneController.text 
        : _userData.phone;
    
    if (phoneNumber.isEmpty) {
      _showSnackBar('Please set your phone number first', Colors.red);
      return;
    }

    try {
      setState(() => _isProcessing = true);

      final formattedPhone = _formatPhoneTo254(phoneNumber);
      
      final withdrawResponse = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/mpesa/b2c/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': formattedPhone,
          'amount': amount.toString(),
          'command_id': 'BusinessPayment',
          'remarks': 'Withdrawal from FanClash',
          'occasion': 'Cash Withdrawal'
        }),
      );

      final withdrawResult = jsonDecode(withdrawResponse.body);

      if (withdrawResponse.statusCode != 200) {
        final errorMessage = withdrawResult['error'] ?? 
                          withdrawResult['response_description'] ?? 
                          'Withdrawal request failed';
        throw Exception(errorMessage);
      }

      if (withdrawResult['response_code'] != "0" && withdrawResult['response_code'] != "0.00") {
        final errorMsg = withdrawResult['response_description'] ?? 'M-Pesa transaction failed';
        throw Exception(errorMsg);
      }

      final newBalance = _userData.balance - amount;

      final updateResponse = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/profile/update-balance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userData.userId,
          'balance': newBalance
        }),
      );
      
      if (updateResponse.statusCode == 200) {
        final updatedUser = jsonDecode(updateResponse.body);
        
        setState(() {
          _userData = UserData(
            username: _userData.username,
            phone: _userData.phone,
            clubFan: _userData.clubFan,
            nickname: _userData.nickname,
            countryFan: _userData.countryFan,
            balance: updatedUser['balance'] ?? newBalance,
            numberOfBets: _userData.numberOfBets,
            userId: _userData.userId,
          );
          _recentTransaction = -amount;
        });
        
        _showSnackBar('Withdrawal of Ksh ${amount.toStringAsFixed(0)} processing!', Colors.green);
        _withdrawAmountController.clear();
        setState(() => _currentPage = 0);
        
        Future.delayed(const Duration(seconds: 3), () {
          setState(() => _recentTransaction = null);
        });
      } else {
        _showSnackBar('Withdrawal sent but balance update failed. Contact support.', Colors.orange);
      }

    } catch (error) {
      print('Withdrawal error: $error');
      _showSnackBar(error.toString(), Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handleLogout() {
    setState(() {
      _userData = UserData(
        username: '',
        phone: '',
        clubFan: '',
        nickname: '',
        countryFan: '',
        balance: 0,
        numberOfBets: 0,
        userId: '',
      );
      _currentPage = 1;
      _isNewUser = true;
      _depositAmountController.clear();
      _depositPhoneController.clear();
      _withdrawAmountController.clear();
      _withdrawPhoneController.clear();
      _recentTransaction = null;
    });
    
    widget.onLogout?.call();
    _showSnackBar('Successfully logged out!', Colors.green);
  }

  String _formatPhoneTo254(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    
    if (clean.length == 12 && clean.startsWith('254')) {
      return clean;
    }
    
    if (clean.length == 10 && clean.startsWith('0')) {
      return '254${clean.substring(1)}';
    }
    
    if (clean.length == 9) {
      return '254$clean';
    }
    
    return clean;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(16),
          child: Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildViewPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_isNewUser) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(24),
                decoration: _glassCardDecoration,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: _accentGlassDecoration,
                      child: Icon(
                        Icons.person_add_alt_1,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your profile to start betting',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => setState(() => _currentPage = 1),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          decoration: _accentGlassDecoration,
                          child: Center(
                            child: Text(
                              'Create Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _isSyncing ? null : _loadUserFromBackend,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          decoration: _glassButtonDecoration,
                          child: Center(
                            child: Text(
                              _isSyncing ? 'Checking...' : 'Already have an account?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Balance Cards with Glass Effect
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: _accentGlassDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Ksh ${_userData.balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_recentTransaction != null) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _recentTransaction! > 0 
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _recentTransaction! > 0 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _recentTransaction! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 12,
                                    color: _recentTransaction! > 0 ? Colors.green[200] : Colors.red[200],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ksh ${_recentTransaction!.abs().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: _recentTransaction! > 0 
                                          ? Colors.green[200]
                                          : Colors.red[200],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => setState(() => _currentPage = 2),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.arrow_upward, size: 16, color: Colors.white70),
                                          SizedBox(width: 6),
                                          Text(
                                            'Add Funds',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_userData.balance > 50) ...[
                                SizedBox(width: 8),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => setState(() => _currentPage = 3),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.arrow_downward, size: 16, color: Colors.blue[200]),
                                            SizedBox(width: 6),
                                            Text(
                                              'Withdraw',
                                              style: TextStyle(
                                                color: Colors.blue[200],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: _glassCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Bets',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            _userData.numberOfBets.toString(),
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Icon(
                              Icons.sports_soccer,
                              color: Color(0xFF10B981).withOpacity(0.7),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Profile Info with Glass Cards
              Container(
                padding: EdgeInsets.all(20),
                decoration: _glassCardDecoration,
                child: Column(
                  children: [
                    _buildInfoItem('Username', _userData.username, Icons.person),
                    SizedBox(height: 16),
                    _buildInfoItem('Phone', _userData.phone, Icons.phone),
                    SizedBox(height: 16),
                    _buildInfoItem('Nickname', _userData.nickname, Icons.tag),
                    SizedBox(height: 16),
                    _buildInfoItem('Club Fan', _userData.clubFan, Icons.sports_soccer),
                    SizedBox(height: 16),
                    _buildInfoItem('Country Fan', _userData.countryFan, Icons.public),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isNewUser = true;
                            _currentPage = 1;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: _glassButtonDecoration,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.switch_account, size: 18, color: Colors.white70),
                                SizedBox(width: 8),
                                Text(
                                  'Switch Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _handleLogout,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: _redGlassDecoration,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 18, color: Colors.red[200]),
                                SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.red[200],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Icon(icon, size: 20, color: Color(0xFF10B981)),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'Not set',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: _glassCardDecoration,
              child: Column(
                children: [
                  _buildGlassTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 16),
                  _buildGlassTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  _buildGlassTextField(
                    controller: _nicknameController,
                    label: 'Nickname',
                    icon: Icons.tag,
                  ),
                  SizedBox(height: 16),
                  _buildGlassTextField(
                    controller: _clubFanController,
                    label: 'Club Fan',
                    icon: Icons.sports_soccer,
                  ),
                  SizedBox(height: 16),
                  _buildGlassTextField(
                    controller: _countryFanController,
                    label: 'Country Fan',
                    icon: Icons.public,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: _accentGlassDecoration.copyWith(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF10B981).withOpacity(0.2),
                    Color(0xFF10B981).withOpacity(0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Balance and betting statistics are managed automatically.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _isProcessing ? null : _handleSave,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  decoration: _accentGlassDecoration,
                  child: Center(
                    child: _isProcessing
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isNewUser ? 'Create Profile' : 'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: _glassInputDecoration,
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white, fontSize: 14),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70, fontSize: 14),
          floatingLabelStyle: TextStyle(color: Color(0xFF10B981), fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }

  Widget _buildDepositPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: _glassCardDecoration,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: _accentGlassDecoration,
                    child: Icon(
                      Icons.arrow_upward,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Deposit Funds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add money to your account',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            Container(
              padding: EdgeInsets.all(20),
              decoration: _accentGlassDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ksh ${_userData.balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            Container(
              padding: EdgeInsets.all(20),
              decoration: _glassCardDecoration,
              child: Column(
                children: [
                  _buildGlassTextField(
                    controller: _depositPhoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  _buildGlassTextField(
                    controller: _depositAmountController,
                    label: 'Amount (Ksh)',
                    icon: Icons.money,
                    keyboardType: TextInputType.number,
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Quick Select',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [100, 500, 1000].map((amount) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _depositAmountController.text = amount.toString(),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Ksh $amount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You'll receive an M-Pesa prompt on your phone.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => setState(() => _currentPage = 0),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: _glassButtonDecoration,
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _isProcessing || 
                          _depositAmountController.text.isEmpty || 
                          _depositPhoneController.text.isEmpty
                          ? null
                          : _handleDeposit,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: _accentGlassDecoration,
                        child: Center(
                          child: _isProcessing
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Deposit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
      ),
    );
  }

  Widget _buildWithdrawPage() {
    final canWithdraw = _userData.balance > 50;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: _glassCardDecoration,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: _blueGlassDecoration,
                    child: Icon(
                      Icons.arrow_downward,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Withdraw Cash',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Withdraw to M-Pesa',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            Container(
              padding: EdgeInsets.all(20),
              decoration: _blueGlassDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!canWithdraw)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                'Min: Ksh 50',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ksh ${_userData.balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            Container(
              padding: EdgeInsets.all(20),
              decoration: _glassCardDecoration,
              child: Column(
                children: [
                  _buildGlassTextField(
                    controller: _withdrawPhoneController,
                    label: 'M-Pesa Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  _buildGlassTextField(
                    controller: _withdrawAmountController,
                    label: 'Amount (Ksh)',
                    icon: Icons.money,
                    keyboardType: TextInputType.number,
                  ),
                  
                  SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Min: Ksh 50',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Max: Ksh ${_userData.balance.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Quick Select',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [50, 100, 500].map((amount) {
                      final isDisabled = amount > _userData.balance;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: isDisabled 
                                  ? null
                                  : () => _withdrawAmountController.text = amount.toString(),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDisabled
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDisabled
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Ksh $amount',
                                    style: TextStyle(
                                      color: isDisabled
                                          ? Colors.white30
                                          : Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.money, color: Colors.blue[200], size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "No fees! Withdrawals are free.",
                            style: TextStyle(
                              color: Colors.blue[200],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => setState(() => _currentPage = 0),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: _glassButtonDecoration,
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _isProcessing || 
                          _withdrawAmountController.text.isEmpty || 
                          double.tryParse(_withdrawAmountController.text) == null ||
                          double.parse(_withdrawAmountController.text) < 50 ||
                          double.parse(_withdrawAmountController.text) > _userData.balance
                          ? null
                          : _handleWithdraw,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: _blueGlassDecoration,
                        child: Center(
                          child: _isProcessing
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Withdraw',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Semi-transparent backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        
        // Modal content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              0,
              widget.isOpen ? 0 : 1000,
              0,
            ),
            child: Container(
              decoration: _glassDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: widget.onClose,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _currentPage == 0 ? Icons.close : Icons.arrow_back,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              _currentPage == 0
                                  ? (_isNewUser ? 'Welcome!' : 'Profile')
                                  : _currentPage == 1
                                      ? (_userData.username.isNotEmpty && !_isNewUser 
                                          ? 'Edit Profile' 
                                          : 'Setup Profile')
                                      : _currentPage == 2
                                          ? 'Deposit Funds'
                                          : 'Withdraw Cash',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        if (_currentPage == 0 && _userData.username.isNotEmpty && !_isNewUser)
                          Row(
                            children: [
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: _isSyncing ? null : () => _syncFromBackend(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isSyncing
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                                            ),
                                          )
                                        : Icon(
                                            Icons.sync,
                                            color: Color(0xFF10B981),
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => setState(() => _currentPage = 1),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(0xFF10B981).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Content
                  IndexedStack(
                    index: _currentPage,
                    children: [
                      _buildViewPage(),
                      _buildEditPage(),
                      _buildDepositPage(),
                      _buildWithdrawPage(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}