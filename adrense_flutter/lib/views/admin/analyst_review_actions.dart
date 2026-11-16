part of '../../main.dart';

extension _AnalystReviewActions on _ADRenseAppState {
  Future<void> loadAnalystApplications() async {
    if(applicationsBusy)return;
    updateView((){applicationsBusy=true;applicationsError=null;});
    try {
      final result=await authApi.analystApplications();
      if(!mounted||role!='admin')return;
      final rows=List<Map<String,dynamic>>.from(result['applications'] as List);
      updateView((){
        applicants.clear();applicationDocuments.clear();
        for(final row in rows){
          final details=Map<String,dynamic>.from(row['details'] as Map);
          final id=row['id'].toString();
          applicationDocuments[id]=List<Map<String,dynamic>>.from(row['documents'] as List);
          applicants.add({
            'id':id,'name':row['name'].toString(),'email':row['email'].toString(),
            'status':row['status']=='active'?'Verified':row['status']=='rejected'?'Rejected':'Pending',
            'profession':row['profession'].toString(),'license':row['license_number'].toString(),
            'institution':row['institution'].toString(),'submitted':row['created_at'].toString().split('T').first,
            'phone':details['phone']?.toString()??'Not provided',
            'country':details['country']?.toString()??'Not provided',
            'role':details['professional_role']?.toString()??'Analyst',
            'professional_email':details['professional_email']?.toString()??'Not provided',
            'qualification':details['qualification']?.toString()??'Not provided',
            'graduation':details['graduation_year']?.toString()??'Not provided',
            'authority':details['issuing_authority']?.toString()??'Not provided',
            'expiry':details['license_expiry']?.toString()??'Not provided',
            'email_verified':row['email_verified']==true?'Verified':'Not verified',
            'reason':row['review_reason']?.toString()??'',
          });
        }
      });
    } on AuthApiException catch(error){if(mounted)updateView(()=>applicationsError=error.message);}
    finally{if(mounted)updateView(()=>applicationsBusy=false);}
  }

  Future<void> reviewSelectedAnalyst(String decision,{String reason=''}) async {
    if(reviewBusy||selectedApplicant==null)return;
    final id=selectedApplicant!['id']!;
    updateView(()=>reviewBusy=true);
    try {
      final result=await authApi.reviewAnalyst(id,decision,reason);
      if(!mounted)return;
      toast(result['message'].toString());
      await loadAnalystApplications();
      if(!mounted)return;
      updateView((){screen='adminDash';adminTab='Verification';verificationFilter=decision=='approve'?'Verified':'Rejected';selectedApplicant=null;});
    } on AuthApiException catch(error){if(mounted)toast(error.message);}
    finally{if(mounted)updateView(()=>reviewBusy=false);}
  }

  Future<void> rejectSelectedAnalyst() async {
    if(reviewBusy)return;
    final controller=TextEditingController();
    final reason=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(
      backgroundColor:P.surface2,title:Text('Reject application',style:TextStyle(color:P.text)),
      content:TextField(controller:controller,maxLength:1000,maxLines:3,style:TextStyle(color:P.text),decoration:const InputDecoration(labelText:'Reason for rejection',helperText:'At least 3 characters')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
        TextButton(onPressed:(){if(controller.text.trim().length>=3)Navigator.pop(ctx,controller.text.trim());},child:const Text('Reject'))]));
    // The dialog may still be animating; dispose its controller after the transition.
    await Future<void>.delayed(const Duration(milliseconds:300));
    controller.dispose();
    if(reason!=null&&mounted)await reviewSelectedAnalyst('reject',reason:reason);
  }

  Future<void> viewAnalystDocument(Map<String,dynamic> document) async {
    final content=authApi.analystDocument(document['id'].toString());
    await showDialog<void>(context:context,builder:(ctx)=>Dialog(backgroundColor:P.surface2,
      insetPadding:const EdgeInsets.all(16),child:SizedBox(width:760,height:MediaQuery.sizeOf(ctx).height*.85,
        child:Column(children:[
          Padding(padding:const EdgeInsets.fromLTRB(16,8,8,8),child:Row(children:[
            Expanded(child:Text(document['filename'].toString(),style:TextStyle(color:P.text,fontWeight:FontWeight.w700))),
            IconButton(tooltip:'Close document',onPressed:()=>Navigator.pop(ctx),icon:Icon(Icons.close,color:P.text)),
          ])),
          Expanded(child:FutureBuilder(future:content,builder:(context,snapshot){
            if(snapshot.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:Text(snapshot.error.toString(),style:TextStyle(color:P.danger))));
            if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
            return document['media_type']=='application/pdf'
              ?PdfViewer.data(snapshot.data!,sourceName:'analyst-document-${document['id']}-${document['filename']}')
              :InteractiveViewer(minScale:.5,maxScale:5,child:Center(child:Image.memory(snapshot.data!,fit:BoxFit.contain,
                errorBuilder:(context,error,stack)=>const Text('Unable to preview this image.'))));
          })),
        ]))));
  }
}
