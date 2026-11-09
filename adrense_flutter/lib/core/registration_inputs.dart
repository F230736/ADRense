import 'dart:convert';
import 'package:flutter/services.dart';

/// Inserts separators as month and day are completed, including pasted input.
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits=newValue.text.replaceAll(RegExp(r'\D'),'');
    var cursorDigits=newValue.selection.baseOffset<0?digits.length:
      newValue.text.substring(0,newValue.selection.baseOffset.clamp(0,newValue.text.length)).replaceAll(RegExp(r'\D'),'').length;
    // Backspacing over an inserted slash removes the preceding digit too.
    if(newValue.text.length<oldValue.text.length && digits==oldValue.text.replaceAll(RegExp(r'\D'),'')){
      final index=(cursorDigits-1).clamp(0,digits.length);
      if(index<digits.length){digits=digits.substring(0,index)+digits.substring(index+1);cursorDigits=index;}
    }
    digits=digits.substring(0,digits.length.clamp(0,8));
    final output=StringBuffer();
    var caret=0;
    for(var i=0;i<digits.length;i++){
      output.write(digits[i]);
      if(i==1||i==3)output.write('/');
      if(i<cursorDigits)caret=output.length;
    }
    return TextEditingValue(text:output.toString(),selection:TextSelection.collapsed(offset:caret));
  }
}

class RegistrationDocument {
  const RegistrationDocument(this.filename,this.bytes);
  final String filename;
  final Uint8List bytes;
  String get extension=>filename.split('.').last.toLowerCase();
  bool get isPdf=>extension=='pdf';
  static String? validate(String filename,Uint8List bytes){
    final ext=filename.split('.').last.toLowerCase();
    if(!['pdf','jpg','jpeg','png'].contains(ext))return 'Choose a PDF, JPG, JPEG, or PNG file.';
    if(bytes.isEmpty||bytes.length>5*1024*1024)return 'Choose a nonempty file no larger than 5 MB.';
    final pdf=bytes.length>=5&&ascii.decode(bytes.sublist(0,5),allowInvalid:true)=='%PDF-';
    final png=bytes.length>=8&&bytes[0]==137&&bytes[1]==80&&bytes[2]==78&&bytes[3]==71&&bytes[4]==13&&bytes[5]==10&&bytes[6]==26&&bytes[7]==10;
    final jpeg=bytes.length>=3&&bytes[0]==255&&bytes[1]==216&&bytes[2]==255;
    if(!(ext=='pdf'?pdf:ext=='png'?png:jpeg))return 'The file contents do not match the selected file type.';
    return null;
  }
  Map<String,dynamic> toJson(String kind)=>{'kind':kind,'filename':filename,'content_base64':base64Encode(bytes)};
}
