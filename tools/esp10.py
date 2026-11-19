# Minimal TES5 plugin reader/writer for OStim Beast Form 1.0 builds. That Guy (Coronerra).
import struct, zlib
def subs(d):
    i=0; out=[]; big=None
    while i < len(d):
        t=d[i:i+4].decode('latin1'); n=struct.unpack('<H', d[i+4:i+6])[0]
        if t=='XXXX': big=struct.unpack('<I', d[i+6:i+10])[0]; i+=10; continue
        if big is not None: n=big; big=None
        out.append([t, d[i+6:i+6+n]]); i+=6+n
    return out
class Rec:
    def __init__(s, typ, fid, sub, flags=0, vc=b'\0'*4, ver=44, uk=b'\0\0'):
        s.type=typ; s.fid=fid; s.subs=sub; s.flags=flags & ~0x40000; s.vc=vc; s.ver=ver; s.uk=uk
    def get(s, t, n=0):
        k=[b for x,b in s.subs if x==t]; return k[n] if len(k)>n else None
    def edid(s):
        e=s.get('EDID'); return e.rstrip(b'\0').decode('cp1252') if e else ''
    def set(s, t, b, n=0):
        c=0
        for x in s.subs:
            if x[0]==t:
                if c==n: x[1]=b; return
                c+=1
        raise KeyError(t)
    def pack(s):
        body=b''
        for t,b in s.subs:
            if len(b) > 0xFFFF:
                body+=b'XXXX'+struct.pack('<HI',4,len(b))+t.encode()+struct.pack('<H',0)+b
            else:
                body+=t.encode()+struct.pack('<H',len(b))+b
        return s.type.encode()+struct.pack('<III',len(body),s.flags,s.fid)+s.vc+struct.pack('<H',s.ver)+s.uk+body
class Plugin:
    def __init__(s, path=None):
        s.hdr=[]; s.flags=0x200; s.recs=[]; s.order=[]
        if path: s.load(path)
    def load(s, path):
        d=open(path,'rb').read(); hs=struct.unpack('<I',d[4:8])[0]
        s.flags=struct.unpack('<I',d[8:12])[0]; s.tes4vc=d[16:24]
        s.hdr=subs(d[24:24+hs])
        def walk(i,end,top):
            while i<end:
                if d[i:i+4]==b'GRUP':
                    sz=struct.unpack('<I',d[i+4:i+8])[0]
                    if top:
                        lab=d[i+8:i+12].decode('latin1')
                        if lab not in s.order: s.order.append(lab)
                    walk(i+24,i+sz,False); i+=sz; continue
                sz,fl,fid=struct.unpack('<III',d[i+4:i+16]); body=d[i+24:i+24+sz]
                if fl & 0x40000: body=zlib.decompress(body[4:])
                s.recs.append(Rec(d[i:i+4].decode(),fid,subs(body),fl,d[i+16:i+20],struct.unpack('<H',d[i+20:i+22])[0],d[i+22:i+24])); i+=24+sz
        walk(24+hs,len(d),True)
    @property
    def masters(s): return [b.rstrip(b'\0').decode() for t,b in s.hdr if t=='MAST']
    def find(s, fid, typ=None):
        r=[r for r in s.recs if r.fid==fid and (typ is None or r.type==typ)]; return r[0] if r else None
    def byedid(s, e):
        r=[r for r in s.recs if r.edid()==e]; return r[0] if r else None
    def add(s, r):
        assert not s.find(r.fid), hex(r.fid); s.recs.append(r)
        if r.type not in s.order: s.order.append(r.type)
    def set_masters(s, names):
        h=[]; done=False
        for t,b in s.hdr:
            if t in ('MAST','DATA'):
                if not done:
                    for n in names: h+= [['MAST', n.encode('cp1252')+b'\0'], ['DATA', b'\0'*8]]
                    done=True
                continue
            h.append([t,b])
        if not done:
            # insert after CNAM/SNAM
            k=max(i for i,(t,b) in enumerate(h) if t in ('HEDR','CNAM','SNAM'))+1
            for n in reversed(names): h[k:k]=[['MAST', n.encode('cp1252')+b'\0'], ['DATA', b'\0'*8]]
        s.hdr=h
    def set_desc(s, text):
        b=text.encode('cp1252')+b'\0'
        for x in s.hdr:
            if x[0]=='SNAM': x[1]=b; return
        k=[i for i,(t,_) in enumerate(s.hdr) if t=='CNAM'][0]+1; s.hdr.insert(k,['SNAM',b])
    def write(s, path):
        s.hdr=[x for x in s.hdr if x[0]!='ONAM']
        hedr=[b for t,b in s.hdr if t=='HEDR'][0]
        ver,_,nid=struct.unpack('<fII',hedr)
        mx=max([r.fid&0xFFFFFF for r in s.recs if (r.fid>>24)==len(s.masters)]+[nid-1])
        for x in s.hdr:
            if x[0]=='HEDR': x[1]=struct.pack('<fII',ver,len(s.recs),max(nid,mx+1))
        hb=b''.join(t.encode()+struct.pack('<H',len(b))+b for t,b in s.hdr)
        out=b'TES4'+struct.pack('<III',len(hb),s.flags,0)+getattr(s,'tes4vc',b'\0'*4+struct.pack('<H',44)+b'\0\0')+hb
        for typ in s.order:
            rs=[r for r in s.recs if r.type==typ]
            if not rs: continue
            body=b''.join(r.pack() for r in rs)
            out+=b'GRUP'+struct.pack('<I',len(body)+24)+typ.encode()+struct.pack('<I',0)+b'\0'*4+struct.pack('<H',0)+b'\0\0'+body
        open(path,'wb').write(out)
def z(s): return s.encode('cp1252')+b'\0'
def u32(v): return struct.pack('<I',v)
