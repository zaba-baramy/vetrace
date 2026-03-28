import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' show cos, sqrt, asin;

class ParentMapTab extends StatefulWidget {
  const ParentMapTab({super.key});

  @override
  State<ParentMapTab> createState() => _ParentMapTabState();
}

// UPDATED: Added with AutomaticKeepAliveClientMixin
class _ParentMapTabState extends State<ParentMapTab> with AutomaticKeepAliveClientMixin {
  LatLng _busLocation = const LatLng(11.198125, 75.857481);
  LatLng? _homeStop;
  String? _assignedBusId;
  GoogleMapController? _mapController;
  BitmapDescriptor _busIcon = BitmapDescriptor.defaultMarker;
  bool _isTripActive = false;
  double _distanceToHome = 0.0;

  bool _hasReached = false;
  DateTime? _arrivalTime;

  // REQUIRED: Tell Flutter to keep this state alive
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadCustomMarker();
  }

  void _loadCustomMarker() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/bus_marker.png',
      );
      setState(() => _busIcon = icon);
    } catch (e) {
      setState(() => _busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure));
    }
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.email!.toLowerCase()).get();
      if (mounted && doc.exists) {
        setState(() {
          _assignedBusId = doc.get('busId');
          double? lat = doc.data()?.containsKey('stopLat') == true ? doc.get('stopLat') : null;
          double? lng = doc.data()?.containsKey('stopLng') == true ? doc.get('stopLng') : null;

          if (lat != null && lng != null) {
            _homeStop = LatLng(lat, lng);
          }
        });
      }
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) * c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    // REQUIRED: Must call super.build
    super.build(context);

    if (_assignedBusId == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('buses').doc(_assignedBusId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
          double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
          String status = data['status'] ?? 'idle';

          if (status == 'active' && lat != 0.0 && lng != 0.0) {
            _busLocation = LatLng(lat, lng);
            _isTripActive = true;

            if (_homeStop != null) {
              _distanceToHome = _calculateDistance(_busLocation, _homeStop!);

              // Threshold check: Stay reached once triggered until trip ends
              if (!_hasReached && _distanceToHome <= 0.05) {
                _hasReached = true;
                _arrivalTime = DateTime.now();
              }
            }

            _mapController?.animateCamera(CameraUpdate.newLatLng(_busLocation));
          } else {
            // Only reset when trip actually ends/stops
            _isTripActive = false;
            _hasReached = false;
            _arrivalTime = null;
          }
        }

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(target: _busLocation, zoom: 15),
              markers: {
                if (_isTripActive)
                  Marker(
                    markerId: const MarkerId("bus"),
                    position: _busLocation,
                    icon: _busIcon,
                  ),
                if (_homeStop != null)
                  Marker(
                    markerId: const MarkerId("home"),
                    position: _homeStop!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
              },
            ),

            if (_isTripActive && _homeStop != null)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _hasReached
                        ? Colors.green[700]
                        : (_distanceToHome < 0.5 ? Colors.orange[800] : Colors.blue[900]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)],
                  ),
                  child: Row(
                    children: [
                      Icon(
                          _hasReached ? Icons.check_circle : Icons.directions_bus,
                          color: Colors.white
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasReached
                              ? "THE BUS REACHED YOUR STOP AT ${DateFormat('hh:mm a').format(_arrivalTime ?? DateTime.now())}"
                              : (_distanceToHome < 0.5
                              ? "ARRIVING SOON! (${(_distanceToHome * 1000).toInt()}m)"
                              : "Distance: ${_distanceToHome.toStringAsFixed(1)} km"),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_isTripActive)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bus_alert, size: 50, color: Colors.amber),
                          const SizedBox(height: 15),
                          const Text("Trip Inactive", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Bus $_assignedBusId is not currently running."),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}