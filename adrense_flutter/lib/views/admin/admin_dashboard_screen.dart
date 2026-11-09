part of '../../main.dart';

extension _AdmindashViews on _ADRenseAppState {
  Widget adminBottomNav()=>Container(
    decoration:BoxDecoration(color:P.navy,border:Border(top:BorderSide(color:P.border))),
    padding:EdgeInsets.fromLTRB(0,8,0,13),child:Row(children:[
      for(final tab in [('Overview',Icons.home),('Verification',Icons.shield_outlined),
        ('Decisions',Icons.check),('Users',Icons.person_outline),('Datasets',Icons.bar_chart_outlined)])
        Expanded(child:InkWell(onTap:()=>selectAdminTab(tab.$1),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            Icon(tab.$2,size:21,color:adminTab==tab.$1?P.teal:P.muted),
            gap(5),Text(tab.$1,style:TextStyle(fontSize:9,
              fontWeight:adminTab==tab.$1?FontWeight.w700:FontWeight.w400,
              color:adminTab==tab.$1?P.teal:P.muted)),
          ]))),
    ]));
  Widget adminHeader()=>Row(children:[
    SizedBox(width:36,height:36,child:SvgPicture.asset('assets/logo.svg')),
    SizedBox(width:11),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Admin Dashboard',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17)),
      gap(3),Text('System Administration · ADRense',style:TextStyle(color:P.muted,fontSize:10)),
    ])),
    Column(mainAxisSize:MainAxisSize.min,children:[
      dashboardThemeControl(),
      logoutControl(),
    ]),
  ]);
  Widget adminStats()=>Column(children:[
    Row(children:[
      Expanded(child:adminStat('${applicants.where((a)=>a['status']=='Pending').length}','Pending Verifications',P.warning)),SizedBox(width:8),
      Expanded(child:adminStat(userSummary['active']?.toString()??'—','Active Users',P.success)),
    ]),gap(8),Row(children:[
      Expanded(child:adminStat('${decisions.where((d)=>d['status']=='Awaiting').length}','Decisions for Review',adminPurple)),
      SizedBox(width:8),Expanded(child:adminStat('${datasets.where((d)=>d['status']=='Active').length}','Active Datasets',P.teal)),
    ]),
  ]);
  Widget adminStat(String value,String label,Color color)=>Container(
    padding:EdgeInsets.all(12),
    decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(13),border:Border.all(color:P.border)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(value,style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:color)),
      gap(4),Text(label,style:TextStyle(fontSize:10,color:P.muted)),
    ]));
  Widget adminDash()=>_pinnedHeaderPage(adminHeader(),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    adminStats(),gap(20),
    if(adminTab=='Overview')...adminOverview()
    else if(adminTab=='Verification')...adminVerification()
    else if(adminTab=='Decisions')...adminDecisions()
    else if(adminTab=='Users')...adminUsers()
    else ...adminDatasets(),
  ]));
  Widget adminIntro(String titleText,String description)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(titleText,style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),gap(8),
    Text(description,style:TextStyle(color:P.muted,fontSize:12,height:1.55)),gap(17),
  ]);
  Widget adminOverviewTile(String titleText,Color accent,List<String> lines,String link,String tab)=>
    Container(width:double.infinity,padding:EdgeInsets.all(15),
      decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(17),
        border:Border.all(color:P.border)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(titleText,style:TextStyle(fontSize:14,fontWeight:FontWeight.w800)),gap(10),
        for(final line in lines)...[
          Text('• $line',style:TextStyle(color:P.muted,fontSize:12)),gap(7),
        ],gap(8),InkWell(onTap:()=>selectAdminTab(tab),
          child:Text('$link →',style:TextStyle(color:accent,fontWeight:FontWeight.w800,fontSize:12))),
      ]));
  List<Widget> adminOverview()=>[
    adminIntro('Administrative Overview','Live registration trends and accounts across ADRense.'),
    RegistrationChart(api:authApi,onSummary:(summary){if(mounted&&role=='admin')updateView(()=>userSummary=summary);}),gap(16),
    adminOverviewTile('Analyst Verification',P.warning,
      ['${applicants.where((a)=>a['status']=='Pending').length} Pending Requests','${applicants.where((a)=>a['status']=='Verified').length} Approved Analysts','${applicants.where((a)=>a['status']=='Rejected').length} Rejected Applications'],'Review Requests','Verification'),gap(12),
    adminOverviewTile('Registered Accounts',P.teal,
      ['${userSummary['total']??'—'} Total Accounts','${userSummary['general_users']??'—'} General Users','${userSummary['analysts']??'—'} Analysts'],'View Accounts','Users'),
  ];
}
