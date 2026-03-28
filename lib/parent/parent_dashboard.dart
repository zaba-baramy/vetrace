import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_bus_tracking/login%20page/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_bus_tracking/parent/parent_map_tab.dart';
import 'package:school_bus_tracking/parent/parent_notif_tab.dart';
import 'package:school_bus_tracking/parent/parent_feedback.dart';
import 'package:school_bus_tracking/parent/parent_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  int _lastSeenCount = 0;
  String? _busId;

  final List<Widget> _pages = [
    const ParentMapTab(),
    const ParentNotifTab(),
    const ParentFeedbackScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchBusId();
    _loadLastSeenCount();
  }

  void _fetchBusId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email!.toLowerCase())
          .get();
      if (mounted && doc.exists) {
        setState(() => _busId = doc.get('busId'));
      }
    }
  }

  Future<void> _loadLastSeenCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSeenCount = prefs.getInt('lastSeenNotifs') ?? 0;
    });
  }

  Future<void> _updateSavedCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeenNotifs', count);
    setState(() {
      _lastSeenCount = count;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                // 1. CAPTURE references before the async gap
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                // 2. Close dialog immediately
                Navigator.pop(dialogContext);

                try {
                  // 3. Optional: Clear local notification preferences on logout
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('lastSeenNotifs');

                  // 4. Perform Firebase Sign Out
                  await FirebaseAuth.instance.signOut();

                  // 5. Safe Navigation
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Logout failed: $e")),
                  );
                }
              },
              child: const Text(
                  "LOGOUT",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Portal"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: "My Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ParentProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue[900],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: _busId == null
                  ? null
                  : FirebaseFirestore.instance
                  .collection('notifications')
                  .where('targetBus', whereIn: [_busId, 'ALL']).snapshots(),
              builder: (context, snapshot) {
                final importantDocs = snapshot.hasData
                    ? snapshot.data!.docs.where((doc) {
                  String msg = (doc['message'] ?? "").toString().toLowerCase();
                  bool isRoutine = msg.contains("started") ||
                      msg.contains("stopped") ||
                      msg.contains("finished") ||
                      msg.contains("initiated");
                  return !isRoutine;
                }).toList()
                    : [];

                int currentTotal = importantDocs.length;

                if (_currentIndex == 1 && _lastSeenCount != currentTotal) {
                  Future.microtask(() => _updateSavedCount(currentTotal));
                }

                bool showBadge = currentTotal > _lastSeenCount;

                return Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (showBadge)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '${currentTotal - _lastSeenCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: "Alerts",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.message), label: "Feedback"),
        ],
      ),
    );
  }
}