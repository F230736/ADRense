import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../core/theme/adrense_theme.dart';

class RegistrationChart extends StatefulWidget {
  const RegistrationChart({super.key,required this.api,required this.onSummary});
  final ApiService api;
  final ValueChanged<Map<String,dynamic>> onSummary;
  @override State<RegistrationChart> createState()=>_RegistrationChartState();
}

class _RegistrationChartState extends State<RegistrationChart> {
  int days=30,requestId=0;
  bool loading=true,general=true,analysts=true;
  String? error;
  List<Map<String,dynamic>> buckets=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final current=++requestId;
    setState((){loading=true;error=null;});
    try {
      final result=await widget.api.registrationStatistics(days);
      if(!mounted||current!=requestId)return;
      setState(()=>buckets=List<Map<String,dynamic>>.from(result['buckets'] as List));
      widget.onSummary(Map<String,dynamic>.from(result['summary'] as Map));
    } catch(e){if(mounted&&current==requestId)setState(()=>error=e.toString());}
    finally{if(mounted&&current==requestId)setState(()=>loading=false);}
  }
  int count(String key)=>buckets.fold(0,(sum,row)=>sum+(row[key] as num).toInt());
  String label(int index,{bool full=false}){
    if(index<0||index>=buckets.length)return '';
    final date=DateTime.parse(buckets[index]['date'] as String);
    const months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return full?'${date.day} ${months[date.month-1]} ${date.year}':days==365?months[date.month-1]:'${date.day} ${months[date.month-1]}';
  }
  @override Widget build(BuildContext context){
    final t=context.tokens;
    final teal=t.teal,purple=const Color(0xFF9357FF);
    final maximum=buckets.fold<double>(0,(value,row)=>math.max(value,math.max(general?(row['general_users'] as num).toDouble():0,analysts?(row['analysts'] as num).toDouble():0)));
    final maxY=math.max(2.0,(maximum*1.3).ceilToDouble());
    final total=count('general_users')+count('analysts');
    return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:t.surfaceRaised,borderRadius:BorderRadius.circular(22),border:Border.all(color:t.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('User registrations',style:TextStyle(color:t.ink,fontSize:17,fontWeight:FontWeight.w800))),IconButton(tooltip:'Refresh registrations',onPressed:loading?null:load,icon:Icon(Icons.refresh,color:t.muted,size:20))]),
      Text('New accounts · Pakistan time',style:TextStyle(color:t.muted,fontSize:11)),const SizedBox(height:14),
      Row(children:[Text(loading?'—':'$total',style:TextStyle(color:t.ink,fontSize:32,fontWeight:FontWeight.w800)),const SizedBox(width:9),Expanded(child:Text('registered in the last $days days',style:TextStyle(color:t.muted,fontSize:11)))]),
      const SizedBox(height:14),
      Row(children:[for(final range in [7,30,90,365])Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:2),child:ChoiceChip(
        label:Text(range==365?'1Y':'${range}D',style:const TextStyle(fontSize:11)),selected:days==range,showCheckmark:false,
        onSelected:(_){if(days!=range){setState(()=>days=range);load();}},
      )))]),const SizedBox(height:18),
      if(loading)const SizedBox(height:220,child:Center(child:CircularProgressIndicator()))
      else if(error!=null)SizedBox(height:220,child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,style:TextStyle(color:t.muted),textAlign:TextAlign.center),TextButton(onPressed:load,child:const Text('Try again'))])))
      else if(buckets.isEmpty)const SizedBox(height:220,child:Center(child:Text('No registrations in this period.')))
      else SizedBox(height:220,child:LineChart(LineChartData(
        minX:0,maxX:math.max(1,buckets.length-1).toDouble(),minY:0,maxY:maxY,
        clipData:const FlClipData.all(),
        gridData:FlGridData(show:true,drawVerticalLine:false,horizontalInterval:math.max(1,(maxY/4).ceilToDouble()),getDrawingHorizontalLine:(_)=>FlLine(color:t.border.withValues(alpha:.65),strokeWidth:1,dashArray:[4,5])),
        borderData:FlBorderData(show:false),
        titlesData:FlTitlesData(topTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),
          leftTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,reservedSize:30,interval:math.max(1,(maxY/4).ceilToDouble()),getTitlesWidget:(value,meta)=>Text(value.toInt().toString(),style:TextStyle(color:t.muted,fontSize:10)))),
          bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,reservedSize:30,interval:math.max(1,((buckets.length-1)/3).ceilToDouble()),getTitlesWidget:(value,meta)=>Padding(padding:const EdgeInsets.only(top:10),child:Text(label(value.toInt()),style:TextStyle(color:t.muted,fontSize:9))))),
        ),
        lineTouchData:LineTouchData(enabled:true,handleBuiltInTouches:true,touchTooltipData:LineTouchTooltipData(
          getTooltipColor:(_)=>t.surface,fitInsideHorizontally:true,fitInsideVertically:true,
          getTooltipItems:(spots)=>spots.map((spot)=>LineTooltipItem('${label(spot.x.toInt(),full:true)}\n${spot.bar.color==purple?'Analysts':'General users'}: ${spot.y.toInt()}',TextStyle(color:spot.bar.color,fontSize:11,fontWeight:FontWeight.w700))).toList())),
        lineBarsData:[
          if(general)series('general_users',teal),if(analysts)series('analysts',purple),
        ],
      ),duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:400))),
      if(!loading&&error==null&&total==0)Padding(padding:const EdgeInsets.only(top:8),child:Text('No new accounts in this period.',style:TextStyle(color:t.muted,fontSize:11))),
      const SizedBox(height:12),Wrap(spacing:16,runSpacing:6,children:[
        legend('General users',count('general_users'),teal,general,()=>setState((){if(analysts)general=!general;})),
        legend('Analysts',count('analysts'),purple,analysts,()=>setState((){if(general)analysts=!analysts;})),
      ]),const SizedBox(height:8),Text('Tap or hover to inspect · tap a legend to filter',style:TextStyle(color:t.muted,fontSize:10)),
    ]));
  }
  LineChartBarData series(String key,Color color)=>LineChartBarData(
    spots:[for(var i=0;i<buckets.length;i++)FlSpot(i.toDouble(),(buckets[i][key] as num).toDouble())],
    color:color,barWidth:3,isCurved:true,preventCurveOverShooting:true,isStrokeCapRound:true,
    dotData:FlDotData(show:buckets.length<=13),belowBarData:BarAreaData(show:true,gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[color.withValues(alpha:.16),color.withValues(alpha:0)])),
  );
  Widget legend(String name,int total,Color color,bool selected,VoidCallback onTap)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(8),child:Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(mainAxisSize:MainAxisSize.min,children:[
    Container(width:9,height:9,decoration:BoxDecoration(color:selected?color:Colors.grey,shape:BoxShape.circle)),const SizedBox(width:6),
    Text('$name  $total',style:TextStyle(fontSize:11,color:selected?color:Colors.grey,fontWeight:FontWeight.w700)),
  ])));
}
