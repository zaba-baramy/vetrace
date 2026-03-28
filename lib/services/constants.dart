import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteData {
  // Precise Farook College Main Gate
  static const LatLng farookCollege = LatLng(11.198125, 75.857481);

  // ROUTE A: Farook College -> Cheruvannur -> Meenchanda -> Kozhikode
  static const List<LatLng> routeA = [


    LatLng(11.198125, 75.857481), LatLng(11.1920798, 75.8557573), LatLng(11.183076, 75.845131),
    LatLng(11.18365, 75.83887), LatLng(11.17660, 75.83137), LatLng(11.189088, 75.829718),
    LatLng(11.194577, 75.823830), LatLng(11.19941, 75.81769), LatLng(11.206988, 75.809568),
    LatLng(11.212953, 75.805508), LatLng(11.213547, 75.803947),LatLng(11.2139798, 75.8019606),
    LatLng(11.216588, 75.801915), LatLng(11.226213, 75.801188), LatLng(11.236354, 75.804275),
    LatLng(11.241003, 75.803318), LatLng(11.255353, 75.791905), LatLng(11.258790, 75.791463),
    LatLng(11.259087, 75.790063), LatLng(11.259203, 75.785992),
  ];


  // ROUTE B: Farook College -> Ramanattukara -> Airport Road -> Kondotty
  static const List<LatLng> routeB = [
    LatLng(11.198144, 75.857752), LatLng(11.192509, 75.856169), LatLng(11.177788, 75.864771),
    LatLng(11.16978, 75.87513), LatLng(11.167178, 75.876022), LatLng(11.162634, 75.881895),
    LatLng(11.161383, 75.887721), LatLng(11.157609, 75.890087), LatLng(11.153230, 75.893335),
    LatLng(11.152096, 75.896685), LatLng(11.149814, 75.900590), LatLng(11.148285, 75.903765),
    LatLng(11.148651, 75.906201), LatLng(11.150242, 75.907969), LatLng(11.150265, 75.909821),
    LatLng(11.151642, 75.915481), LatLng(11.155520, 75.922857), LatLng(11.161412, 75.929321),
    LatLng(11.164514, 75.932526), LatLng(11.164833, 75.934412),
  ];

  // ROUTE C: Farook College -> Karadaparamba
  static const List<LatLng> routeC = [
    LatLng(11.198136, 75.857220), LatLng(11.192477, 75.856151), LatLng(11.198010, 75.859739),
    LatLng(11.199495, 75.859736), LatLng(11.199367, 75.862643), LatLng(11.199576, 75.864383),
    LatLng(11.199920, 75.865443), LatLng(11.200135, 75.866773), LatLng(11.200430, 75.870873),
    LatLng(11.200584, 75.873342), LatLng(11.204640, 75.876805), LatLng(11.205810, 75.877692),
    LatLng(11.203552, 75.880051), LatLng(11.203470, 75.882681), LatLng(11.202596, 75.887475),
    LatLng(11.203639, 75.889002), LatLng(11.204957, 75.889228), LatLng(11.205729, 75.891369),
    LatLng(11.206484, 75.893289), LatLng(11.209267, 75.894465),
  ];
}