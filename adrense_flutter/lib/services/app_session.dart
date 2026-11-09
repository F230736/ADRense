part of '../main.dart';

// Session-scoped dialogs and confirmation actions.
extension _AppSessionActions on _ADRenseAppState {
  Future<void> adminConfirmDialog(String heading,String description,
      String action,Color color,VoidCallback onConfirm) async {
    await showDialog<void>(context:context,builder:(ctx)=>Dialog(
      backgroundColor:P.surface2,
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),
        side:BorderSide(color:color.withValues(alpha:.35))),
      child:Padding(padding:EdgeInsets.all(18),child:Column(
        mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(width:43,height:43,
            decoration:BoxDecoration(color:color.withValues(alpha:.12),
              borderRadius:BorderRadius.circular(11)),
            child:Icon(Icons.shield_outlined,color:color)),
          gap(15),
          Text(heading,style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
          gap(10),
          Text(description,style:TextStyle(color:P.muted,fontSize:12,height:1.6)),
          gap(18),
          Row(children:[
            Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(ctx),
              child:Text('Cancel'))),
            SizedBox(width:8),
            Expanded(child:FilledButton(
              style:FilledButton.styleFrom(backgroundColor:color,
                foregroundColor:P.text),
              onPressed:(){Navigator.pop(ctx);onConfirm();},
              child:Text(action,textAlign:TextAlign.center,
                style:TextStyle(fontSize:11,fontWeight:FontWeight.w800)))),
          ]),
        ])),
    ));
  }
  Future<void> askReason(String titleText,VoidCallback confirm)async{final c=TextEditingController();await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:P.surface,title:Text(titleText),content:TextField(controller:c,decoration:InputDecoration(hintText:'Reason / notes')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text('Cancel')),TextButton(onPressed:(){confirm();Navigator.pop(ctx);toast('Change saved in demo state');},child:Text('Confirm'))]));c.dispose();}
}
