part of '../main.dart';

class P {
  // Two independent semantic palettes. No image/color-matrix inversion.
  static bool light = true;
  static Color get navy => light ? Color(0xFFF7F9FD) : Color(0xFF080D1A);
  static Color get surface => light ? Color(0xFFFFFFFF) : Color(0xFF0F1626);
  static Color get surface2 => light ? Color(0xFFEAF0F8) : Color(0xFF1A2538);
  static Color get surface3 => light ? Color(0xFFDCE6F3) : Color(0xFF212E45);
  static Color get teal => light ? Color(0xFF007D77) : Color(0xFF00C9B8);
  static Color get tealDim => light ? Color(0xFF006D68) : Color(0xFF007A72);
  static Color get danger => light ? Color(0xFFCE2947) : Color(0xFFFF4757);
  static Color get warning => light ? Color(0xFFAC6500) : Color(0xFFFFB017);
  static Color get success => light ? Color(0xFF087D48) : Color(0xFF2ED573);
  static Color get text => light ? Color(0xFF14243B) : Color(0xFFF0F4FF);
  static Color get muted => light ? Color(0xFF50647F) : Color(0xFF8896B3);
  static Color get onAccent => light ? Colors.white : Color(0xFF061B24);
  static Color get border => light ? Color(0xFFCCD8E8) : Color(0x1FFFFFFF);
}
