import sys, struct, os
sys.path.insert(0, os.path.dirname(__file__)); sys.path.insert(0, '/workspace/skyrim/beastform_esl/tool')
import esp10, vmad
B = "/workspace/skyrim/bf081/pkg"; O = "/workspace/skyrim/bf10/build/esp"
def refs(P):
    out = []
    for r in P.recs:
        for t, b in r.subs:
            if t in esp10_FID or (t == 'MODL' and len(b) == 4):
                out += [(r, t, struct.unpack_from('<I', b, i)[0]) for i in range(0, len(b) - 3, 4)]
            elif t == 'CTDA':
                out += [(r, t, struct.unpack_from('<I', b, o)[0]) for o in (12, 16, 24)]
            elif t == 'VMAD':
                out += [(r, t, struct.unpack_from('<I', b, o)[0]) for o in vmad.object_offsets(b, r.type)]
    return out
esp10_FID = {'RNAM','HEAD','KWDA','LNAM','SNDD','ALFR','SPLO','WNAM','GNAM','ONAM','UNES','QNAM','NAM4','NAM5'}
ok = True
def chk(cond, msg):
    global ok
    print(('PASS ' if cond else 'FAIL ') + msg); ok &= bool(cond)
for core, new, old, selfmap in (('A', f"{O}/coreA/OStim_Beast_Form_TWO.esp", f"{B}/21 TWO Softbody/OStim_Beast_Form_TWO.esp", {8: 6, 7: 5, 6: 4}),
                                 ('B', f"{O}/coreB/OStim_Beast_Form_TWO.esp", f"{B}/21 TWO Softbody/OStim_Beast_Form_TWO.esp", {}),
                                 ('C', f"{O}/coreC/OStim_Beast_Form_Merged.esp", f"{B}/10 Growl/OStim_Beast_Form_Merged.esp", {})):
    N, Old = esp10.Plugin(new), esp10.Plugin(old)
    nm = len(N.masters)
    # every old record still there with same type/EDID and local id
    miss = []
    for r in Old.recs:
        f = r.fid; hi = f >> 24; f2 = (selfmap.get(hi, hi) << 24) | (f & 0xFFFFFF)
        n = N.find(f2, r.type)
        if not n or n.edid() != r.edid(): miss.append(hex(f))
    chk(not miss, f"core {core}: all {len(Old.recs)} 0.8.1 records kept with same FormID/EDID {miss}")
    # master names of referenced forms unchanged
    oldnames = Old.masters + ['<self>']; newnames = N.masters + ['<self>']
    bad = [(hex(r.fid), t, hex(x)) for r, t, x in refs(N) if x and (x >> 24) > nm]
    chk(not bad, f"core {core}: no reference past the master list ({nm} masters) {bad[:5]}")
    # same referenced plugin names for kept records
    def named(P, names):
        d = {}
        for r, t, x in refs(P):
            if not x: continue
            key = (r.type, r.edid(), t)
            d.setdefault(key, []).append((names[x >> 24] if (x >> 24) < len(names) else '?', x & 0xFFFFFF))
        return d
    dn, do = named(N, newnames), named(Old, oldnames)
    changed = [k for k in do if k in dn and do[k] != dn[k]]
    chk(not changed or core == 'A' and all(k[0] == 'RACE' for k in changed), f"core {core}: references of kept records point at the same plugin+id {changed}")
    own = [r for r in N.recs if r.fid >> 24 == nm]
    chk(all(0x800 <= r.fid & 0xFFFFFF <= 0xFFF for r in own) and N.flags & 0x200, f"core {core}: ESL flag set, {len(own)} own records all in 0x800-0xFFF")
    new_ids = sorted(hex(r.fid & 0xFFFFFF) for r in own if not Old.find(((8 if core!='A' else 8) << 24) | (r.fid & 0xFFFFFF)) and not Old.find(r.fid))
    print(f"     core {core} new records: {new_ids}")
    print(f"     core {core} masters: {N.masters}")
    hedr = [b for t, b in N.hdr if t == 'HEDR'][0]; print('     HEDR', struct.unpack('<fII', hedr))
    import esp as E2
    try:
        E2.load(new); print('     cross-parse with beastform_esl/tool/esp.py: ok')
    except Exception as e:
        chk(False, f'cross-parse {e}')
print('ALL OK' if ok else 'SOME FAILED')
