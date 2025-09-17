import 'package:cloud_firestore/cloud_firestore.dart';

class SearchInfo {
  final String? address;
  final GeoPoint point;

  SearchInfo({this.address, required this.point});
}
