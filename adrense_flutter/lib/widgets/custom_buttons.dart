part of '../main.dart';

extension _ButtonsViews on _ADRenseAppState {
  Widget btn(String text,VoidCallback onTap,{bool outline=false,Color? color,IconData? icon}){
    final c=color??P.teal;
    if(!outline && color==null)return GradientButton(label:text,onPressed:onTap,icon:icon);
    return SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:onTap,
      icon:Icon(icon??Icons.arrow_forward_rounded,size:17),label:Text(text),
      style:OutlinedButton.styleFrom(backgroundColor:outline?Colors.transparent:c,
        foregroundColor:outline?c:P.onAccent,side:BorderSide(color:c),
        padding:const EdgeInsets.symmetric(vertical:15),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
        textStyle:const TextStyle(fontWeight:FontWeight.w700,fontSize:13))));
  }
  Widget smallBtn(String t,VoidCallback action,{Color? color}){final c=color??P.teal;return TextButton(onPressed:action,style:TextButton.styleFrom(foregroundColor:c,backgroundColor:c.withValues(alpha:.1),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(9))),child:Text(t,style:TextStyle(fontSize:12,fontWeight:FontWeight.w700)));}
  Widget field(String hint,{TextEditingController? controller,int lines=1,bool secret=false})=>TextField(controller:controller,maxLines:lines,obscureText:secret,style:TextStyle(fontSize:13),decoration:InputDecoration(hintText:hint,contentPadding:EdgeInsets.all(15)));
  Widget rowKV(String a,String b,{Color? color})=>Padding(padding:EdgeInsets.symmetric(vertical:9),child:Row(children:[Expanded(child:Text(a,style:TextStyle(fontSize:12,color:P.muted))),Flexible(child:Text(b,textAlign:TextAlign.right,style:TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:color??P.text)))]));
  Widget pills(List<String> items,String active,void Function(String) action)=>Wrap(spacing:7,runSpacing:8,children:items.map((t)=>ChoiceChip(label:Text(t,style:TextStyle(fontSize:12,color:t==active?P.onAccent:P.muted,fontWeight:FontWeight.w600)),selected:t==active,onSelected:(_)=>action(t),selectedColor:P.teal,backgroundColor:P.surface3,side:BorderSide.none,showCheckmark:false)).toList());
  Widget metric(String v,String l,{Color? color})=>Expanded(child:Column(children:[Text(v,style:TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:color??P.text)),gap(4),Text(l,textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:P.muted))]));
  Widget header(String text,String back,{Widget? right})=>Row(children:[IconButton(onPressed:()=>go(back),icon:Icon(Icons.arrow_back_ios_new,size:18)),Expanded(child:Text(text,style:TextStyle(fontSize:19,fontWeight:FontWeight.w700))),if(right!=null)right]);
}
