part of '../main.dart';

extension _ProfileActions on _ADRenseAppState {
  void applyProfileUser(Map<String,dynamic> user){
    activeAccountId=user['id']?.toString();
    profile['Full Name']=user['name']?.toString()??'';
    profile['Email']=user['email']?.toString()??'';
    profile['created_at']=user['created_at']?.toString()??'';
    final p=user['profile'] as Map<String,dynamic>?;
    if(p==null)return;
    profile['Age Group']=p['age_group']?.toString()??'';
    profile['Biological Sex']=p['gender']?.toString()??'';
    profile['Weight Range']=p['weight_range']?.toString()??'';
    for(final entry in {'Medical Conditions':'medical_conditions','Current Medications':'current_medications','Allergies':'allergies'}.entries){
      profileLists[entry.key]=List<String>.from(p[entry.value] as List? ?? []);
    }
    medicationDoses..clear()..addAll(Map<String,String>.from(p['medication_doses'] as Map? ?? {}));
  }
  Future<bool> persistProfile(Map<String,dynamic> changes) async {
    if(profileSaving)return false;
    final owner=activeAccountId;
    updateView((){profileSaving=true;profileSaveError=null;});
    try{
      final result=await authApi.updateProfile(changes);
      if(!mounted||activeAccountId!=owner)return false;
      updateView(()=>applyProfileUser(Map<String,dynamic>.from(result['user'] as Map)));
      toast('Profile saved');return true;
    }on AuthApiException catch(e){if(mounted)updateView(()=>profileSaveError=e.message);return false;}
    finally{if(mounted)updateView(()=>profileSaving=false);}
  }
  Future<void> saveBasicProfileField(String label,String fallback) async {
    if(profileSaving)return;
    final value=(basicDrafts[label]??profile[label]??fallback).trim();
    String? error;
    if(label=='Full Name'&&!validName(value))error='Enter first and last name using letters only';
    if(label=='Email'&&!validEmail(value))error='Enter a valid email address';
    if(value.isEmpty)error='This field is required';
    if(error!=null){updateView(()=>formErrors['profile-$label']=error!);return;}
    if(label=='Email'){
      if(value.toLowerCase()==profile['Email']?.toLowerCase()){updateView(()=>inlineBasicKey='');return;}
      await changeProfileEmail(value.toLowerCase());return;
    }
    final field={'Full Name':'name','Age Group':'age_group','Biological Sex':'gender','Weight Range':'weight_range'}[label];
    if(field==null)return;
    if(await persistProfile({field:value})&&mounted)updateView((){inlineBasicKey='';basicDrafts.remove(label);formErrors.remove('profile-$label');});
  }
  Future<void> changeProfileEmail(String email) async {
    if(profileSaving)return;
    final owner=activeAccountId;
    if(pendingProfileEmail!=email){
      updateView((){profileSaving=true;profileSaveError=null;});
      try{
        final response=await authApi.requestEmailChange(email);
        if(!mounted||activeAccountId!=owner)return;
        pendingProfileEmail=response['email']?.toString()??email;emailChangeSentAt=DateTime.now();
      }on AuthApiException catch(e){if(mounted)updateView(()=>profileSaveError=e.message);return;}
      finally{if(mounted)updateView(()=>profileSaving=false);}
    }
    if(!mounted||activeAccountId!=owner)return;
    final result=await showDialog<Map<String,dynamic>>(context:context,barrierDismissible:false,builder:(ctx)=>Theme(data:AdrenseTheme.build(lightMode),
      child:EmailChangeDialog(api:authApi,email:email,sentAt:emailChangeSentAt??DateTime.now(),onSent:(date)=>emailChangeSentAt=date)));
    if(result==null||!mounted||activeAccountId!=owner)return;
    if(result['requires_sign_in']==true){await go('login');if(mounted)toast(result['message']?.toString()??'Please sign in again.');return;}
    updateView((){applyProfileUser(Map<String,dynamic>.from(result['user'] as Map));pendingProfileEmail=null;emailChangeSentAt=null;inlineBasicKey='';basicDrafts.remove('Email');});
    toast('Email verified and updated');
  }
  Future<void> saveProfileList(String section,{String? old,bool remove=false}) async {
    if(profileSaving)return;
    final items=List<String>.from(profileLists[section]!);
    final doses=Map<String,String>.from(medicationDoses);
    final value=profileItemDraft.trim();
    if(!remove&&(value.isEmpty||value.length>120)){
      updateView(()=>profileSaveError='Enter a name with 1–120 characters');return;
    }
    if(!remove&&items.any((item)=>item!=old&&item.toLowerCase()==value.toLowerCase())){
      updateView(()=>profileSaveError='That item is already listed');return;
    }
    if(old!=null){
      final index=items.indexOf(old);if(index<0)return;
      if(remove){items.removeAt(index);}else{items[index]=value;}
      if(section=='Current Medications')doses.remove(old);
    }else{items.add(value);}
    if(section=='Current Medications'&&!remove&&profileDoseDraft.trim().isNotEmpty)doses[value]=profileDoseDraft.trim();
    final field={'Medical Conditions':'medical_conditions','Current Medications':'current_medications','Allergies':'allergies'}[section]!;
    if(await persistProfile({field:items,if(section=='Current Medications')'medication_doses':doses})&&mounted){
      updateView((){profileEntry='';inlineListItem='';profileItemDraft='';profileDoseDraft='';});
    }
  }
  Widget basicProfileEditor(String label,String fallback){
    final choices=switch(label){'Age Group'=>['18–25','26–35','36–50','51–65','65+'],'Biological Sex'=>['Male','Female','Other'],'Weight Range'=>['<50kg','50–70kg','70–90kg','90–110kg','>110kg'],_ => <String>[]};
    if(choices.isNotEmpty){
      final current=(basicDrafts[label]??profile[label]??'').replaceAll(' ','').replaceAll('-','–');
      return DropdownButtonFormField<String>(key:ValueKey('basic-$label'),initialValue:choices.contains(current)?current:null,
        isExpanded:true,dropdownColor:P.surface2,items:choices.map((value)=>DropdownMenuItem(value:value,child:Text(value,style:const TextStyle(fontSize:12)))).toList(),
        onChanged:profileSaving?null:(value){if(value!=null)basicDrafts[label]=value;},decoration:InputDecoration(hintText:label,errorText:formErrors['profile-$label']));
    }
    return TextFormField(key:ValueKey('basic-$label'),initialValue:basicDrafts[label]??profile[label]??fallback,enabled:!profileSaving,
      onChanged:(value){basicDrafts[label]=value;if(formErrors.containsKey('profile-$label'))updateView(()=>formErrors.remove('profile-$label'));},
      inputFormatters:label=='Full Name'?[FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]'))]:[FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      keyboardType:label=='Email'?TextInputType.emailAddress:TextInputType.text,
      decoration:InputDecoration(contentPadding:const EdgeInsets.all(9),errorText:formErrors['profile-$label'],errorMaxLines:3));
  }
  Widget savedProfileListCard(String name){
    final items=profileLists[name]!;
    final editing=profileEditing==name;
    return card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(name,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:14))),badge('${items.length}'),const SizedBox(width:10),
        smallBtn(editing?'Done':'Edit',(){if(profileSaving)return;updateView((){profileEditing=editing?'':name;profileEntry='';inlineListItem='';profileSaveError=null;});},color:editing?P.teal:P.muted)]),gap(12),
      if(items.isEmpty)Text('No ${name.toLowerCase()} added.',style:TextStyle(color:P.muted,fontSize:12)),
      for(final item in items)...[
        Row(children:[Icon(name=='Current Medications'?Icons.medication_outlined:Icons.circle,size:name=='Current Medications'?22:8,color:name=='Allergies'?P.danger:P.teal),const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
            if(name=='Current Medications')Text(medicationDoses[item]??'Dose not set',style:TextStyle(color:P.muted,fontSize:11))])),
          if(editing)...[
            TextButton(onPressed:profileSaving?null:()=>updateView((){inlineListItem=item;profileEntry='';profileItemDraft=item;profileDoseDraft=medicationDoses[item]??'';}),child:const Text('Edit',style:TextStyle(fontSize:11))),
            IconButton(tooltip:'Remove $item',onPressed:profileSaving?null:()=>saveProfileList(name,old:item,remove:true),icon:Icon(Icons.close,size:17,color:P.danger)),
          ],
        ]),
        if(editing&&inlineListItem==item)profileListForm(name,old:item),
        gap(9),Divider(height:1,color:P.border),gap(9),
      ],
      if(editing)...[
        if(profileEntry==name)profileListForm(name)
        else TextButton.icon(onPressed:profileSaving?null:()=>updateView((){profileEntry=name;inlineListItem='';profileItemDraft='';profileDoseDraft='';}),
          icon:const Icon(Icons.add,size:18),label:Text(name=='Medical Conditions'?'Add condition':name=='Current Medications'?'Add medication':'Add allergy')),
      ],
    ]));
  }
  Widget profileListForm(String section,{String? old})=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Column(children:[
    TextFormField(key:ValueKey('profile-item-$section-$old'),initialValue:profileItemDraft,enabled:!profileSaving,maxLength:120,
      onChanged:(value)=>profileItemDraft=value,decoration:const InputDecoration(labelText:'Name')),
    if(section=='Current Medications')TextFormField(key:ValueKey('profile-dose-$old'),initialValue:profileDoseDraft,enabled:!profileSaving,maxLength:120,
      onChanged:(value)=>profileDoseDraft=value,decoration:const InputDecoration(labelText:'Dose (optional)')),
    Row(children:[TextButton(onPressed:profileSaving?null:()=>saveProfileList(section,old:old),child:Text(old==null?'Add':'Save')),
      TextButton(onPressed:profileSaving?null:()=>updateView((){profileEntry='';inlineListItem='';}),child:const Text('Cancel'))]),
  ]));
}
