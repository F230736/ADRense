import os
from pathlib import Path
from dotenv import load_dotenv
import httpx
load_dotenv(Path(__file__).resolve().parent / '.env')
with httpx.Client(base_url='http://127.0.0.1:8000',trust_env=False,timeout=20) as client:
    result=client.post('/api/auth/login',json={'email':'admin.adrense@gmail.com','password':os.environ['ADR_ADMIN_PASSWORD']})
    if result.status_code!=200:
        print('Live admin data check could not sign in. HTTP status:',result.status_code)
        raise SystemExit(1)
    headers={'Authorization':'Bearer '+result.json()['access_token']}
    users=client.get('/api/admin/users',headers=headers)
    stats=client.get('/api/admin/registrations?days=30',headers=headers)
    users.raise_for_status();stats.raise_for_status()
    print('Live database account count:',len(users.json()['users']))
    print('Registration buckets:',len(stats.json()['buckets']))
    print('Account summary:',stats.json()['summary'])
    assert all('password_hash' not in row for row in users.json()['users'])
