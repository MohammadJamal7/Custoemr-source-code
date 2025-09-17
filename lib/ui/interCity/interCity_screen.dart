import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/interCity/interCity_view.dart';
import 'package:customer/controller/interCity_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class InterCityScreen extends StatelessWidget {
  final bool showAppBar;

  const InterCityScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ Clear InterCity data when user navigates back
        InterCityController controller = Get.find<InterCityController>();
        controller.clearInterCityData();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: showAppBar
            ? AppBar(
                title: Text('OutStation'.tr,
                    style: GoogleFonts.poppins(
                        fontSize: Responsive.height(2.2, context))),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // ✅ Clear InterCity data when user taps back button
                    InterCityController controller =
                        Get.find<InterCityController>();
                    controller.clearInterCityData();
                    Get.back();
                  },
                ),
              )
            : null,
        body: InterCityView(),
      ),
    );
  }
}
