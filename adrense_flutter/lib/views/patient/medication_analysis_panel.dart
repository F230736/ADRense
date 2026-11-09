import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/adrense_theme.dart';

class MedicationAnalysisPanel extends StatefulWidget {
  const MedicationAnalysisPanel({super.key,required this.controller});
  final TextEditingController controller;
  @override State<MedicationAnalysisPanel> createState()=>_MedicationAnalysisPanelState();
}

class _MedicationAnalysisPanelState extends State<MedicationAnalysisPanel> {
  final focus=FocusNode();
  final inputKey=GlobalKey();
  final resultsKey=GlobalKey();
  bool reviewed=false;
  Map<String,dynamic>? sessionReport;
  String? error;
  String? selectedExample;
  static const examples={
    'Stomach discomfort':'I have been taking Metformin 500mg twice a day for three months. Over the past week, I have felt nausea, abdominal pain after meals, and unusual fatigue.',
    'Dizziness':'I started taking Lisinopril two weeks ago. I have noticed dizziness and a headache, usually a few hours after taking my medicine.',
    'Skin irritation':'I began taking Amoxicillin three days ago. Since yesterday, I have noticed a rash and itching on my arms.',
  };
  @override void initState(){super.initState();lastText=widget.controller.text;widget.controller.addListener(changed);}
  @override void didUpdateWidget(covariant MedicationAnalysisPanel old){super.didUpdateWidget(old);if(old.controller!=widget.controller){old.controller.removeListener(changed);widget.controller.addListener(changed);}}
  @override void dispose(){widget.controller.removeListener(changed);focus.dispose();super.dispose();}
  String lastText='';
  void changed(){
    if(lastText==widget.controller.text)return;
    lastText=widget.controller.text;
    setState((){reviewed=false;error=null;selectedExample=null;sessionReport=null;});
  }
  void useExample(String label){
    widget.controller.text=examples[label]!;
    setState(()=>selectedExample=label);
    focus.unfocus();
  }
  Future<void> paste() async {
    try{
      final data=await Clipboard.getData(Clipboard.kTextPlain);
      if(!mounted)return;
      if(data?.text?.trim().isNotEmpty!=true){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Copy a description first, then tap Paste.')));return;}
      final text=data!.text!;
      widget.controller.text=text.length>2000?text.substring(0,2000):text;
      if(text.length>2000)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pasted the first 2,000 characters.')));
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Paste is unavailable. You can type your description instead.')));}
  }
  void analyze(){
    final text=widget.controller.text.trim();
    if(text.length<20){setState(()=>error='Please add a little more detail (at least 20 characters).');focus.requestFocus();return;}
    if(text.length>2000){setState(()=>error='Keep your description within 2,000 characters.');return;}
    focus.unfocus();
    setState((){
      reviewed=true;error=null;sessionReport=null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(mounted&&reviewed&&resultsKey.currentContext!=null)Scrollable.ensureVisible(resultsKey.currentContext!,alignment:.05,duration:const Duration(milliseconds:250));
    });
  }
  @override Widget build(BuildContext context){
    final t=context.tokens;
    final text=widget.controller.text;
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),
        gradient:LinearGradient(colors:[t.teal.withValues(alpha:.14),t.cyan.withValues(alpha:.04)]),border:Border.all(color:t.teal.withValues(alpha:.22))),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:t.teal.withValues(alpha:.12),borderRadius:BorderRadius.circular(12)),child:Icon(Icons.notes_rounded,color:t.teal,size:24)),
            const SizedBox(width:12),Expanded(child:Text('Analyze symptoms',style:TextStyle(color:t.ink,fontSize:21,fontWeight:FontWeight.w800)))]),
          const SizedBox(height:12),Text('Tell us about your medicine and how you have been feeling.',style:TextStyle(color:t.ink,fontSize:13,height:1.6)),
          const SizedBox(height:8),Text('Include the medicine name, when you started it, and any symptoms you noticed.',style:TextStyle(color:t.muted,fontSize:12,height:1.6)),
        ])),
      const SizedBox(height:20),
      Text('Try an example',style:TextStyle(color:t.ink,fontWeight:FontWeight.w700,fontSize:13)),const SizedBox(height:9),
      Wrap(spacing:7,runSpacing:7,children:[for(final label in examples.keys)ChoiceChip(label:Text(label,style:const TextStyle(fontSize:11)),selected:selectedExample==label,showCheckmark:true,onSelected:(_)=>useExample(label))]),
      const SizedBox(height:18),
      Row(children:[Expanded(child:Text('Your description',style:TextStyle(color:t.ink,fontWeight:FontWeight.w800,fontSize:14))),
        TextButton.icon(onPressed:paste,icon:const Icon(Icons.content_paste_outlined,size:16),label:const Text('Paste')),
        if(text.isNotEmpty)IconButton(tooltip:'Clear description',onPressed:()=>widget.controller.clear(),icon:Icon(Icons.close_rounded,color:t.muted,size:19)),
      ]),
      TextField(key:inputKey,controller:widget.controller,focusNode:focus,minLines:5,maxLines:9,maxLength:2000,
        textCapitalization:TextCapitalization.sentences,keyboardType:TextInputType.multiline,
        decoration:InputDecoration(hintText:'For example: I started taking my medicine two weeks ago. Since yesterday, I have noticed…',
          hintStyle:TextStyle(color:t.muted,fontSize:13,height:1.6),errorText:error,errorMaxLines:3,
          filled:true,fillColor:t.surfaceRaised,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)),
          focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:t.teal,width:1.5)))),
      const SizedBox(height:8),
      Row(children:[Icon(text.trim().length>=20?Icons.check_circle_outline:Icons.edit_note,color:text.trim().length>=20?t.teal:t.muted,size:17),const SizedBox(width:7),
        Expanded(child:Text(text.trim().length>=20?'Ready to analyze':'A few sentences will help.',style:TextStyle(color:text.trim().length>=20?t.teal:t.muted,fontSize:11)))]),
      const SizedBox(height:16),
      if(!reviewed)SizedBox(height:50,child:FilledButton.icon(onPressed:text.trim().isEmpty?null:analyze,icon:const Icon(Icons.manage_search_rounded,size:22),label:const Text('Analyze',style:TextStyle(fontSize:15,fontWeight:FontWeight.w800)))),
      const SizedBox(height:12),Text('Demo preview: results and confidence scores are illustrative.',style:TextStyle(color:t.muted,fontSize:11,height:1.5)),
      const SizedBox(height:12),
      AnimatedSize(alignment:Alignment.topCenter,duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:250),
        child:reviewed?results():const SizedBox.shrink()),
      const SizedBox(height:8),
      Theme(data:Theme.of(context).copyWith(dividerColor:Colors.transparent),child:ExpansionTile(tilePadding:EdgeInsets.zero,
        leading:Icon(Icons.lightbulb_outline,color:t.teal,size:21),title:const Text('What should I include?',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700)),
        children:[for(final tip in ['Medicine name and dose, if you know them.','When you started taking it and when symptoms appeared.','How the symptoms feel and whether they come and go.'])
          Padding(padding:const EdgeInsets.only(bottom:10),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.check,size:15,color:t.teal),const SizedBox(width:9),Expanded(child:Text(tip,style:TextStyle(color:t.muted,fontSize:12,height:1.5)))]))])),
    ]);
  }
  Widget results(){
    final t=context.tokens;
    Widget badge(String text,Color color)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),
      decoration:BoxDecoration(color:color.withValues(alpha:.1),border:Border.all(color:color.withValues(alpha:.4)),borderRadius:BorderRadius.circular(20)),
      child:Text(text,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.w700)));
    Widget card(Widget child)=>Container(width:double.infinity,padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(color:t.surfaceRaised,border:Border.all(color:t.border),borderRadius:BorderRadius.circular(20)),child:child);
    return Semantics(key:resultsKey,liveRegion:true,child:Column(key:const ValueKey('analysis-results'),crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:t.teal.withValues(alpha:.07),
        border:Border.all(color:t.teal.withValues(alpha:.45)),borderRadius:BorderRadius.circular(12)),
        child:Row(children:[Icon(Icons.circle,color:t.success,size:10),const SizedBox(width:10),
          Expanded(child:Text('Analysis complete · 94.3% confidence',style:TextStyle(color:t.teal,fontWeight:FontWeight.w700,fontSize:12)))])),
      const SizedBox(height:14),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text('Detected Drugs',style:TextStyle(color:t.ink,fontSize:15,fontWeight:FontWeight.w800))),badge('NER',t.teal)]),const SizedBox(height:14),
        Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:t.teal.withValues(alpha:.1),border:Border.all(color:t.teal),borderRadius:BorderRadius.circular(11)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Metformin',style:TextStyle(color:t.teal,fontWeight:FontWeight.w700,fontSize:14)),const SizedBox(height:7),
            Text('500mg · Daily · 96.2%',style:TextStyle(color:t.muted,fontSize:11))])),
      ])),const SizedBox(height:14),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text('Detected ADRs',style:TextStyle(color:t.ink,fontSize:15,fontWeight:FontWeight.w800))),badge('3 found',t.warning)]),const SizedBox(height:14),
        Wrap(spacing:8,runSpacing:8,children:[for(final item in [('Nausea','94%',t.warning),('Abdominal pain','89%',t.warning),('Fatigue','82%',t.success)])
          Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:item.$3.withValues(alpha:.09),border:Border.all(color:item.$3.withValues(alpha:.35)),borderRadius:BorderRadius.circular(11)),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.circle,color:item.$3,size:9),const SizedBox(width:7),Text(item.$1,style:TextStyle(color:t.ink,fontSize:12,fontWeight:FontWeight.w700))]),
              const SizedBox(height:8),Text('Confidence: ${item.$2}',style:TextStyle(color:t.muted,fontSize:11))])),
        ]),
      ])),const SizedBox(height:14),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Drug-ADR Relationships',style:TextStyle(color:t.ink,fontSize:15,fontWeight:FontWeight.w800)),const SizedBox(height:16),
        for(final item in [('Nausea','CAUSES',94,t.success),('Abdominal Pain','ASSOCIATED',89,t.warning),('Fatigue','POSSIBLE',82,t.warning)])...[
          Row(children:[Text('Metformin',style:TextStyle(color:t.teal,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(width:7),
            Text('—${item.$2}→',style:TextStyle(color:t.muted,fontSize:9)),const SizedBox(width:7),
            Expanded(child:Text(item.$1,style:TextStyle(color:t.ink,fontSize:11,fontWeight:FontWeight.w700))),const SizedBox(width:6),
            SizedBox(width:40,child:LinearProgressIndicator(value:item.$3/100,backgroundColor:t.border,valueColor:AlwaysStoppedAnimation(item.$4))),const SizedBox(width:6),
            Text('${item.$3}%',style:TextStyle(color:t.muted,fontSize:9)),
          ]),const SizedBox(height:13),Divider(height:1,color:t.border),const SizedBox(height:10),
        ],
      ])),const SizedBox(height:14),
      Row(children:[
        Expanded(child:TextButton(onPressed:sessionReport!=null?null:()=>setState(()=>sessionReport={'description':widget.controller.text,'medicine':'Metformin','symptoms':['Nausea','Abdominal pain','Fatigue']}),
          style:TextButton.styleFrom(foregroundColor:t.teal,backgroundColor:t.teal.withValues(alpha:.1),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(9))),child:const Text('Submit ADR',style:TextStyle(fontWeight:FontWeight.w700,fontSize:12)))),
        const SizedBox(width:10),
        Expanded(child:TextButton(onPressed:(){setState((){reviewed=false;sessionReport=null;});if(inputKey.currentContext!=null)Scrollable.ensureVisible(inputKey.currentContext!,duration:const Duration(milliseconds:250));},
          style:TextButton.styleFrom(foregroundColor:t.muted,backgroundColor:t.muted.withValues(alpha:.1),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(9))),child:const Text('Reset Analysis',style:TextStyle(fontWeight:FontWeight.w700,fontSize:12)))),
      ]),
      if(sessionReport!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text('Report saved for this session (demo).',style:TextStyle(color:t.success,fontSize:11))),
    ]));
  }
}
