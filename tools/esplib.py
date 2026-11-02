import struct, zlib
def recs(d, off=0, end=None):
    end = len(d) if end is None else end
    while off < end:
        t = d[off:off+4]; sz = struct.unpack_from('<I', d, off+4)[0]
        if t == b'GRUP':
            yield ('GRUP', d[off+8:off+12], off, sz, list(recs(d, off+24, off+sz))); off += sz
        else:
            flags, fid = struct.unpack_from('<II', d, off+8)
            data = d[off+24:off+24+sz]
            if flags & 0x40000: data = zlib.decompress(data[4:])
            yield (t.decode(), fid, flags, data); off += 24+sz
def subs(data):
    o=0; big=None
    while o < len(data):
        t=data[o:o+4]; l=struct.unpack_from('<H',data,o+4)[0]; o+=6
        if t==b'XXXX': big=struct.unpack_from('<I',data,o)[0]; o+=4; continue
        if big is not None: l=big; big=None
        yield t.decode(), data[o:o+l]; o+=l
def flat(rs):
    for r in rs:
        if r[0]=='GRUP': yield from flat(r[4])
        else: yield r
