import 'dart:async';
import 'dart:math' show cos, sqrt, asin; // NEW: Added for distance calculation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:school_bus_tracking/services/constants.dart';

class SimulationService {
  final Map<String, Timer?> _busTimers = {};

  // Helper: Haversine formula to calculate distance in km
  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) * c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Helper: Send private notification to specific parent
  Future<void> _sendPrivateAlert(String email, String busId, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'message': message,
      'targetBus': busId,
      'targetUser': email.toLowerCase(), // NEW: Targeted to specific parent
      'timestamp': FieldValue.serverTimestamp(),
      'adminName': 'System Update',
    });
  }

  void startSimulation(String busId, String adminName, {Function? onComplete}) async {
    List<LatLng> selectedRoute;

    if (busId == 'BUS-A') {
      selectedRoute = RouteData.routeA;
    } else if (busId == 'BUS-B') {
      selectedRoute = RouteData.routeB;
    } else {
      selectedRoute = RouteData.routeC;
    }

    _busTimers[busId]?.cancel();

    // NEW: Fetch all parents for this specific bus to track their stops
    QuerySnapshot parentDocs = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'parent')
        .where('busId', isEqualTo: busId)
        .get();

    // Track who has already been notified this trip to avoid duplicate alerts
    Set<String> notifiedArrivingSoon = {};
    Set<String> notifiedReached = {};

    int currentIndex = 0;

    // Public Notify (Start of trip)
    await FirebaseFirestore.instance.collection('notifications').add({
      'message': "$busId has started the trip.",
      'targetBus': busId,
      'timestamp': FieldValue.serverTimestamp(),
      'adminName': adminName,
    });

    // Notify ADMIN Log
    await FirebaseFirestore.instance.collection('notifications').add({
      'message': "Trip Initiated: $busId has started ($adminName).",
      'targetBus': 'ADMIN',
      'timestamp': FieldValue.serverTimestamp(),
      'adminName': adminName,
    });

    _busTimers[busId] = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (currentIndex < selectedRoute.length) {
        LatLng currentPos = selectedRoute[currentIndex];

        // Update Bus Location in Firestore
        await FirebaseFirestore.instance.collection('buses').doc(busId).set({
          'latitude': currentPos.latitude,
          'longitude': currentPos.longitude,
          'status': 'active',
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // --- NEW: CHECK PROXIMITY FOR EVERY PARENT ---
        for (var doc in parentDocs.docs) {
          String email = doc.id;
          var data = doc.data() as Map<String, dynamic>;

          if (data.containsKey('stopLat') && data.containsKey('stopLng')) {
            LatLng stopPos = LatLng(data['stopLat'], data['stopLng']);
            double dist = _calculateDistance(currentPos, stopPos);

            // A. ARRIVING SOON (500 meters)
            if (dist <= 0.5 && dist > 0.05 && !notifiedArrivingSoon.contains(email)) {
              await _sendPrivateAlert(email, busId, "🚨 Bus $busId is Arriving Soon at your stop!");
              notifiedArrivingSoon.add(email);
            }

            // B. REACHED (50 meters)
            if (dist <= 0.05 && !notifiedReached.contains(email)) {
              await _sendPrivateAlert(email, busId, "✅ YOUR BUS HAS REACHED YOUR STOP");
              notifiedReached.add(email);
            }
          }
        }

        currentIndex++;
      } else {
        stopSimulation(busId, endReason: "(Route Completed)");
        if (onComplete != null) onComplete();
      }
    });
  }

  void stopSimulation(String busId, {String? endReason}) async {
    if (!_busTimers.containsKey(busId)) return;

    _busTimers[busId]?.cancel();
    _busTimers.remove(busId);

    await FirebaseFirestore.instance.collection('buses').doc(busId).update({
      'status': 'idle',
      'latitude': 0.0,
      'longitude': 0.0,
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'message': "Trip Ended: $busId has stopped ${endReason ?? ''}",
      'targetBus': 'ADMIN',
      'timestamp': FieldValue.serverTimestamp(),
      'adminName': 'System',
    });
  }
}