part of '../../main.dart';

extension _AnalystRegistrationWidgets on _ADRenseAppState {
  String documentLabel(String kind)=>switch(kind){
    'license'=>'Professional License / Registration Document',
    'degree'=>'Degree / Qualification Certificate',
    _=>'Professional ID Card',
  };

  Future<void> pickRegistrationDocument(String kind) async {
    if(pickingDocument||authBusy)return;
    updateView(()=>pickingDocument=true);
    try {
      final file=await FilePicker.pickFile(type:FileType.custom,allowedExtensions:['pdf','jpg','jpeg','png'],dialogTitle:documentLabel(kind));
      if(file==null)return;
      if((await file.length()??0)>5*1024*1024){if(mounted)toast('Each document must be no larger than 5 MB.');return;}
      final bytes=await file.readAsBytes();
      if(!mounted)return;
      final error=RegistrationDocument.validate(file.name,bytes);
      if(error!=null){toast(error);return;}
      updateView((){registrationDocuments[kind]=RegistrationDocument(file.name,bytes);formErrors.remove('Documents');});
    } catch(_){if(mounted)toast('Could not read that file. Please choose another PDF or picture.');}
    finally {if(mounted)updateView(()=>pickingDocument=false);}
  }

  bool validateRequiredDocuments(){
    final valid=registrationDocuments.containsKey('license')&&registrationDocuments.containsKey('degree');
    updateView((){if(valid){formErrors.remove('Documents');}else{formErrors['Documents']='Upload both your professional license and degree certificate.';regStep=4;}});
    return valid;
  }

  Widget analystDocumentUpload(String kind){
    final document=registrationDocuments[kind];
    return Padding(padding:const EdgeInsets.only(bottom:10),child:card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Icon(document==null?Icons.upload_file_outlined:Icons.check_circle_outline,color:document==null?P.muted:P.success),const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(documentLabel(kind),style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),gap(5),
          Text(kind=='id_card'?'Optional':'Required',style:TextStyle(color:P.muted,fontSize:11)),
        ])),
      ]),
      if(document!=null)...[gap(10),Text('${document.filename} · ${(document.bytes.length/1024).toStringAsFixed(0)} KB',style:TextStyle(color:P.teal,fontSize:11))],
      Row(children:[
        Expanded(child:TextButton.icon(onPressed:pickingDocument||authBusy?null:()=>pickRegistrationDocument(kind),
          icon:const Icon(Icons.folder_open,size:17),label:Text(document==null?'Upload from device':'Replace file'))),
        if(document!=null)IconButton(tooltip:'Remove file',onPressed:authBusy?null:()=>updateView(()=>registrationDocuments.remove(kind)),icon:Icon(Icons.close,size:18,color:P.muted)),
      ]),
    ])));
  }

  Widget countryFlag(String code)=>flags.CountryFlag.fromCountryCode(code,theme:const flags.ImageTheme(width:24,height:17,shape:flags.RoundedRectangle(3)));

  void chooseRegistrationCountry({required bool phone}){
    // Capture the local theme because the root navigator lives outside the app's Theme.
    showCountryPicker(context:context,showPhoneCode:phone,useSafeArea:true,favorite:const ['PK'],
      customFlagBuilder:(country)=>countryFlag(country.countryCode),
      header:Padding(padding:const EdgeInsets.all(16),child:Text(phone?'Select country calling code':'Select country',style:TextStyle(color:P.text,fontWeight:FontWeight.w800,fontSize:18))),
      countryListTheme:CountryListThemeData(backgroundColor:P.surface2,textStyle:TextStyle(color:P.text,fontSize:14),searchTextStyle:TextStyle(color:P.text),
        bottomSheetHeight:MediaQuery.sizeOf(context).height*.78,bottomSheetWidth:500,
        borderRadius:const BorderRadius.vertical(top:Radius.circular(20)),
        inputDecoration:InputDecoration(hintText:'Search by name or code',hintStyle:TextStyle(color:P.muted),
          prefixIcon:Icon(Icons.search,color:P.muted),filled:true,fillColor:P.surface,
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:P.border)),
          focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:P.teal)))),
      onSelect:(country)=>updateView((){
        if(phone){phoneCountry=country;updatePhoneNumber(registrationData['Phone Local']??'');}
        else {registrationData['Country']=country.name;registrationData['Country Code']=country.countryCode;formErrors.remove('Country');}
      }));
  }

  void updatePhoneNumber(String value){
    registrationData['Phone Local']=value;
    registrationData['Phone Number']='+${phoneCountry.phoneCode}$value';
    formErrors.remove('Phone Number');
  }

  Widget analystPhoneField()=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Phone Number *',style:TextStyle(color:P.muted,fontSize:11)),gap(8),
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Semantics(label:'Select country calling code',button:true,child:InkWell(onTap:()=>chooseRegistrationCountry(phone:true),borderRadius:BorderRadius.circular(12),child:Container(
        height:55,padding:const EdgeInsets.symmetric(horizontal:10),decoration:BoxDecoration(color:P.surface2,border:Border.all(color:P.border),borderRadius:BorderRadius.circular(12)),
        child:Row(mainAxisSize:MainAxisSize.min,children:[countryFlag(phoneCountry.countryCode),const SizedBox(width:7),Text('+${phoneCountry.phoneCode}',style:const TextStyle(fontSize:12)),const Icon(Icons.arrow_drop_down,size:18)])))),
      const SizedBox(width:8),Expanded(child:TextFormField(key:ValueKey('phone-local-$role'),initialValue:registrationData['Phone Local']??'',keyboardType:TextInputType.phone,
        inputFormatters:[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(14)],onChanged:(v)=>updateView(()=>updatePhoneNumber(v)),
        decoration:const InputDecoration(hintText:'3001234567',contentPadding:EdgeInsets.symmetric(horizontal:12,vertical:16)))),
    ]),gap(5),Text('Enter the number without the country calling code.',style:TextStyle(color:P.muted,fontSize:10)),
    inlineSelectionError('Phone Number'),
  ]));

  Widget analystCountryField()=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Country *',style:TextStyle(color:P.muted,fontSize:11)),gap(8),
    InkWell(onTap:()=>chooseRegistrationCountry(phone:false),borderRadius:BorderRadius.circular(12),child:InputDecorator(
      decoration:InputDecoration(errorText:formErrors['Country'],suffixIcon:const Icon(Icons.arrow_drop_down)),
      child:Row(children:[if(registrationData['Country Code']!=null)...[countryFlag(registrationData['Country Code']!),const SizedBox(width:10)],
        Expanded(child:Text(registrationData['Country']??'Select country',style:TextStyle(color:registrationData['Country']==null?P.muted:P.text,fontSize:14)))]))),
  ]));
}
