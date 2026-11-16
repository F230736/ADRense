import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/core/registration_inputs.dart';
void main(){
 test('Expiry formatter inserts slashes after month and day and handles backspace',(){
  final formatter=ExpiryDateInputFormatter();
  TextEditingValue value=TextEditingValue.empty;
  for(final char in '01102030'.split('')){
   value=formatter.formatEditUpdate(value,TextEditingValue(text:value.text+char,selection:TextSelection.collapsed(offset:value.text.length+1)));
   if(value.text.length==3)expect(value.text,'01/');
   if(value.text.length==6)expect(value.text,'01/10/');
  }
  expect(value.text,'01/10/2030');expect(value.selection.baseOffset,10);
  final old=const TextEditingValue(text:'01/',selection:TextSelection.collapsed(offset:3));
  final deleted=formatter.formatEditUpdate(old,const TextEditingValue(text:'01',selection:TextSelection.collapsed(offset:2)));
  expect(deleted.text,'0');
 });
 test('Expiry formatter handles paste and limits the year',(){
  final result=ExpiryDateInputFormatter().formatEditUpdate(TextEditingValue.empty,const TextEditingValue(text:'12/31/203012',selection:TextSelection.collapsed(offset:12)));
  expect(result.text,'12/31/2030');expect(result.selection.baseOffset,10);
 });
 test('File validation rejects wrong types, empty files and oversized files',(){
  final png=Uint8List.fromList([137,80,78,71,13,10,26,10]);
  expect(RegistrationDocument.validate('degree.png',png),isNull);
  expect(RegistrationDocument.validate('degree.pdf',png),isNotNull);
  expect(RegistrationDocument.validate('degree.exe',png),isNotNull);
  expect(RegistrationDocument.validate('degree.png',Uint8List(0)),isNotNull);
  expect(RegistrationDocument.validate('degree.png',Uint8List(5*1024*1024+1)),isNotNull);
 });
}
