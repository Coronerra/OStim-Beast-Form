# Assemble OStim Beast Form 1.0 main package (box only). That Guy (Coronerra).
import os, shutil, json, subprocess, glob
R = "/workspace/skyrim/bf10"; S = "/workspace/skyrim/bf081/pkg"; P = f"{R}/pkg_main"
ESP = f"{R}/build/esp"; DOC = f"{R}/docs_src"; SRC = f"{R}/src"
CA = "meshes/actors/werewolfbeast/character assets"
def cp(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copy2(src, dst)
def cpt(src, dst):
    shutil.copytree(src, dst, dirs_exist_ok=True)
def put(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', newline='\r\n').write(text.strip() + "\n")
def compile_(out, sd, files):
    r = subprocess.run([f"{R}/tools/compile.sh", out, sd] + files, capture_output=True, text=True)
    errs = [l for l in (r.stdout + r.stderr).splitlines() if 'Error' in l]
    assert not errs, errs
    for f in files:
        assert os.path.exists(f"{out}/{f[:-4]}.pex"), f

shutil.rmtree(P, ignore_errors=True)
C = f"{P}/00 Common"
# ---------- 00 Common ----------
cpt(f"{S}/00 Common/meshes", f"{C}/meshes")
cpt(f"{S}/00 Common/interface", f"{C}/interface")
cpt(f"{S}/00 Common/SKSE/Plugins/OStim/scenes/OBeastLite", f"{C}/SKSE/Plugins/OStim/scenes/OBeastLite")
cpt(f"{S}/00 Common/SKSE/Plugins/OStim/scenes/OBFMerged", f"{C}/SKSE/Plugins/OStim/scenes/OBFMerged")
cpt(f"{S}/00 Common/SKSE/Plugins/OStimNet", f"{C}/SKSE/Plugins/OStimNet")
cpt(f"{SRC}/skyrimnet", f"{C}/SKSE/Plugins/SkyrimNet/external")
sb = f"{S}/30 Softbody"
cpt(f"{sb}/meshes", f"{C}/meshes")
cpt(f"{sb}/SKSE/Plugins/hdtSkinnedMeshConfigs", f"{C}/SKSE/Plugins/hdtSkinnedMeshConfigs")
hs = "/workspace/skyrim/bfa/heads_out/stage/meshes/actors"
cp(f"{hs}/werewolfbeast/character assets/werewolfhead.tri", f"{C}/{CA}/coronerra/bfa/werewolfhead.tri")
for t in ("vampirelordhead.tri", "vampirelordfemalehead.tri"):
    cp(f"{hs}/vampirelord/character assets/{t}", f"{C}/meshes/actors/vampirelord/character assets/coronerra/bfa/{t}")
common_psc = sorted(os.listdir(f"{SRC}/common"))
compile_(f"{C}/Scripts", f"{SRC}/common", common_psc)
for f in common_psc: cp(f"{SRC}/common/{f}", f"{C}/Scripts/Source/{f}")
cp(f"{DOC}/README_OStim_Beast_Form.txt", f"{C}/README_OStim_Beast_Form.txt")
for f in ("README_OStim_Beast_Form.txt", "BodySlide_OBody.txt", "CHANGELOG.txt", "Lite_animation_attribution.txt"):
    cp(f"{DOC}/{f}", f"{C}/Docs/OStim Beast Form/{f}")
cp(f"{S}/00 Common/Docs/OStim Beast Form Merged/OStimNet_SkyrimNet_Integration_0.4.txt", f"{C}/Docs/OStim Beast Form/OStimNet_SkyrimNet_Integration.txt")
VL = """PUT_VAMPIRE_LORD_FILES_HERE
OStim Beast Form 1.0 - That Guy (Coronerra)

Not included because I didn't change these files (they belong to their authors).
If Monster Facial Animation (and an aroused Vampire Lord mesh) are installed, they're already in place and you can ignore this note.

{files}
"""
put(f"{C}/meshes/actors/vampirelord/character assets/body/PUT_VAMPIRE_LORD_FILES_HERE.txt", VL.format(files="""This folder: vampirelord.nif, vampirelordfemale.nif
  = the headless Vampire Lord bodies from Monster Facial Animation (MFA)."""))
put(f"{C}/meshes/actors/vampirelord/character assets/PUT_VAMPIRE_LORD_FILES_HERE.txt", VL.format(files="""This folder: vampirelordhead.nif, vampirelordfemalehead.nif, vampirelordeyes.nif, vampirelordfemaleeyes.nif
  = Monster Facial Animation's Vampire Lord head parts.
The expression files (vampirelordhead.tri, vampirelordfemalehead.tri) ARE included, in coronerra\\bfa\\ (edited by me, with brow and smile morphs)."""))
put(f"{C}/meshes/MoreNastyCritters/vampirelord/PUT_VAMPIRE_LORD_FILES_HERE.txt", VL.format(files="""This folder: vampirelord_Hard.nif
  = the aroused Vampire Lord body (More Nasty Critters / OCreatures Reforged). Without it, Vampire Lords just keep their normal body in scenes."""))

# ---------- cores ----------
def actor_props(dst, mod, extra=()):
    for f in ("OBLWerewolfMale", "OBLWerewolfFemale", "OBLVampireLordMale", "OBLVampireLordFemale"):
        d = json.load(open(f"{S}/10 Growl/SKSE/Plugins/OStim/actor properties/{f}.json"))
        d["condition"]["mod"] = mod
        put(f"{dst}/SKSE/Plugins/OStim/actor properties/{f}.json", json.dumps(d, indent="\t"))
    for name, info, fid, typ, male in extra:
        req = {"penis": True, "testicles": True, "anus": True, "mouth": True, "hand": True, "foot": True} if male else \
              {"penis": False, "testicles": False, "vagina": True, "breast": True, "nipple": True, "anus": True, "mouth": True, "hand": True, "foot": True}
        d = {"condition": {"info": info, "mod": mod, "formid": fid}, "type": typ, "requirements": req}
        put(f"{dst}/SKSE/Plugins/OStim/actor properties/{name}.json", json.dumps(d, indent="\t"))

TWO_NOTE = """PUT_TWO_FILES_HERE
OStim Beast Form 1.0 - That Guy (Coronerra)

Not included: these are Frosferes' TWO - Total Werewolf Overhaul 4.1 files, which I didn't change.
Frosferes is okay with patches but I will not repackage any files he made that I did not have to patch.
Get TWO 4.1: https://www.loverslab.com/topic/159911-two-total-werewolf-overhaul/
Copy these files from TWO's "Core" folder into THIS folder (same names). You don't need TWO's plugin (Werewolves.esp) for this.

{files}
"""
def two_placeholders(core, heads):
    put(f"{core}/{CA}/PUT_TWO_FILES_HERE.txt", TWO_NOTE.format(files="""This folder (meshes\\actors\\werewolfbeast\\character assets\\):
  malebodywerewolf_0.nif, malebodywerewolf_1.nif, malebodywerewolf.tri   (male body, headless)
  skeleton.nif                                                            (TWO's werewolf skeleton)
The female body and the cock ARE included (edited by me) in coronerra\\twosoftbody\\."""))
    if heads:
        put(f"{core}/{CA}/HeadParts/PUT_TWO_FILES_HERE.txt", TWO_NOTE.format(files="""This folder (meshes\\actors\\werewolfbeast\\character assets\\HeadParts\\):
  MaleHeadWerewolf.nif, MaleMouthWerewolf.nif, MaleEyesWerewolf.nif
  FemaleHeadWerewolf.nif, FemaleMouthWerewolf.nif, FemaleEyesWerewolf.nif
  ExpMouthWerewolf.tri, ExpEyesWerewolf.tri
The head expression file (ExpHeadWerewolf_BFA.tri, edited by me) IS included, in coronerra\\two\\."""))
    put(f"{core}/textures/actors/character/werewolf/PUT_TWO_FILES_HERE.txt", TWO_NOTE.format(files="""This folder (textures\\actors\\character\\werewolf\\): every .dds in TWO's textures\\actors\\character\\werewolf\\ (body, head, mouth, with _n and _sk maps)."""))
    put(f"{core}/textures/actors/character/eyes/PUT_TWO_FILES_HERE.txt", TWO_NOTE.format(files="""This folder (textures\\actors\\character\\eyes\\): TWO's eyewerewolfbeast*.dds files."""))
    put(f"{core}/textures/MoreNastyCritters/werewolf/PUT_TWO_FILES_HERE.txt", TWO_NOTE.format(files="""This folder (textures\\MoreNastyCritters\\werewolf\\): werewolfballs.dds, werewolfballs_n.dds, werewolfballs_sk.dds, werewolfpenis_red.dds, werewolfpenis_n.dds, werewolfpenis_sk.dds (cock textures used by the included cock)."""))

two_psc_out = f"{R}/build/pex_two"; growl_psc_out = f"{R}/build/pex_growl"
compile_(two_psc_out, f"{SRC}/mcm_two", ["OBF_MCM.psc"])
compile_(growl_psc_out, f"{SRC}/mcm_growl", ["OBF_MCM.psc"])
tri_bfa_two = f"{S}/20 TWO/{CA}/coronerra/two/ExpHeadWerewolf_BFA.tri"

A = f"{P}/10 Core A Vanilla"
cp(f"{ESP}/coreA/OStim_Beast_Form_TWO.esp", f"{A}/OStim_Beast_Form_TWO.esp")
cp(f"{two_psc_out}/OBF_MCM.pex", f"{A}/Scripts/OBF_MCM.pex"); cp(f"{SRC}/mcm_two/OBF_MCM.psc", f"{A}/Scripts/Source/OBF_MCM.psc")
actor_props(A, "OStim_Beast_Form_TWO.esp")
cp(tri_bfa_two, f"{A}/{CA}/coronerra/two/ExpHeadWerewolf_BFA.tri")
two_placeholders(A, heads=True)

B = f"{P}/20 Core B TWO"
cp(f"{ESP}/coreB/OStim_Beast_Form_TWO.esp", f"{B}/OStim_Beast_Form_TWO.esp")
cp(f"{ESP}/coreB_extra/OStim_Beast_Form_TWO - BFA Heads.esp", f"{B}/OStim_Beast_Form_TWO - BFA Heads.esp")
cp(f"{two_psc_out}/OBF_MCM.pex", f"{B}/Scripts/OBF_MCM.pex"); cp(f"{SRC}/mcm_two/OBF_MCM.psc", f"{B}/Scripts/Source/OBF_MCM.psc")
actor_props(B, "OStim_Beast_Form_TWO.esp")
cp(tri_bfa_two, f"{B}/{CA}/coronerra/two/ExpHeadWerewolf_BFA.tri")

Cc = f"{P}/30 Core C Growl"
cp(f"{ESP}/coreC/OStim_Beast_Form_Merged.esp", f"{Cc}/OStim_Beast_Form_Merged.esp")
cp(f"{growl_psc_out}/OBF_MCM.pex", f"{Cc}/Scripts/OBF_MCM.pex"); cp(f"{SRC}/mcm_growl/OBF_MCM.psc", f"{Cc}/Scripts/Source/OBF_MCM.psc")
actor_props(Cc, "OStim_Beast_Form_Merged.esp", extra=(
    ("OBLWerebearAsWerewolfMale", "OBL_WerebearAsWerewolfMaleCondition (MCM: Werebears use werewolf scenes)", "0x83A", "Werewolf", True),
    ("OBLWerebearAsWerewolfFemale", "OBL_WerebearAsWerewolfFemaleCondition (MCM: Werebears use werewolf scenes)", "0x83B", "Werewolf", False),
    ("OBLWerebearMale", "OBL_WerebearMaleCondition (own Werebear type for future packs)", "0x83C", "Werebear", True),
    ("OBLWerebearFemale", "OBL_WerebearFemaleCondition (own Werebear type for future packs)", "0x83D", "Werebear", False)))
two_placeholders(Cc, heads=False)
put(f"{Cc}/{CA}/PUT_MFA_FILES_HERE.txt", """PUT_MFA_FILES_HERE
OStim Beast Form 1.0 (Growl core) - That Guy (Coronerra)

Not included because I didn't change these files. If Monster Facial Animation (MFA) is installed, they're already here and you can ignore this note.
This folder (meshes\\actors\\werewolfbeast\\character assets\\), from Monster Facial Animation:
  werewolfhead.nif                                 (head, used for male and female werewolves)
  werewolfteeth.nif, werewolfteeth.tri             (mouth)
  eyesmalewerewolfbeast.nif, eyesmalewerewolfbeast.tri  (eyes)
The head expression file (werewolfhead.tri with BFA brow morphs, edited by me) IS included, in coronerra\\bfa\\.
With "Growl + TWO" picked in the installer, TWO's own heads are used instead and you can ignore this note.""")
WB = """PUT_WEREBEAR_FILES_HERE
OStim Beast Form 1.0 (Growl core) - That Guy (Coronerra)

Not included because I didn't change these files. Growl uses the vanilla Dragonborn werebear paths, so if your werebear mods are installed they're already here.

{files}
"""
put(f"{Cc}/meshes/actors/dlc02/werebear/body/PUT_WEREBEAR_FILES_HERE.txt", WB.format(files="This folder: werebear.nif, werebear_female.nif (werebear bodies from your werebear body mod, e.g. ABC / More Nasty Critters)."))
put(f"{Cc}/meshes/actors/dlc02/werebear/PUT_WEREBEAR_FILES_HERE.txt", WB.format(files="This folder: werebear head, eyes and teeth meshes (.nif/.tri) from your werebear mod, if it has them."))
put(f"{Cc}/meshes/MoreNastyCritters/werebear/PUT_WEREBEAR_FILES_HERE.txt", WB.format(files="This folder: werebearHard.nif = the aroused werebear body (More Nasty Critters / OCreatures Reforged). Without OCreatures Reforged, this mod puts it on male werebears during scenes if the file is here."))
put(f"{Cc}/textures/actors/dlc02/werebear/PUT_WEREBEAR_FILES_HERE.txt", WB.format(files="This folder: werebear body/head/mouth textures (+ _n) from your werebear mod."))
put(f"{Cc}/textures/MoreNastyCritters/bear/PUT_WEREBEAR_FILES_HERE.txt", WB.format(files="This folder: bear cock and balls textures used by werebearHard.nif (More Nasty Critters)."))

C2 = f"{P}/31 Core C TWO addon"
cp(f"{ESP}/coreC_two/OStim_Beast_Form_Merged_TWO_Patch.esp", f"{C2}/OStim_Beast_Form_Merged_TWO_Patch.esp")
cp(f"{ESP}/coreC_two/OStim_Beast_Form_Merged_TWO_Patch - BFA Heads.esp", f"{C2}/OStim_Beast_Form_Merged_TWO_Patch - BFA Heads.esp")
cp(tri_bfa_two, f"{C2}/{CA}/coronerra/two/ExpHeadWerewolf_BFA.tri")
cp(f"{S}/10 Growl/{CA}/coronerra/twopatch/werewolfsheath.nif", f"{C2}/{CA}/coronerra/twopatch/werewolfsheath.nif")

# ---------- OCR stand-ins (only without OCreatures Reforged) ----------
cpt(f"{S}/00 Common/SKSE/Plugins/OStim/scenes/OCreatures", f"{P}/40 OCR standins/SKSE/Plugins/OStim/scenes/OCreatures")

# ---------- Beast couples (Lirael's animations, our own scene files; no edits to her files) ----------
cs = f"{S}/53 WVL Beast Couples/SKSE/Plugins"
cd = f"{P}/50 Beast couples/SKSE/Plugins/OStim/scenes/OBFWVL/couples"
keep_files = ["OBFWerewolfIdleCCMF.json", "OBFWerewolfIdleCCFM.json", "OBFWerewolfIdleCCMM.json",
              "OBFVampireLordIdleCCMF.json", "OBFVampireLordIdleCCFM.json", "OBFWVLCCHubMF.json", "OBFWVLCCVLHubMF.json"]
keep_dirs = ["mmgwerewolffystyleMF", "mmgwerewolvesblowjobMF", "mmgwerewolvescowgirlMF", "mmgwerewolvesmissionaryMF", "mmgvamponvampMF"]
ids = []
for f in keep_files:
    cp(f"{cs}/OStim/scenes/OBFWVL/couples/{f}", f"{cd}/{f}"); ids.append(f[:-5])
for dname in keep_dirs:
    for f in sorted(os.listdir(f"{cs}/OStim/scenes/OBFWVL/couples/{dname}")):
        d = json.load(open(f"{cs}/OStim/scenes/OBFWVL/couples/{dname}/{f}"))
        tags = [t for t in d.get("tags", []) if t != "obfunlock"]
        if "obfmalefirst" not in tags: tags.append("obfmalefirst")
        d["tags"] = tags
        put(f"{cd}/{dname}/{f}", json.dumps(d, indent=4)); ids.append(f[:-5])
desc = json.load(open(glob.glob(f"{cs}/OStimNet/animationsDescriptions/*.json")[0]))
fix = {"and he starts sucking him": "and she starts sucking him", "in a steady rhythm, his breathing matching his": "in a steady rhythm, her breathing matching his",
       "his lips sliding along his length, while he presses back against him": "her lips sliding along his length, while she presses back against him",
       "pushing down his throat, as he leans into him": "pushing down her throat, as she leans into him", "spilling over his tongue": "spilling over her tongue"}
out = {}
for k in ids:
    if k in desc:
        v = desc[k]
        if "blowjobMF" in k:
            for a, b in fix.items(): v = v.replace(a, b)
        out[k] = v
put(f"{P}/50 Beast couples/SKSE/Plugins/OStimNet/animationsDescriptions/zz OStim Beast Form - Beast Couples.json", json.dumps(out, indent=4))
print("couples scenes:", len(ids), "descriptions:", len(out))
print("built", P)
