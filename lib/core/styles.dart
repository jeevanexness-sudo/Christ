import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class T {
  T._();
  static TextStyle get h1 => GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: C.white, letterSpacing: -0.5);
  static TextStyle get h2 => GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: C.white);
  static TextStyle get h3 => GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: C.white);
  static TextStyle get body => GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: C.text1, height: 1.7);
  static TextStyle get body2 => GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: C.text2, height: 1.6);
  static TextStyle get bold => GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: C.white);
  static TextStyle get cap => GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: C.muted, letterSpacing: 0.5);
  static TextStyle get over => GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w700, color: C.muted, letterSpacing: 1.2);
  static TextStyle get gold => GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: C.gold);
  static TextStyle get goldH => GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: C.gold);
  static TextStyle get btn => GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black);
  static TextStyle get btn2 => GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: C.white);
}
