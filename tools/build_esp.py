# OStim Beast Form 1.0 plugin builder (box only). That Guy (Coronerra).
import os, struct, copy, shutil, sys
sys.path.insert(0, os.path.dirname(__file__))
import esp10, vmad
from esp10 import Rec, z, u32
SRC = "/workspace/skyrim/bf081/pkg"
OUT = "/workspace/skyrim/bf10/build/esp"
TWO_ESP = "/workspace/skyrim/two_41/src/TWO/Core/Werewolves.esp"
BFA = "actors\\werewolfbeast\\character assets\\coronerra\\bfa\\"
VLBFA = "actors\\vampirelord\\character assets\\coronerra\\bfa\\"
SB = "actors\\werewolfbeast\\character assets\\coronerra\\twosoftbody\\"
FID_SUBS = {'RNAM','HEAD','KWDA','LNAM','SNDD','ALFR','SPLO','WNAM','GNAM','ONAM','UNES','QNAM','NAM4','NAM5'}

def remap_val(x, m):
    hi = x >> 24
    if hi in m and 0 < (x & 0xFFFFFF) < 0x1000000:
        return (m[hi] << 24) | (x & 0xFFFFFF)
    return x

def remap_plugin(P, m):
    for r in P.recs:
        r.fid = remap_val(r.fid, m)
        for s in r.subs:
            t, b = s
            if t in FID_SUBS or (t == 'MODL' and len(b) == 4) or (t == 'VTCK' and r.type == 'QUST'):
                if len(b) % 4: continue
                s[1] = b''.join(u32(remap_val(struct.unpack_from('<I', b, i)[0], m)) for i in range(0, len(b), 4))
            elif t == 'CTDA':
                bb = bytearray(b)
                for o in (12, 16, 24):
                    struct.pack_into('<I', bb, o, remap_val(struct.unpack_from('<I', bb, o)[0], m))
                s[1] = bytes(bb)
            elif t == 'VMAD':
                bb = bytearray(b)
                for o in vmad.object_offsets(b, r.type):
                    struct.pack_into('<I', bb, o, remap_val(struct.unpack_from('<I', bb, o)[0], m))
                s[1] = bytes(bb)

def drop(r, *types):
    r.subs = [s for s in r.subs if s[0] not in types]

def setstr(r, t, v):
    r.set(t, z(v))

def perk(fid, edid, desc, race, sex, level, glob=None):
    c = []
    c.append(['CTDA', struct.pack('<B3sfHHIIIIi', 0, b'\0\0\0', 1.0, 0x45, 0, race, 0, 0, 0, -1)])
    c.append(['CTDA', struct.pack('<B3sfHHIIIIi', 0, b'\0\0\0', 1.0, 0x46, 0, sex, 0, 0, 0, -1)])
    if glob:
        c.append(['CTDA', struct.pack('<B3sfHHIIIIi', 0, b'\0\0\0', 1.0, 0x4A, 0, glob, 0, 0, 0, -1)])
    return Rec('PERK', fid, [['EDID', z(edid)], ['DESC', z(desc)]] + c + [['DATA', bytes([0, level, 1, 0, 0])]])

def check_esl(P, name):
    own = [r for r in P.recs if (r.fid >> 24) == len(P.masters)]
    for r in own:
        assert 0x800 <= (r.fid & 0xFFFFFF) <= 0xFFF, (name, hex(r.fid))
    assert P.flags & 0x200, name
    return len(own)

def core_b():
    P = esp10.Plugin(f"{SRC}/21 TWO Softbody/OStim_Beast_Form_TWO.esp")
    for fid, tri in ((0x8000805, 'vampirelordhead.tri'), (0x8000808, 'vampirelordfemalehead.tri')):
        setstr(P.find(fid), 'NAM1', VLBFA + tri)
    P.set_desc("OStim Beast Form 1.0 (TWO / vanilla core) - That Guy (Coronerra). Werewolves and Vampire Lords in OStim, Beast Aware, Beast Load. Credit: That Guy (Coronerra).")
    return P

