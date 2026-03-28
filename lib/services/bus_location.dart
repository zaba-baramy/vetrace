class BusLocation {
  final double lat;
  final double lng;
  final bool isRunning;

  BusLocation({
    required this.lat,
    required this.lng,
    required this.isRunning,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'isRunning': isRunning,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
