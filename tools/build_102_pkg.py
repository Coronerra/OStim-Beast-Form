# Assemble OStim Beast Form 1.0.2 main package from the 1.0.1 package (box only). That Guy (Coronerra).
# Only the female-body plugin variants, the installer and the docs change; scripts, meshes, scenes are 1.0.1's.
import os, shutil, sys, subprocess
V101, ESP, DOC, P = sys.argv[1:5]
shutil.rmtree(P, ignore_errors=True)
shutil.copytree(V101, P)
def mv_in(src, dst_dir):
    os.makedirs(dst_dir, exist_ok=True); shutil.copy2(src, dst_dir)
os.remove(f"{P}/20 Core B TWO/OStim_Beast_Form_TWO.esp")
mv_in(f"{ESP}/coreB_softbody/OStim_Beast_Form_TWO.esp", f"{P}/21 Core B Softbody body")
mv_in(f"{ESP}/coreB_twobody/OStim_Beast_Form_TWO.esp", f"{P}/22 Core B TWO body")
os.remove(f"{P}/31 Core C TWO addon/OStim_Beast_Form_Merged_TWO_Patch.esp")
mv_in(f"{ESP}/coreC_two_softbody/OStim_Beast_Form_Merged_TWO_Patch.esp", f"{P}/32 Core C TWO addon Softbody body")
mv_in(f"{ESP}/coreC_two_twobody/OStim_Beast_Form_Merged_TWO_Patch.esp", f"{P}/33 Core C TWO addon TWO body")
C = f"{P}/00 Common"
shutil.copy2(f"{DOC}/README_OStim_Beast_Form.txt", f"{C}/README_OStim_Beast_Form.txt")
for f in ("README_OStim_Beast_Form.txt", "BodySlide_OBody.txt", "CHANGELOG.txt", "Lite_animation_attribution.txt"):
    shutil.copy2(f"{DOC}/{f}", f"{C}/Docs/OStim Beast Form/{f}")
subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), "fomod_main.py"), P], check=True)
print("built", P)
