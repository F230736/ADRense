part of '../../main.dart';

extension _RegistrationViews on _ADRenseAppState {
  bool validEmail(String? value) {
    final v=value??'';
    if(v.isEmpty||v.contains(RegExp(r'\s'))||v.length>254||v.contains('..'))return false;
    final parts=v.split('@');
    if(parts.length!=2||parts[0].isEmpty||parts[0].length>64)return false;
    if(parts[0].startsWith('.')||parts[0].endsWith('.'))return false;
    if(!RegExp(r"^[A-Za-z0-9!#\$%&'*+/=?^_`{|}~.-]+$").hasMatch(parts[0]))return false;
    final domain=parts[1].split('.');
    if(domain.length<2||domain.last.length<2)return false;
    return domain.every((label)=>label.isNotEmpty&&label.length<=63&&
      RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$').hasMatch(label));
  }
  bool validName(String? value) => RegExp(r'^[A-Za-z]+(?: +[A-Za-z]+)+$').hasMatch((value??'').trim());
  bool validPassword(String value)=>value.length>=8&&utf8.encode(value).length<=72&&RegExp(r'[a-z]').hasMatch(value)&&
    RegExp(r'[A-Z]').hasMatch(value)&&RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)&&!value.contains(RegExp(r'\s'));
  bool validPhone(String? value) => RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch((value??'').trim());
  bool validYear(String? value) {
    final n=int.tryParse((value??'').trim());
    return n!=null && n>=1950 && n<=DateTime.now().year;
  }
  bool validDate(String? value) {
    final v=(value??'').trim();
    final iso=RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
    final us=RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(v);
    if(iso==null&&us==null)return false;
    final y=int.parse((iso?.group(1)??us!.group(3))!);
    final m=int.parse((iso?.group(2)??us!.group(1))!);
    final d=int.parse((iso?.group(3)??us!.group(2))!);
    final date=DateTime(y,m,d);
    return date.year==y&&date.month==m&&date.day==d;
  }
  String? registrationError(String label,String? value) {
    final v=(value??'').trim();
    if(v.isEmpty)return '$label is required';
    if(label.toLowerCase().contains('email')&&!validEmail(v))return 'Enter a valid email address (e.g. name@example.com)';
    if(label=='Full Name'&&!validName(v))return 'Enter first and last name using letters only';
    if(label=='Phone Number'&&!validPhone(v))return 'Enter a valid phone number including area code';
    if(label=='Graduation Year'&&!validYear(v))return 'Enter a valid 4-digit graduation year';
    if(label=='Expiry Date'||label=='License Expiry Date'){
      if(!validDate(v))return 'Use a real date in MM/DD/YYYY or YYYY-MM-DD format';
      final parts=v.contains('/')?v.split('/'):v.split('-');
      final date=v.contains('/')?DateTime(int.parse(parts[2]),int.parse(parts[0]),int.parse(parts[1])):
        DateTime(int.parse(parts[0]),int.parse(parts[1]),int.parse(parts[2]));
      if(!date.isAfter(DateTime.now()))return 'The license must not be expired';
    }
    if(label=='Password'&&!validPassword(v))return 'Use 8+ characters, uppercase, lowercase and a special character (no spaces)';
    if(label=='Confirm Password'&&v!=registrationData['Password'])return 'Passwords do not match';
    if(label=='Country'&&registrationData['Country Code']==null)return 'Select a country from the list';
    if(label=='License / Registration Number'&&!RegExp(r'^[A-Za-z0-9/-]{4,40}$').hasMatch(v))return 'Enter a valid license number';
    if(label=='Qualification / Degree'&&v.length<2)return 'Enter your qualification';
    if(label=='University / Institution'&&v.length<3)return 'Enter your institution';
    if(label=='Issuing Authority'&&v.length<3)return 'Enter a valid issuing authority';
    return null;
  }
  bool checkRegistrationFields(List<String> labels){
    for(final label in labels){
      final error=registrationError(label,registrationData[label]);
      if(error!=null){formErrors[label]=error;}
      else{formErrors.remove(label);}
    }
    setState((){});
    return labels.every((label)=>!formErrors.containsKey(label));
  }
  List<TextInputFormatter> formattersFor(String label){
    if(label=='Expiry Date'||label=='License Expiry Date')return [ExpiryDateInputFormatter()];
    if(label=='Full Name'||label=='Country')return [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]'))];
    if(label=='Graduation Year')return [FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(4)];
    if(label=='Phone Number')return [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]'))];
    if(label.toLowerCase().contains('email'))return [FilteringTextInputFormatter.deny(RegExp(r'\s'))];
    if(label=='Password'||label=='Confirm Password')return [FilteringTextInputFormatter.deny(RegExp(r'\s'))];
    return [];
  }
  Widget inlineRegistrationField(String label,{String? hint,bool secret=false}) => Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      TextFormField(key:ValueKey('validated-$role-$regStep-$label'),
        initialValue:registrationData[label]??'',
        keyboardType:label.toLowerCase().contains('email')?TextInputType.emailAddress:
          label=='Phone Number'?TextInputType.phone:(label=='Graduation Year'||label=='Expiry Date'||label=='License Expiry Date')?TextInputType.number:TextInputType.text,
        inputFormatters:formattersFor(label),
        obscureText:secret && !(label=='Password'?showRegisterPassword:showConfirmPassword),
        onChanged:(v){registrationData[label]=v;
          if(formErrors.containsKey(label))setState((){
            final e=registrationError(label,v);
            if(e==null)formErrors.remove(label);else formErrors[label]=e;
          });
        },
        decoration:InputDecoration(hintText:hint??label,
          suffixIcon:secret?IconButton(
            tooltip:(label=='Password'?showRegisterPassword:showConfirmPassword)?'Hide password':'Show password',
            onPressed:()=>setState(() {
              if(label=='Password')showRegisterPassword=!showRegisterPassword;
              else showConfirmPassword=!showConfirmPassword;
            }),
            icon:Icon((label=='Password'?showRegisterPassword:showConfirmPassword)?Icons.visibility_off_outlined:Icons.visibility_outlined,color:P.muted)):null,
          errorText:formErrors[label],errorMaxLines:3,
          errorStyle:TextStyle(color:P.danger,fontSize:12,fontWeight:FontWeight.w700))),
    ]);
  Widget inlineSelectionError(String label)=>formErrors[label]==null?SizedBox.shrink():
    Padding(padding:EdgeInsets.only(bottom:10),child:Text(formErrors[label]!,
      style:TextStyle(color:P.danger,fontSize:12,fontWeight:FontWeight.w700)));
  Widget registrationField(String label, {bool password = false, String? hint}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: P.muted)),
        gap(7),
        inlineRegistrationField(label,hint:hint,secret:password),
      ]),
    );
  }

  Widget registrationSelect(String label, List<String> choices) {
    return Padding(
      padding: EdgeInsets.only(bottom: 13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: P.muted)),
        gap(7),
        DropdownButtonFormField<String>(
          key: ValueKey('$role-$regStep-$label'),
          initialValue: choices.contains(registrationData[label]) ? registrationData[label] : null,
          dropdownColor: P.surface2,
          decoration: InputDecoration(hintText: 'Select $label'),
          items: choices.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (v != null) setState(() => registrationData[label] = v); },
        ),
      ]),
    );
  }

  Widget registrationProgress(int total) => Padding(padding:EdgeInsets.symmetric(vertical:20),child:Row(children:[
    for(int i=0;i<total;i++) ...[
      if(i>0)Expanded(child:Container(height:2,color:i<=regStep?P.teal:P.surface3)),
      Container(width:27,height:27,alignment:Alignment.center,decoration:BoxDecoration(
        color:i<regStep?P.teal:i==regStep?P.navy:P.surface3,shape:BoxShape.circle,
        border:Border.all(color:i<=regStep?P.teal:P.border)),
        child:i<regStep?Icon(Icons.check,size:15,color:P.navy):Text('${i+1}',
          style:TextStyle(color:i==regStep?P.teal:P.muted,fontSize:11))),
    ],
  ]));
  Widget registrationChoices(String label,List<String> values)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:TextStyle(color:P.muted,fontSize:11)),gap(8),
    Wrap(spacing:7,runSpacing:8,children:[for(final v in values)
      InkWell(onTap:()=>setState(()=>registrationData[label]=v),child:Container(
        padding:EdgeInsets.symmetric(horizontal:13,vertical:10),decoration:BoxDecoration(
          color:registrationData[label]==v?P.teal.withValues(alpha:.12):P.surface2,
          border:Border.all(color:registrationData[label]==v?P.teal:P.border),borderRadius:BorderRadius.circular(20)),
        child:Text(v,style:TextStyle(color:registrationData[label]==v?P.teal:P.muted,fontSize:11)))),
    ]),gap(19),
  ]);
  Widget registrationItems(String key,List<String> suggestions){
    final items=registrationLists[key]!;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:TextFormField(key:ValueKey('input-$key-${items.length}'),
        initialValue:registrationData['draft-$key']??'',onChanged:(v)=>registrationData['draft-$key']=v,
        decoration:InputDecoration(hintText:key=='Medical Conditions'?'e.g. Type 2 Diabetes':key=='Allergies'?'e.g. Penicillin':'e.g. Metformin'))),
        SizedBox(width:8),SizedBox(width:45,height:47,child:FilledButton(
          style:FilledButton.styleFrom(backgroundColor:P.teal,padding:EdgeInsets.zero),
          onPressed:(){final v=(registrationData['draft-$key']??'').trim();if(v.isNotEmpty) {
            setState((){
            if(!items.contains(v))items.add(v);if(key=='Current Medications'){final dose=(registrationData['draft-dose']??'').trim();if(dose.isNotEmpty)registrationDoses[v]=dose;registrationData['draft-dose']='';}registrationData['draft-$key']='';
          });
          }},child:Icon(Icons.add,color:P.navy))),
      ]),gap(12),
      if(key=='Current Medications')...[TextFormField(key:ValueKey('registration-dose-${items.length}'),initialValue:registrationData['draft-dose']??'',onChanged:(v)=>registrationData['draft-dose']=v,decoration:InputDecoration(hintText:'Dose (optional, e.g. 500mg twice daily)')),gap(12)],
      Wrap(spacing:7,runSpacing:8,children:[for(final v in suggestions)
        InkWell(onTap:()=>setState((){if(!items.contains(v))items.add(v);}),child:Container(
          padding:EdgeInsets.symmetric(horizontal:12,vertical:8),
          decoration:BoxDecoration(color:P.surface3,borderRadius:BorderRadius.circular(20)),
          child:Text('+ $v',style:TextStyle(color:P.muted,fontSize:11)))),
      ]),
      if(items.isNotEmpty)...[gap(12),Wrap(spacing:6,runSpacing:6,children:[for(final v in List<String>.from(items))
        InputChip(label:Text(v),onDeleted:()=>setState((){items.remove(v);if(key=='Current Medications')registrationDoses.remove(v);}),
          backgroundColor:P.surface2,side:BorderSide(color:P.tealDim))])],
    ]);
  }
  Widget registrationSteps(){
    final analyst=role=='analyst';
    final titles=analyst?['Role & Credentials','Professional Information','License Details','Documents']:
      ['Role & Credentials','Basic Information','Medical Conditions','Current Medications'];
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(regStep>0)...[
        registrationProgress(4),
        Text(titles[regStep],style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),gap(7),
        Text(!analyst&&regStep==1?'* All fields required':
          'Optional — ${regStep==2?'update later in your profile':'add details now or later'}.',
          style:TextStyle(color:!analyst&&regStep==1?P.danger:P.muted,fontSize:11)),gap(21),
      ],
      if(regStep==0)...[
        inlineRegistrationField('Email Address',hint:'Email address'),gap(12),
        inlineRegistrationField('Password',hint:'Password',secret:true),gap(12),
        inlineRegistrationField('Confirm Password',hint:'Confirm password',secret:true),
      ],
      if(regStep==1&&!analyst)...[
        registrationField('Full Name',hint:'Your full name'),
        registrationChoices('Age group',['18–25','26–35','36–50','51–65','65+']),inlineSelectionError('Age group'),
        registrationChoices('Biological sex',['Male','Female','Other']),inlineSelectionError('Biological sex'),
        registrationChoices('Weight range (optional)',['<50kg','50–70kg','70–90kg','90–110kg','>110kg']),
      ],
      if(regStep==1&&analyst)...[registrationField('Full Name'),registrationField('Profession'),
        registrationField('Degree / Qualification'),registrationField('Institution')],
      if(regStep==2&&!analyst)...[
        registrationItems('Medical Conditions',['Type 2 Diabetes','Hypertension','Hyperlipidemia','Asthma','Arthritis']),
        gap(20),Text('Allergies (optional)',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700)),gap(10),
        registrationItems('Allergies',['Penicillin','Sulfonamides','Aspirin','Latex']),
      ],
      if(regStep==2&&analyst)...[registrationField('License Number'),registrationField('Issuing Authority'),
        registrationField('License Expiry Date')],
      if(regStep==3&&!analyst)registrationItems('Current Medications',
        ['Metformin','Ibuprofen','Lisinopril','Atorvastatin','Aspirin']),
      if(regStep==3&&analyst)for(final doc in ['Professional License','Degree Certificate'])...[card(Text('$doc — Upload pending backend integration')),gap(10)],
      gap(20),
      SizedBox(height:52,width:double.infinity,child:FilledButton(
        style:FilledButton.styleFrom(backgroundColor:P.teal,foregroundColor:P.onAccent),
        onPressed:authBusy?null:(){
          if(regStep==0&&!checkRegistrationFields(['Email Address','Password','Confirm Password']))return;
          if(regStep==1&&!analyst){
            if(!checkRegistrationFields(['Full Name']))return;
            if(registrationData['Age group']==null||registrationData['Biological sex']==null){
              setState((){if(registrationData['Age group']==null)formErrors['Age group']='Select an age group';if(registrationData['Biological sex']==null)formErrors['Biological sex']='Select biological sex';});return;
            }
          }
          if(regStep<3){setState(()=>regStep++);return;}
          if(analyst){registerWithBackend();return;}
          registerWithBackend();
        },child:Text(regStep==3?(analyst?'Submit for Verification':'Create Account & Verify Email'):'Continue →',
          style:TextStyle(fontWeight:FontWeight.w800)))),
      if(regStep>=2&&!analyst)Center(child:TextButton(onPressed:()=>setState((){
        if(regStep<3) {
          regStep++;
        } else {
          registerWithBackend();
        }
      }),child:Text(regStep==3?'Skip — set up later':'Skip this step',style:TextStyle(color:P.muted)))),
      if(regStep>0)Center(child:TextButton(onPressed:()=>setState(()=>regStep--),
        child:Text('← Back',style:TextStyle(color:P.muted)))),
    ]);
  }
  Widget analystRegistrationProgress()=>Padding(padding:EdgeInsets.symmetric(vertical:20),child:Row(children:[
    for(var i=0;i<6;i++) ...[
      if(i>0)Expanded(child:Container(height:2,color:i<=regStep?_ADRenseAppState.analystPurple:P.surface3)),
      Container(width:26,height:26,alignment:Alignment.center,decoration:BoxDecoration(
        color:i<regStep?_ADRenseAppState.analystPurple:i==regStep?P.navy:P.surface3,
        border:Border.all(color:i<=regStep?_ADRenseAppState.analystPurple:P.border),shape:BoxShape.circle),
        child:i<regStep?Icon(Icons.check,color:P.text,size:14):Text('${i+1}',style:TextStyle(fontSize:11,color:i==regStep?_ADRenseAppState.analystPurple:P.muted))),
    ],
  ]));
  Widget analystRegistrationChoices(String label,List<String> options)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('$label *',style:TextStyle(color:P.muted,fontSize:11)),gap(9),
    Wrap(spacing:7,runSpacing:8,children:[
      for(final option in options)InkWell(onTap:()=>setState(() {registrationData[label]=option;formErrors.remove(label);}),child:Container(
        padding:EdgeInsets.symmetric(horizontal:12,vertical:9),
        decoration:BoxDecoration(color:registrationData[label]==option?_ADRenseAppState.analystPurple.withValues(alpha:.1):P.surface2,
          border:Border.all(color:registrationData[label]==option?_ADRenseAppState.analystPurple:P.border),borderRadius:BorderRadius.circular(20)),
        child:Text(option,style:TextStyle(fontSize:11,color:registrationData[label]==option?_ADRenseAppState.analystPurple:P.muted,fontWeight:registrationData[label]==option?FontWeight.w700:FontWeight.w400)))),
    ]),inlineSelectionError(label),gap(18),
  ]);
  Widget analystRegistrationField(String label,String hint)=>Padding(padding:EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('$label *',style:TextStyle(color:P.muted,fontSize:11)),gap(8),
    inlineRegistrationField(label,hint:hint,secret:label.contains('Password')),
  ]));
  Widget analystRegistrationSteps(){
    final headings=['Role & Credentials','Basic Information','Professional Information','Professional Registration','Upload Documents','Submit for Verification'];
    final sub=['Role & Credentials','Personal details','Qualifications','License details','Verification documents','Review your application'];
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(regStep>0)...[
        analystRegistrationProgress(),
        Text(headings[regStep],style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),gap(6),
        Text('Step ${regStep+1} of 6 — ${sub[regStep]}',style:TextStyle(color:P.muted,fontSize:12)),gap(20),
      ],
      if(regStep==0)...[
        Container(width:double.infinity,padding:EdgeInsets.all(13),decoration:BoxDecoration(color:_ADRenseAppState.analystPurple.withValues(alpha:.06),border:Border.all(color:_ADRenseAppState.analystPurple.withValues(alpha:.3)),borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Professional Verification Required',style:TextStyle(color:_ADRenseAppState.analystPurple,fontSize:12,fontWeight:FontWeight.w700)),SizedBox(height:7),
          Text('Analyst access requires professional credential verification. Your account will remain pending until approved by an authorized administrator.',style:TextStyle(color:P.muted,fontSize:11,height:1.6)),
        ])),gap(14),
        analystRegistrationField('Email Address','Email address'),
        analystRegistrationField('Password','Password'),
        analystRegistrationField('Confirm Password','Confirm password'),
      ],
      if(regStep==1)...[
        analystRegistrationField('Full Name','Dr. Ahmed Khan'),
        analystRegistrationField('Professional Email','ahmed.khan@hospital.pk'),
        analystPhoneField(),
        analystCountryField(),
        analystRegistrationChoices('Professional Role',['Doctor','Pharmacist','Clinical Pharmacist','Pharmacovigilance Professional','Other Healthcare Professional']),
      ],
      if(regStep==2)...[
        analystRegistrationChoices('Profession',['Doctor (MBBS/MD)','Pharmacist (B.Pharm)','Clinical Pharmacist (Pharm-D)','Pharmacovigilance Officer','Research Scientist','Other']),
        analystRegistrationField('Qualification / Degree','e.g. Pharm-D, MBBS, PhD'),
        analystRegistrationField('University / Institution','e.g. University of Karachi'),
        analystRegistrationField('Graduation Year','e.g. 2019'),
      ],
      if(regStep==3)...[
        analystRegistrationField('License / Registration Number','e.g. PK-PHARM-12345'),
        analystRegistrationField('Issuing Authority','e.g. Pakistan Pharmacy Council'),
        analystRegistrationField('Expiry Date','mm/dd/yyyy'),
        Container(padding:EdgeInsets.all(13),decoration:BoxDecoration(color:P.teal.withValues(alpha:.04),border:Border.all(color:P.tealDim.withValues(alpha:.3)),borderRadius:BorderRadius.circular(10)),child:Text('Your registration number will be cross-checked with the relevant professional registry where available. Matches speed up the verification process.',style:TextStyle(color:P.muted,fontSize:10,height:1.6))),
      ],
      if(regStep==4)...[
        Text('Upload supporting documents for admin verification. Accepted formats: PDF, JPG, PNG (max 5MB each).',style:TextStyle(color:P.muted,fontSize:12,height:1.6)),gap(16),
        for(final kind in ['license','degree','id_card'])analystDocumentUpload(kind),
        inlineSelectionError('Documents'),
      ],
      if(regStep==5)...[
        card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Application Summary',style:TextStyle(fontWeight:FontWeight.w700)),gap(12),
          for(final k in ['Full Name','Professional Email','Professional Role','Profession','Qualification / Degree','License / Registration Number'])
            rowKV(k,registrationData[k]??'Not entered'),
          for(final entry in registrationDocuments.entries)rowKV(documentLabel(entry.key),entry.value.filename),
        ])),gap(12),
        Text('Your application will remain pending until an administrator verifies your professional credentials.',style:TextStyle(color:P.muted,fontSize:11,height:1.6)),
      ],
      gap(13),
      if(regStep==4)Text('License and degree are required. ID card is optional.',style:TextStyle(color:P.muted,fontSize:10)),
      SizedBox(width:double.infinity,height:53,child:FilledButton(onPressed:authBusy||pickingDocument?null:(){
        if(regStep==0){
          if(!checkRegistrationFields(['Email Address','Password','Confirm Password']))return;
        }
        if(regStep>=1&&regStep<=3){
          final fields=regStep==1?['Full Name','Professional Email','Phone Number','Country','Professional Role']:
            regStep==2?['Profession','Qualification / Degree','University / Institution','Graduation Year']:
            ['License / Registration Number','Issuing Authority','Expiry Date'];
          if(!checkRegistrationFields(fields))return;
        }
        if(regStep==4&&!validateRequiredDocuments())return;
        if(regStep<5){setState(()=>regStep++);return;}
        registerWithBackend();
      },style:FilledButton.styleFrom(backgroundColor:_ADRenseAppState.analystPurple,foregroundColor:P.text,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(11))),child:Text(regStep==5?'Submit for Verification →':'Continue →',style:TextStyle(fontWeight:FontWeight.w800)))),
      if(regStep>0)Center(child:TextButton(onPressed:()=>setState(()=>regStep--),child:Text('← Back',style:TextStyle(color:P.muted,fontSize:12)))),
    ]);
  }
}
