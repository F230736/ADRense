import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'session_store.dart';

class AuthApiException implements Exception {
  final String message;
  const AuthApiException(this.message, {this.statusCode});
  final int? statusCode;
  @override String toString() => message;
}

class ApiService {
  ApiService({this.baseUrl = const String.fromEnvironment('ADR_API_URL', defaultValue: 'http://192.168.100.27:8000'), SessionStore? sessionStore, http.Client? client})
    : _store=sessionStore??SecureSessionStore('adrense.session.${base64Url.encode(utf8.encode(baseUrl.replaceFirst(RegExp(r'/$'), '')))}'),
      _client=client??http.Client();
  final SessionStore _store;
  final http.Client _client;
  int _sessionGeneration=0;
  Future<void> _storageTail=Future<void>.value();
  Future<T> _stored<T>(Future<T> Function() action){
    final operation=_storageTail.then((_)=>action());
    _storageTail=operation.then<void>((_) {},onError:(Object error,StackTrace stack) {});
    return operation;
  }
  final String baseUrl;
  String? _token;
  Future<Map<String,dynamic>> _request(String path, {Map<String,dynamic>? body, bool authorized=false,String method='POST'}) async {
    final generation=_sessionGeneration;
    try {
      final response = await (body == null
        ? _client.get(Uri.parse('$baseUrl$path'), headers: authorized ? {'Authorization':'Bearer $_token'} : {})
        : (method=='PATCH'?_client.patch(Uri.parse('$baseUrl$path'),headers:{'Content-Type':'application/json',if(authorized)'Authorization':'Bearer $_token'},body:jsonEncode(body)):_client.post(Uri.parse('$baseUrl$path'), headers:{'Content-Type':'application/json',if(authorized)'Authorization':'Bearer $_token'}, body:jsonEncode(body)))).timeout(const Duration(seconds:60));
      if(authorized&&response.statusCode==401&&generation==_sessionGeneration)await logout();
      dynamic decoded;
      try{decoded=jsonDecode(response.body);}
      catch(_){
        if(response.statusCode<400)throw const AuthApiException('The backend returned an invalid response. Please retry.');
        decoded=<String,dynamic>{};
      }
      final data = decoded is Map<String,dynamic> ? decoded : <String,dynamic>{};
      if(response.statusCode >= 400) {
        final detail = data['detail'];
        throw AuthApiException(detail is String ? detail : detail is List && detail.isNotEmpty ? detail.first['msg'].toString().replaceFirst('Value error, ', '') : 'Request failed (${response.statusCode})',statusCode:response.statusCode);
      }
      return data;
    } on AuthApiException { rethrow; }
      catch (_) { throw const AuthApiException('Cannot connect to the ADRense backend. Check that FastAPI is running.'); }
  }
  Future<Map<String,dynamic>> register(Map<String,dynamic> fields) => _request('/api/auth/register',body:fields);
  Future<Map<String,dynamic>> login(String email,String password) async {
    final generation=++_sessionGeneration;
    final result=await _request('/api/auth/login',body:{'email':email,'password':password});
    final token=result['access_token'];
    if(token is! String||token.isEmpty)throw const AuthApiException('The server did not return a valid session.');
    if(generation!=_sessionGeneration)throw const AuthApiException('Sign-in was cancelled.');
    try{await _stored(()=>_store.write(token));}
    catch(_){throw const AuthApiException('Unable to save your login securely. Please try again.');}
    if(generation!=_sessionGeneration)throw const AuthApiException('Sign-in was cancelled.');
    _token=token;
    return result;
  }
  Future<Map<String,dynamic>?> restoreSession() async {
    final generation=_sessionGeneration;
    String? saved;
    try{saved=await _stored(()=>_store.read());}
    catch(_){throw const AuthApiException('Unable to read your saved session. Please retry.');}
    if(generation!=_sessionGeneration||saved==null||saved.isEmpty)return null;
    _token=saved;
    try{
      final user=await me();
      return generation==_sessionGeneration?user:null;
    } on AuthApiException catch(error){
      if(error.statusCode==401||error.statusCode==403){
        if(generation==_sessionGeneration)await logout();
        return null;
      }
      rethrow;
    }
  }
  Future<Map<String,dynamic>> me() => _request('/api/auth/me',authorized:true);
  Future<Map<String,dynamic>> updateProfile(Map<String,dynamic> changes)=>_request('/api/profile',body:changes,authorized:true,method:'PATCH');
  Future<Map<String,dynamic>> requestEmailChange(String email)=>_request('/api/profile/email-change/request',body:{'email':email},authorized:true);
  Future<Map<String,dynamic>> confirmEmailChange(String email,String code) async {
    final generation=_sessionGeneration;
    final result=await _request('/api/profile/email-change/confirm',body:{'email':email,'code':code},authorized:true);
    if(generation!=_sessionGeneration)throw const AuthApiException('Email verification was interrupted. Please sign in again.');
    final token=result['access_token'];
    if(token is! String||token.isEmpty)throw const AuthApiException('Please sign in again with your verified email.');
    final next=++_sessionGeneration;
    _token=token;
    try{await _stored(()=>_store.write(token));}
    catch(_){
      _token=null;
      try{await _stored(()=>_store.clear());}catch(_){}
      throw const AuthApiException('Your email was verified. Please sign in again with the new address.',statusCode:401);
    }
    if(next!=_sessionGeneration)throw const AuthApiException('Your session changed. Please sign in again.');
    return result;
  }
  Future<Map<String,dynamic>> requestCode(String email, {required bool reset}) => _request(reset?'/api/auth/forgot-password':'/api/auth/resend-verification', body:{'email':email});
  Future<Map<String,dynamic>> verifyEmail(String email,String code) => _request('/api/auth/verify-email',body:{'email':email,'code':code});
  Future<Map<String,dynamic>> resetPassword(String email,String code,String password,String confirmation) => _request('/api/auth/reset-password',body:{'email':email,'code':code,'password':password,'confirm_password':confirmation});
  Future<Map<String,dynamic>> analystApplications()=>_request('/api/admin/analysts',authorized:true);
  Future<Map<String,dynamic>> adminUsers()=>_request('/api/admin/users',authorized:true);
  Future<Map<String,dynamic>> registrationStatistics(int days)=>_request('/api/admin/registrations?days=$days',authorized:true);
  Future<Map<String,dynamic>> changeUserStatus(String id,String action)=>_request('/api/admin/users/$id/status',body:{'action':action},authorized:true);
  Future<Map<String,dynamic>> reviewAnalyst(String id,String decision,String reason)=>_request('/api/admin/analysts/$id/review',body:{'decision':decision,'reason':reason},authorized:true);
  Future<Uint8List> analystDocument(String id) async {
    try {
      final response=await _client.get(Uri.parse('$baseUrl/api/admin/documents/$id'),headers:{'Authorization':'Bearer $_token'}).timeout(const Duration(seconds:30));
      if(response.statusCode!=200)throw const AuthApiException('Unable to load this document. Please check your session and try again.');
      return response.bodyBytes;
    } on AuthApiException {rethrow;}
    catch(_){throw const AuthApiException('Cannot connect to the ADRense backend.');}
  }
  Future<void> logout(){
    _sessionGeneration++;
    _token=null;
    return _stored(()=>_store.clear());
  }
}
