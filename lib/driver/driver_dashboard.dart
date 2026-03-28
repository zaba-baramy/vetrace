import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/simulation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_bus_tracking/login%20page/login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final SimulationService _simulationService = SimulationService();
  String? _assignedBusId;
  String _driverName = "Driver";
  bool _isLoading = true;
  bool _isTripActive = false;
  bool _isArrivalReached = false;

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
  }

  Future<void> _fetchDriverData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email!.toLowerCase())
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _assignedBusId = userDoc.get('busId');
          _driverName = userDoc.get('name') ?? "Driver";
          _isLoading = false;
        });
        _checkActiveStatus();
      }
    }
  }

  void _checkActiveStatus() async {
    if (_assignedBusId != null) {
      var doc = await FirebaseFirestore.instance.collection('buses').doc(_assignedBusId).get();
      if (doc.exists && doc.data()?['status'] == 'active') {
        setState(() => _isTripActive = true);
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: Text(_isTripActive
              ? "Warning: You have an active trip. Logging out will stop the bus tracking for parents. Proceed?"
              : "Are you sure you want to log out?"),
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

                // 2. Close the dialog immediately using the dialog's context
                Navigator.pop(dialogContext);

                try {
                  // 3. Cleanup simulation if active
                  if (_isTripActive && _assignedBusId != null) {
                    _simulationService.stopSimulation(_assignedBusId!, endReason: "(Logged Out)");
                  }

                  // 4. Perform the sign out
                  await FirebaseAuth.instance.signOut();

                  // 5. Navigate using the captured navigator (Safe from async gaps)
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Logout error: $e")),
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
        title: Text(_assignedBusId != null ? "Bus: $_assignedBusId" : "Driver Dashboard"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.grey),
            Text("Welcome, $_driverName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Assigned to: $_assignedBusId", style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("START TRIP"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(250, 60),
              ),
              onPressed: _isTripActive
                  ? null
                  : () async {
                if (_assignedBusId != null) {
                  setState(() {
                    _isTripActive = true;
                    _isArrivalReached = false;
                  });

                  _simulationService.startSimulation(_assignedBusId!, _driverName, onComplete: () {
                    if (mounted) {
                      setState(() => _isArrivalReached = true);
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Trip Started for $_assignedBusId")),
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: Icon(_isArrivalReached ? Icons.check_circle : Icons.stop),
              label: Text(_isArrivalReached ? "FINISH TRIP" : "STOP TRIP"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isArrivalReached ? Colors.orange : Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(250, 60),
              ),
              onPressed: !_isTripActive
                  ? null
                  : () {
                if (_assignedBusId != null) {
                  if (_isArrivalReached) {
                    setState(() {
                      _isTripActive = false;
                      _isArrivalReached = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Trip records finalized.")),
                    );
                  } else {
                    setState(() {
                      _isTripActive = false;
                      _isArrivalReached = false;
                    });

                    _simulationService.stopSimulation(
                      _assignedBusId!,
                      endReason: "(Stopped by Driver: $_driverName)",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Trip Ended.")),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 12, color: _isTripActive ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(_isTripActive ? "Status: LIVE" : "Status: OFFLINE",
                    style: TextStyle(fontWeight: FontWeight.bold, color: _isTripActive ? Colors.green : Colors.red)),
              ],
            )
          ],
        ),
      ),
    );
  }
}