def core_a():
    P = core_b()
    assert P.masters == ['Skyrim.esm','Update.esm','Dawnguard.esm','Dragonborn.esm','Werewolves.esp','MonsterLipSync1.esp','OStim.esp','OCum.esp'], P.masters
    remap_plugin(P, {6: 4, 7: 5, 8: 6})
    P.set_masters(['Skyrim.esm','Update.esm','Dawnguard.esm','Dragonborn.esm','OStim.esp','OCum.esp'])
    # TWO-style head parts as our own records (meshes come from the user's TWO files, see PUT_TWO_FILES_HERE.txt)
    W = esp10.Plugin(TWO_ESP)
    order = [0x2000800,0x2000801,0x2000802,0x3000800,0x3000801,0x3000802,0x3000803,0x3000804,
             0x3000805,0x3000806,0x3000807,0x3000808,0x3000809,0x300080a,0x300080b,0x300080c]
    newid = {old: 0x6000840 + i for i, old in enumerate(order)}
    # TWO's head-fur parts point at meshes TWO itself doesn't ship: left out, only head/mouth/eyes are used
    furs = {0x3000800,0x3000801,0x3000802,0x3000803,0x3000804,0x3000808,0x3000809,0x300080a,0x300080b,0x300080c}
    order = [o for o in order if o not in furs]
    for old in order:
        src = W.find(old)
        r = Rec('HDPT', newid[old], copy.deepcopy(src.subs))
        r.set('EDID', z('OBFA_' + src.edid()))
        if src.edid() in ('MaleHeadWerewolf', 'FemaleHeadWerewolf'):
            setstr(r, 'NAM1', 'meshes\\actors\\werewolfbeast\\character assets\\coronerra\\two\\ExpHeadWerewolf_BFA.tri')
        if src.edid() == 'FemaleMouthWerewolf':
            setstr(r, 'NAM1', 'meshes\\actors\\werewolfbeast\\character assets\\HeadParts\\ExpMouthWerewolf.tri')
        P.add(r)
    race = W.find(0xcdd84)
    subs = []
    skip_next = False
    src = copy.deepcopy(race.subs)
    for i, s in enumerate(src):
        if s[0] == 'INDX' and i + 1 < len(src) and src[i + 1][0] == 'HEAD' and struct.unpack('<I', src[i + 1][1])[0] in furs:
            skip_next = True
            continue
        if skip_next:
            skip_next = False
            continue
        if s[0] == 'HEAD':
            s[1] = u32(newid[struct.unpack('<I', s[1])[0]])
        subs.append(s)
    rr = Rec('RACE', 0xcdd84, subs, race.flags)
    # put the race next to the other RACE record
    P.add(rr)
    P.set_desc("OStim Beast Form 1.0 (vanilla core, no TWO plugin needed) - That Guy (Coronerra). Uses TWO-style werewolf heads and body files that you copy in yourself.")
    return P

