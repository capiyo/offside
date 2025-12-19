import 'package:flutter/material.dart';
import 'package:offside/pages/posts_page.dart';
import 'package:offside/modals/profile_modal.dart'; // Import the modal
import '../pages/fixture_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showProfileModal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header with offside indicator and user profile
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
                          'Offside',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        
                        // User profile on the right
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showProfileModal = true;
                            });
                          },
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
                    Tab(
                      icon: Icon(Icons.article, size: 22),
                      text: 'news',
                    ),
                    Tab(
                      icon: Icon(Icons.calendar_today, size: 22),
                      text: 'fixtures',
                    ),
                    Tab(
                      icon: Icon(Icons.favorite, size: 22),
                      text: 'pledges',
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    PostsPage(),
                    FixturesPage(),
                    FixturesPage(),
                  ],
                ),
              ),
            ],
          ),

          // Profile Modal Overlay - FIXED: Remove const and provide required parameters
          if (_showProfileModal)
            ProfileModal(
              isOpen: _showProfileModal,
              onClose: () {
                setState(() {
                  _showProfileModal = false;
                });
              },
              onLogout: () {
                // Handle logout logic
                setState(() {
                  _showProfileModal = false;
                });
              },
              apiBaseUrl: 'https://fanclash-api.onrender.com',
            ),
        ],
      ),
    );
  }
}