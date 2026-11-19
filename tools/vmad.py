# VMAD walker: yields byte offsets of every object FormID (objFormat 2). That Guy (Coronerra).
import struct
def _ws(b,i):
    n,=struct.unpack_from('<H',b,i); return b[i+2:i+2+n].decode('cp1252'), i+2+n
def _scripts(b,i,out,ver,fmt):
    cnt,=struct.unpack_from('<H',b,i); i+=2
    for _ in range(cnt):
        _,i=_ws(b,i)
        if ver>=4: i+=1
        pc,=struct.unpack_from('<H',b,i); i+=2
        for _ in range(pc):
            _,i=_ws(b,i); typ=b[i]; i+=1
            if ver>=4: i+=1
            i=_val(b,i,typ,out,fmt)
    return i
def _obj(b,i,out,fmt):
    out.append(i+4 if fmt==2 else i); return i+8
def _val(b,i,typ,out,fmt):
    if typ==1: return _obj(b,i,out,fmt)
    if typ==2: return _ws(b,i)[1]
    if typ in (3,4): return i+4
    if typ==5: return i+1
    if typ in (11,12,13,14,15):
        n,=struct.unpack_from('<I',b,i); i+=4
        for _ in range(n): i=_val(b,i,typ-10,out,fmt)
        return i
    raise ValueError(typ)
def object_offsets(b, rtype):
    out=[]; ver,fmt=struct.unpack_from('<hh',b,0); i=4
    i=_scripts(b,i,out,ver,fmt)
    if rtype=='QUST' and i<len(b):
        i+=1; fc,=struct.unpack_from('<H',b,i); i+=2
        _,i=_ws(b,i)
        for _ in range(fc):
            i+=2+2+4+1; _,i=_ws(b,i); _,i=_ws(b,i)
        ac,=struct.unpack_from('<H',b,i); i+=2
        for _ in range(ac):
            i=_obj(b,i,out,fmt)
            v2,f2=struct.unpack_from('<hh',b,i); i+=4
            i=_scripts(b,i,out,v2,f2)
    assert i==len(b),(i,len(b))
    return out
