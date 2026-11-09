import os
os.environ['DATABASE_URL']='sqlite://'
os.environ['SECRET_KEY']='test-only-secret-with-more-than-32-characters'
import unittest
from unittest.mock import patch
from datetime import datetime,timedelta
from Models.User import User
from Models.AuthState import AuthState,EmailChallenge
from Models.ProfileData import ProfileData,PendingEmailChange
import test_analyst_application as fixtures

class ProfileTests(unittest.TestCase):
 def setUp(self):
  fixtures.AnalystApplicationTests.setUp(self)
  self.email_mock=patch('API.profile_routes.send_code');self.send=self.email_mock.start()
  payload={'name':'Test Patient','email':'old@example.com','password':'Original@123','role':'patient','age_group':'18–25','gender':'Other','weight_range':'50–70kg','medical_conditions':['Condition, with comma'],'allergies':['Penicillin'],'current_medications':['Medicine A'],'medication_doses':{'Medicine A':'500mg daily'}}
  response=self.client.post('/api/auth/register',json=payload);self.assertEqual(response.status_code,201,response.text);self.user_id=response.json()['user_id']
  self.db.get(AuthState,self.user_id).is_verified=True;self.db.commit();self.auth=self.login('old@example.com')
 def tearDown(self):
  self.email_mock.stop();fixtures.AnalystApplicationTests.tearDown(self)
 def login(self,email):
  response=self.client.post('/api/auth/login',json={'email':email,'password':'Original@123'});self.assertEqual(response.status_code,200,response.text)
  return {'Authorization':'Bearer '+response.json()['access_token']}
 def me(self,headers=None):
  response=self.client.get('/api/auth/me',headers=headers or self.auth);self.assertEqual(response.status_code,200,response.text);return response.json()
 def request_code(self,email='new@example.com'):
  response=self.client.post('/api/profile/email-change/request',headers=self.auth,json={'email':email});self.assertEqual(response.status_code,200,response.text)
  return self.send.call_args.args[1]
 def confirm(self,code,email='new@example.com',headers=None):
  return self.client.post('/api/profile/email-change/confirm',headers=headers or self.auth,json={'email':email,'code':code})
 def test_registration_saves_all_profile_lists_and_doses(self):
  data=self.me()['profile'];self.assertEqual(data['weight_range'],'50–70kg');self.assertEqual(data['medical_conditions'],['Condition, with comma']);self.assertEqual(data['allergies'],['Penicillin']);self.assertEqual(data['medication_doses'],{'Medicine A':'500mg daily'})
 def test_partial_update_and_list_add_edit_delete_persist(self):
  result=self.client.patch('/api/profile',headers=self.auth,json={'name':'Updated Patient','age_group':'26–35','gender':'Female','weight_range':'70–90kg'});self.assertEqual(result.status_code,200,result.text)
  self.assertEqual(self.me()['name'],'Updated Patient');self.assertEqual(self.me()['profile']['weight_range'],'70–90kg')
  for values in [['First condition','Second condition'],['Renamed condition','Second condition'],[]]:
   result=self.client.patch('/api/profile',headers=self.auth,json={'medical_conditions':values,'allergies':['Latex']});self.assertEqual(result.status_code,200,result.text);self.assertEqual(self.me()['profile']['medical_conditions'],values)
  result=self.client.patch('/api/profile',headers=self.auth,json={'current_medications':['New medicine'],'medication_doses':{'New medicine':'10mg daily'}});self.assertEqual(result.status_code,200,result.text)
  self.assertEqual(self.me()['profile']['medication_doses'],{'New medicine':'10mg daily'})
  self.client.patch('/api/profile',headers=self.auth,json={'current_medications':[],'allergies':[]});self.assertEqual(self.me()['profile']['medication_doses'],{});self.assertEqual(self.me()['profile']['allergies'],[])
 def test_profile_update_is_owner_bound_validated_and_atomic(self):
  self.assertIn(self.client.patch('/api/profile',json={'name':'Bad Actor'}).status_code,[401,403])
  for fields in [{'email':'bypass@example.com'},{'previous_adrs':['Do not persist']},{'user_id':123,'name':'Bad Actor'},{'weight_range':'invalid'},{'name':'Updated Patient','medication_doses':{'Missing medicine':'dose'}}]:
   result=self.client.patch('/api/profile',headers=self.auth,json=fields);self.assertEqual(result.status_code,422,result.text)
  self.assertEqual(self.me()['name'],'Test Patient');self.assertEqual(self.me()['email'],'old@example.com')
  self.assertEqual(self.client.patch('/api/profile',headers=self.headers,json={'name':'Admin Patient'}).status_code,403)
 def test_email_is_unchanged_until_correct_otp_and_session_rotates(self):
  code=self.request_code();self.assertEqual(self.send.call_args.args[0],'new@example.com');self.assertEqual(self.send.call_args.args[2],'email-change')
  self.assertEqual(self.me()['email'],'old@example.com');self.db.expire_all();self.assertNotEqual(self.db.get(PendingEmailChange,self.user_id).digest,code)
  wrong='000001' if code!='000001' else '000002';self.assertEqual(self.confirm(wrong).status_code,400);self.assertEqual(self.me()['email'],'old@example.com')
  result=self.confirm(code);self.assertEqual(result.status_code,200,result.text);self.assertEqual(result.json()['user']['email'],'new@example.com')
  new_auth={'Authorization':'Bearer '+result.json()['access_token']};self.assertEqual(self.client.get('/api/auth/me',headers=self.auth).status_code,401);self.assertEqual(self.me(new_auth)['email'],'new@example.com')
  self.assertEqual(self.confirm(code,headers=new_auth).status_code,400)
  self.assertEqual(self.client.post('/api/auth/login',json={'email':'old@example.com','password':'Original@123'}).status_code,401);self.login('new@example.com')
 def test_expiry_attempt_limit_and_resend_lock(self):
  code=self.request_code();wrong='000001' if code!='000001' else '000002'
  for _ in range(5):self.assertEqual(self.confirm(wrong).status_code,400)
  self.assertEqual(self.confirm(code).status_code,400)
  self.db.expire_all();pending=self.db.get(PendingEmailChange,self.user_id);pending.sent_at=datetime.utcnow()-timedelta(seconds=61);self.db.commit()
  self.assertEqual(self.client.post('/api/profile/email-change/request',headers=self.auth,json={'email':'different@example.com'}).status_code,429)
  pending.expires_at=datetime.utcnow()-timedelta(seconds=1);self.db.commit();self.assertEqual(self.confirm(code).status_code,400);self.assertEqual(self.me()['email'],'old@example.com')
 def test_resend_replaces_code_and_enforces_cooldown(self):
  with patch('API.profile_routes.secrets.randbelow',return_value=123456):old=self.request_code()
  self.assertEqual(self.client.post('/api/profile/email-change/request',headers=self.auth,json={'email':'new@example.com'}).status_code,429)
  self.db.expire_all();self.db.get(PendingEmailChange,self.user_id).sent_at=datetime.utcnow()-timedelta(seconds=61);self.db.commit()
  with patch('API.profile_routes.secrets.randbelow',return_value=654321):new=self.request_code()
  self.assertEqual(self.confirm(old).status_code,400);self.assertEqual(self.confirm(new).status_code,200)
 def test_smtp_failure_never_changes_current_email(self):
  self.send.side_effect=RuntimeError('SMTP unavailable')
  self.assertEqual(self.client.post('/api/profile/email-change/request',headers=self.auth,json={'email':'new@example.com'}).status_code,503)
  self.assertEqual(self.me()['email'],'old@example.com');self.db.expire_all();self.assertIsNone(self.db.get(PendingEmailChange,self.user_id))
 def test_conflicting_email_is_rechecked_at_confirmation(self):
  code=self.request_code();new_owner=User(name='Other Owner',email='new@example.com',role='patient',status='active',password_hash='unused');self.db.add(new_owner);self.db.commit()
  self.assertEqual(self.confirm(code).status_code,409);self.assertEqual(self.me()['email'],'old@example.com')
 def test_pending_code_is_invalid_after_password_reset_version_change(self):
  code=self.request_code();self.db.expire_all();self.db.get(AuthState,self.user_id).session_version+=1;self.db.commit();new_auth=self.login('old@example.com')
  self.assertEqual(self.confirm(code,headers=new_auth).status_code,400);self.assertEqual(self.me(new_auth)['email'],'old@example.com')
 def test_old_address_reset_codes_are_invalidated(self):
  from Business.EmailAuthService import request_code
  with patch('Business.EmailAuthService.send_code'):request_code(self.db,'old@example.com','reset')
  code=self.request_code();self.assertEqual(self.confirm(code).status_code,200);self.db.expire_all();self.assertTrue(self.db.query(EmailChallenge).one().consumed)
 def test_legacy_profile_is_preserved_on_first_edit(self):
  self.db.query(ProfileData).filter_by(user_id=self.user_id).delete();self.db.commit()
  before=self.me()['profile']['current_medications'];result=self.client.patch('/api/profile',headers=self.auth,json={'name':'Updated Patient'});self.assertEqual(result.status_code,200,result.text);self.assertEqual(self.me()['profile']['current_medications'],before)
