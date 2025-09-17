import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../constant/constant.dart';

class OsmSearchPlaceController extends GetxController {
  Rx<TextEditingController> searchTxtController = TextEditingController().obs;
  RxList<Map<String, dynamic>> suggestionsList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    searchTxtController.value.addListener(() {
      _onChanged();
    });
  }

  void _onChanged() {
    fetchAddress(searchTxtController.value.text);
  }

  Future<void> fetchAddress(String text) async {
    if (text.isEmpty) {
      suggestionsList.clear();
      return;
    }
    log(":: fetchAddress :: $text");
    try {
      // استدعاء API نومتيم للبحث
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$text&format=json&addressdetails=1&limit=10&accept-language=ar');

      final response = await http.get(uri, headers: {
        'User-Agent': 'your_app_name', // ضع اسم تطبيقك هنا
        'Accept-Language': 'ar', // Added Accept-Language header
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // فلترة النتائج حسب الدولة أو السماح لكل النتائج إذا كانت 'all'
        final filtered = data.where((place) {
          final address = place['address'] as Map<String, dynamic>? ?? {};
          final country = (address['country'] ?? '').toString().toLowerCase();
          final displayName = (place['display_name'] ?? '').toString().toLowerCase();
          if (Constant.regionCountry.toLowerCase() == 'all') {
            return true;
          }
          return country == Constant.regionCountry.toLowerCase() ||
              displayName.contains(Constant.regionCountry.toLowerCase());
        }).toList();

        suggestionsList.value = List<Map<String, dynamic>>.from(filtered);
      } else {
        log("Error from Nominatim API: ${response.statusCode}");
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
