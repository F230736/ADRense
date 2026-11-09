import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:convert' show utf8;
import 'package:file_picker/file_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:country_flags/country_flags.dart' as flags;
import 'package:pdfrx/pdfrx.dart';
import 'core/registration_inputs.dart';
import 'views/admin/registration_chart.dart';
import 'views/patient/medication_analysis_panel.dart';
import 'views/auth/email_change_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'core/theme/adrense_theme.dart';
import 'core/widgets/premium_widgets.dart';
import 'core/widgets/animated_search_field.dart';
import 'features/splash/cinematic_splash.dart';
import 'features/charts/animated_charts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'services/api_service.dart';
import 'services/theme_preference_store.dart';


part 'theme/palette.dart';
part 'services/app_session.dart';
part 'widgets/custom_cards.dart';
part 'widgets/custom_buttons.dart';
part 'widgets/bottom_navigation.dart';
part 'views/auth/splash_screen.dart';
part 'views/auth/registration_screen.dart';
part 'views/auth/login_screen.dart';
part 'views/auth/email_auth_screen.dart';
part 'views/auth/analyst_registration_widgets.dart';
part 'views/admin/analyst_review_actions.dart';
part 'views/admin/user_management_actions.dart';
part 'views/patient/home_screen.dart';
part 'views/patient/drug_search_screen.dart';
part 'views/patient/drug_detail_screen.dart';
part 'views/patient/adr_analysis_screen.dart';
part 'views/patient/pharma_dashboard_screen.dart';
part 'views/patient/personalized_evidence_screen.dart';
part 'views/patient/drug_comparison_screen.dart';
part 'views/patient/alerts_screen.dart';
part 'views/patient/profile_screen.dart';
part 'services/profile_actions.dart';
part 'views/analyst/analyst_dashboard_screen.dart';
part 'views/analyst/analyst_review_screen.dart';
part 'views/analyst/signal_investigation_screen.dart';
part 'views/analyst/analyst_drug_screen.dart';
part 'views/analyst/analyst_report_screen.dart';
part 'views/admin/admin_dashboard_screen.dart';
part 'views/admin/admin_management_screen.dart';
part 'views/admin/verification_details_screen.dart';
part 'views/admin/decision_review_screen.dart';
part 'views/admin/user_details_screen.dart';
part 'views/admin/dataset_details_screen.dart';
part 'widgets/chart_painters.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const ADRense());}
class ADRense extends StatelessWidget {
  const ADRense({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'ADRense',
    theme: AdrenseTheme.build(true),
    darkTheme: AdrenseTheme.build(false),
    themeMode: ThemeMode.light,
    home:const ADRenseApp(),
  );
}
class ADRenseApp extends StatefulWidget {const ADRenseApp({super.key,this.api,this.themePreference});final ApiService? api;final ThemePreferenceStore? themePreference;@override State<ADRenseApp> createState()=>_ADRenseAppState();}
class _ADRenseAppState extends State<ADRenseApp>{
  String screen='splash',role='user',drug='Metformin',drugTab='Overview',analystTab='Verify Queue',adminTab='Overview',alertFilter='All',reviewFilter='All';
  final Map<String, String> registrationData = {};
  final Map<String,String> formErrors={};
  late final ApiService authApi=widget.api??ApiService();
  String? emailFlow;
  bool authBusy=false;
  bool restoringSession=true;
  String? sessionRestoreError;
  int sessionRestoreAttempt=0;
  String? authError;
  String? activeAccountId;
  bool profileSaving=false;
  String? profileSaveError,pendingProfileEmail;
  DateTime? emailChangeSentAt;
  String profileItemDraft='',profileDoseDraft='';
  final Map<String,String> registrationDoses={};
  bool lightMode=true;
  late final ThemePreferenceStore themePreference=widget.themePreference??LocalThemePreferenceStore();
  int themeChanges=0;
  bool splashRevealed=false;
  String loginEmail='',loginPassword='';
  bool showLoginPassword=false;
  bool showRegisterPassword=false;
  bool showConfirmPassword=false;
  int loginFormVersion=0;
  final Map<String,RegistrationDocument> registrationDocuments={};
  Country phoneCountry=Country.parse('PK');
  bool pickingDocument=false,applicationsBusy=false,reviewBusy=false;
  String? applicationsError;
  bool usersBusy=false,userStatusBusy=false;
  String? usersError;
  Map<String,dynamic> userSummary={};
  final Map<String,List<Map<String,dynamic>>> applicationDocuments={};

