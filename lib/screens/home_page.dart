import 'package:flutter/material.dart';
import 'package:clash/pages/posts_page.dart';
import 'package:clash/modals/login_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/fixture_page.dart';
import '../pages/chats_history.dart';
import '../pages/bottom_navigation.dart';
// Add this import at the top of your home_page.dart
import '../modals/add_post_modal.dart'; // Adjust path as needed

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomIndex = 0;
  bool _showPostModal = false; //
  bool _showModal = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _togglePostModal() {
    setState(() {
      _showPostModal = true;
    });
  }

  // ← ADD THIS METHOD
  void _closePostModal() {
    setState(() {
      _showPostModal = false;
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userString = prefs.getString('user');

    setState(() {
      _isLoggedIn = isLoggedIn;
      if (userString != null) {
        _userData = jsonDecode(userString);
      }
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isLoggedIn = false;
      _userData = null;
      _showModal = false;
    });
  }

  void _toggleModal() {
    setState(() {
      _showModal = true;
    });
  }

  void _closeModal() {
    setState(() {
      _showModal = false;
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Show content based on bottom navigation selection
          _buildContent(),

          // Modal Overlay with double somersault animation
          if (_showModal)
            AnimatedModalOverlay(
              isLoggedIn: _isLoggedIn,
              userData: _userData,
              onClose: _closeModal,
              onLoginSuccess: () {
                _checkLoginStatus();
              },
              onLogout: _handleLogout,
            ),

          AddPostModal(
            isOpen: _showPostModal,
            onClose: _closePostModal,
            onPostCreated: () {
              print('Post created successfully!');
            },
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTapped,
        onAddPressed: _togglePostModal, // ← THIS IS THE PROBLEM
      ),
    );
  }

  Widget _buildContent() {
    // If Home is selected (index 0), show the original tab structure
    if (_currentBottomIndex == 0) {
      return Column(
        children: [
          // Header with clash logo and user profile
          Container(
            color: const Color(0xFF18181B),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Offside on the left
                    const Text(
                      'clash',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    // User profile on the right
                    GestureDetector(
                      onTap: _toggleModal,
                      child: Row(
                        children: [
                          // Username
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Man United',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Capiyo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),

                          // Profile image
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 2,
                              ),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://upload.wikimedia.org/wikipedia/en/7/7a/Manchester_United_FC_crest.svg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Bar
          Container(
            color: const Color(0xFF18181B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF10B981),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6EE7B7),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.article, size: 22), text: 'news'),
                Tab(
                  icon: Icon(Icons.calendar_today, size: 22),
                  text: 'fixtures',
                ),
                Tab(icon: Icon(Icons.favorite, size: 22), text: 'history'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [PostsPage(), FixturesPage(), ChatHistoryPage()],
            ),
          ),
        ],
      );
    }

    // For other bottom navigation items, show placeholder pages
    return _buildPlaceholderPage();
  }

  Widget _buildPlaceholderPage() {
    String title;
    IconData icon;
    Color color;

    switch (_currentBottomIndex) {
      case 1:
        title = 'Trending';
        icon = Icons.trending_up;
        color = Colors.orange;
        break;
      case 2:
        title = 'Create Post';
        icon = Icons.add_circle;
        color = const Color(0xFF10B981);
        break;
      case 3:
        title = 'Chats';
        icon = Icons.chat_bubble;
        color = Colors.blue;
        break;
      case 4:
        title = 'Profile';
        icon = Icons.person;
        color = Colors.purple;
        break;
      default:
        title = 'Page';
        icon = Icons.error;
        color = Colors.grey;
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header for placeholder pages
          Container(
            color: const Color(0xFF18181B),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    // User profile on the right (same as home)
                    GestureDetector(
                      onTap: _toggleModal,
                      child: Row(
                        children: [
                          // Username
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Man United',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Capiyo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),

                          // Profile image
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 2,
                              ),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://upload.wikimedia.org/wikipedia/en/7/7a/Manchester_United_FC_crest.svg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Placeholder content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, size: 60, color: color),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Coming Soon',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      'This page is under development',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
}

class AnimatedModalOverlay extends StatefulWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final VoidCallback onClose;
  final VoidCallback onLoginSuccess;
  final VoidCallback onLogout;

  const AnimatedModalOverlay({
    super.key,
    required this.isLoggedIn,
    required this.userData,
    required this.onClose,
    required this.onLoginSuccess,
    required this.onLogout,
  });

  @override
  State<AnimatedModalOverlay> createState() => _AnimatedModalOverlayState();
}

class _AnimatedModalOverlayState extends State<AnimatedModalOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        // Two complete rotations (2 * 2π = 4π radians = 720°)
        final angle = _flipAnimation.value * 3.14159 * 2;

        // Show content only after animation completes
        final showContent = _flipAnimation.value >= 1.95;

        if (showContent) {
          // Animation complete - show modal without transform
          return widget.isLoggedIn
              ? ProfileModal(
                  userData: widget.userData,
                  onClose: _handleClose,
                  onLogout: widget.onLogout,
                )
              : LoginModal(
                  isOpen: true,
                  onClose: _handleClose,
                  onLoginSuccess: widget.onLoginSuccess,
                );
        } else {
          // Still animating - show visible flipping card
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(angle)
            ..scale(0.6); // 40% smaller (100% - 40% = 60%)

          return Stack(
            children: [
              // Dark backdrop
              Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
              // Flipping card with content
              Center(
                child: Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: BoxConstraints(maxHeight: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A2520), Color(0xFF0D3328)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(0xFF10B981).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon at top
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981).withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF10B981).withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Title
                          Text(
                            widget.isLoggedIn ? 'Profile' : 'Welcome',
                            style: TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Subtitle
                          Text(
                            widget.isLoggedIn
                                ? (widget.userData?['username'] ?? 'User')
                                : 'Sign in to continue',
                            style: TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 24),

                          // Loading indicator
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class ProfileModal extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onClose;
  final VoidCallback onLogout;

  const ProfileModal({
    super.key,
    required this.userData,
    required this.onClose,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
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
                  Color(0xFF0A2520).withOpacity(0.95),
                  Color(0xFF0D3328).withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 50,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData?['username'] ?? 'User',
                              style: TextStyle(
                                color: Color(0xFFD1FAE5),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userData?['phone'] ?? '',
                              style: TextStyle(
                                color: Color(0xFFA7F3D0),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balance',
                                  style: TextStyle(
                                    color: Color(0xFFA7F3D0),
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ksh ${userData?['balance'] ?? '0'}',
                                  style: TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF10B981),
                              size: 32,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: onLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
