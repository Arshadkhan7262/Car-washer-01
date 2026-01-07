import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Font Sizes
  static const double fontSize24 = 24.0;
  static const double fontSize15 = 15.0;
  static const double fontSize13 = 13.0;
  static const double fontSize11 = 11.0;

  // Inter Font Styles
  static TextStyle interRegular24(Color color) => GoogleFonts.inter(
        fontSize: fontSize24,
        fontWeight: FontWeight.w400, // Regular
        color: color,
      );

  static TextStyle interRegular15(Color color) => GoogleFonts.inter(
        fontSize: fontSize15,
        fontWeight: FontWeight.w400, // Regular
        color: color,
      );

  static TextStyle interRegular13(Color color) => GoogleFonts.inter(
        fontSize: fontSize13,
        fontWeight: FontWeight.w400, // Regular
        color: color,
      );

  static TextStyle interRegular11(Color color) => GoogleFonts.inter(
        fontSize: fontSize11,
        fontWeight: FontWeight.w400, // Regular
        color: color,
      );

  static TextStyle interSemiBold24(Color color) => GoogleFonts.inter(
        fontSize: fontSize24,
        fontWeight: FontWeight.w600, // SemiBold
        color: color,
      );

  static TextStyle interSemiBold15(Color color) => GoogleFonts.inter(
        fontSize: fontSize15,
        fontWeight: FontWeight.w600, // SemiBold
        color: color,
      );

  static TextStyle interSemiBold13(Color color) => GoogleFonts.inter(
        fontSize: fontSize13,
        fontWeight: FontWeight.w600, // SemiBold
        color: color,
      );

  static TextStyle interSemiBold11(Color color) => GoogleFonts.inter(
        fontSize: fontSize11,
        fontWeight: FontWeight.w600, // SemiBold
        color: color,
      );

  static TextStyle interBold24(Color color) => GoogleFonts.inter(
        fontSize: fontSize24,
        fontWeight: FontWeight.w700, // Bold
        color: color,
      );

  static TextStyle interBold15(Color color) => GoogleFonts.inter(
        fontSize: fontSize15,
        fontWeight: FontWeight.w700, // Bold
        color: color,
      );

  static TextStyle interBold13(Color color) => GoogleFonts.inter(
        fontSize: fontSize13,
        fontWeight: FontWeight.w700, // Bold
        color: color,
      );

  static TextStyle interBold11(Color color) => GoogleFonts.inter(
        fontSize: fontSize11,
        fontWeight: FontWeight.w700, // Bold
        color: color,
      );
}



