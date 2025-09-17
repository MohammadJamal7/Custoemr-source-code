import 'dart:developer';

import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/osm_map_search_place.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:provider/provider.dart';

import '../model/search_info.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? selectedLocation;
  GoogleMapController? mapController;
  Place? place;
  TextEditingController textController = TextEditingController();
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _setUserLocation();
  }

  Future<void> _setUserLocation() async {
    try {
      final locationData = await Utils.getCurrentLocation();
      LatLng userLatLng = LatLng(locationData.latitude, locationData.longitude);
      setState(() {
        selectedLocation = userLatLng;
        markers = {
          Marker(
            markerId: const MarkerId('selected-location'),
            position: userLatLng,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          )
        };
      });
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 14));
      await _updatePlace(userLatLng);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _updatePlace(LatLng position) async {
    place = await Nominatim.reverseSearch(
      lat: position.latitude,
      lon: position.longitude,
      zoom: 14,
      addressDetails: true,
      extraTags: true,
      nameDetails: true,
      language: 'ar',
    );
    setState(() {});
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      selectedLocation = position;
      markers = {
        Marker(
          markerId: const MarkerId('selected-location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        )
      };
    });
    await _updatePlace(position);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Picker'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation ??
                  LatLng(31.5, 34.5), // مركز افتراضي (مثلاً فلسطين)
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              if (selectedLocation != null) {
                mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(selectedLocation!, 14));
              }
            },
            markers: markers,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
            },
          ),

          // Custom Zoom Controls
          Positioned(
            bottom: 200,
            right: 18,
            child: Column(
              children: [
                // Zoom In Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      try {
                        if (mapController != null) {
                          await mapController!.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        }
                      } catch (e) {
                        print('Zoom in error: $e');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: AppColors.darkModePrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Zoom Out Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      try {
                        if (mapController != null) {
                          await mapController!.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        }
                      } catch (e) {
                        print('Zoom out error: $e');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.remove,
                        color: AppColors.darkModePrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // عرض الاسم المكتشف أسفل الشاشة
          if (place?.displayName != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place?.displayName ?? '',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          size: 40, color: Colors.black),
                      onPressed: () {
                        Get.back(result: place);
                      },
                    ),
                  ],
                ),
              ),
            ),

          // مربع البحث في أعلى الخريطة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 40),
            child: InkWell(
              onTap: () async {
                final value = await Get.to(const OsmSearchPlacesApi());
                if (value != null) {
                  if (value is SearchInfo) {
                    textController.text = value.address.toString();
                    LatLng latLng =
                        LatLng(value.point.latitude, value.point.longitude);
                    setState(() {
                      selectedLocation = latLng;
                      markers = {
                        Marker(
                          markerId: const MarkerId('selected-location'),
                          position: latLng,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed),
                        )
                      };
                    });
                    mapController
                        ?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
                    await _updatePlace(latLng);
                  } else if (value is Map<String, dynamic>) {
                    // Handle OSM Nominatim result directly
                    final displayName = value['display_name'].toString();
                    textController.text = displayName;
                    
                    final lat = double.parse(value['lat'].toString());
                    final lon = double.parse(value['lon'].toString());
                    final latLng = LatLng(lat, lon);
                    
                    setState(() {
                      selectedLocation = latLng;
                      markers = {
                        Marker(
                          markerId: const MarkerId('selected-location'),
                          position: latLng,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed),
                        )
                      };
                    });
                    mapController
                        ?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
                    await _updatePlace(latLng);}
                }
              },
              child: buildTextField(
                title: "Search Address".tr,
                textController: textController,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(
          Icons.my_location,
          color: themeChange.getThem()
              ? AppColors.darkModePrimary
              : AppColors.primary,
        ),
      ),
    );
  }

  Widget buildTextField(
      {required String title, required TextEditingController textController}) {
    return TextField(
      controller: textController,
      readOnly: true,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_on, color: Colors.black),
        fillColor: Colors.white,
        filled: true,
        hintText: title,
        hintStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }
}
