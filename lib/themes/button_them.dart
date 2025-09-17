import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:customer/configs/color_config.dart';

//     double txtSize = 14,
//     double btnWidthRatio = 0.9,
//     double btnRadius = 6,
//     required Function() onPress,
//     bool isVisible = true,
//   }) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//
//     return Visibility(
//       visible: isVisible,
//       child: SizedBox(
//         width: Responsive.width(100, context) * btnWidthRatio,
//         child: MaterialButton(
//           onPressed: onPress,
//           height: btnHeight,
//           elevation: 0.5,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(btnRadius),
//           ),
//           color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
//           child: Text(
//             title.toUpperCase(),
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(fontSize: txtSize, fontWeight: FontWeight.w600),
//           ),
//         ),
//       ),
//     );
//   }
//
//   static buildBorderButton(
//     BuildContext context, {
//     required String title,
//     double btnHeight = 48,
//     double txtSize = 14,
//     double btnWidthRatio = 0.9,
//     double borderRadius = 6,
//     required Function() onPress,
//     bool isVisible = true,
//     bool iconVisibility = false,
//     String iconAssetImage = '',
//     Color? iconColor,
//         Color? color,
//   }) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//
//     return Visibility(
//       visible: isVisible,
//       child: SizedBox(
//         width: Responsive.width(100, context) * btnWidthRatio,
//         height: btnHeight,
//         child: ElevatedButton(
//           style: ButtonStyle(
//             backgroundColor: MaterialStateProperty.all<Color>(themeChange.getThem() ? Colors.transparent : Colors.white),
//             foregroundColor: MaterialStateProperty.all<Color>(themeChange.getThem() ? AppColors.darkModePrimary : Colors.white),
//             shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//               RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(borderRadius),
//                 side: BorderSide(
//                   color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
//                 ),
//               ),
//             ),
//           ),
//           onPressed: onPress,
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Visibility(
//                 visible: iconVisibility,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Image.asset(iconAssetImage, fit: BoxFit.cover, width: 32,color: iconColor,),
//                 ),
//               ),
//               Text(
//                 title.toUpperCase(),
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary, fontSize: txtSize, fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   static roundButton(
//     BuildContext context, {
//     required String title,
//     required Color btnColor,
//     required Color txtColor,
//     double btnHeight = 48,
//     double txtSize = 14,
//     double btnWidthRatio = 0.9,
//     required Function() onPress,
//     bool isVisible = true,
//   }) {
//     return Visibility(
//       visible: isVisible,
//       child: SizedBox(
//         width: Responsive.width(100, context) * btnWidthRatio,
//         child: MaterialButton(
//           onPressed: onPress,
//           height: btnHeight,
//           elevation: 0.5,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(30),
//           ),
//           color: btnColor,
//           child: Text(
//             title.toUpperCase(),
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(color: txtColor, fontSize: txtSize, fontWeight: FontWeight.w600),
//           ),
//         ),
//       ),
//     );
//   }
// }
class ButtonThem {
  const ButtonThem({Key? key});

  static buildButton(
    BuildContext context, {
    required String title,
    double btnHeight = 48,
    double txtSize = 14,
    double btnWidthRatio = 0.9,
    double btnRadius = 10,
    required dynamic Function()? onPress,
    bool isVisible = true,
    Color? customColor, // Optional override for background color
    Color? customTextColor, // Optional override for text color
  }) {
    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        child: MaterialButton(
          onPressed: onPress,
          height: btnHeight,
          elevation: 0.5,
          // Ensure text color isn't overridden by theme defaults
          textColor: customTextColor ?? Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnRadius),
          ),
          // Use green color from ColorConfig for all buttons
          color: customColor ?? ColorConfig.appThemeColor,
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: txtSize,
              fontWeight: FontWeight.w600,
              color: customTextColor ?? Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  static buildBorderButton(
    BuildContext context, {
    required String title,
    double btnHeight = 50,
    double txtSize = 14,
    double btnWidthRatio = 0.9,
    double borderRadius = 10,
    required dynamic Function()? onPress,
    bool isVisible = true,
    bool iconVisibility = false,
    String iconAssetImage = '',
    Color? color,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        height: btnHeight,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
                themeChange.getThem() ? Colors.transparent : Colors.white),
            foregroundColor: WidgetStateProperty.all<Color>(
                themeChange.getThem()
                    ? AppColors.darkModePrimary
                    : Colors.white),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(
                  color: color ?? ColorConfig.appThemeColor,
                ),
              ),
            ),
          ),
          onPressed: onPress,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: iconVisibility,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child:
                      Image.asset(iconAssetImage, fit: BoxFit.cover, width: 32),
                ),
              ),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: color ?? ColorConfig.appThemeColor,
                    fontSize: txtSize,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static roundButton(
    BuildContext context, {
    required String title,
    double btnHeight = 48,
    double txtSize = 14,
    double btnWidthRatio = 0.9,
    required Function() onPress,
    required Color btnColor,
    required Color txtColor,
    bool isVisible = true,
  }) {
    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        child: MaterialButton(
          onPressed: onPress,
          height: btnHeight,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          // Use green color from ColorConfig for all buttons
          color: ColorConfig.appThemeColor,
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: txtSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
