import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LiveMapWidget extends StatefulWidget {
  final LatLng source;
  final LatLng? destination;
  final String? driverId;
  final bool showRoute;
  final bool isRideActive;
  final bool isRideInProgress;

  const LiveMapWidget({
    super.key,
    required this.source,
    this.destination,
    this.driverId,
    this.showRoute = false,
    this.isRideActive = false,
    this.isRideInProgress = false,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  bool _isFollowingDriver = true;
  StreamSubscription<DocumentSnapshot>? _driverSubscription;
  DriverUserModel? _driverModel;
  
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _departureIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _initMapAssets();
    
    if (widget.driverId != null && widget.driverId!.isNotEmpty) {
      _setupDriverLocationListener();
    } else {
      _initStaticMap();
    }
  }

  Future<void> _initMapAssets() async {
    try {
      // Load the same assets as live tracking
      final Uint8List departure = await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
      final Uint8List destination = await Constant().getBytesFromAsset('assets/images/dropoff.png', 100);
      final Uint8List driver = await Constant().getBytesFromAsset('assets/images/ic_cab.png', 50); // Original size

      _departureIcon = BitmapDescriptor.fromBytes(departure);
      _destinationIcon = BitmapDescriptor.fromBytes(destination);
      _carIcon = BitmapDescriptor.fromBytes(driver);
      
      if (mounted) {
        setState(() {
          // Force update markers if driver model is already loaded
          if (_driverModel != null && _driverModel!.location != null) {
            _updateMarkers(LatLng(
              _driverModel!.location!.latitude!,
              _driverModel!.location!.longitude!
            ));
          }
        });
      }
    } catch (e) {
      print('Error loading map assets: $e');
      _departureIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow); // Use yellow for car if custom icon fails
    }
  }

  void _setupDriverLocationListener() {
    // Cancel any existing subscription
    _driverSubscription?.cancel();
    
    // Listen to driver location updates in real-time
    _driverSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(widget.driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final driverData = snapshot.data();
        if (driverData != null) {
          setState(() {
            _driverModel = DriverUserModel.fromJson(driverData);
            _updateMapWithDriverLocation();
          });
        }
      }
    }, onError: (e) {
      print('Driver location listener error: $e');
    });
  }

  void _updateMapWithDriverLocation() {
    if (_driverModel?.location == null) return;
    
    // Update driver marker
    final driverLocation = LatLng(
      _driverModel!.location!.latitude!,
      _driverModel!.location!.longitude!
    );
    
    // Update markers
    _updateMarkers(driverLocation);
    
    // Update route if needed
    if (widget.showRoute) {
      _fetchRoute(driverLocation);
    }
    
    // Center on driver if following mode is enabled
    if (_isFollowingDriver && _mapController != null) {
      _centerOnDriver(driverLocation);
    }
    
    setState(() {
      _loading = false;
    });
  }
  
  void _centerOnDriver(LatLng driverLocation) {
    if (_mapController == null) return;
    
    // If ride is in progress, show route between driver and destination
    if (widget.isRideInProgress && widget.destination != null) {
      _updateCameraLocation(driverLocation, widget.destination!);
    } 
    // If ride is active but not in progress, show route between driver and pickup
    else if (widget.isRideActive) {
      _updateCameraLocation(driverLocation, widget.source);
    }
    // Otherwise just center on driver
    else {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        driverLocation,
        15.0,
      ));
    }
  }

  void _updateMarkers(LatLng driverLocation) {
    if (_departureIcon == null || _destinationIcon == null || _carIcon == null) return;
    
    final markers = <Marker>{};
    
    // Always add pickup marker
    markers.add(Marker(
      markerId: const MarkerId('Pickup'),
      position: widget.source,
      icon: _departureIcon!,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndex: 1,
    ));
    
    // Add destination marker if available
    if (widget.destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('Destination'),
        position: widget.destination!,
        icon: _destinationIcon!,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 1,
      ));
    }
    
    // Add driver marker - make it more prominent
    markers.add(Marker(
      markerId: const MarkerId('Driver'),
      position: driverLocation,
      icon: _carIcon!,
      rotation: _driverModel?.rotation ?? 0.0,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndex: 3, // Higher zIndex to ensure it's on top
      visible: true,
      draggable: false,
      consumeTapEvents: true,
      onTap: () {
        // Re-center on driver when tapped
        if (_mapController != null) {
          setState(() {
            _isFollowingDriver = true;
          });
          _centerOnDriver(driverLocation);
        }
      },
    ));
    
    setState(() {
      _markers = markers;
    });
  }

  Future<void> _fetchRoute(LatLng driverLocation) async {
    try {
      if (!mounted) return;
      
      final apiKey = Constant.mapAPIKey;
      final LatLng destination;
      
      // If ride is in progress, route is from driver to dropoff
      if (widget.isRideInProgress && widget.destination != null) {
        destination = widget.destination!;
      } 
      // Otherwise route is from driver to pickup
      else {
        destination = widget.source;
      }
      
      final origin = '${driverLocation.latitude},${driverLocation.longitude}';
      final dest = '${destination.latitude},${destination.longitude}';
      
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey&mode=driving';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylineCoords = _decodePolyline(points);
          
          if (mounted) {
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: AppColors.primary,
                  width: 4,
                  points: polylineCoords,
                ),
              };
            });
          }
        }
      }
    } catch (e) {
      print('Route fetch error: $e');
    }
  }

  void _initStaticMap() {
    if (_departureIcon == null) return;
    
    // Just show the pickup location with marker
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('Pickup'),
          position: widget.source,
          icon: _departureIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 1,
        ),
      };
      _loading = false;
    });
  }

  Future<void> _updateCameraLocation(LatLng source, LatLng destination) async {
    if (_mapController == null || !mounted) return;

    try {
      // Calculate bounds to include both points
      LatLngBounds bounds;

      if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
        bounds = LatLngBounds(southwest: destination, northeast: source);
      } else if (source.longitude > destination.longitude) {
        bounds = LatLngBounds(
          southwest: LatLng(source.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, source.longitude)
        );
      } else if (source.latitude > destination.latitude) {
        bounds = LatLngBounds(
          southwest: LatLng(destination.latitude, source.longitude),
          northeast: LatLng(source.latitude, destination.longitude)
        );
      } else {
        bounds = LatLngBounds(southwest: source, northeast: destination);
      }

      // Add minimal padding to bounds to maximize route visibility
      // This makes the route touch the map borders as requested
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 10);
      await _mapController!.animateCamera(cameraUpdate);
    } catch (e) {
      print('Camera update error: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.source,
            zoom: 15,
          ),
          markers: _markers,
          polylines: _polylines,
          mapType: MapType.normal,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false, // We'll add custom zoom controls
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
          compassEnabled: false,
          mapToolbarEnabled: false,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
            Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
          },
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            if (widget.driverId != null && _driverModel != null && _driverModel!.location != null) {
              final driverLocation = LatLng(
                _driverModel!.location!.latitude!,
                _driverModel!.location!.longitude!
              );
              _centerOnDriver(driverLocation);
            }
          },
          onCameraMove: (_) {
            // Disable follow mode when user interacts with map
            _isFollowingDriver = false;
          },
        ),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        // Zoom controls (top-right as per original design)
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              // Zoom in button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                  onPressed: () {
                    if (_mapController != null) {
                      _mapController!.animateCamera(CameraUpdate.zoomIn());
                    }
                  },
                ),
              ),
              const SizedBox(height: 6),
              // Zoom out button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.remove, size: 18, color: AppColors.primary),
                  onPressed: () {
                    if (_mapController != null) {
                      _mapController!.animateCamera(CameraUpdate.zoomOut());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // Recenter button (show whenever driver is available) - bottom-right
        if (widget.driverId != null && _driverModel != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.my_location, size: 18, color: AppColors.primary),
                onPressed: () {
                  if (_driverModel?.location != null) {
                    setState(() {
                      _isFollowingDriver = true;
                    });
                    _centerOnDriver(LatLng(
                      _driverModel!.location!.latitude!,
                      _driverModel!.location!.longitude!
                    ));
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}
