import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/live_tracking_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LiveTrackingController>(
      init: LiveTrackingController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            elevation: 2,
            backgroundColor: AppColors.primary,
            title: Text("Map view".tr),
            leading: InkWell(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          body: Obx(
            () => Stack(
              children: [
                GoogleMap(
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.terrain,
                  zoomControlsEnabled: false,
                  polylines: Set<Polyline>.of(controller.polyLines.values),
                  padding: const EdgeInsets.only(top: 22.0),
                  markers: Set<Marker>.of(controller.markers.values),
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                    Factory<ScaleGestureRecognizer>(
                        () => ScaleGestureRecognizer()),
                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                    Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer()),
                  },
                  onMapCreated: (GoogleMapController mapController) {
                    try {
                      controller.mapController = mapController;
                    } catch (e) {
                      print("Map controller creation error: $e");
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    zoom: 15,
                    target: LatLng(
                      Constant.currentLocation?.latitude ?? 45.521563,
                      Constant.currentLocation?.longitude ?? -122.677433,
                    ),
                  ),
                ),
                // Custom Zoom Controls
                Positioned(
                  bottom: 80,
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
                              if (controller.mapController != null) {
                                await controller.mapController!.animateCamera(
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
                              if (controller.mapController != null) {
                                await controller.mapController!.animateCamera(
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
              ],
            ),
          ),
        );
      },
    );
  }
}
