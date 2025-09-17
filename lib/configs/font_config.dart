import 'package:flutter/material.dart';

import 'color_config.dart';

class FontConfig {
  static const TextStyle title1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
  );
  static  const TextStyle titleColored = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorConfig.appThemeColor,
  );
  static const TextStyle titleBig = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
  );
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
  );

  static const TextStyle cardSubtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
  );

  static const TextStyle info = TextStyle(
    fontSize: 12,
    //overflow: TextOverflow.ellipsis,
    color: Color(0xFF222222),
  );
  static const TextStyle infoError = TextStyle(
    fontSize: 12,
    color: Color(0xFFE92C2C),
  );

  static const TextStyle field = TextStyle(
    fontSize: 14,
    color: Color(0xFF222222),
  );

  static const TextStyle fieldHint = TextStyle(
    fontSize: 14,
    color: Color(0xFF222222),
    fontWeight: FontWeight.w400,
  );
  static const TextStyle fieldHintSmall = TextStyle(
    fontSize: 11,
    color: Color(0xFF222222),
    fontWeight: FontWeight.w400,
  );
  static const TextStyle floatingLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Color(0xFF222222),
  );
  static const TextStyle forgotPassword = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
  );
}
