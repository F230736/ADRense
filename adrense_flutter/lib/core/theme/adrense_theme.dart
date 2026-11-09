import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AdrenseTokens extends ThemeExtension<AdrenseTokens> {
  final Color teal, cyan, purple, danger, warning, success, background, surface, surfaceRaised, ink, muted, border;
  const AdrenseTokens({required this.teal,required this.cyan,required this.purple,required this.danger,required this.warning,required this.success,required this.background,required this.surface,required this.surfaceRaised,required this.ink,required this.muted,required this.border});
  static const light=AdrenseTokens(teal:Color(0xFF007F7A),cyan:Color(0xFF00A7BE),purple:Color(0xFF6938D3),danger:Color(0xFFCA2748),warning:Color(0xFF9D6200),success:Color(0xFF087B4B),background:Color(0xFFF6F9FC),surface:Colors.white,surfaceRaised:Color(0xFFEAF2F8),ink:Color(0xFF14243B),muted:Color(0xFF50647F),border:Color(0xFFD1DDE9));
  static const dark=AdrenseTokens(teal:Color(0xFF00C9B8),cyan:Color(0xFF43DCEB),purple:Color(0xFF9B68FF),danger:Color(0xFFFF526B),warning:Color(0xFFFFB52D),success:Color(0xFF30D78A),background:Color(0xFF080D1A),surface:Color(0xFF0F1626),surfaceRaised:Color(0xFF1A2538),ink:Color(0xFFF0F4FF),muted:Color(0xFF9BAAC4),border:Color(0xFF344158));
  LinearGradient get primaryGradient=>LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[teal,cyan]);
  LinearGradient get analystGradient=>const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF087E82),Color(0xFF075B77),Color(0xFF274C9B)]);
  LinearGradient get adminGradient=>const LinearGradient(colors:[Color(0xFF147D88),Color(0xFF4B50A8)]);
  LinearGradient get warningGradient=>LinearGradient(colors:[warning,const Color(0xFFF5A623)]);
  LinearGradient get pageGradient=>LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:background==const Color(0xFFF6F9FC)?const [Color(0xFFF8FCFF),Color(0xFFEAF8F6),Color(0xFFF2F5FE)]:const [Color(0xFF080D1A),Color(0xFF102735),Color(0xFF101426)]);
  LinearGradient get dangerGradient=>LinearGradient(colors:[danger,const Color(0xFFF46A85)]);
  LinearGradient get successGradient=>LinearGradient(colors:[success,teal]);
  LinearGradient get surfaceGradient=>LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[surface,surfaceRaised.withValues(alpha:.65)]);
  LinearGradient get backgroundGradient=>pageGradient;
  List<BoxShadow> get softGlow=>[BoxShadow(color:teal.withValues(alpha:.11),blurRadius:24,offset:const Offset(0,9))];
  @override AdrenseTokens copyWith({Color? teal,Color? cyan,Color? purple,Color? danger,Color? warning,Color? success,Color? background,Color? surface,Color? surfaceRaised,Color? ink,Color? muted,Color? border})=>AdrenseTokens(teal:teal??this.teal,cyan:cyan??this.cyan,purple:purple??this.purple,danger:danger??this.danger,warning:warning??this.warning,success:success??this.success,background:background??this.background,surface:surface??this.surface,surfaceRaised:surfaceRaised??this.surfaceRaised,ink:ink??this.ink,muted:muted??this.muted,border:border??this.border);
  @override AdrenseTokens lerp(ThemeExtension<AdrenseTokens>? other,double t){if(other is! AdrenseTokens)return this;Color c(Color a,Color b)=>Color.lerp(a,b,t)!;return AdrenseTokens(teal:c(teal,other.teal),cyan:c(cyan,other.cyan),purple:c(purple,other.purple),danger:c(danger,other.danger),warning:c(warning,other.warning),success:c(success,other.success),background:c(background,other.background),surface:c(surface,other.surface),surfaceRaised:c(surfaceRaised,other.surfaceRaised),ink:c(ink,other.ink),muted:c(muted,other.muted),border:c(border,other.border));}
}
class AdrenseMotion {static const micro=Duration(milliseconds:240),standard=Duration(milliseconds:360),reveal=Duration(milliseconds:900);static const Curve curve=Curves.easeOutCubic;static const double cardRadius=20,controlRadius=14;}
class AdrenseTheme {
  static ThemeData build(bool light){final t=light?AdrenseTokens.light:AdrenseTokens.dark;final brightness=light?Brightness.light:Brightness.dark;return ThemeData(useMaterial3:true,brightness:brightness,scaffoldBackgroundColor:t.background,colorScheme:ColorScheme.fromSeed(seedColor:t.teal,brightness:brightness,surface:t.surface,onSurface:t.ink),extensions:[t],textTheme:GoogleFonts.plusJakartaSansTextTheme(ThemeData(brightness:brightness).textTheme).apply(bodyColor:t.ink,displayColor:t.ink),appBarTheme:AppBarTheme(backgroundColor:t.background,foregroundColor:t.ink),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:t.surfaceRaised,hintStyle:TextStyle(color:t.muted),contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:15),border:OutlineInputBorder(borderRadius:BorderRadius.circular(AdrenseMotion.controlRadius)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(AdrenseMotion.controlRadius),borderSide:BorderSide(color:t.border)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(AdrenseMotion.controlRadius),borderSide:BorderSide(color:t.teal,width:1.6))));}
}
extension AdrenseThemeContext on BuildContext {AdrenseTokens get tokens=>Theme.of(this).extension<AdrenseTokens>()??AdrenseTokens.light;}
