import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// OpenStreetMap map (no API key) that draws the driving route between
/// [from] and [to] and shows its distance.
///
/// The route comes from the public OSRM demo server. If it can't be reached
/// (offline / rate limited) a straight line is drawn instead, so the map never
/// stays empty. For heavy production traffic point [routingBaseUrl] to your own
/// OSRM / GraphHopper / OpenRouteService instance.
class OsmRouteMap extends StatefulWidget {
  final LatLng from;
  final LatLng to;
  final String? fromLabel;
  final String? toLabel;
  final Color routeColor;
  final double height;
  final String routingBaseUrl;

  const OsmRouteMap({
    super.key,
    required this.from,
    required this.to,
    this.fromLabel,
    this.toLabel,
    this.routeColor = const Color(0xFF8B1038),
    this.height = 260,
    this.routingBaseUrl = 'https://router.project-osrm.org',
  });

  @override
  State<OsmRouteMap> createState() => _OsmRouteMapState();
}

class _OsmRouteMapState extends State<OsmRouteMap> {
  List<LatLng> _route = const [];
  double? _distanceMeters;
  bool _loading = true;
  bool _approximate = false;
  bool _routeFound = false;
  final MapController _mapController = MapController();
  LatLng? _me;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant OsmRouteMap old) {
    super.didUpdateWidget(old);
    if (old.from != widget.from || old.to != widget.to) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    setState(() => _loading = true);
    final from = widget.from, to = widget.to;
    List<LatLng> points = const [];
    double distance = Geolocator.distanceBetween(from.latitude, from.longitude, to.latitude, to.longitude);
    bool approximate = true;
    try {
      final uri = Uri.parse(
        '${widget.routingBaseUrl}/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = body['routes'] as List?;
        if (body['code'] == 'Ok' && routes != null && routes.isNotEmpty) {
          final coords = (routes.first['geometry']['coordinates'] as List)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (coords.length >= 2) {
            points = coords;
            distance = (routes.first['distance'] as num).toDouble();
            approximate = false;
          }
        }
      }
    } catch (_) {
      // keep the straight-line fallback
    }
    if (!mounted) return;
    setState(() {
      _route = points;
      _routeFound = !approximate;
      _distanceMeters = distance;
      _approximate = approximate;
      _loading = false;
    });
    _fitToRoute();
  }

  void _fitToRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_route.isEmpty ? [widget.from, widget.to] : _route),
          padding: const EdgeInsets.all(44),
          maxZoom: 17,
        ));
      } catch (_) {}
    });
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      Position? p;
      try {
        p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
        );
      } catch (_) {
        p = await Geolocator.getLastKnownPosition();
      }
      if (p != null && mounted) {
        final me = LatLng(p.latitude, p.longitude);
        setState(() => _me = me);
        _mapController.move(me, 16);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _distanceText() {
    final m = _distanceMeters ?? 0;
    final text = m >= 1000 ? '${(m / 1000).toStringAsFixed(2)} Km' : '${m.round()} m';
    return _approximate ? '≈ $text' : text;
  }

  Widget _pin(Color color, IconData icon) => Icon(icon, color: color, size: 38);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: Stack(children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([widget.from, widget.to]),
                padding: const EdgeInsets.all(44),
                maxZoom: 17,
              ),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.femalecar.eon',
              ),
              // Only the real road route is drawn - never a straight line.
              if (_routeFound)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _route,
                    strokeWidth: 5,
                    color: widget.routeColor,
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white,
                  ),
                ]),
              MarkerLayer(markers: [
                Marker(
                  point: widget.from, width: 44, height: 44, alignment: Alignment.topCenter,
                  child: _pin(Colors.blue.shade700, Icons.my_location),
                ),
                if (_me != null)
                  Marker(
                    point: _me!, width: 26, height: 26,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                  ),
                Marker(
                  point: widget.to, width: 44, height: 44, alignment: Alignment.topCenter,
                  child: _pin(Colors.red.shade700, Icons.location_on),
                ),
              ]),
            ],
          ),

          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),

          PositionedDirectional(
            bottom: 10, end: 10,
            child: Material(
              color: Colors.white, shape: const CircleBorder(), elevation: 3,
              child: InkWell(
                key: const Key('osm_my_location_button'),
                customBorder: const CircleBorder(),
                onTap: _goToMyLocation,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _locating
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.my_location, size: 22, color: widget.routeColor),
                ),
              ),
            ),
          ),

          PositionedDirectional(
            top: 8, start: 8, end: 8,
            child: Row(children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: _loading
                      ? const SizedBox(width: 16, height: 16)
                      : Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _distanceText(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
