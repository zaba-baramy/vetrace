import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FleetMapTab extends StatefulWidget {
  const FleetMapTab({super.key});

  @override
  State<FleetMapTab> createState() => _FleetMapTabState();
}

class _FleetMapTabState extends State<FleetMapTab> {
  GoogleMapController? _mapController;
  BitmapDescriptor _busIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  void _loadCustomMarker() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/bus_marker.png',
      );
      setState(() => _busIcon = icon);
    } catch (e) {
      setState(() => _busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('buses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        List<Marker> markersList = [];
        List<LatLng> points = [];

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;

          double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
          double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

          // Only show markers for buses that are currently active
          if (lat != 0.0 && data['status'] == 'active') {
            LatLng pos = LatLng(lat, lng);
            points.add(pos);

            markersList.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: pos,
                icon: _busIcon,
                infoWindow: InfoWindow(
                  title: "Bus ${doc.id}",
                  snippet: "Status: ${data['status']}",
                ),
              ),
            );
          }
        }

        if (points.isNotEmpty && _mapController != null) {
          _zoomToFitBuses(points);
        }

        return GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: const CameraPosition(
            target: LatLng(11.198125, 75.857481),
            zoom: 14,
          ),
          markers: markersList.toSet(),
        );
      },
    );
  }


  void _zoomToFitBuses(List<LatLng> points) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
    } else {
      LatLngBounds bounds = _calculateBounds(points);
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}