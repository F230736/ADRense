part of '../../main.dart';

extension _AdminverifyViews on _ADRenseAppState {
  Widget adminApplicantDetail(){final a=selectedApplicant;if(a==null)return Text('No applicant selected');
    return _pinnedHeaderPage(
      adminDetailHeading('Verification Details','adminDash',a['status']!,
        a['status']=='Pending'?P.warning:a['status']=='Verified'?P.success:P.danger),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      adminDataCard('Applicant Information',[
        ('Full Name',a['name']!),('Email Address',a['email']!),('Phone Number',a['phone']!),
        ('Country',a['country']!),('Professional Role',a['role']!),
        ('Professional Email',a['professional_email']!),('Account Email',a['email_verified']!),
      ]),gap(12),
      adminDataCard('Professional Information',[
        ('Profession',a['profession']!),('Qualification / Degree',a['qualification']!),
        ('University / Institution',a['institution']!),('Graduation Year',a['graduation']!),
      ]),gap(12),
      adminDataCard('Professional Registration',[
        ('License / Registration Number',a['license']!),('Issuing Authority',a['authority']!),
        ('Expiry Date',a['expiry']!),
      ]),gap(12),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Verification Documents',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800)),gap(12),
        if((applicationDocuments[a['id']]??[]).isEmpty)Text('No documents submitted. This application cannot be approved.',style:TextStyle(color:P.warning,fontSize:12)),
        for(final document in applicationDocuments[a['id']]??<Map<String,dynamic>>[])...[
          Row(children:[badge(document['media_type']=='application/pdf'?'PDF':'Image',color:adminPurple),SizedBox(width:8),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(documentLabel(document['kind'].toString()),style:TextStyle(fontSize:11,fontWeight:FontWeight.w600)),
              Text(document['filename'].toString(),style:TextStyle(fontSize:10,color:P.muted)),
            ])),
            TextButton(onPressed:()=>viewAnalystDocument(document),child:Text('View',style:TextStyle(color:adminPurple,fontSize:11))),
          ]),Divider(height:1,color:P.border),
        ],
      ])),gap(14),
      if((a['reason']??'').isNotEmpty)...[Text('Review notes: ${a['reason']}',style:TextStyle(color:P.muted,fontSize:12)),gap(12)],
      if(reviewBusy)const LinearProgressIndicator(),
      if(a['status']=='Pending')Row(children:[
        Expanded(child:adminAction('Approve Analyst',P.success,()=>reviewSelectedAnalyst('approve'))),SizedBox(width:8),
        Expanded(child:adminAction('Reject Application',P.danger,rejectSelectedAnalyst,outline:true)),
      ]),
    ]));
  }
  Widget adminAction(String text,Color accent,VoidCallback action,{bool outline=false})=>
    SizedBox(height:46,child:OutlinedButton(onPressed:reviewBusy?null:action,style:OutlinedButton.styleFrom(
      backgroundColor:outline?Colors.transparent:accent,
      foregroundColor:outline?accent:P.navy,side:BorderSide(color:accent.withValues(alpha:.7)),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(11)),
      padding:EdgeInsets.symmetric(horizontal:8)),
      child:Text(text,textAlign:TextAlign.center,style:TextStyle(fontSize:11,fontWeight:FontWeight.w800))));
  List<Widget> adminDecisions()=>[
    adminIntro('Analyst Decision Review','Review decisions made by analysts on AI-generated ADR findings.'),
    Row(children:[
      Expanded(child:adminStat('${decisions.where((d)=>d['status']=='Awaiting').length}','Awaiting',P.warning)),
      SizedBox(width:8),Expanded(child:adminStat('18','Approved',P.success)),
      SizedBox(width:8),Expanded(child:adminStat('2','Returned',adminPurple)),
    ]),gap(13),
    for(final d in decisions)...[
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${d['drug']} → ${d['finding']}',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800)),gap(10),
        Wrap(spacing:6,runSpacing:6,children:[
          badge('AI ${d['confidence']}%',color:P.success),
          badge(d['decision']!,color:d['decision']=='Verified'?P.success:P.danger),
          badge(d['status']=='Awaiting'?'Awaiting Admin Review':d['status']!,color:P.warning),
        ]),gap(10),
        Text('Analyst: ${d['analyst']}\nReviewed: ${d['reviewed']}',
          style:TextStyle(color:P.muted,fontSize:10,height:1.5)),
        if(d['decision']=='Rejected')...[gap(8),Text('Reason: ${d['reason']}',
          style:TextStyle(color:P.muted,fontSize:10,height:1.5))],
        gap(12),InkWell(onTap:()=>setState((){selectedAdminDecision=d;screen='adminDecision';}),
          child:Text('Review Decision →',style:TextStyle(color:adminPurple,fontSize:12,fontWeight:FontWeight.w800))),
      ])),gap(10),
    ],
  ];

}
