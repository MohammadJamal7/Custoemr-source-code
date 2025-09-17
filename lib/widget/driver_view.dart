import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/review/reviews_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../utils/DarkThemeProvider.dart';

class DriverView extends StatelessWidget {
  final String? driverId;
  final String? amount;
  final String? name;
  final String? carName;
  final String? carModel;
  final String? carColor;
  final String? carNumber;

  const DriverView(
      {super.key,
      this.driverId,
      this.amount,
      this.name,
      this.carName,
      this.carModel,
      this.carColor,
      this.carNumber});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DriverUserModel?>(
        future: FireStoreUtils.getDriver(driverId.toString()),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const SizedBox();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else {
                log("Amount: $amount");
                if (snapshot.data == null) {
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Get.to(
                            ReviewsScreen(
                              driverId: driverId ?? '',
                              driverName: name.toString() == "null"
                                  ? ""
                                  : name.toString(),
                              orders: "0",
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: CachedNetworkImage(
                                height: 50,
                                width: 50,
                                imageUrl: Constant.userPlaceHolder,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Constant.loader(),
                                errorWidget: (context, url, error) =>
                                    Image.network(Constant.userPlaceHolder),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Asynchronous".tr,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 22,
                                              color: AppColors.ratingColour,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                                Constant.calculateReview(
                                                    reviewCount: "0.0",
                                                    reviewSum: "0.0"),
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                            amount: amount.toString()),
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                DriverUserModel driverModel = snapshot.data!;
                return Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        Get.to(
                          ReviewsScreen(
                            driverId: driverId ?? '',
                            driverName: name.toString() == "null"
                                ? driverModel.fullName.toString()
                                : name.toString(),
                            orders: 0.toString(),
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: CachedNetworkImage(
                              height: 50,
                              width: 50,
                              imageUrl: driverModel.profilePic.toString(),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Constant.loader(),
                              errorWidget: (context, url, error) =>
                                  Image.network(Constant.userPlaceHolder),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverModel.fullName.toString(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Reorganized row with better spacing
                                Row(
                                  children: [
                                    // Price (moved to left)
                                    Container(
                                      constraints: BoxConstraints(maxWidth: 80),
                                      child: Text(
                                        Constant.amountShow(amount: amount.toString()),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    
                                    // AC Indicator (in middle)
                                    if (driverModel.vehicleInformation?.is_AC == true) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.ac_unit,
                                              size: 14,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              'مكيفة',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.not_interested_outlined,
                                              size: 14,
                                              color: Colors.red[300],
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              'بدون',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[300],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    
                                    // Rating (moved to right)
                                    const Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: AppColors.ratingColour,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            Constant.calculateReview(
                                              reviewCount: driverModel.reviewsCount.toString(),
                                              reviewSum: driverModel.reviewsSum.toString(),
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(thickness: 1),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('نوع السيارة',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('الموديل',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('اللون',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('رقم اللوحة',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                Constant.localeVehicleType(
                                    driverModel
                                        .vehicleInformation!.vehicleType!),
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.only(top: 10, left: 10, right: 10),
                              child: Text(
                                (() {
                                  final String? year = driverModel.vehicleInformation?.vehicle_year?.toString();
                                  final String? cm = carModel;
                                  String pick(String? v) {
                                    if (v == null) return '';
                                    final s = v.trim();
                                    if (s.isEmpty) return '';
                                    if (s.toLowerCase() == 'null') return '';
                                    return s;
                                  }
                                  final resolved = pick(year).isNotEmpty
                                      ? pick(year)
                                      : (pick(cm).isNotEmpty ? pick(cm) : '-');
                                  if (resolved == '-') {
                                    log('DriverView: vehicle year missing for driverId=${driverId}. vehicleInformation=${driverModel.vehicleInformation?.toJson()}');
                                  }
                                  return resolved;
                                })(),
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                getLocalizedColorName(
                                    driverModel.vehicleInformation!
                                            .vehicleColor ??
                                        ''),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              child: Text(
                                driverModel.vehicleInformation!.vehicleNumber ??
                                    '',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }
            default:
              return const Text('Error');
          }
        });
  }

  String getLocalizedColorName(String colorName) {
    if (colorName.isEmpty) return '';
    final String src = colorName.toLowerCase().trim();
    final String lang = Constant.getLanguage().code ?? 'en';

    // English -> Arabic
    const Map<String, String> enToAr = {
      'red': 'أحمر',
      'blue': 'أزرق',
      'green': 'أخضر',
      'black': 'أسود',
      'white': 'أبيض',
      'yellow': 'أصفر',
      'orange': 'برتقالي',
      'gray': 'رمادي',
      'grey': 'رمادي',
      'silver': 'فضي',
      'brown': 'بني',
      'purple': 'بنفسجي',
      'pink': 'وردي',
      'gold': 'ذهبي',
      'beige': 'بيج',
      'maroon': 'خمري',
      'navy': 'كحلي',
      'teal': 'تركوازي',
    };

    // Arabic -> English
    const Map<String, String> arToEn = {
      'أحمر': 'Red',
      'أزرق': 'Blue',
      'أخضر': 'Green',
      'أسود': 'Black',
      'أبيض': 'White',
      'أصفر': 'Yellow',
      'برتقالي': 'Orange',
      'رمادي': 'Gray',
      'فضي': 'Silver',
      'بني': 'Brown',
      'بنفسجي': 'Purple',
      'وردي': 'Pink',
      'ذهبي': 'Gold',
      'بيج': 'Beige',
      'خمري': 'Maroon',
      'كحلي': 'Navy',
      'تركوازي': 'Teal',
    };

    if (lang == 'ar') {
      // If incoming is English, map to Arabic
      if (enToAr.containsKey(src)) return enToAr[src]!;
      return colorName; // already Arabic or unknown
    } else {
      // If incoming is Arabic, map to English (Title Case)
      final String? mapped = arToEn[colorName];
      if (mapped != null) return mapped;
      // If incoming is English lowercase, Title Case it for display
      String title = colorName;
      if (enToAr.containsKey(src)) {
        title = src[0].toUpperCase() + src.substring(1);
      }
      return title;
    }
  }

  Color getColorFromName(String colorName, BuildContext context) {
    switch (colorName.toLowerCase()) {
      case 'red':
      case 'أحمر':
        return Colors.red;
      case 'blue':
      case 'أزرق':
        return Colors.blue;
      case 'green':
      case 'أخضر':
        return Colors.green;
      case 'black':
      case 'أسود':
        return Colors.black;
      case 'white':
      case 'أبيض':
        return Colors.white;
      case 'yellow':
      case 'أصفر':
        return Colors.yellow;
      case 'orange':
      case 'برتقالي':
        return Colors.orange;
      case 'gray':
      case 'grey':
      case 'رمادي':
      case 'فضي':
        return Colors.grey;
      default:
        final themeChange = Provider.of<DarkThemeProvider>(context);
        return themeChange.getThem() ? Colors.white : Colors.black;
    }
  }
}
