import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_bus_tracking/login%20page/login_screen.dart';
import 'package:school_bus_tracking/admin_tabs/user_management.dart';
import 'package:school_bus_tracking/admin_tabs/fleet_map.dart';
import 'package:school_bus_tracking/admin_tabs/notifications.dart';
import 'package:school_bus_tracking/admin_tabs/feedback.dart';
import 'package:school_bus_tracking/services/simulation_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final SimulationService _simulationService = SimulationService();

  final List<Widget> _pages = [
    const UserManagementTab(),
    const FleetMapTab(),
    const AdminNotificationTab(),
    const AdminFeedbackTab(),
  ];

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Renamed for clarity
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out of the Admin Panel?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                // 1. CAPTURE the Navigator and ScaffoldMessenger BEFORE the await
                // This 'freezes' the reference so we don't need 'context' later.
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  // 2. Perform the async work
                  await FirebaseAuth.instance.signOut();

                  // 3. Use the captured navigator (No context needed here!)
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                } catch (e) {
                  // 4. Use the captured messenger for errors
                  messenger.showSnackBar(
                    SnackBar(content: Text("Logout failed: $e")),
                  );
                }
              },
              child: const Text(
                "LOGOUT",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startAllBuses() {
    List<String> fleet = ['BUS-A', 'BUS-B', 'BUS-C'];
    for (String busId in fleet) {
      _simulationService.startSimulation(busId, "Admin Master");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Fleet simulation started! All buses are now active."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Start All Buses",
            icon: const Icon(Icons.play_circle_fill, size: 28),
            onPressed: _startAllBuses,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _showLogoutDialog,
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber[900],
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.person_add), label: "Users"),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: "Fleet"),
          const BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
              builder: (context, snapshot) {
                int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Badge(
                  label: Text(count.toString()),
                  isLabelVisible: count > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.message),
                );
              },
            ),
            label: "Feedback",
          ),
        ],
      ),
    );
  }
}