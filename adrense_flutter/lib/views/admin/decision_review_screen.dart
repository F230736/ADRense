part of '../../main.dart';

extension _AdmindecisionViews on _ADRenseAppState {
  Widget adminDecisionDetail(){
    final d=selectedAdminDecision;
    if(d==null)return Text('No decision selected');
    return _pinnedHeaderPage(
      adminDetailHeading('Decision Review','adminDash',d['status']!,P.warning),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('AI FINDING',style:TextStyle(color:P.teal,fontSize:10,letterSpacing:1.1)),
        gap(12),
        rowKV('Drug',d['drug']!),rowKV('ADR',d['finding']!),
        rowKV('AI Confidence','${d['confidence']}%'),
        gap(7),Divider(color:P.border),
        gap(8),Text('Extracted Evidence',style:TextStyle(color:P.muted,fontSize:10)),
        gap(7),
        Text('Patient developed elevated lactate, weakness, and rapid breathing after a dose increase. Three associated reports show the same temporal relationship.',
          style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,height:1.6)),
      ])),gap(11),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('ANALYST REVIEW',style:TextStyle(color:adminPurple,fontSize:10,letterSpacing:1.1)),
        gap(12),rowKV('Analyst',d['analyst']!),
        rowKV('Decision',d['decision']!),rowKV('Review Date',d['reviewed']!),
        gap(8),Divider(color:P.border),
        gap(7),Text('Review Reason / Comments',style:TextStyle(color:P.muted,fontSize:10)),
        gap(7),Text(d['reason']??'The extracted relationship is supported by the report chronology and known risk profile.',
          style:TextStyle(fontSize:11,height:1.5,fontWeight:FontWeight.w600)),
      ])),gap(11),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Supporting Evidence',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800)),
        gap(12),
        for(final e in ['Associated ADR reports · 3 records','Drug safety reference · Current','Patient details · Anonymized'])...[
          Row(children:[Icon(Icons.check,size:14,color:P.success),SizedBox(width:8),
            Expanded(child:Text(e,style:TextStyle(color:P.muted,fontSize:11)))]),
          gap(9),Divider(height:1,color:P.border),gap(9),
        ],
      ])),gap(12),
      Row(children:[
        Expanded(child:adminAction('Approve Analyst Decision',P.success,(){
          setState((){d['status']='Approved';screen='adminDash';});
          toast('Analyst decision approved');
        })),
        SizedBox(width:8),
        Expanded(child:adminAction('Return for Reconsideration',adminPurple,()=>
          adminConfirmDialog(
            'Return for Reconsideration?',
            'The analyst will be asked to review this decision again.',
            'Return Decision',adminPurple,(){
              setState((){d['status']='Returned';screen='adminDash';});
              toast('Decision returned for reconsideration');
            }),outline:true)),
      ]),
    ]));
  }
  List<Widget> adminUsers()=>[
    adminIntro('User Management',
      'View and manage ADRense user accounts without exposing private health-profile data.'),
    Row(children:[Expanded(child:Text('${users.length} registered accounts',style:TextStyle(color:P.muted,fontSize:12))),TextButton.icon(onPressed:usersBusy?null:loadAdminUsers,icon:Icon(Icons.refresh,size:18),label:Text('Refresh'))]),
    if(usersBusy)LinearProgressIndicator(),
    if(usersError!=null)...[Text(usersError!,style:TextStyle(color:P.danger)),gap(10)],
    TextField(onChanged:(v)=>setState(()=>userQuery=v),
      decoration:InputDecoration(prefixIcon:Icon(Icons.search,color:P.muted),hintText:'Search by name or email...')),
    gap(11),adminFilter(['All','General Users','Analysts','Active'],userFilter,(v)=>userFilter=v),gap(15),
    if(!usersBusy&&usersError==null&&filteredAdminUsers.isEmpty)Padding(padding:EdgeInsets.symmetric(vertical:24),child:Text(users.isEmpty?'No registered users yet.':'No accounts match your search.',style:TextStyle(color:P.muted))),
    for(final u in filteredAdminUsers)...[
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          CircleAvatar(radius:18,backgroundColor:P.teal.withValues(alpha:.12),
            child:Text(u['name']!.split(' ').where((v)=>v.isNotEmpty).map((v)=>v[0]).take(2).join(),
              style:TextStyle(color:P.teal,fontSize:11,fontWeight:FontWeight.w800))),
          SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(u['name']!,style:TextStyle(fontSize:12,fontWeight:FontWeight.w800)),gap(4),
            Text(u['role']!,style:TextStyle(color:P.muted,fontSize:10)),gap(4),
            Text(u['email']!,style:TextStyle(color:P.muted,fontSize:10)),
          ])),badge(u['status']!,color:['Restricted','Rejected'].contains(u['status'])?P.danger:u['status']=='Active'?P.success:P.warning),
        ]),gap(13),InkWell(onTap:()=>setState((){selectedUser=u;screen='adminUser';}),
          child:Text('View Account →',style:TextStyle(color:P.teal,fontSize:11,fontWeight:FontWeight.w800))),
      ])),gap(10),
    ],
  ];
}
