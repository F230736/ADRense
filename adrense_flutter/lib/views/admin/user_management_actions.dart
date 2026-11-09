part of '../../main.dart';

extension _UserManagementActions on _ADRenseAppState {
  Future<void> loadAdminUsers() async {
    if(usersBusy)return;
    updateView((){usersBusy=true;usersError=null;});
    try{
      final result=await authApi.adminUsers();
      if(!mounted||role!='admin')return;
      updateView((){
        users.clear();
        for(final row in List<Map<String,dynamic>>.from(result['users'] as List)){
          final raw=row['status'].toString();
          final verified=row['email_verified']==true;
          final status=raw=='restricted'?'Restricted':raw=='pending'?'Pending approval':raw=='rejected'?'Rejected':!verified?'Email unverified':'Active';
          users.add({'id':row['id'].toString(),'name':row['name'].toString(),'email':row['email'].toString(),
            'role':row['role']=='patient'?'General User':'Healthcare Professional / Analyst',
            'status':status,'raw_status':raw,'email_verified':verified?'Verified':'Not verified',
            'created':row['created_at'].toString().split('T').first});
        }
      });
    } on AuthApiException catch(e){if(mounted)updateView(()=>usersError=e.message);}
    finally{if(mounted)updateView(()=>usersBusy=false);}
  }
  List<Map<String,String>> get filteredAdminUsers=>users.where((user){
    final matches='${user['name']} ${user['email']}'.toLowerCase().contains(userQuery.trim().toLowerCase());
    return matches&&(userFilter=='All'||(userFilter=='General Users'&&user['role']=='General User')||
      (userFilter=='Analysts'&&user['role']!='General User')||(userFilter=='Active'&&user['status']=='Active'));
  }).toList();
  Future<void> changeSelectedUserStatus() async {
    if(userStatusBusy||selectedUser==null)return;
    final selected=selectedUser!;
    updateView(()=>userStatusBusy=true);
    try{
      final result=await authApi.changeUserStatus(selected['id']!,selected['raw_status']=='restricted'?'restore':'restrict');
      if(!mounted)return;
      await loadAdminUsers();
      if(!mounted)return;
      updateView((){selectedUser=null;adminTab='Users';screen='adminDash';userSummary={};});
      toast(result['message'].toString());
    } on AuthApiException catch(e){if(mounted)toast(e.message);}
    finally{if(mounted)updateView(()=>userStatusBusy=false);}
  }
  void selectAdminTab(String tab){
    updateView((){adminTab=tab;screen='adminDash';});
    if(tab=='Verification')loadAnalystApplications();
    if(tab=='Users')loadAdminUsers();
  }
}
