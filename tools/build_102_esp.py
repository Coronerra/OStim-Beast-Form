# OStim Beast Form 1.0.2 plugin fix (box only). That Guy (Coronerra).
# Core B and the Growl + TWO add-on get a "TWO body" plugin variant: same records and FormIDs as 1.0.1,
# only the female body path (ARMA NakedTorsoWerewolfBeast 0xCDD87 MOD3/MOD5) and the aroused cock path
# (OBL_WerewolfAddonAA MOD2) point back at TWO's own files, exactly like 0.8.x "No softbody".
import sys, os, struct
sys.path.insert(0, os.path.dirname(__file__))
import esp10
from esp10 import z
V101 = sys.argv[1]          # extracted 1.0.1 main package
OUT = sys.argv[2]
TWO_F = "actors\\werewolfbeast\\character assets\\femalebodywerewolf_1.nif"
TWO_COCK = "actors\\werewolfbeast\\character assets\\CreatureFramework\\CanineRedHard.nif"
SB = "actors\\werewolfbeast\\character assets\\coronerra\\twosoftbody\\"

def two_body(P, cock_fid):
    a = P.find(0xCDD87)
    for t in ('MOD3', 'MOD5'):
        assert a.get(t) == z(SB + 'femalebodywerewolf_1.nif'), (t, a.get(t))
        a.set(t, z(TWO_F))
    c = P.find(cock_fid)
    assert c.get('MOD2') == z(SB + 'CanineRedHard.nif')
    c.set('MOD2', z(TWO_COCK))

os.makedirs(f"{OUT}/coreB_twobody", exist_ok=True); os.makedirs(f"{OUT}/coreB_softbody", exist_ok=True)
src = f"{V101}/20 Core B TWO/OStim_Beast_Form_TWO.esp"
P = esp10.Plugin(src); two_body(P, P.masters.__len__() << 24 | 0x833)
P.set_desc("OStim Beast Form 1.0.2 (TWO core, TWO's own female body: BodySlide builds apply) - That Guy (Coronerra). Werewolves and Vampire Lords in OStim, Beast Aware, Beast Load. Credit: That Guy (Coronerra).")
P.write(f"{OUT}/coreB_twobody/OStim_Beast_Form_TWO.esp")
P = esp10.Plugin(src)
P.set_desc("OStim Beast Form 1.0.2 (TWO core, converted softbody female body) - That Guy (Coronerra). Werewolves and Vampire Lords in OStim, Beast Aware, Beast Load. Credit: That Guy (Coronerra).")
P.write(f"{OUT}/coreB_softbody/OStim_Beast_Form_TWO.esp")

os.makedirs(f"{OUT}/coreC_two_twobody", exist_ok=True); os.makedirs(f"{OUT}/coreC_two_softbody", exist_ok=True)
src = f"{V101}/31 Core C TWO addon/OStim_Beast_Form_Merged_TWO_Patch.esp"
P = esp10.Plugin(src)
mi = P.masters.index('OStim_Beast_Form_Merged.esp')
two_body(P, mi << 24 | 0x833)
P.set_desc("OStim Beast Form 1.0.2, Growl + TWO add-on, TWO's own female body (BodySlide builds apply) - That Guy (Coronerra).")
P.write(f"{OUT}/coreC_two_twobody/OStim_Beast_Form_Merged_TWO_Patch.esp")
P = esp10.Plugin(src)
P.set_desc("OStim Beast Form 1.0.2, Growl + TWO add-on, converted softbody female body - That Guy (Coronerra).")
P.write(f"{OUT}/coreC_two_softbody/OStim_Beast_Form_Merged_TWO_Patch.esp")
print("ok")
