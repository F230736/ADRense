import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class EmailChangeDialog extends StatefulWidget {
  const EmailChangeDialog({super.key,required this.api,required this.email,required this.sentAt,required this.onSent});
  final ApiService api;
  final String email;
  final DateTime sentAt;
  final ValueChanged<DateTime> onSent;
  @override State<EmailChangeDialog> createState()=>_EmailChangeDialogState();
}
class _EmailChangeDialogState extends State<EmailChangeDialog> {
  final code=TextEditingController();
  late DateTime sentAt;
  Timer? timer;
  bool busy=false;
  String? error;
  int get remaining=>60-DateTime.now().difference(sentAt).inSeconds;
  @override void initState(){super.initState();sentAt=widget.sentAt;timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted)setState((){});});}
  @override void dispose(){timer?.cancel();code.dispose();super.dispose();}
  Future<void> verify() async {
    if(busy)return;
    if(!RegExp(r'^\d{6}$').hasMatch(code.text)){setState(()=>error='Enter the six-digit code from your new email.');return;}
    setState((){busy=true;error=null;});
    try{
      final result=await widget.api.confirmEmailChange(widget.email,code.text);
      if(mounted)Navigator.pop(context,result);
    } on AuthApiException catch(e){
      if(!mounted)return;
      if(e.statusCode==401){Navigator.pop(context,{'requires_sign_in':true,'message':e.message});}
      else{setState(()=>error=e.message);}
    }finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> resend() async {
    if(busy||remaining>0)return;
    setState((){busy=true;error=null;});
    try{
      await widget.api.requestEmailChange(widget.email);
      if(!mounted)return;
      setState((){sentAt=DateTime.now();code.clear();});widget.onSent(sentAt);
    }on AuthApiException catch(e){if(mounted)setState(()=>error=e.message);}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>AlertDialog(
    title:const Text('Verify new email'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('Enter the code sent to:'),const SizedBox(height:8),Text(widget.email,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:14),
      const Text('Your current email and login remain unchanged until verification succeeds.'),const SizedBox(height:16),
      TextField(controller:code,enabled:!busy,keyboardType:TextInputType.number,autofillHints:const [AutofillHints.oneTimeCode],
        inputFormatters:[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(6)],
        decoration:const InputDecoration(labelText:'6-digit code',helperText:'The code expires in 10 minutes.')),
      if(error!=null)...[const SizedBox(height:12),Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))],
      const SizedBox(height:10),TextButton(onPressed:busy||remaining>0?null:resend,child:Text(remaining>0?'Resend in ${remaining}s':'Resend code')),
      if(busy)const LinearProgressIndicator(),
    ])),
    actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:const Text('Cancel')),
      FilledButton(onPressed:busy?null:verify,child:const Text('Verify & update'))]);
}