def core_c():
    P = esp10.Plugin(f"{SRC}/10 Growl/OStim_Beast_Form_Merged.esp")
    assert P.masters[3] == 'Dragonborn.esm' and len(P.masters) == 8
    a = P.find(0xcdd87)
    setstr(a, 'MOD2', 'Actors\\WerewolfBeast\\Character Assets\\MaleBodyWereWolf_1.NIF')
    setstr(a, 'MOD3', SB + 'femalebodywerewolf_1.nif')
    setstr(a, 'MOD4', 'Actors\\WerewolfBeast\\Character Assets\\MaleBodyWereWolf_1.NIF')
    setstr(a, 'MOD5', SB + 'femalebodywerewolf_1.nif')
    drop(a, 'MO2T', 'MO3T', 'MO4T', 'MO5T')
    c = P.find(0x8000833)
    setstr(c, 'MOD2', SB + 'CanineRedHard.nif'); drop(c, 'MO2T')
    for fid in (0x8000800, 0x8000803):
        setstr(P.find(fid), 'NAM1', BFA + 'werewolfhead.tri')
    setstr(P.find(0x8000803), 'MODL', 'Actors\\werewolfbeast\\character assets\\werewolfhead.nif')
    drop(P.find(0x8000803), 'MODT')
    for fid, tri in ((0x8000805, 'vampirelordhead.tri'), (0x8000808, 'vampirelordfemalehead.tri')):
        setstr(P.find(fid), 'NAM1', VLBFA + tri)
    WB = 0x0301E17B
    P.add(Rec('GLOB', 0x8000839, [['EDID', z('OBL_WerebearAsWerewolf')], ['FNAM', b's'], ['FLTV', struct.pack('<f', 1.0)]]))
    d = "Condition holder for OStim actor properties (OStim Beast Form 1.0, werebears). Actors do not need this perk."
    P.add(perk(0x800083A, 'OBL_WerebearAsWerewolfMaleCondition', d, WB, 0, 22, 0x8000839))
    P.add(perk(0x800083B, 'OBL_WerebearAsWerewolfFemaleCondition', d, WB, 1, 22, 0x8000839))
    P.add(perk(0x800083C, 'OBL_WerebearMaleCondition', d, WB, 0, 21))
    P.add(perk(0x800083D, 'OBL_WerebearFemaleCondition', d, WB, 1, 21))
    vla, vlo = P.find(0x8000834), P.find(0x8000836)
    aa = Rec('ARMA', 0x800083F, [['EDID', z('OBL_WerebearArousedAA')], ['BOD2', vla.get('BOD2')], ['RNAM', u32(WB)],
             ['DNAM', vla.get('DNAM')], ['MOD2', z('MoreNastyCritters\\werebear\\werebearHard.nif')], ['SNDD', vla.get('SNDD')]])
    ao = Rec('ARMO', 0x800083E, [['EDID', z('OBL_WerebearAroused')], ['OBND', vlo.get('OBND')], ['BOD2', vlo.get('BOD2')],
             ['RNAM', u32(WB)], ['KSIZ', u32(1)], ['KWDA', u32(0x8000838)], ['DESC', b'\0'], ['MODL', u32(0x800083F)],
             ['DATA', vlo.get('DATA')], ['DNAM', vlo.get('DNAM')]], vlo.flags)
    P.add(ao); P.add(aa)
    P.set_desc("OStim Beast Form 1.0 (Growl core) - That Guy (Coronerra). Werewolves, Vampire Lords and Growl werebears in OStim, Beast Aware, Beast Load. Credit: That Guy (Coronerra).")
    return P

def main():
    os.makedirs(OUT, exist_ok=True)
    res = {}
    for name, fn, fname in (('coreA', core_a, 'OStim_Beast_Form_TWO.esp'), ('coreB', core_b, 'OStim_Beast_Form_TWO.esp'), ('coreC', core_c, 'OStim_Beast_Form_Merged.esp')):
        P = fn(); d = f"{OUT}/{name}"; os.makedirs(d, exist_ok=True)
        n = check_esl(P, name)
        P.write(f"{d}/{fname}"); res[name] = (P.masters, n, len(P.recs))
    d = f"{OUT}/coreC_two"; os.makedirs(d, exist_ok=True)
    shutil.copy2(f"{SRC}/11 Growl Softbody/OStim_Beast_Form_Merged_TWO_Patch.esp", d)
    shutil.copy2(f"{SRC}/10 Growl/OStim_Beast_Form_Merged_TWO_Patch - BFA Heads.esp", d)
    d = f"{OUT}/coreB_extra"; os.makedirs(d, exist_ok=True)
    shutil.copy2(f"{SRC}/20 TWO/OStim_Beast_Form_TWO - BFA Heads.esp", d)
    for k, v in res.items(): print(k, v)

if __name__ == '__main__':
    main()
