import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/adrense_theme.dart';

class GradientCard extends StatelessWidget {final Widget child;final Gradient? gradient;final EdgeInsets padding;const GradientCard({super.key,required this.child,this.gradient,this.padding=const EdgeInsets.all(18)});@override Widget build(BuildContext context){final t=context.tokens;return Container(width:double.infinity,padding:padding,decoration:BoxDecoration(gradient:gradient??t.surfaceGradient,borderRadius:BorderRadius.circular(AdrenseMotion.cardRadius),border:Border.all(color:t.border.withValues(alpha:.7)),boxShadow:t.softGlow),child:child);}}
class GlassCard extends StatelessWidget {final Widget child;final EdgeInsets padding;const GlassCard({super.key,required this.child,this.padding=const EdgeInsets.all(14)});@override Widget build(BuildContext context){final t=context.tokens;return ClipRRect(borderRadius:BorderRadius.circular(20),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:10,sigmaY:10),child:Container(padding:padding,decoration:BoxDecoration(color:t.surface.withValues(alpha:.70),borderRadius:BorderRadius.circular(20),border:Border.all(color:t.border.withValues(alpha:.55))),child:child)));}}
class GradientButton extends StatefulWidget {final String label;final VoidCallback onPressed;final Gradient? gradient;final IconData? icon;const GradientButton({super.key,required this.label,required this.onPressed,this.gradient,this.icon});@override State<GradientButton> createState()=>_GradientButtonState();}
class _GradientButtonState extends State<GradientButton>{bool down=false;@override Widget build(BuildContext context){final t=context.tokens;return AnimatedScale(scale:down ? 0.97 : 1.0,duration:AdrenseMotion.micro,child:Container(height:54,decoration:BoxDecoration(gradient:widget.gradient??t.primaryGradient,borderRadius:BorderRadius.circular(15),boxShadow:[BoxShadow(color:t.teal.withValues(alpha:.20),blurRadius:20,offset:const Offset(0,7))]),child:Material(color:Colors.transparent,child:InkWell(borderRadius:BorderRadius.circular(15),onTap:(){HapticFeedback.lightImpact();widget.onPressed();},onHighlightChanged:(v)=>setState(()=>down=v),child:Center(child:Row(mainAxisSize:MainAxisSize.min,children:[if(widget.icon!=null)...[Icon(widget.icon,color:Colors.white,size:19),const SizedBox(width:8)],Text(widget.label,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:14))]))))));}}
class AnimatedCounter extends StatelessWidget {final int value;final String suffix;final TextStyle? style;final Duration duration;const AnimatedCounter({super.key,required this.value,this.suffix='',this.style,this.duration=AdrenseMotion.reveal});@override Widget build(BuildContext context){final reduce=MediaQuery.disableAnimationsOf(context);return TweenAnimationBuilder<double>(tween:Tween(begin:0,end:value.toDouble()),duration:reduce?Duration.zero:duration,curve:Curves.easeOutCubic,builder:(context,n,_)=>Text('${n.round()}$suffix',style:style??const TextStyle(fontSize:26,fontWeight:FontWeight.w800,fontFeatures:[FontFeature.tabularFigures()])));}}
class StatusChip extends StatelessWidget {final String label;final Color? color;final IconData? icon;const StatusChip({super.key,required this.label,this.color,this.icon});@override Widget build(BuildContext context){final c=color??context.tokens.teal;return Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:c.withValues(alpha:.10),borderRadius:BorderRadius.circular(20),border:Border.all(color:c.withValues(alpha:.3))),child:Row(mainAxisSize:MainAxisSize.min,children:[if(icon!=null)...[Icon(icon,size:12,color:c),const SizedBox(width:4)],Text(label,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:c))]));}}
class SectionHeader extends StatelessWidget {final String title;final String? subtitle;const SectionHeader({super.key,required this.title,this.subtitle});@override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),if(subtitle!=null)Padding(padding:const EdgeInsets.only(top:5),child:Text(subtitle!,style:TextStyle(fontSize:12,color:context.tokens.muted)))]);}
class ShimmerLoader extends StatefulWidget {final double height;const ShimmerLoader({super.key,this.height=70});@override State<ShimmerLoader> createState()=>_ShimmerLoaderState();}
class _ShimmerLoaderState extends State<ShimmerLoader> with SingleTickerProviderStateMixin {late final AnimationController ctrl;@override void initState(){super.initState();ctrl=AnimationController(vsync:this,duration:const Duration(milliseconds:1200))..repeat();}@override void dispose(){ctrl.dispose();super.dispose();}@override Widget build(BuildContext context){final t=context.tokens;if(MediaQuery.disableAnimationsOf(context))return Container(height:widget.height,decoration:BoxDecoration(color:t.surfaceRaised,borderRadius:BorderRadius.circular(15)));return AnimatedBuilder(animation:ctrl,builder:(context,_)=>Container(height:widget.height,decoration:BoxDecoration(borderRadius:BorderRadius.circular(15),gradient:LinearGradient(begin:Alignment(-1.5+ctrl.value*3,-.4),end:Alignment(-.5+ctrl.value*3,.4),colors:[t.surfaceRaised,t.surface,t.surfaceRaised]))));}}


/// Compact animated severity/notification indicator.
class PulseBadge extends StatefulWidget {
  final Color color;
  final double size;
  const PulseBadge({super.key, required this.color, this.size = 12});
  @override State<PulseBadge> createState() => _PulseBadgeState();
}
class _PulseBadgeState extends State<PulseBadge> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override void initState() { super.initState(); controller=AnimationController(vsync:this,duration:const Duration(milliseconds:1200))..repeat(reverse:true); }
  @override void dispose(){controller.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    if(MediaQuery.disableAnimationsOf(context))return _dot(1);
    return AnimatedBuilder(animation:controller,builder:(context,_)=>_dot(.75+controller.value*.25));
  }
  Widget _dot(double scale)=>Transform.scale(scale:scale,child:Container(width:widget.size,height:widget.size,decoration:BoxDecoration(shape:BoxShape.circle,color:widget.color,boxShadow:[BoxShadow(color:widget.color.withValues(alpha:.28),blurRadius:9,spreadRadius:3)])));
}

class GradientIconBadge extends StatelessWidget {
  final IconData icon;
  final Gradient? gradient;
  final double size;
  const GradientIconBadge({super.key,required this.icon,this.gradient,this.size=46});
  @override Widget build(BuildContext context)=>Container(width:size,height:size,decoration:BoxDecoration(gradient:gradient??context.tokens.primaryGradient,borderRadius:BorderRadius.circular(14),boxShadow:context.tokens.softGlow),child:Icon(icon,color:Colors.white,size:size*.48));
}

class ShimmerBox extends StatelessWidget {
  final double height;
  const ShimmerBox({super.key,this.height=70});
  @override Widget build(BuildContext context)=>ShimmerLoader(height:height);
}
