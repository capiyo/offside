import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function()? onLoginSuccess;

  const LoginModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.onLoginSuccess,
  });

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _loginUsernameController =
      TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final TextEditingController _registerUsernameController =
      TextEditingController();
  final TextEditingController _registerPhoneController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();

  final String _loginUrl = "https://fanclash-api.onrender.com/api/auth/login";
  final String _registerUrl =
      "https://fanclash-api.onrender.com/api/auth/register";

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _loadUserData(String token, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final betsResponse = await http.get(
        Uri.parse('https://fanclash-api.onrender.com/api/bets/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (betsResponse.statusCode == 200) {
        await prefs.setString('userBets', betsResponse.body);
      }

      final profileResponse = await http.get(
        Uri.parse('https://fanclash-api.onrender.com/api/user/profile/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (profileResponse.statusCode == 200) {
        await prefs.setString('userProfile', profileResponse.body);
      }

      final gamesResponse = await http.get(
        Uri.parse('https://fanclash-api.onrender.com/api/games/active'),
      );

      if (gamesResponse.statusCode == 200) {
        await prefs.setString('availableGames', gamesResponse.body);
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': _loginUsernameController.text.trim(),
          'password': _loginPasswordController.text.trim(),
        }),
      );

      final result = jsonDecode(response.body);

      if (result['token'] != null && result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("usertoken", result['token']);
        await prefs.setString("user", jsonEncode(result['user']));
        await prefs.setBool("isLoggedIn", true);

        await _loadUserData(result['token'], result['user']['id']);

        _showToast('Welcome back!', isError: false);

        widget.onLoginSuccess?.call();

        _loginUsernameController.clear();
        _loginPasswordController.clear();

        widget.onClose();
      } else {
        _showToast(result['error'] ?? 'Invalid credentials', isError: true);
      }
    } catch (error) {
      _showToast('Connection error', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': _registerUsernameController.text.trim(),
          'phone': _registerPhoneController.text.trim(),
          'password': _registerPasswordController.text.trim(),
        }),
      );

      final result = jsonDecode(response.body);

      if (result['token'] != null && result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("usertoken", result['token']);
        await prefs.setString("user", jsonEncode(result['user']));
        await prefs.setBool("isLoggedIn", true);

        await _loadUserData(result['token'], result['user']['id']);

        _showToast('Account created! Ksh 100 bonus', isError: false);

        widget.onLoginSuccess?.call();

        _registerUsernameController.clear();
        _registerPhoneController.clear();
        _registerPasswordController.clear();

        widget.onClose();
      } else {
        _showToast(result['error'] ?? 'Registration failed', isError: true);
      }
    } catch (error) {
      _showToast('Connection error', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0D3328).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: _isLogin
                    ? BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      size: 14,
                      color: _isLogin
                          ? Color(0xFFD1FAE5)
                          : Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isLogin
                            ? Color(0xFFD1FAE5)
                            : Colors.white.withOpacity(0.6),
                        fontWeight: _isLogin
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: !_isLogin
                    ? BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 14,
                      color: !_isLogin
                          ? Color(0xFFD1FAE5)
                          : Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 12,
                        color: !_isLogin
                            ? Color(0xFFD1FAE5)
                            : Colors.white.withOpacity(0.6),
                        fontWeight: !_isLogin
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            'Username',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
          ),
          SizedBox(height: 2),
          TextFormField(
            controller: _loginUsernameController,
            style: TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Enter username',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
              filled: true,
              fillColor: Color(0xFF0D3328).withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),

          SizedBox(height: 8),

          Text(
            'Password',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
          ),
          SizedBox(height: 2),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Enter password',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
              filled: true,
              fillColor: Color(0xFF0D3328).withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                padding: EdgeInsets.zero,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length < 6) return 'Min 6 characters';
              return null;
            },
          ),

          SizedBox(height: 12),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            'Username',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
          ),
          SizedBox(height: 2),
          TextFormField(
            controller: _registerUsernameController,
            style: TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Choose username',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
              filled: true,
              fillColor: Color(0xFF0D3328).withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length < 3) return 'Min 3 characters';
              return null;
            },
          ),

          SizedBox(height: 8),

          Text(
            'Phone',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
          ),
          SizedBox(height: 2),
          TextFormField(
            controller: _registerPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: '0712345679',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
              filled: true,
              fillColor: Color(0xFF0D3328).withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value))
                return 'Invalid phone';
              return null;
            },
          ),

          SizedBox(height: 8),

          Text(
            'Password',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
          ),
          SizedBox(height: 2),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Create password',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
              filled: true,
              fillColor: Color(0xFF0D3328).withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                padding: EdgeInsets.zero,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length < 6) return 'Min 6 characters';
              return null;
            },
          ),

          SizedBox(height: 12),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMessage() {
    List<Map<String, String>> chatMessages = [
      {
        'text': 'Hey there! Ready to join the action?',
        'color': '0xFF1A4838', // Dark green
      },
      {
        'text': 'Get Ksh 100 bonus when you register!',
        'color': '0xFF216E4E', // Medium green
      },
      {
        'text': 'Predict matches, win rewards!',
        'color': '0xFF2A8F64', // Brighter green
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: chatMessages.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, String> message = entry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: 6, left: 40, right: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 220),
                  child: CustomPaint(
                    painter: SpeechBubblePainter(
                      color: Color(int.parse(message['color']!)),
                      isOwn: true,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        message['text']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6),
              CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF10B981).withOpacity(0.3),
                child: Icon(
                  Icons.smart_toy,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A2520).withOpacity(0.98),
                  Color(0xFF0D3328).withOpacity(0.98),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 6, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF10B981).withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLogin ? 'Welcome Back' : 'Join FanClash',
                              style: TextStyle(
                                color: Color(0xFFD1FAE5),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isLogin
                                  ? 'Sign in to continue'
                                  : 'Create your account',
                              style: TextStyle(
                                color: Color(0xFFA7F3D0),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildToggleSwitch(),
                            SizedBox(height: 12),

                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              child: _isLogin
                                  ? _buildLoginForm()
                                  : _buildRegisterForm(),
                            ),

                            SizedBox(height: 8),

                            TextButton(
                              onPressed: () =>
                                  setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin
                                    ? 'Need an account? Register'
                                    : 'Have an account? Sign In',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 8),

                      Container(
                        width: 2,
                        height: 280,
                        color: Color(0xFF10B981).withOpacity(0.2),
                      ),

                      SizedBox(width: 8),

                      Expanded(child: _buildInfoMessage()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color color;
  final bool isOwn;

  SpeechBubblePainter({required this.color, required this.isOwn});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isOwn) {
      // Right-aligned speech bubble (pointing left)
      path.moveTo(size.width - 12, 0);
      path.lineTo(8, 0);
      path.quadraticBezierTo(0, 0, 0, 8);
      path.lineTo(0, size.height - 8);
      path.quadraticBezierTo(0, size.height, 8, size.height);
      path.lineTo(size.width - 8, size.height);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - 8,
      );
      path.lineTo(size.width, 8);
      path.quadraticBezierTo(size.width, 0, size.width - 8, 0);

      // Speech bubble tail (pointing left)
      path.lineTo(size.width - 4, 0);
      path.lineTo(size.width - 10, -6);
      path.lineTo(size.width - 16, 0);
      path.lineTo(size.width - 12, 0);
    } else {
      // Left-aligned speech bubble (pointing right)
      path.moveTo(12, 0);
      path.lineTo(size.width - 8, 0);
      path.quadraticBezierTo(size.width, 0, size.width, 8);
      path.lineTo(size.width, size.height - 8);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - 8,
        size.height,
      );
      path.lineTo(8, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - 8);
      path.lineTo(0, 8);
      path.quadraticBezierTo(0, 0, 8, 0);

      // Speech bubble tail (pointing right)
      path.lineTo(4, 0);
      path.lineTo(10, -6);
      path.lineTo(16, 0);
      path.lineTo(12, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
