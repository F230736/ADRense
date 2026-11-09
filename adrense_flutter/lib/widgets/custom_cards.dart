part of '../main.dart';

extension _CardsViews on _ADRenseAppState {
  Widget gap([double h=14])=>SizedBox(height:h);
  Widget title(String s,{String? subtitle})=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s,style:TextStyle(fontSize:23,fontWeight:FontWeight.w800)),if(subtitle!=null)...[gap(4),Text(subtitle,style:TextStyle(fontSize:12,color:P.muted))],gap(20)]);
  Widget section(String s)=>Padding(padding:EdgeInsets.only(bottom:12,top:5),child:Text(s,style:TextStyle(fontSize:16,fontWeight:FontWeight.w700)));
  Widget card(Widget child,{Color? color,EdgeInsets? padding})=>
    color==null?GradientCard(padding:padding??const EdgeInsets.all(16),child:child):
    Container(width:double.infinity,padding:padding??const EdgeInsets.all(16),
      decoration:BoxDecoration(color:color,border:Border.all(color:P.border),borderRadius:BorderRadius.circular(20)),child:child);
  Widget badge(String t,{Color? color}){ final c=color??P.teal; return Container(padding:EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:c.withValues(alpha:.12),border:Border.all(color:c.withValues(alpha:.3)),borderRadius:BorderRadius.circular(20)),child:Text(t,style:TextStyle(color:c,fontSize:11,fontWeight:FontWeight.w700)));}
}
