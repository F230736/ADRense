part of '../../main.dart';

extension _AdminuserViews on _ADRenseAppState {
  Widget adminUserDetail(){final u=selectedUser;if(u==null)return Text('No user selected');
    return _pinnedHeaderPage(
      adminDetailHeading('User Details','adminDash',u['status']!,
        u['status']=='Restricted'?P.danger:P.success),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      adminDataCard('',[
        ('Name',u['name']!),('Email',u['email']!),('Account Type',u['role']!),
        ('Account Status',u['status']!),('Created Date',u['created']!),('Email Ownership',u['email_verified']!),
      ]),gap(14),
      Container(width:double.infinity,padding:EdgeInsets.all(12),
        decoration:BoxDecoration(color:P.teal.withValues(alpha:.04),border:Border.all(color:P.tealDim.withValues(alpha:.4)),
          borderRadius:BorderRadius.circular(11)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Privacy protected',style:TextStyle(color:P.teal,fontSize:11,fontWeight:FontWeight.w800)),
          SizedBox(height:7),Text('Medical conditions, medications, and personalized safety information are not available to administrators.',
            style:TextStyle(color:P.muted,fontSize:10,height:1.5)),
        ])),gap(12),
      if(userStatusBusy)LinearProgressIndicator(),
      if(['active','restricted'].contains(u['raw_status']))SizedBox(width:double.infinity,child:OutlinedButton(
        onPressed:userStatusBusy?null:()=>adminConfirmDialog(
          u['raw_status']=='restricted'?'Restore User Account?':'Restrict User Account?',
          u['raw_status']=='restricted'?'Restore access to this account. Email verification is still required.':'Sign out this user and prevent access until the account is restored.',
          u['raw_status']=='restricted'?'Restore Account':'Restrict Account',P.danger,changeSelectedUserStatus),
        child:Text(u['raw_status']=='restricted'?'Restore Account':'Restrict Account'))),
    ]));
  }
  List<Widget> adminDatasets()=>[
    adminIntro('Dataset Management',
      'Manage datasets used by ADRense for ADR analysis and drug-safety information.'),
    adminAction('＋ Add Dataset',P.teal,()=>toast('Dataset upload requires backend integration')),
    gap(13),
    for(final d in datasets)...[
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(d['name']!,style:TextStyle(fontSize:13,fontWeight:FontWeight.w800)),gap(4),
            Text('${d['source']} · Version ${d['version']}',
              style:TextStyle(color:P.muted,fontSize:10)),
          ])),badge(d['status']!,color:P.success),
        ]),gap(11),
        Text('${d['records']} Records     ${d['updated']} Last Updated',
          style:TextStyle(fontSize:11,fontWeight:FontWeight.w600)),gap(14),
        InkWell(onTap:()=>setState((){selectedDataset=d;screen='adminDataset';}),
          child:Text('View / Manage →',style:TextStyle(color:P.teal,fontSize:11,fontWeight:FontWeight.w800))),
      ])),gap(10),
    ],
  ];
}
