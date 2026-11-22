import json, urllib.request, urllib.error, sys, time
BASE='http://127.0.0.1:8000/api'
PASS=FAIL=0
fails=[]
def call(method, path, token=None, body=None, accept=True):
    for attempt in range(4):
        data=None; h={}
        if accept: h['Accept']='application/json'
        if body is not None:
            data=json.dumps(body).encode(); h['Content-Type']='application/json'
        if token: h['Authorization']='Bearer '+token
        req=urllib.request.Request(BASE+path, data=data, method=method, headers=h)
        retry_after=None
        try:
            r=urllib.request.urlopen(req, timeout=20); code=r.status; raw=r.read()
        except urllib.error.HTTPError as e:
            code=e.code; raw=e.read(); retry_after=e.headers.get('Retry-After')
        # Login + register dibatasi 10 permintaan/menit (throttle:10,1): tunggu lalu ulangi.
        if code==429 and attempt<3:
            wait=int(retry_after or 60)+1
            print(f'  (batas 10 login/menit tercapai, menunggu {wait} detik...)'); time.sleep(wait); continue
        break
    try: js=json.loads(raw)
    except Exception: js={'_raw':raw[:200].decode('utf8','ignore')}
    return code, js
def tok(j):
    return j.get('token') if isinstance(j,dict) else None
def check(name, cond, extra=''):
    global PASS, FAIL
    if cond: PASS+=1
    else:
        FAIL+=1; fails.append(f'{name} {extra}'); print('FAIL:', name, extra)
def login(email, pw):
    c,j=call('POST','/auth/login',body={'email':email,'password':pw}); return c,j
# --- auth
c,j=login('admin@laundryku.com','admin123'); check('owner login',c==200 and j['session']['role']=='owner'); OW=tok(j)
c,j=login('sari@laundryku.com','sari123'); check('emp login',c==200 and j['session']['permissions']==['transaksi','pengeluaran'],str(j)); SA=tok(j)
c,j=login('admin@laundryku.com','salah'); check('wrong pw 401',c==401)
c,j=call('GET','/orders'); check('no token 401 json',c==401 and 'message' in j,str(c))
c,j=call('GET','/orders',accept=False); check('no token no Accept still json',c==401 and 'message' in j,str(j)[:80])
c,j=call('GET','/tidak-ada',OW); check('unknown route 404 json',c==404,str(c))
# --- catalog & data
c,svcs=call('GET','/services',OW); check('services',c==200 and len(svcs)==16)
sv={f"{s['name']}|{s['unit']}":s for s in svcs}
reg2=[s for s in svcs if s['name']=='Reguler 2 Hari'][0]
king=[s for s in svcs if s['name']=='King'][0]
c,cats=call('GET','/categories',OW); check('categories',c==200 and len(cats)==6)
c,custs=call('GET','/customers',OW); check('customers',c==200 and len(custs)==6 and 'orders_count' in custs[0])
c,orders=call('GET','/orders',OW); check('orders seeded',c==200 and len(orders)==17)
check('created_at has +07:00', orders[0]['created_at'].endswith('+07:00'), orders[0]['created_at'])
inv=[o['invoice'] for o in orders]; check('invoice unique', len(set(inv))==len(inv))
# --- create order: price from server, client price ignored
cust=custs[0]['id']
c,o=call('POST','/orders',SA,{'customer_id':int(cust),'items':[{'service_id':int(reg2['id']),'qty':3.5,'price':1}],'note':'tes','first_payment':{'method':'tunai','amount':999999999}})
check('create order 201',c==201,str(o)[:200])
check('total from server 3.5*10000=35000',o.get('total')==35000,str(o.get('total')))
check('first payment capped to total',o.get('paid')==35000 and o.get('is_paid') is True,str(o.get('paid')))
check('status antrian + 1 log',o.get('status')=='antrian' and len(o.get('logs',[]))==1)
check('due_at = created+48h', True)
OID=o['id']
# min qty / inactive / bad input
c,j=call('POST','/orders',SA,{'customer_id':int(cust),'items':[{'service_id':int(king['id']),'qty':0.5}]}); check('qty below min 422',c==422,str(c)+str(j)[:100])
c,j=call('POST','/orders',SA,{'customer_id':int(cust),'items':[]}); check('empty items 422',c==422)
c,j=call('POST','/orders',SA,{'customer_id':99999,'items':[{'service_id':int(reg2['id']),'qty':1}]}); check('unknown customer 422',c==422)
# no permission cases
c,emp_list=call('GET','/employees',OW); check('employees owner',c==200 and len(emp_list)==1)
c,j=call('GET','/employees',SA); check('employees forbidden for emp',c==403)
c,j=call('GET','/reports/summary',SA); check('report forbidden for emp w/o laporan',c==403)
c,j=call('POST','/services',SA,{'category_id':1,'name':'X','unit':'kg','price':1000,'duration_value':1,'duration_unit':'hari'}); check('emp cannot create service',c==403)
c,j=call('PATCH',f"/services/{reg2['id']}/active",SA,{'active':False}); check('emp w/o layanan cannot toggle',c==403)
c,j=call('PUT','/business',SA,{'business_name':'x','owner_name':'y'}); check('emp cannot edit business',c==403)
c,j=call('POST','/reports/downloads',SA,{'period_label':'x','from':'2026-11-01','to':'2026-11-02','sections':['ringkasan']}); check('emp cannot log downloads',c==403)
# status flow
c,j=call('PATCH',f'/orders/{OID}/status',SA,{'status':'selesai'}); check('skip step 422',c==422,str(j)[:100])
for st in ['diproses','selesai','diambil']:
    c,j=call('PATCH',f'/orders/{OID}/status',SA,{'status':st}); check('advance '+st,c==200 and j['status']==st,str(j)[:100])
