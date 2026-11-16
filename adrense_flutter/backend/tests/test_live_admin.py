import os
os.environ['DATABASE_URL']='sqlite://'
os.environ['SECRET_KEY']='test-only-secret-with-more-than-32-characters'
import unittest
from datetime import datetime,timedelta
from unittest.mock import patch
from sqlalchemy.orm import sessionmaker
from Models.User import User
from Models.AuthState import AuthState
from Models.ReviewNotification import ReviewNotification
from Business.AuthService import pwd_context,login_user
from Business.ReviewNotifications import deliver_review_notification
import test_analyst_application as fixtures

class LiveAdminTests(unittest.TestCase):
 setUp=fixtures.AnalystApplicationTests.setUp
 tearDown=fixtures.AnalystApplicationTests.tearDown
 payload=fixtures.AnalystApplicationTests.payload
 register=fixtures.AnalystApplicationTests.register
 def test_user_list_is_real_and_private(self):
  user_id=self.register();result=self.client.get('/api/admin/users',headers=self.headers)
  self.assertEqual(result.status_code,200,result.text);users=result.json()['users'];self.assertEqual(len(users),1);self.assertEqual(users[0]['id'],user_id)
  self.assertEqual(set(users[0]),{'id','name','email','role','status','email_verified','created_at'})
  self.assertIn(self.client.get('/api/admin/users').status_code,[401,403])
 def test_registration_counts_and_empty_buckets(self):
  self.register();patient=User(name='General Person',email='general@example.com',role='patient',status='active',password_hash=pwd_context.hash('Original@123'))
  self.db.add(patient);self.db.flush();self.db.add(AuthState(user_id=patient.id,is_verified=True,session_version=0));self.db.commit()
  result=self.client.get('/api/admin/registrations?days=7',headers=self.headers);self.assertEqual(result.status_code,200,result.text);data=result.json()
  self.assertEqual(data['summary'],{'total':2,'general_users':1,'analysts':1,'active':1});self.assertEqual(len(data['buckets']),7)
  self.assertEqual(sum(r['general_users'] for r in data['buckets']),1);self.assertEqual(sum(r['analysts'] for r in data['buckets']),1)
  self.assertTrue(any(r['general_users']==0 and r['analysts']==0 for r in data['buckets']))
  for days in [30,90,365]:self.assertEqual(self.client.get(f'/api/admin/registrations?days={days}',headers=self.headers).status_code,200)
  self.assertEqual(self.client.get('/api/admin/registrations?days=400',headers=self.headers).status_code,422)
 def test_review_enqueues_one_notification(self):
  user_id=self.register();url=f'/api/admin/analysts/{user_id}/review'
  self.assertEqual(self.client.post(url,headers=self.headers,json={'decision':'reject','reason':'License is unreadable'}).status_code,200)
  job=self.db.query(ReviewNotification).one();self.assertEqual(job.email,'analyst@example.com');self.assertEqual(job.reason,'License is unreadable')
  self.assertEqual(self.client.post(url,headers=self.headers,json={'decision':'reject','reason':'Test'}).status_code,409);self.assertEqual(self.db.query(ReviewNotification).count(),1)
 def test_delivery_retries_and_does_not_resend_completed_job(self):
  user_id=self.register();self.client.post(f'/api/admin/analysts/{user_id}/review',headers=self.headers,json={'decision':'approve'});job_id=self.db.query(ReviewNotification).one().id
  with patch('Business.ReviewNotifications.SessionLocal',sessionmaker(bind=self.engine)):
   with patch('Business.ReviewNotifications.send_review_result',side_effect=RuntimeError('SMTP unavailable')):deliver_review_notification(job_id)
   self.db.expire_all();job=self.db.get(ReviewNotification,job_id);self.assertIsNone(job.sent_at);self.assertEqual(job.attempts,1);self.assertGreater(job.next_attempt_at,datetime.utcnow())
   job.next_attempt_at=datetime.utcnow()-timedelta(seconds=1);self.db.commit()
   with patch('Business.ReviewNotifications.send_review_result') as send:
    deliver_review_notification(job_id);deliver_review_notification(job_id);send.assert_called_once_with('analyst@example.com','Test Analyst','approve','')
   self.db.expire_all();self.assertIsNotNone(self.db.get(ReviewNotification,job_id).sent_at)
 def test_restriction_and_restoration_revoke_sessions(self):
  user_id=self.register();self.client.post(f'/api/admin/analysts/{user_id}/review',headers=self.headers,json={'decision':'approve'});self.db.expire_all();self.db.get(AuthState,user_id).is_verified=True;self.db.commit()
  token=login_user(self.db,'analyst@example.com','Original@123')[0]['access_token'];headers={'Authorization':'Bearer '+token};url=f'/api/admin/users/{user_id}/status'
  for action in ['restrict','restore']:
   self.assertEqual(self.client.post(url,headers=self.headers,json={'action':action}).status_code,200);self.assertEqual(self.client.get('/api/auth/me',headers=headers).status_code,401)
  self.assertEqual(self.client.get('/api/admin/users',headers=self.headers).json()['users'][0]['status'],'active')
 def test_branded_email_escapes_names_and_reasons(self):
  from Business.EmailService import send_review_result
  with patch.dict(os.environ,{'SMTP_FROM':'ADRense <sender@example.com>'}):
   with patch('Business.EmailService.deliver_message') as deliver:
    send_review_result('analyst@example.com','Test <Analyst>','reject','Bad <script>alert(1)</script>');message=deliver.call_args.args[0];self.assertIn('rejected',message['Subject'])
    html=message.get_body(preferencelist=('html',)).get_content();self.assertIn('cid:adrense-logo',html);self.assertNotIn('<script>',html);self.assertIn('&lt;script&gt;',html)
    send_review_result('analyst@example.com','Test Analyst','approve');self.assertIn('approved',deliver.call_args.args[0]['Subject'])
