part of '../../main.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key,required this.api,required this.reset,required this.initialEmail,required this.onBack,this.initiallySent=false});
  final ApiService api;
  final bool reset;
  final bool initiallySent;
  final String initialEmail;
  final VoidCallback onBack;
  @override State<EmailAuthScreen> createState()=>_EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  late final TextEditingController email;
  final code=TextEditingController(), password=TextEditingController(), confirmation=TextEditingController();
  final form=GlobalKey<FormState>();
  bool busy=false, sent=false, done=false, showPassword=false;
  String? error, message;
  DateTime? nextSend;
  @override void initState(){super.initState();email=TextEditingController(text:widget.initialEmail);
    if(widget.initiallySent){sent=true;message='We have requested a verification code for your email. Check your inbox and spam folder.';nextSend=DateTime.now().add(const Duration(seconds:60));}
  }
  @override void dispose(){email.dispose();code.dispose();password.dispose();confirmation.dispose();super.dispose();}
  Future<void> send() async {
    if(busy)return;
    if(!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())){setState(()=>error='Enter a valid email address');return;}
    setState((){busy=true;error=null;});
    try {
      final result=await widget.api.requestCode(email.text.trim(),reset:widget.reset);
      if(!mounted)return;
      setState((){sent=true;message=result['message'] as String;nextSend=DateTime.now().add(const Duration(seconds:60));code.clear();});
    } on AuthApiException catch(e){if(mounted)setState(()=>error=e.message);}
    finally {if(mounted)setState(()=>busy=false);}
  }
  Future<void> submit() async {
    if(busy || !(form.currentState?.validate()??false))return;
    setState((){busy=true;error=null;});
    try {
      final result=widget.reset?await widget.api.resetPassword(email.text.trim(),code.text,password.text,confirmation.text):await widget.api.verifyEmail(email.text.trim(),code.text);
      if(!mounted)return;
      await widget.api.logout();
      if(!mounted)return;
      setState((){done=true;message=result['message'] as String;password.clear();confirmation.clear();code.clear();});
    } on AuthApiException catch(e){if(mounted)setState(()=>error=e.message);}
    finally {if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>SingleChildScrollView(
    padding:const EdgeInsets.all(24),child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const SizedBox(height:32),
      Center(child:SizedBox(width:64,height:64,child:SvgPicture.asset('assets/logo.svg'))),
      const SizedBox(height:14),
      const Text('ADRense',textAlign:TextAlign.center,style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
      const SizedBox(height:28),
      Text(done?(widget.reset?'Password updated':'Email verified'):(widget.reset?'Reset your password':'Verify your email'),style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
      const SizedBox(height:12),
      if(message!=null)Text(message!,style:TextStyle(color:P.muted,height:1.5)),
      if(!done)...[
        if(message==null)Text(widget.reset?'Enter your registered email. We will send a six-digit code if an account exists.':'Confirm you own this email before signing in. Request a code below if your registration email has not arrived.',style:TextStyle(color:P.muted,height:1.5)),
        const SizedBox(height:20),
        TextFormField(controller:email,readOnly:sent||busy,keyboardType:TextInputType.emailAddress,autofillHints:const [AutofillHints.email],
          decoration:const InputDecoration(labelText:'Email address'),
          validator:(v)=>RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v??'').trim())?null:'Enter a valid email address'),
        if(sent)...[
          const SizedBox(height:16),
          TextFormField(controller:code,enabled:!busy,keyboardType:TextInputType.number,autofillHints:const [AutofillHints.oneTimeCode],
            inputFormatters:[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(6)],
            decoration:const InputDecoration(labelText:'Six-digit email code',helperText:'Expires in 10 minutes. Check your spam folder.'),
            validator:(v)=>RegExp(r'^\d{6}$').hasMatch(v??'')?null:'Enter the six-digit code'),
          if(widget.reset)...[
            const SizedBox(height:16),
            TextFormField(controller:password,enabled:!busy,obscureText:!showPassword,autofillHints:const [AutofillHints.newPassword],
              decoration:InputDecoration(labelText:'New password',helperText:'8+ characters, uppercase, lowercase and a special character. No spaces.',helperMaxLines:3,
                suffixIcon:IconButton(onPressed:()=>setState(()=>showPassword=!showPassword),tooltip:showPassword?'Hide password':'Show password',icon:Icon(showPassword?Icons.visibility_off:Icons.visibility))),
              validator:(v){final p=v??'';return p.length>=8&&utf8.encode(p).length<=72&&RegExp(r'[A-Z]').hasMatch(p)&&RegExp(r'[a-z]').hasMatch(p)&&RegExp(r'[^A-Za-z0-9\s]').hasMatch(p)&&!RegExp(r'\s').hasMatch(p)?null:'Use 8+ characters, uppercase, lowercase, a special character, and no spaces (maximum 72 bytes).';}),
            const SizedBox(height:16),
            TextFormField(controller:confirmation,enabled:!busy,obscureText:!showPassword,
              decoration:const InputDecoration(labelText:'Confirm new password'),validator:(v)=>v==password.text?null:'Passwords do not match'),
          ],
        ],
        if(error!=null)...[const SizedBox(height:16),Text(error!,style:TextStyle(color:P.danger))],
        const SizedBox(height:24),
        FilledButton(onPressed:busy?null:(sent?submit:send),child:Padding(padding:const EdgeInsets.all(14),child:Text(busy?'Please wait…':sent?(widget.reset?'Update password':'Verify email'):'Send code'))),
        if(sent)StreamBuilder<int>(stream:Stream.periodic(const Duration(seconds:1),(n)=>n),builder:(context,snapshot){
          final remaining=nextSend==null?0:nextSend!.difference(DateTime.now()).inSeconds+1;
          return TextButton(onPressed:busy||remaining>0?null:()async {
            // Resending must not require the code or new password fields.
            setState((){sent=false;message=null;error=null;});
            await send();
          },child:Text(remaining>0?'Resend code in ${remaining}s':'Resend code'));
        }),
        if(sent)TextButton(onPressed:busy?null:()=>setState((){sent=false;message=null;error=null;code.clear();}),child:const Text('Use a different email')),
      ],
      const SizedBox(height:12),
      TextButton(onPressed:busy?null:widget.onBack,child:const Text('Back to sign in')),
    ])));
}
