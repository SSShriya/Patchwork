import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickLocationMap extends StatefulWidget {
  final LatLng? initialLocation;
  const PickLocationMap({super.key, this.initialLocation});

  @override
  State<PickLocationMap> createState() => _PickLocationMapState();
}

class _PickLocationMapState extends State<PickLocationMap> {
  late final MapController _mapController;
  LatLng _centre = const LatLng(51.5074, -0.1278); // london default
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLocation != null) {
      _centre = widget.initialLocation!;
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF84DCC6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Event Location'),
        backgroundColor: teal,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              final location = _mapController.camera.center;
              debugPrint('confirming location: $location');
              Navigator.pop(context, location);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centre,
              initialZoom: 14,
              onMapReady: () {
                setState(() {
                  _centre = _mapController.camera.center;
                });
              },
              onMapEvent: (event) {
                // Track centre as map moves
                if (event is MapEventMove || event is MapEventScrollWheelZoom) {
                  setState(() {
                    _isMoving = true;
                    _centre = _mapController.camera.center;
                  });
                }
                if (event is MapEventMoveEnd ||
                    event is MapEventFlingAnimationEnd) {
                  setState(() {
                    _isMoving = false;
                    _centre = _mapController.camera.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.drp',
              ),
            ],
          ),

          // Centred crosshair pin — animates up while dragging
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(bottom: _isMoving ? 24 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_pin,
                    size: 48,
                    color: _isMoving ? teal : teal,
                  ),
                  // Shadow dot below pin
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isMoving ? 12 : 8,
                    height: _isMoving ? 4 : 6,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coordinates pill at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 16,
                    color: Color(0xFF84DCC6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_centre.latitude.toStringAsFixed(5)}, ${_centre.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
