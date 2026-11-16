import os
os.environ['DATABASE_URL']='sqlite://'
os.environ['SECRET_KEY']='test-only-secret-with-more-than-32-characters'
import base64
import io
import unittest
from datetime import date,timedelta
from unittest.mock import patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool
from PIL import Image
from pypdf import PdfWriter
from DAO.DatabaseConnection import Base,get_db
from Models.User import User
from Models.AuthState import AuthState
from Models.AnalystApplication import AnalystApplication,AnalystDocument
from Business.AuthService import pwd_context,login_user
from main import app

class AnalystApplicationTests(unittest.TestCase):
 def setUp(self):
  self.engine=create_engine('sqlite://',connect_args={'check_same_thread':False},poolclass=StaticPool)
  Base.metadata.create_all(self.engine)
  def db_override():
   with Session(self.engine) as db:yield db
  app.dependency_overrides[get_db]=db_override
  self.db=Session(self.engine)
  admin=User(name='Test Admin',email='admin.adrense@gmail.com',role='admin',status='active',password_hash=pwd_context.hash('Original@123'))
  self.db.add(admin);self.db.commit()
  session,_=login_user(self.db,admin.email,'Original@123')
  self.headers={'Authorization':'Bearer '+session['access_token']}
  self.client=TestClient(app)
  self.delivery=patch('API.auth_routes.deliver_code');self.delivery.start()
  self.review_delivery=patch('API.admin_routes.deliver_review_notification');self.review_delivery.start()
  image=io.BytesIO();Image.new('RGB',(10,10),'white').save(image,'PNG');self.png=image.getvalue()
 def tearDown(self):
  self.delivery.stop();self.review_delivery.stop();self.client.close();self.db.close();app.dependency_overrides.clear();self.engine.dispose()
 def payload(self):
  return {'name':'Test Analyst','email':'analyst@example.com','password':'Original@123','role':'analyst','profession':'Pharmacist','license_number':'PHARM-12345','institution':'Test University',
   'analyst_details':{'professional_email':'work@example.com','phone':'+923001234567','country':'Pakistan','country_code':'PK','professional_role':'Pharmacist','qualification':'Pharm-D','graduation_year':2020,'issuing_authority':'Pharmacy Council','license_expiry':(date.today()+timedelta(days=365)).strftime('%m/%d/%Y')},
   'documents':[{'kind':kind,'filename':kind+'.png','content_base64':base64.b64encode(self.png).decode()} for kind in ['license','degree']]}
 def register(self,payload=None):
  response=self.client.post('/api/auth/register',json=payload or self.payload())
  self.assertEqual(response.status_code,201,response.text);return response.json()['user_id']
 def test_upload_persistence_listing_and_private_preview(self):
  user_id=self.register()
  docs=self.db.query(AnalystDocument).filter_by(user_id=user_id).all();self.assertEqual(len(docs),2);self.assertEqual(docs[0].content,self.png)
  application=self.db.get(AnalystApplication,user_id);self.assertEqual(application.details['phone'],'+923001234567')
  response=self.client.get('/api/admin/analysts',headers=self.headers);self.assertEqual(response.status_code,200,response.text)
  row=response.json()['applications'][0];self.assertEqual(row['details']['country'],'Pakistan');self.assertNotIn('content',row['documents'][0])
  doc_id=row['documents'][0]['id']
  denied=self.client.get(f'/api/admin/documents/{doc_id}');self.assertIn(denied.status_code,[401,403])
  preview=self.client.get(f'/api/admin/documents/{doc_id}',headers=self.headers);self.assertEqual(preview.content,self.png);self.assertEqual(preview.headers['cache-control'],'no-store')
 def test_required_documents_and_duplicate_categories(self):
  payload=self.payload();payload['documents']=payload['documents'][:1]
  self.assertEqual(self.client.post('/api/auth/register',json=payload).status_code,422)
  payload=self.payload();payload['documents'].append(payload['documents'][0])
  self.assertEqual(self.client.post('/api/auth/register',json=payload).status_code,422)
  self.assertEqual(self.db.query(User).filter_by(role='analyst').count(),0)
 def test_disguised_malformed_and_oversized_files(self):
  for filename,content in [('license.pdf',self.png),('license.exe',self.png),('license.png',b'not an image'),('license.png',b'x'*(5*1024*1024+1))]:
   payload=self.payload();payload['documents'][0].update(filename=filename,content_base64=base64.b64encode(content).decode())
   result=self.client.post('/api/auth/register',json=payload);self.assertEqual(result.status_code,422)
   self.assertNotIn('content_base64":',result.text)
 def test_pdf_upload_and_encrypted_pdf_rejection(self):
  writer=PdfWriter();writer.add_blank_page(width=300,height=300);buffer=io.BytesIO();writer.write(buffer)
  payload=self.payload();payload['documents'][0].update(filename='license.pdf',content_base64=base64.b64encode(buffer.getvalue()).decode())
  self.register(payload)
  writer.encrypt('secret');buffer=io.BytesIO();writer.write(buffer)
  payload=self.payload();payload['email']='another@example.com';payload['documents'][0].update(filename='license.pdf',content_base64=base64.b64encode(buffer.getvalue()).decode())
  self.assertEqual(self.client.post('/api/auth/register',json=payload).status_code,422)
 def test_approval_and_login_stay_gated_by_email(self):
  user_id=self.register();response=self.client.post(f'/api/admin/analysts/{user_id}/review',headers=self.headers,json={'decision':'approve'})
  self.assertEqual(response.status_code,200,response.text);self.db.expire_all();self.assertEqual(self.db.get(User,user_id).status,'active')
  self.assertEqual(login_user(self.db,'analyst@example.com','Original@123')[1],'EMAIL_NOT_VERIFIED')
  self.db.get(AuthState,user_id).is_verified=True;self.db.commit();self.assertIsNone(login_user(self.db,'analyst@example.com','Original@123')[1])
  self.assertEqual(self.client.post(f'/api/admin/analysts/{user_id}/review',headers=self.headers,json={'decision':'approve'}).status_code,409)
 def test_rejection_is_persisted_with_reason(self):
  user_id=self.register();url=f'/api/admin/analysts/{user_id}/review'
  self.assertEqual(self.client.post(url,headers=self.headers,json={'decision':'reject'}).status_code,422)
  result=self.client.post(url,headers=self.headers,json={'decision':'reject','reason':'License is unreadable'})
  self.assertEqual(result.status_code,200,result.text);self.db.expire_all();self.assertEqual(self.db.get(User,user_id).status,'rejected');self.assertEqual(self.db.get(AnalystApplication,user_id).review_reason,'License is unreadable')
 def test_non_admin_cannot_review_or_view(self):
  user_id=self.register();self.db.get(AuthState,user_id).is_verified=True;user=self.db.get(User,user_id);user.status='active';self.db.commit()
  token=login_user(self.db,user.email,'Original@123')[0]['access_token'];headers={'Authorization':'Bearer '+token}
  self.assertEqual(self.client.get('/api/admin/analysts',headers=headers).status_code,403)
  doc_id=self.db.query(AnalystDocument).first().id
  self.assertEqual(self.client.get(f'/api/admin/documents/{doc_id}',headers=headers).status_code,403)
  self.assertEqual(self.client.post(f'/api/admin/analysts/{user_id}/review',headers=headers,json={'decision':'approve'}).status_code,403)
 def test_expired_date_and_body_limit(self):
  payload=self.payload();payload['analyst_details']['license_expiry']='01/01/2020'
  self.assertEqual(self.client.post('/api/auth/register',json=payload).status_code,422)
  response=self.client.post('/api/auth/register',content=b'{}',headers={'Content-Type':'application/json','Content-Length':str(23*1024*1024)})
  self.assertEqual(response.status_code,413)
