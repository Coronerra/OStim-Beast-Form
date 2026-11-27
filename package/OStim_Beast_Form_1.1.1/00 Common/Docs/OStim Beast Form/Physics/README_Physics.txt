OStim Beast Form 1.1.1: physics reference (inert)
by That Guy (Coronerra)

Nothing in this folder is loaded by the game. It lives under Docs, not
under SKSE\Plugins, on purpose. Copy what you need into your own body
mod.

WHY BEAST FORM CANNOT TURN PHYSICS ON BY ITSELF
A body mesh names its own SMP configuration in its extra data, and that
configuration names bones and shapes. Beast Form ships no body, so the
body author supplies all three: bones in the skeleton or in the mesh, a
mesh skinned to them, and a configuration.

THE BONES THAT ALREADY EXIST (TWO 4.1 werewolf skeleton, also used by
Growl werebears)
  NPC L Breast, NPC R Breast, Breast01, and the P1, P2, P3 chains
  (NPC L/R Breast Pn, Breast00 to Breast04 Pn); also butt, belly, tail.
The vanilla (non-Growl) werebear skeleton and the vanilla vampire lord
skeleton lack breast bones. Check with a nif viewer before you skin.

TWO-BREASTED ONLY
Remove the lower pairs in BodySlide for female werewolf, werebear and
vampire lord bodies.

REFERENCE CONFIGURATION
Reference_BreastChain_SMP.xml in this folder: a small left-side breast
chain for the standard community bone names, with our own conservative
values, in the common FSMP / HDT-SMP structure. It is a starting point
only: it has not been loaded, tuned or tested in game, and it covers one
bone pair. Mirror it for the right side, add the chain bones your body is
skinned to, point your nif at your own renamed copy, then tune.

BODY-EMBEDDED BONES (for vampire lords or any rig without breast bones)
Add physics bones to the body mesh itself, with names that carry your own
prefix (for example MYMOD L Breast01 to 03), skin the breast shapes to
them, and drive them from your configuration. Bones carried by the mesh
need no skeleton override and do not conflict with whoever owns the
skeleton file.

CBPC
Same bones; the configuration format is CBPC's own and is the body
author's to write.