  int regStep=0;bool register=false,analyzed=false,submitted=false;String selectedFinding='';
  String profileEditing = '', profileEntry = '', inlineBasicKey = '', inlineListItem = '';
  String comparisonDrug = 'Ibuprofen';
  String analystDrugQuery='', reportQuery='', selectedReportDrug='Metformin';
  String verificationFilter='Pending',userFilter='All',userQuery='';
  Map<String,String>? selectedApplicant,selectedAdminDecision,selectedUser,selectedDataset;
  final Color adminPurple=Color(0xFF8736F5);
  String analystSignalStatus='Unreviewed';
  Map<String,String>? activeFinding;
  String? activeSignal;
  String analystReviewReason='';
  String signalAssessment='';
  final Map<String,String> signalStatuses={};
  final Map<String,bool> dismissedAlerts = {};
  final Map<String,String> basicDrafts = {};
  final Map<String,List<String>> registrationLists = {'Medical Conditions': [], 'Current Medications': [], 'Allergies': []};
  final Map<String,List<String>> profileLists = {'Medical Conditions':[],'Current Medications':[],'Allergies':[],'Previous ADRs':['Metformin — Nausea (mild)','Aspirin — GI Discomfort']};
  final Map<String,String> medicationDoses={};
  final adrController=TextEditingController();
  final searchController=TextEditingController();
  final Map<String,String> profile={'Full Name':'','Email':'','Age Group':'','Biological Sex':'','Weight Range':''};
  final List<Map<String,String>> findings=[
    {'id':'P001','drug':'Metformin','reaction':'Lactic Acidosis','confidence':'94','status':'Pending','source':'FAERS report #2847','text':'Patient reported severe muscle pain and weakness after 3 months of Metformin 1000mg. Lab results showed elevated lactate levels.','severity':'high'},
    {'id':'P002','drug':'Ibuprofen','reaction':'GI Haemorrhage','confidence':'88','status':'Pending','source':'Social media #SM-4291','text':'Patient reported GI haemorrhage after 3 months of Ibuprofen.','severity':'high'},
    {'id':'P003','drug':'Lisinopril','reaction':'Angioedema','confidence':'76','status':'Pending','source':'CADEC record #1103','text':'Patient reported swelling after beginning Lisinopril.','severity':'high'},
    {'id':'P004','drug':'Atorvastatin','reaction':'Rhabdomyolysis','confidence':'71','status':'Pending','source':'FAERS report #3012','text':'Patient reported severe muscle pain.','severity':'medium'},
    {'id':'P005','drug':'Warfarin','reaction':'Intracranial Bleeding','confidence':'82','status':'Pending','source':'FAERS report #2991','text':'Patient reported bleeding symptoms.','severity':'high'},
  ];
  final List<Map<String,String>> applicants=[];
  final List<Map<String,String>> decisions=[
    {'drug':'Metformin','analyst':'Dr. Ahmed Khan','finding':'Lactic Acidosis','status':'Awaiting','decision':'Verified','confidence':'91','reviewed':'Oct 3, 2026 · 10:42','reason':'Evidence consistent with documented adverse reaction.'},
    {'drug':'Ibuprofen','analyst':'Dr. Maya Patel','finding':'GI Haemorrhage','status':'Awaiting','decision':'Rejected','confidence':'88','reviewed':'Oct 3, 2026 · 09:18','reason':'Insufficient supporting evidence to attribute the event to Ibuprofen.'},
    {'drug':'Warfarin','analyst':'Dr. Omar Farooq','finding':'Haemorrhage','status':'Awaiting','decision':'Verified','confidence':'85','reviewed':'Oct 2, 2026 · 14:15','reason':'Clinical review supports the finding.'},
  ];
  final List<Map<String,String>> users=[];
  final List<Map<String,String>> datasets=[
    {'name':'SMM4H Dataset','source':'SMM4H','version':'2026.2','records':'12,450','updated':'Sep 28, 2026','uploaded':'Jan 12, 2026','status':'Active','validation':'Validated'},
    {'name':'FAERS Safety Reports','source':'FDA FAERS','version':'Q2 2026','records':'48,312','updated':'Sep 24, 2026','uploaded':'Jan 12, 2026','status':'Active','validation':'Validated'},
    {'name':'Drug Reference Catalog','source':'Reference','version':'2026.1','records':'2,401','updated':'Sep 20, 2026','uploaded':'Jan 12, 2026','status':'Active','validation':'Validated'},
    {'name':'CADEC ADR Records','source':'CADEC','version':'2026','records':'8,120','updated':'Sep 18, 2026','uploaded':'Jan 12, 2026','status':'Active','validation':'Validated'},
  ];
  String dashPeriod='6M';
  static const Color analystPurple = Color(0xFF8738F5);
  static const Color analystBg = Color(0xFF180D30);
  final List<(String,String,int,int,int)> safetySignals=[
    ('Ibuprofen','GI Haemorrhage',12,72,500),('Warfarin','Intracranial Bleeding',8,34,325),
    ('Atorvastatin','Rhabdomyolysis',5,22,340),('Metformin','Lactic Acidosis',7,16,128),
  ];
  final List<(String,String,int,int,int)> analystDrugs=[
    ('Metformin','Biguanide · Antidiabetic',234,87,1),('Ibuprofen','NSAID · Analgesic',412,72,2),
    ('Lisinopril','ACE Inhibitor',189,79,1),('Atorvastatin','Statin · Lipid-lowering',298,81,1),
    ('Warfarin','Anticoagulant',521,58,2),('Aspirin','NSAID',231,74,1),
    ('Amoxicillin','Antibiotic',197,82,1),('Omeprazole','PPI',164,86,1),
  ];
  Future<void> go(String s) async {
    if(s=='login'||s=='splash'){
      sessionRestoreAttempt++;
      try{await authApi.logout();}
      catch(_){if(mounted)toast('Unable to remove the saved session. Please retry logout.');return;}
    }
    if(!mounted)return;
    setState(() {
    if(s=='login' || s=='splash') {
      authError=null;emailFlow=null;restoringSession=false;sessionRestoreError=null;
      loginEmail=''; loginPassword=''; showLoginPassword=false;
      loginFormVersion++; formErrors.clear(); register=false; role='user';
      activeAccountId=null;registrationDoses.clear();pendingProfileEmail=null;emailChangeSentAt=null;profileSaveError=null;medicationDoses.clear();for(final key in ['Medical Conditions','Current Medications','Allergies']){profileLists[key]=[];}registrationDocuments.clear();applicationDocuments.clear();applicants.clear();selectedApplicant=null;users.clear();selectedUser=null;userSummary={};usersError=null;
    }
    screen=s;
    });
  }
  Future<void> signInWithBackend() async {
    if(authBusy)return;
    setState(() {authBusy=true;authError=null;});
    try {
      final session=await authApi.login(loginEmail.trim(),loginPassword);
      final serverRole=session['role']=='patient'?'user':session['role'];
      if(serverRole!=role && serverRole!='admin'){await authApi.logout();throw const AuthApiException('This account is registered under a different role.');}
      final user=await authApi.me();
      if(!mounted)return;
      await openAuthenticatedUser(user);
    } on AuthApiException catch(e){if(mounted)setState(() {
      if(e.message=='EMAIL_NOT_VERIFIED'){
        emailFlow='verify';authError=null;
      } else {authError=e.message;}
    });}
    finally {if(mounted)setState(()=>authBusy=false);}
  }
  @override void initState(){super.initState();initializeAppearance();}
  Future<void> initializeAppearance() async {
    bool? saved;
    try{saved=await themePreference.readLightMode();}catch(_){}
    if(!mounted)return;
    if(themeChanges==0)setState((){lightMode=saved??true;P.light=lightMode;});
    await restoreSavedSession();
  }
  Future<void> restoreSavedSession() async {
    final attempt=++sessionRestoreAttempt;
    setState((){restoringSession=true;sessionRestoreError=null;});
    try{
      final user=await authApi.restoreSession();
      if(!mounted||attempt!=sessionRestoreAttempt)return;
      if(user==null){setState((){restoringSession=false;screen='splash';});return;}
      await openAuthenticatedUser(user);
    } on AuthApiException catch(error){
      if(mounted&&attempt==sessionRestoreAttempt)setState(()=>sessionRestoreError=error.message);
    } catch(_){
      if(mounted&&attempt==sessionRestoreAttempt)setState(()=>sessionRestoreError='Unable to restore your session. Please retry.');
    }
  }
  Future<void> openAuthenticatedUser(Map<String,dynamic> user) async {
    final serverRole=user['role']=='patient'?'user':user['role'];
    if(!['user','analyst','admin'].contains(serverRole))throw const AuthApiException('Unsupported account role.',statusCode:403);
    setState(() {
        applyProfileUser(user);
        restoringSession=false;sessionRestoreError=null;
        role=serverRole;
        screen=serverRole=='admin'?'adminDash':serverRole=='analyst'?'analystDash':'home';
      });
      if(serverRole=='admin')await Future.wait([loadAnalystApplications(),loadAdminUsers()]);
  }
  Widget sessionStartup()=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    SizedBox(width:64,height:64,child:SvgPicture.asset('assets/logo.svg')),
    gap(20),Text('ADRense',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),gap(18),
    if(sessionRestoreError==null)...[CircularProgressIndicator(),gap(16),Text('Checking your saved session…',style:TextStyle(color:P.muted))]
    else ...[Text(sessionRestoreError!,textAlign:TextAlign.center,style:TextStyle(color:P.muted)),gap(16),
      FilledButton(onPressed:restoreSavedSession,child:Text('Retry connection')),
      TextButton(onPressed:()=>go('login'),child:Text('Sign in instead')),
    ],
  ])));
  Future<void> registerWithBackend() async {
    if(authBusy)return;
    setState(() {authBusy=true;authError=null;});
    try {
      final analyst=role=='analyst';
      if(analyst&&!validateRequiredDocuments())return;
      final result=await authApi.register({
        'name':registrationData['Full Name']?.trim(),
        'email':registrationData['Email Address']?.trim(),
        'password':registrationData['Password'],
        'role':analyst?'analyst':'patient',
        'age_group':analyst?null:registrationData['Age group'],
        'gender':analyst?null:registrationData['Biological sex'],
        'weight_range':analyst?null:registrationData['Weight range (optional)'],
        'medical_conditions':registrationLists['Medical Conditions'] ?? <String>[],
        'allergies':registrationLists['Allergies'] ?? <String>[],
        'medication_doses':registrationDoses,
        'current_medications':registrationLists['Current Medications'] ?? <String>[],
        'profession':analyst?(registrationData['Profession']??registrationData['Professional Role']):null,
        'license_number':analyst?registrationData['License / Registration Number']:null,
        'institution':analyst?registrationData['University / Institution']:null,
        if(analyst)'analyst_details':{
          'professional_email':registrationData['Professional Email'],
          'phone':registrationData['Phone Number'],
          'country':registrationData['Country'],
          'country_code':registrationData['Country Code'],
          'professional_role':registrationData['Professional Role'],
          'qualification':registrationData['Qualification / Degree'],
          'graduation_year':int.tryParse(registrationData['Graduation Year']??''),
          'issuing_authority':registrationData['Issuing Authority'],
          'license_expiry':registrationData['Expiry Date'],
        },
        if(analyst)'documents':registrationDocuments.entries.map((entry)=>entry.value.toJson(entry.key)).toList(),
      });
      if(!mounted)return;
      setState((){loginEmail=registrationData['Email Address']!.trim();emailFlow='verify-new';register=false;regStep=0;registrationData.clear();registrationDoses.clear();registrationDocuments.clear();registrationLists.values.forEach((items)=>items.clear());formErrors.clear();loginFormVersion++;});
      toast(result['message'] as String); 
    } on AuthApiException catch(e){if(mounted)setState(()=>authError=e.message);}
    finally {if(mounted)setState(()=>authBusy=false);}
  }
  Future<void> toggleTheme() async {
    final next=!lightMode;
    themeChanges++;
    setState((){lightMode=next;P.light=next;});
    try{await themePreference.saveLightMode(next);}
    catch(_){if(mounted)toast('The theme changed, but your preference could not be saved. Please try again.');}
  }
  void updateView(VoidCallback change){if(mounted)setState(change);}
  void toast(String t)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t),backgroundColor:P.surface3));
  @override void dispose(){adrController.dispose();searchController.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdrenseTheme.build(lightMode),
      child:Scaffold(

      backgroundColor: P.navy,
      bottomNavigationBar: appBottomNavigation(),
      body: DecoratedBox(decoration:BoxDecoration(gradient:(lightMode?AdrenseTokens.light:AdrenseTokens.dark).pageGradient),child:SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 393),
            child: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: restoringSession || screen == 'splash' || screen == 'login'
                          ? Alignment.center
                          : Alignment.topCenter,
                      children: [...previousChildren, if (currentChild != null) currentChild],
                    ),
                    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds:300),
                    switchInCurve: Curves.easeOutCubic,
                    child:KeyedSubtree(key:ValueKey(screen),child:restoringSession?sessionStartup():screen == 'splash' ? splash() : screen == 'login' ? (emailFlow==null?login():EmailAuthScreen(api:authApi,reset:emailFlow=='reset',initialEmail:loginEmail,initiallySent:emailFlow=='verify-new',onBack:()=>setState((){emailFlow=null;authError=null;loginPassword='';loginFormVersion++;}))) : body())),
                ),
              ],
            ),
          ),
        ),
      )),
    ));
  }

  Widget? appBottomNavigation(){
    if(restoringSession||['splash','login'].contains(screen))return null;
    final Widget navigation;
    if(role=='user'){
      navigation=bottomNav();
    }else if(role=='admin'&&screen.startsWith('admin')){
      navigation=adminBottomNav();
    }else if(role=='analyst'&&(screen=='analystDash'||screen=='analystReport')){
      navigation=analystBottomNav();
    }else{
      return null;
    }
    return ColoredBox(key:const ValueKey('app-bottom-navigation'),color:P.navy,
      child:DecoratedBox(decoration:BoxDecoration(border:Border(top:BorderSide(color:P.border))),
        child:SafeArea(top:false,child:LayoutBuilder(builder:(context,constraints)=>Align(
          heightFactor:1,
          child:SizedBox(key:const ValueKey('navigation-controls'),
            width:constraints.maxWidth<=600?constraints.maxWidth:393,
            child:navigation),
        )))));
  }

  Widget _scroll(Widget child) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    child: child,
  );

  Widget _pinnedHeaderPage(Widget header, Widget content) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: header),
      Expanded(child: _scroll(content)),
    ],
  );

  Widget body() => switch (screen) {
    'adminDash' => adminDash(),
    'adminApplicant' => adminApplicantDetail(),
    'adminDecision' => adminDecisionDetail(),
    'adminUser' => adminUserDetail(),
    'adminDataset' => adminDatasetDetail(),
    'analystDrug' => analystDrugDetail(),
    _ => _scroll(switch (screen) {
      'search' => search(),
      'drugProfile' => drugProfile(),
      'adrAnalysis' => adrAnalysis(),
      'pharmaDash' => pharmaDash(),
      'personalized' => personalized(),
      'compare' => compare(),
      'alerts' => alerts(),
      'healthProfile' => healthProfile(),
      'analystDash' => analystDash(),
      'analystFinding' => analystFindingDetail(),
      'analystSignal' => analystSignalDetail(),
      'analystReport' => analystReportDetail(),
      _ => home(),
    }),
  };
}