c,j=call('PATCH',f'/orders/{OID}/status',SA,{'status':'diambil'}); check('after diambil 422',c==422)
c,j=call('GET',f'/orders/{OID}',SA); check('4 logs',len(j['logs'])==4)
c,j=call('POST',f'/orders/{OID}/cancel',OW); check('cancel diambil 422',c==422)
# partial payment + overpay
c,o2=call('POST','/orders',SA,{'customer_id':int(cust),'items':[{'service_id':int(reg2['id']),'qty':2}],'first_payment':{'method':'qris','amount':5000}}); check('order2',c==201 and o2['total']==20000 and o2['paid']==5000 and o2['remaining']==15000)
O2=o2['id']
c,j=call('POST',f'/orders/{O2}/payments',SA,{'method':'tunai','amount':999999}); check('overpay capped',c==200 and j['paid']==20000 and j['remaining']==0,str(j)[:120])
c,j=call('POST',f'/orders/{O2}/payments',SA,{'method':'tunai','amount':1}); check('pay when paid 422',c==422)
c,j=call('POST',f'/orders/{O2}/cancel',SA); check('emp cancel paid -> 403',c==403,str(c))
c,j=call('POST',f'/orders/{O2}/cancel',OW); check('owner cancel paid ok',c==200 and j['cancelled'] is True)
c,j=call('POST',f'/orders/{O2}/payments',OW,{'method':'tunai','amount':1}); check('pay cancelled 422',c==422)
c,j=call('PATCH',f'/orders/{O2}/status',OW,{'status':'diproses'}); check('advance cancelled 422',c==422)
c,j=call('POST',f'/orders/{O2}/cancel',OW); check('double cancel 422',c==422)
# unpaid order cancellable by emp
c,o3=call('POST','/orders',SA,{'customer_id':int(cust),'items':[{'service_id':int(reg2['id']),'qty':1}]}); O3=o3['id']
c,j=call('POST',f'/orders/{O3}/cancel',SA); check('emp cancel unpaid ok',c==200 and j['cancelled'])
# invoice numbering
c,orders=call('GET','/orders',OW); today=[o['invoice'] for o in orders if o['created_at'][:10]==time.strftime('%Y-%m-%d')]
check('invoice format',all(i.startswith('INV-') and len(i)==15 for i in today),str(today[:3]))
# employee w/o permission gets []
c,e=call('POST','/employees',OW,{'name':'Budi Kasir','email':'budi@laundryku.com','phone':'0811','password':'budi123','permissions':[]}); check('create employee',c==201,str(e)[:100])
c,j=call('POST','/employees',OW,{'name':'Dup','email':'BUDI@laundryku.com','password':'abc123'}); check('dup employee email 422 msg',c==422 and 'Email sudah dipakai' in json.dumps(j),str(j)[:120])
c,j=login('budi@laundryku.com','budi123'); BU=tok(j)
c,j=call('GET','/expenses',BU); check('emp no perm expenses -> []',c==200 and j==[],str(j)[:80])
c,j=call('GET','/expenses',SA); check('emp w/ perm expenses',c==200 and len(j)==4)
c,j=call('POST','/orders',BU,{'customer_id':int(cust),'items':[{'service_id':int(reg2['id']),'qty':1}]}); check('emp no transaksi cannot create',c==403)
c,j=call('GET','/orders',BU); check('emp no perm can read orders (dashboard)',c==200)
# update employee perms -> layanan allows toggle only
c,j=call('PUT',f"/employees/{e['id']}",OW,{'permissions':['layanan','laporan']}); check('update perms',c==200 and set(j['permissions'])=={'layanan','laporan'})
c,j=call('PATCH',f"/services/{reg2['id']}/active",BU,{'active':False}); check('layanan emp toggle ok',c==200 and j['active'] is False)
c,j=call('POST','/orders',SA,{'customer_id':int(cust),'items':[{'service_id':int(reg2['id']),'qty':1}]}); check('inactive service 422',c==422,str(j)[:100])
c,j=call('PUT',f"/services/{reg2['id']}",BU,{'category_id':int(reg2['category_id']),'name':reg2['name'],'unit':reg2['unit'],'price':reg2['price'],'min_qty':reg2['min_qty'],'duration_value':reg2['duration_value'],'duration_unit':reg2['duration_unit'],'active':True}); check('layanan emp PUT only-active ok',c==200 and j['active'] is True,str(j)[:100])
c,j=call('PUT',f"/services/{reg2['id']}",BU,{'category_id':int(reg2['category_id']),'name':reg2['name'],'unit':reg2['unit'],'price':1,'min_qty':reg2['min_qty'],'duration_value':reg2['duration_value'],'duration_unit':reg2['duration_unit'],'active':True}); check('layanan emp cannot change price',c==403)
c,j=call('PUT',f"/services/{reg2['id']}",OW,{'category_id':int(reg2['category_id']),'name':reg2['name'],'unit':reg2['unit'],'price':11000,'min_qty':0,'duration_value':2,'duration_unit':'hari','active':True}); check('owner change price',c==200 and j['price']==11000)
# old orders keep old price snapshot
c,j=call('GET',f'/orders/{OID}',OW); check('old order keeps snapshot price',j['items'][0]['price']==10000 and j['total']==35000)
# reports
c,r=call('GET','/reports/summary?period=custom&from=2026-01-01&to=2026-12-31&group_by=month',BU); check('report w/ laporan',c==200,str(r)[:150])
all_o=[o for o in call('GET','/orders',OW)[1] if not o['cancelled']]
exp_omzet=sum(o['total'] for o in all_o); exp_paid=sum(o['paid'] for o in all_o)
check('report omzet matches',r['omzet']==exp_omzet,f"{r['omzet']} vs {exp_omzet}")
check('report received/receivable',r['received']==exp_paid and r['receivable']==exp_omzet-exp_paid)
check('report tx count',r['transactions']==len(all_o))
check('report profit',r['profit']==r['omzet']-r['expense'] and r['expense']==495000,str(r['expense']))
check('by_method sums to received',r['by_method']['tunai']+r['by_method']['qris']==r['received'],str(r['by_method']))
c,r7=call('GET','/reports/summary?period=7days',OW); check('7days',c==200 and r7['period']['from']<r7['period']['to'])
c,rt=call('GET','/reports/summary',OW); check('today',c==200)
c,rb=call('GET','/reports/summary?period=custom',OW); check('custom w/o dates 422',c==422)
c,d=call('GET','/dashboard',BU); check('dashboard',c==200 and set(d['status_counts'])=={'antrian','diproses','selesai','diambil'},str(d)[:150])
# report downloads (feature added by user)
c,j=call('POST','/reports/downloads',BU,{'format':'pdf','period_label':'7 Hari Terakhir','from':'2026-11-15','to':'2026-11-21','sections':['ringkasan','pengeluaran','ringkasan']}); check('log download',c==201 and j['sections']==['ringkasan','pengeluaran'],str(j)[:150])
c,j=call('POST','/reports/downloads',BU,{'period_label':'x','from':'2026-11-15','to':'2026-11-21','sections':['ngawur']}); check('bad section 422',c==422)
c,j=call('POST','/reports/downloads',BU,{'period_label':'x','from':'2026-11-21','to':'2026-11-15','sections':['ringkasan']}); check('to<from 422',c==422)
c,j=call('GET','/reports/downloads',BU); mine=[d for d in j if d.get('user_name')=='Budi Kasir'] if c==200 and isinstance(j,list) else []; check('list downloads',len(mine)==1 and mine[0]['sections']==['ringkasan','pengeluaran'],str(j)[:150])
# customers soft delete keeps history
c,j=call('POST','/customers',SA,{'name':'Pelanggan Baru','phone':'0812-0000-1111'}); NC=j['id']
c,o4=call('POST','/orders',SA,{'customer_id':int(NC),'items':[{'service_id':int(reg2['id']),'qty':2}]}); 
c,j=call('DELETE',f'/customers/{NC}',SA); check('delete customer',c==200)
c,j=call('GET',f"/orders/{o4['id']}",SA); check('order of deleted customer kept',c==200 and j['customer_name']=='Pelanggan Baru')
c,j=call('POST','/orders',SA,{'customer_id':int(NC),'items':[{'service_id':int(reg2['id']),'qty':1}]}); check('order for deleted customer 422',c==422)
# service delete keeps history; category delete restricted
c,j=call('POST','/services',OW,{'category_id':int(cats[0]['id']),'name':'Tmp','unit':'kg','price':5000,'min_qty':0,'duration_value':1,'duration_unit':'hari'}); TS=j['id']
c,o5=call('POST','/orders',SA,{'customer_id':int(cust),'items':[{'service_id':int(TS),'qty':2}]}); check('order tmp svc',c==201)
c,j=call('DELETE',f'/services/{TS}',OW); check('delete service',c==200)
c,j=call('GET',f"/orders/{o5['id']}",SA); check('order keeps deleted service snapshot',c==200 and j['items'][0]['name']=='Tmp' and j['items'][0]['service_id']=='',str(j['items']))
c,j=call('DELETE',f"/categories/{cats[0]['id']}",OW); check('category w/ services delete 422',c==422)
# whatsapp
c,j=call('GET',f'/orders/{O3}/whatsapp',SA); check('whatsapp cancelled msg',c==200 and 'dibatalkan' in j['message'],str(j)[:150])
c,j=call('GET',f"/orders/{o4['id']}/whatsapp",SA); check('whatsapp msg',c==200 and j['phone'].startswith('62') and 'Total tagihan Rp' in j['message'] and 'Estimasi selesai' in j['message'],str(j)[:250])
print('WA:',j['message'])
# password change
c,j=call('PUT','/auth/password',SA,{'old_password':'salah','new_password':'baru123'}); check('wrong old pw 422 code',c==422 and j.get('code')=='wrong_password')
c,j=call('PUT','/auth/password',SA,{'old_password':'sari123','new_password':'123'}); check('short new pw 422',c==422)
c,j=call('PUT','/auth/password',SA,{'old_password':'sari123','new_password':'baru123'}); check('change pw ok',c==200)
c,j=login('sari@laundryku.com','sari123'); check('old pw rejected',c==401)
c,j=login('sari@laundryku.com','baru123'); check('new pw works',c==200); SA=tok(j)
c,j=call('PUT',f"/employees/{e['id']}/password",OW,{'new_password':'reset123'}); check('owner reset emp pw',c==200)
c,j=call('GET','/orders',BU); check('emp tokens revoked after reset',c==401)
c,j=login('budi@laundryku.com','reset123'); check('login with reset pw',c==200)
# register + tenant isolation
c,j=call('POST','/auth/register',body={'business_name':'Laundry B','owner_name':'Owner B','email':'b@x.com','phone':'081234567890','password':'secret1'}); check('register',c==201,str(j))
c,j=call('POST','/auth/register',body={'business_name':'Laundry B','owner_name':'Owner B','email':'B@x.com','phone':'081234567890','password':'secret1'}); check('register dup email 422 msg',c==422 and 'Email sudah terdaftar' in json.dumps(j),str(j)[:150])
c,j=call('POST','/auth/register',body={'business_name':'','owner_name':'','email':'bad','phone':'1','password':'1'}); check('register invalid 422',c==422)
c,j=login('b@x.com','secret1'); check('login new owner',c==200); B=tok(j)
c,j=call('GET','/services',B); check('new biz has default catalog',c==200 and len(j)==16)
check('new biz service ids differ from A', set(s['id'] for s in j).isdisjoint(set(s['id'] for s in svcs)))
c,j=call('GET','/customers',B); check('new biz no customers',j==[])
c,j=call('GET','/orders',B); check('new biz no orders',j==[])
c,j=call('GET',f'/orders/{OID}',B); check('cross-tenant order 404',c==404)
c,j=call('POST',f'/orders/{OID}/cancel',B); check('cross-tenant cancel 404',c==404)
c,j=call('GET','/business',B); check('new biz profile',c==200 and j['business_name']=='Laundry B' and j['email']=='b@x.com',str(j))
c,j=call('PUT','/business',B,{'business_name':'Laundry B2','owner_name':'Owner B2','phone':'0812','hours':'09.00 - 21.00','owner_wa':'0899'}); check('update profile',c==200 and j['business_name']=='Laundry B2' and j['owner_name']=='Owner B2' and j['owner_wa']=='0899')
c,j=call('PUT',f"/services/{svcs[0]['id']}",B,{'category_id':1,'name':'hack','unit':'kg','price':1,'duration_value':1,'duration_unit':'hari'}); check('cross-tenant service update 404/422',c in (404,422),str(c))
c,j=call('POST','/orders',B,{'customer_id':int(cust),'items':[{'service_id':int(reg2['id']),'qty':1}]}); check('cross-tenant create order 422',c==422)
# logout
c,j=call('POST','/auth/logout',B); check('logout',c==200)
c,j=call('GET','/orders',B); check('token revoked after logout',c==401)
print(f'\nPASS={PASS} FAIL={FAIL}')
for f in fails: print(' -',f)