import os
os.environ['DATABASE_URL']='sqlite://'
os.environ['SECRET_KEY']='test-only-secret-with-more-than-32-characters'
import unittest
from unittest.mock import patch
from datetime import datetime,timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from DAO.DatabaseConnection import Base
from Models.User import User
from Models.AuthState import EmailChallenge
from Business.AuthService import register_user,login_user
from Business.EmailAuthService import request_code,consume_code,state_for
from DTO.AuthDTO import UserRegisterDTO,ResetPasswordDTO
from API.auth_routes import me
from pydantic import ValidationError

class AuthTests(unittest.TestCase):
 def setUp(self):
  self.engine=create_engine('sqlite://');Base.metadata.create_all(self.engine);self.db=Session(self.engine)
  self.user,_=register_user(self.db,UserRegisterDTO(name='Test Person',email='test@example.com',password='Original@123',age_group='18-25',gender='Other'))
  self.patcher=patch('Business.EmailAuthService.send_code');self.mail=self.patcher.start()
 def tearDown(self):
  self.patcher.stop();self.db.close();self.engine.dispose()
 def code(self,purpose):
  request_code(self.db,self.user.email,purpose);return self.mail.call_args.args[1]
 def test_verification_single_use_and_login_gate(self):
  self.assertEqual(login_user(self.db,self.user.email,'Original@123')[1],'EMAIL_NOT_VERIFIED')
  code=self.code('verify');self.assertNotEqual(code,self.db.query(EmailChallenge).one().digest)
  self.assertTrue(consume_code(self.db,self.user.email,code,'verify'))
  self.assertFalse(consume_code(self.db,self.user.email,code,'verify'))
  self.assertIsNone(login_user(self.db,self.user.email,'Original@123')[1])
 def test_reset_revokes_sessions(self):
  state_for(self.db,self.user).is_verified=True;self.db.commit()
  token=login_user(self.db,self.user.email,'Original@123')[0]['access_token']
  credentials=HTTPAuthorizationCredentials(scheme='Bearer',credentials=token)
  self.assertEqual(me(credentials,self.db)['id'],self.user.id)
  code=self.code('reset');self.assertTrue(consume_code(self.db,self.user.email,code,'reset','Replacement@123'))
  with self.assertRaises(HTTPException):me(credentials,self.db)
  self.assertIsNotNone(login_user(self.db,self.user.email,'Original@123')[1])
  self.assertIsNone(login_user(self.db,self.user.email,'Replacement@123')[1])
  self.assertFalse(consume_code(self.db,self.user.email,code,'reset','Another@123'))
 def test_attempt_limit_expiry_and_resend_cooldown(self):
  code=self.code('verify');request_code(self.db,self.user.email,'verify');self.assertEqual(self.mail.call_count,1)
  wrong='000001' if code!='000001' else '000002'
  for _ in range(5):self.assertFalse(consume_code(self.db,self.user.email,wrong,'verify'))
  self.assertFalse(consume_code(self.db,self.user.email,code,'verify'))
  row=self.db.query(EmailChallenge).one();row.sent_at=datetime.utcnow()-timedelta(seconds=61);self.db.commit()
  request_code(self.db,self.user.email,'verify');self.assertEqual(self.mail.call_count,1)
  row.expires_at=datetime.utcnow()-timedelta(seconds=1);self.db.commit()
  self.assertFalse(consume_code(self.db,self.user.email,code,'verify'))
 def test_resend_replaces_old_code(self):
  old=self.code('verify');self.db.query(EmailChallenge).one().sent_at=datetime.utcnow()-timedelta(seconds=61);self.db.commit()
  with patch('Business.EmailAuthService.secrets.randbelow',return_value=(int(old)+1)%1000000):new=self.code('verify')
  self.assertFalse(consume_code(self.db,self.user.email,old,'verify'));self.assertTrue(consume_code(self.db,self.user.email,new,'verify'))
 def test_unknown_address_and_purpose_isolation(self):
  request_code(self.db,'absent@example.com','reset');self.mail.assert_not_called()
  code=self.code('verify');self.assertFalse(consume_code(self.db,self.user.email,code,'reset','Replacement@123'))
  reset=self.code('reset');self.assertTrue(consume_code(self.db,self.user.email,reset,'reset','Replacement@123'))
  self.assertFalse(state_for(self.db,self.user).is_verified)
 def test_analyst_approval_remains_required(self):
  self.user.role='analyst';self.user.status='pending';self.db.commit()
  self.assertTrue(consume_code(self.db,self.user.email,self.code('verify'),'verify'))
  self.assertIn('administrator approval',login_user(self.db,self.user.email,'Original@123')[1])
 def test_password_validation(self):
  for password,confirmation in [('weak','weak'),('Strong@123','Different@123'),('A@a'+'x'*80,'A@a'+'x'*80)]:
   with self.assertRaises(ValidationError):ResetPasswordDTO(email='test@example.com',code='123456',password=password,confirm_password=confirmation)
 def test_persistent_rate_limit(self):
  from starlette.requests import Request
  from Business.RateLimit import auth_rate_limit
  req=Request({'type':'http','path':'/api/auth/forgot-password','client':('127.0.0.1',5000),'headers':[]})
  for _ in range(30):auth_rate_limit(req,self.db)
  with self.assertRaises(HTTPException) as error:auth_rate_limit(req,self.db)
  self.assertEqual(error.exception.status_code,429)
 def test_generic_requests_defer_delivery(self):
  from fastapi import BackgroundTasks
  from DTO.AuthDTO import EmailRequestDTO
  from API.auth_routes import forgot_password
  known=BackgroundTasks();unknown=BackgroundTasks()
  a=forgot_password(EmailRequestDTO(email=self.user.email),known)
  b=forgot_password(EmailRequestDTO(email='absent@example.com'),unknown)
  self.assertEqual(a,b);self.assertEqual(len(known.tasks),1);self.mail.assert_not_called()
 def test_branded_multipart_email(self):
  from Business.EmailService import send_code
  with patch.dict(os.environ,{'SMTP_HOST':'smtp.example.com','SMTP_FROM':'ADRense <no-reply@example.com>','SMTP_USERNAME':'','SMTP_SSL':'false'}):
   with patch('Business.EmailService.smtplib.SMTP') as smtp:
    send_code(self.user.email,'123456','verify')
    message=smtp.return_value.__enter__.return_value.send_message.call_args.args[0]
    self.assertIn('ADRense',message['Subject'])
    self.assertIn('123456',message.get_body(preferencelist=('plain',)).get_content())
    self.assertIn('cid:adrense-logo',message.get_body(preferencelist=('html',)).get_content())
    self.assertTrue(any(part['Content-ID']=='<adrense-logo>' for part in message.walk()))
