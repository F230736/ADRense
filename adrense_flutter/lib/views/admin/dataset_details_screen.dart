part of '../../main.dart';

extension _AdmindatasetViews on _ADRenseAppState {
  Widget adminDatasetDetail(){final d=selectedDataset;if(d==null)return Text('No dataset selected');
    return _pinnedHeaderPage(
      adminDetailHeading('Dataset Details','adminDash',d['status']!,P.success),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      adminDataCard('',[
        ('Dataset Name',d['name']!),('Source',d['source']!),('Version',d['version']!),
        ('Record Count',d['records']!),('Upload Date',d['uploaded']!),
        ('Last Updated',d['updated']!),('Validation Status',d['validation']!),
      ]),gap(12),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Add or Update Data',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),gap(6),
        Text('Select a CSV or JSON file. ADRense validates its schema and records before applying changes.',
          style:TextStyle(color:P.muted,fontSize:10,height:1.5)),gap(11),
        SizedBox(width:double.infinity,child:OutlinedButton(onPressed:()=>toast('File picker requires implementation'),
          style:OutlinedButton.styleFrom(foregroundColor:P.teal,
            side:BorderSide(color:P.tealDim)),child:Text('Select Dataset File'))),
      ])),gap(12),
      Row(children:[
        Expanded(child:adminAction('Update Dataset',P.teal,
          ()=>toast('Choose and validate a dataset file first'))),SizedBox(width:8),
        Expanded(child:adminAction('Remove Dataset',P.danger,
          ()=>adminConfirmDialog('Remove Dataset?',
            'This dataset will no longer be available to ADRense analysis services.',
            'Remove Dataset',P.danger,(){
              setState((){datasets.remove(d);screen='adminDash';});
              toast('Dataset removed from demo');
            }),outline:true)),
      ]),
    ]));
  }

}
