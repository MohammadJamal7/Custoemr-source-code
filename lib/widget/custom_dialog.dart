import 'package:flutter/material.dart';

import '../configs/color_config.dart';
import '../configs/font_config.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final VoidCallback onPositivePressed;
  final VoidCallback onNegativePressed;
  final String positiveText;
  final String negativeText;
  final Widget? positiveIcon;
  final Widget? negativeIcon;
  final String? desc;

  const CustomDialog({
    required this.title,
    required this.onPositivePressed,
    required this.onNegativePressed,
    Key? key,
    required this.positiveText,
    required this.negativeText,
    this.positiveIcon,
    this.desc,
    this.negativeIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Text(title,
                  textAlign: TextAlign.center, style: FontConfig.title1),
              const SizedBox(width: 30),
            ],
          ),

          /// desc (optional)
          if (desc != null)
            Text(
              desc!,
              textAlign: TextAlign.center,
              style: FontConfig.info,
            ),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton(
            onPressed: onPositivePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConfig.appThemeColor,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Adjust the radius as needed
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (positiveIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: positiveIcon,
                  ),
                Text(
                  positiveText,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onNegativePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF222222),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Adjust the radius as needed
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (negativeIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: negativeIcon,
                      ),
                    Text(
                      negativeText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDangerDialog extends StatelessWidget {
  final String title;
  final VoidCallback onPositivePressed;
  final VoidCallback onNegativePressed;
  final String positiveText;
  final String negativeText;
  final Widget? positiveIcon;
  final Widget? negativeIcon;
  final String? desc;

  const CustomDangerDialog({
    required this.title,
    required this.onPositivePressed,
    required this.onNegativePressed,
    Key? key,
    required this.positiveText,
    required this.negativeText,
    this.positiveIcon,
    this.desc,
    this.negativeIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Text(title,
                  textAlign: TextAlign.center, style: FontConfig.title1),
              const SizedBox(width: 30),
            ],
          ),

          /// desc (optional)
          if (desc != null)
            Text(
              desc!,
              textAlign: TextAlign.center,
              style: FontConfig.info,
            ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: onPositivePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Adjust the radius as needed
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (positiveIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: positiveIcon,
                  ),
                Text(
                  positiveText,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onNegativePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF222222),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Adjust the radius as needed
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (negativeIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: negativeIcon,
                      ),
                    Text(
                      negativeText,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
