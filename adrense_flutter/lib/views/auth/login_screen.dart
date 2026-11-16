part of '../../main.dart';

extension _LoginViews on _ADRenseAppState {
  Widget login() => LayoutBuilder(builder:(context, constraints) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    child: ConstrainedBox(constraints:BoxConstraints(minHeight:constraints.maxHeight-44),
      child:Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(height: (constraints.maxHeight * 0.065).clamp(16.0, 62.0)),
    Row(children: [
      Container(width: 36,height: 36,padding: EdgeInsets.all(5),
        decoration: BoxDecoration(color: P.surface2,borderRadius: BorderRadius.circular(10)),
        child: SvgPicture.asset('assets/logo.svg')),
      SizedBox(width: 10),
      Text('ADRense',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w800)),
    ]),
    gap(22),
    Container(height: 48,padding: EdgeInsets.all(4),
      decoration: BoxDecoration(color: P.surface,borderRadius: BorderRadius.circular(13)),
      child: Row(children: [
        for(final item in ['Sign In','Register'])
          Expanded(child: InkWell(
            onTap: () => setState(() {register=item=='Register';regStep=0;formErrors.clear();loginEmail='';loginPassword='';loginFormVersion++;}),
            child: Container(alignment: Alignment.center,
              decoration: BoxDecoration(color: (register ? item=='Register' : item=='Sign In')
                ? P.teal : Colors.transparent,borderRadius: BorderRadius.circular(11),
                boxShadow:(register ? item=='Register' : item=='Sign In')?[BoxShadow(color:P.teal.withValues(alpha:.18),blurRadius:14,offset:Offset(0,4))]:null),
              child: Text(item,style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700,
                color: (register ? item=='Register' : item=='Sign In') ? P.onAccent : P.muted))))),
      ])),
    gap(26),
    Text(register?'Create your account':'Welcome back',style: TextStyle(fontSize: 23,fontWeight: FontWeight.w800)),
    gap(7),
    Text(register?(role=='analyst'?'Step ${regStep+1} of 6 — ${['Role & Credentials','Basic Information','Professional Information','Professional Registration','Upload Documents','Submit for Verification'][regStep]}':'Step ${regStep+1} of 4 — ${regStep==0?'Role & Credentials':regStep==1?'Basic Information':regStep==2?'Medical Conditions':'Current Medications'}'):'Sign in to your ADRense account',
      style: TextStyle(color: P.muted,fontSize: 13)),
    gap(23),
    if (!register || regStep==0) ...[
    Text(register?'I am registering as':'Sign in as',style: TextStyle(color: P.muted,fontSize: 12)),
    gap(9),
    for (final item in [
      ('user','General User','Search drugs & view safety info'),
      ('analyst','Healthcare Professional / Analyst','Review & verify AI-generated ADR predictions'),
    ]) ...[
      InkWell(onTap: () => setState(() {role=item.$1;formErrors.clear();}),
        child: Container(width: double.infinity,padding: EdgeInsets.all(13),
          decoration: BoxDecoration(color: role==item.$1?(role=='analyst'?(P.light?Color(0xFFF0E9FF):Color(0xFF190F30)):(P.light?(role=='admin'?Color(0xFFFFF3DF):Color(0xFFE4F8F5)):Color(0xFF051F26))):P.surface2,
            border: Border.all(color: role==item.$1?(role=='analyst'?_ADRenseAppState.analystPurple:role=='admin'?P.warning:P.tealDim):P.border),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(role==item.$1?Icons.radio_button_checked:Icons.circle,
              color: role==item.$1?(role=='analyst'?_ADRenseAppState.analystPurple:role=='admin'?P.warning:P.teal):P.surface3,size: 13),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
              Text(item.$2,style: TextStyle(fontWeight: FontWeight.w700,fontSize: 13,
                color: role==item.$1?(role=='analyst'?_ADRenseAppState.analystPurple:role=='admin'?P.warning:P.teal):P.text)),
              Text(item.$3,style: TextStyle(color: P.muted,fontSize: 11)),
            ])),
            if(role==item.$1) Icon(Icons.check,color:role=='analyst'?_ADRenseAppState.analystPurple:role=='admin'?P.warning:P.teal,size:16),
          ]))),
      gap(8),
    ],
    gap(7),
    ],
    if (authError != null) ...[Text(authError!,style:TextStyle(color:P.danger,fontWeight:FontWeight.w700)),gap(12)],
    if (register) (role=='analyst'?analystRegistrationSteps():registrationSteps()) else ...[
      TextField(key:ValueKey('login-email-$loginFormVersion'),keyboardType:TextInputType.emailAddress,
        inputFormatters:[FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        onChanged:(v){loginEmail=v;if(formErrors.containsKey('Login Email'))setState((){
          if(validEmail(v))formErrors.remove('Login Email');
          else formErrors['Login Email']='Enter a valid email address';
        });},
        decoration:InputDecoration(prefixIcon:Icon(Icons.mail_outline,color:P.muted,size:18),
          hintText:'Email address',errorText:formErrors['Login Email'],errorMaxLines:2)),
      gap(12),
      TextField(key:ValueKey('login-password-$loginFormVersion'),
        obscureText:!showLoginPassword,
        inputFormatters:[FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        onChanged:(v){loginPassword=v;if(formErrors.containsKey('Login Password'))setState(() {
          if(validPassword(v))formErrors.remove('Login Password');
          else formErrors['Login Password']='Use 8+ characters, uppercase, lowercase and a special character.';
        });},
        decoration:InputDecoration(prefixIcon:Icon(Icons.lock_outline,color:P.muted,size:18),
          suffixIcon:IconButton(tooltip:showLoginPassword?'Hide password':'Show password',
            onPressed:()=>setState(()=>showLoginPassword=!showLoginPassword),
            icon:Icon(showLoginPassword?Icons.visibility_off_outlined:Icons.visibility_outlined,color:P.muted)),
          hintText:'Password',errorText:formErrors['Login Password'],errorMaxLines:3,
          errorStyle:TextStyle(color:P.danger,fontSize:12,fontWeight:FontWeight.w700))),
      gap(10),
      Align(alignment: Alignment.centerRight,child: TextButton(
        onPressed: authBusy?null:() => setState((){emailFlow='reset';authError=null;}),
        child: Text('Forgot password?',style: TextStyle(color: P.teal,fontSize: 12)))),
      gap(10),
      SizedBox(width: double.infinity,height: 54,child: FilledButton(
        onPressed: authBusy ? null : () {
          setState((){
            if(!validEmail(loginEmail))formErrors['Login Email']='Enter a valid email address';else formErrors.remove('Login Email');
            if(!validPassword(loginPassword))formErrors['Login Password']=loginPassword.isEmpty?'Password is required':'Use 8+ characters, uppercase, lowercase and a special character.';else formErrors.remove('Login Password');
          });
          if(formErrors.containsKey('Login Email')||formErrors.containsKey('Login Password'))return;
          signInWithBackend();
        },
        style: FilledButton.styleFrom(backgroundColor: P.teal,foregroundColor: P.navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
        child: Text('Sign In as ${role=='user'?'General User':role=='analyst'?'Analyst':'Administrator'}',
          style: TextStyle(fontWeight: FontWeight.w700,fontSize: 14)))),
    ],
  ]))));
}
