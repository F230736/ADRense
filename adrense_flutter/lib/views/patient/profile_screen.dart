part of '../../main.dart';

String _joinLabel(dynamic raw) {
  if (raw == null || raw.toString().trim().isEmpty) return 'Recently joined';
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return 'Recently joined';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final date = parsed.toLocal();
  return 'Since ${months[date.month - 1]} ${date.year}';
}

String _profileInitials(String? name) {
  final parts=(name??'').trim().split(RegExp(r'\s+')).where((p)=>p.isNotEmpty).toList();
  if(parts.isEmpty)return '?';
  return (parts.length==1?parts.first.substring(0,1):parts.first.substring(0,1)+parts.last.substring(0,1)).toUpperCase();
}

extension _ProfileViews on _ADRenseAppState {
  Widget healthProfile()=>Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
    Row(crossAxisAlignment:CrossAxisAlignment.start,children: [
      Container(width:52,height:52,alignment:Alignment.center,
        decoration:BoxDecoration(shape:BoxShape.circle,
          gradient:context.tokens.primaryGradient,
          border:Border.all(color:P.teal.withValues(alpha:.30),width:2),
          boxShadow:context.tokens.softGlow),
        child:Text(_profileInitials(profile['Full Name']),style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
      SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(profile['Full Name']??'Raahim Ishtiaq',maxLines:1,overflow:TextOverflow.ellipsis,
          style:TextStyle(fontWeight:FontWeight.w800,fontSize:15)),
        Text(profile['Email']??'raahim.ishtiaq@gmail.com',maxLines:1,overflow:TextOverflow.ellipsis,
          style:TextStyle(color:P.muted,fontSize:11)),
        gap(6),Wrap(spacing:5,runSpacing:5,children:[badge('General User'),badge(_joinLabel(profile['created_at']),color:P.muted)]),
      ])),
      SizedBox(width:6),
      Column(mainAxisSize:MainAxisSize.min,children:[
        IconButton(tooltip:lightMode?'Switch to dark mode':'Switch to light mode',
          onPressed:toggleTheme,icon:AnimatedSwitcher(duration:AdrenseMotion.standard,
            transitionBuilder:(child,animation)=>RotationTransition(turns:animation,child:FadeTransition(opacity:animation,child:child)),
            child:Icon(lightMode?Icons.dark_mode_outlined:Icons.light_mode_outlined,
              key:ValueKey(lightMode),color:P.teal,size:21)),visualDensity:VisualDensity.compact),
        logoutControl(),
      ]),
    ]),
    gap(20),
    Container(height:3,decoration:BoxDecoration(gradient:context.tokens.primaryGradient,borderRadius:BorderRadius.circular(8))),
    gap(22),
    if(profileSaving)...[const LinearProgressIndicator(),gap(10)],
    if(profileSaveError!=null)...[Text(profileSaveError!,style:TextStyle(color:P.danger,fontSize:12)),gap(12)],
    profileCard('Basic Information',[
      ('Full Name',''),('Email',''),
      ('Age Group',''),('Biological Sex',''),('Weight Range',''),
    ]),
    gap(12),
    profileListCard('Medical Conditions'),
    gap(12),
    profileListCard('Current Medications'),
    gap(12),
    profileListCard('Allergies'),
    gap(12),
    profileListCard('Previous ADRs'),
    gap(16),
  ]);
  Widget profileCard(String name,List<(String,String)> rows)=>card(
    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Expanded(child:Text(name,style:TextStyle(fontWeight:FontWeight.w700,fontSize:14))),
        smallBtn(profileEditing==name?'Done':'Edit',()=>setState((){
          profileEditing=profileEditing==name?'':name;inlineBasicKey='';
        }),color:profileEditing==name?P.teal:P.muted),
      ]),gap(11),
      for(final row in rows)...[
        Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(row.$1,style:TextStyle(color:P.muted,fontSize:11)),gap(5),
            if(profileEditing==name&&inlineBasicKey==row.$1)
              basicProfileEditor(row.$1,row.$2)
            else Tooltip(message:profile[row.$1]??row.$2,child:SingleChildScrollView(scrollDirection:Axis.horizontal,
              child:Text((profile[row.$1]??row.$2).isEmpty?'Not provided':profile[row.$1]??row.$2,
                key:ValueKey('profile-value-${row.$1}'),maxLines:1,softWrap:false,
                style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)))),
          ])),
          if(profileEditing==name)...[
            const SizedBox(width:8),
            SizedBox(width:88,child:Row(children:[
              SizedBox(width:56,child:TextButton(
                key:ValueKey('profile-action-${row.$1}'),
                onPressed:profileSaving?null:(){
                  if(inlineBasicKey==row.$1){saveBasicProfileField(row.$1,row.$2);}
                  else{setState((){inlineBasicKey=row.$1;profileSaveError=null;});}
                },
                style:TextButton.styleFrom(foregroundColor:P.teal,padding:EdgeInsets.zero,minimumSize:const Size(56,40)),
                child:Text(inlineBasicKey==row.$1?'Save':'Edit',style:const TextStyle(fontSize:11)))),
              SizedBox(width:32,child:IconButton(key:ValueKey('profile-cancel-${row.$1}'),
                tooltip:'Cancel editing ${row.$1}',constraints:const BoxConstraints.tightFor(width:32,height:40),padding:EdgeInsets.zero,
                onPressed:profileSaving?null:()=>setState((){basicDrafts.remove(row.$1);formErrors.remove('profile-${row.$1}');if(inlineBasicKey==row.$1)inlineBasicKey='';profileSaveError=null;}),
                icon:Icon(Icons.close,color:P.danger,size:18)))
            ])),
          ],
        ]),
        gap(10),Divider(color:P.border,height:1),gap(10),
      ],
    ]));
  Widget profileListCard(String name) {
    if(name!='Previous ADRs')return savedProfileListCard(name);
    final items=profileLists[name]!;
    final editing=profileEditing==name;
    final accent=name=='Allergies'?P.danger:P.teal;
    return card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Row(children: [
        Expanded(child:Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,fontSize:14))),
        SizedBox(width:8),
        badge('${items.length}'),
        SizedBox(width:10),
        smallBtn(editing?'Done':'Edit',()=>setState(() {
          profileEditing=editing?'':name;
          profileEntry='';inlineListItem='';
        }),color: editing?P.teal:P.muted),
      ]),
      gap(12),
      if(name=='Allergies') ...[
        Wrap(spacing: 7,runSpacing: 8,children: [
          for(final item in items)
            Container(padding: EdgeInsets.symmetric(horizontal: 11,vertical: 8),
              decoration: BoxDecoration(color: P.danger.withValues(alpha: .07),
                border: Border.all(color: P.danger.withValues(alpha: .25)),
                borderRadius: BorderRadius.circular(9)),
              child: Row(mainAxisSize: MainAxisSize.min,children: [
                Icon(Icons.circle,color: P.danger,size: 8),SizedBox(width: 8),
                Text(item,style: TextStyle(fontSize: 12)),
                if(editing) ...[SizedBox(width: 7),InkWell(
                  onTap: ()=>setState(()=>items.remove(item)),
                  child: Icon(Icons.close,color: P.danger,size: 13))],
              ])),
        ]),
      ] else ...[
        for(final item in List<String>.from(items)) ...[
          Row(children: [
            if(name=='Current Medications')
              Container(width: 35,height: 35,alignment: Alignment.center,
                decoration: BoxDecoration(color: P.teal.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.medication_outlined,color: P.teal,size: 18))
            else Icon(Icons.circle,color: P.success,size: 8),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
              Text(item,style: TextStyle(fontWeight: FontWeight.w700,fontSize: 12)),
              Text(name=='Medical Conditions'?'Since ${items.indexOf(item)+2021}':
                name=='Current Medications'?
                  (medicationDoses[item]??'Dose not set'):
                  item.startsWith('Metformin')?'Jan 2025':'Mar 2024',
                style: TextStyle(color: P.muted,fontSize: 10)),
            ])),
            if(editing) ...[
              InkWell(onTap: ()=>setState(()=>inlineListItem=inlineListItem==item?'':item),
                child: Text('Edit',style: TextStyle(color: P.teal,fontSize: 11))),
              SizedBox(width: 8),
              InkWell(onTap: ()=>setState(()=>items.remove(item)),
                child: Text('Remove',style: TextStyle(color: P.danger,fontSize: 11))),
            ] else if(name!='Current Medications')
              badge(name=='Medical Conditions'?(item=='Hypertension'?'Controlled':'Managed'):'Resolved',
                color: P.success)
            else Icon(Icons.chevron_right,color: P.muted,size: 17),
          ]),
          if(editing&&inlineListItem==item)...[
            gap(8),TextFormField(key:ValueKey('edit-$item'),initialValue:item,
              onChanged:(v)=>registrationData['editItem']=v,
              decoration:InputDecoration(contentPadding:EdgeInsets.all(9))),
            gap(6),smallBtn('Save',()=>setState((){
              final v=(registrationData['editItem']??item).trim();
              final idx=items.indexOf(item);if(idx>=0&&v.isNotEmpty)items[idx]=v;
              inlineListItem='';registrationData.remove('editItem');
            })),
          ],
          gap(10),
          Divider(color: P.border,height: 1),
          gap(10),
        ],
      ],
      if(editing) ...[
        if(profileEntry==name)
          Column(children: [
            TextField(autofocus: true,
              onChanged: (v)=>registrationData['newItem']=v,
              decoration: InputDecoration(hintText: name=='Allergies'?'Allergen name':'Enter item name',
                contentPadding: EdgeInsets.all(10))),
            if(name=='Current Medications')...[gap(8),TextField(
              onChanged:(v)=>registrationData['newDose']=v,
              decoration:InputDecoration(hintText:'Dose (e.g. 100mg once daily)',
                contentPadding:EdgeInsets.all(10)))],
            gap(8),Row(children:[Expanded(child:smallBtn('Add',(){
              final value=(registrationData['newItem']??'').trim();
              if(value.isNotEmpty)setState(() {items.add(value);if(name=='Current Medications'){medicationDoses[value]=registrationData['newDose']??'Dose not set';}profileEntry='';registrationData.remove('newItem');registrationData.remove('newDose');});
            },color: accent)),
            SizedBox(width:7),
            Expanded(child:smallBtn('Cancel',()=>setState(()=>profileEntry=''),color:P.muted)),
            ]),
          ])
        else InkWell(onTap: () {
          if(name=='Previous ADRs'){setState(() {profileEditing='';profileEntry='';});go('adrAnalysis');}
          else setState(()=>profileEntry=name);
        },
          child: Container(width: double.infinity,height: 43,alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: .04),
              border: Border.all(color: accent.withValues(alpha: .35),style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(9)),
            child: Text(name=='Medical Conditions'?'+ Add New Condition':
              name=='Current Medications'?'+ Add Medication':
              name=='Allergies'?'+ Add Allergy':'+ Add ADR Record',
              style: TextStyle(color: accent,fontWeight: FontWeight.w700,fontSize: 12)))),
      ],
    ]));
  }
  Future<void> showEditItem(String name,String old) async {
    final controller=TextEditingController(text: old);
    final result=await showDialog<String>(context: context,builder: (context)=>AlertDialog(
      backgroundColor: P.surface2,
      title: Text('Edit ${name.toLowerCase()}'),
      content: TextField(controller: controller,autofocus: true),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context),child: Text('Cancel')),
        TextButton(onPressed: ()=>Navigator.pop(context,controller.text),child: Text('Save')),
      ]));
    if(result!=null&&result.trim().isNotEmpty){
      setState(() {
        final list=profileLists[name]!;
        final index=list.indexOf(old);
        if(index>=0)list[index]=result.trim();
      });
    }
    controller.dispose();
  }
}
