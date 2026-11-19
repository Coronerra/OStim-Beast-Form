Werewolf and Vampire Lord OStim 0.3.1 Patch 0.2
Author: That Guy (Coronerra)

A FOMOD patch for Werewolf and Vampire Lord OStim v0.3.1 by Lirael
(Lirael Atelier). This patch contains no animations, no plugins, and no
behavior files. It does not change or redistribute any animation from the
0.3.1 pack.

Animations in 0.3.1 are by Billyy, Anub, FlufyFox, Baka (BakaFactory),
FunnyBizness, the More Nasty Critters team (Dayelyte, Panicforever) and
MadMansGun (Horny Creatures of Skyrim). All animation work is theirs.

Requires Werewolf and Vampire Lord OStim v0.3.1 exactly. Install 0.3.1
first, run its installer, then install this patch after (below) it in Mod
Organizer 2. In this patch's FOMOD, tick the same animation packs, animators
and male-partner option you chose for 0.3.1. If 0.3.1 is already installed
and enabled, the installer tries to pre-tick what it finds; check those ticks
before you continue. Restart the game after installing. You do not need to
run Pandora or Nemesis.

This supersedes WVL 0.3.1 Icon Patch 0.1. If you have 0.1 installed, remove
it and use this instead. 0.1 was a flat set of scene files and could add
scenes for 0.3.1 modules you never installed (for example FlufyFox), which
led to OStim warnings about missing navigation targets. 0.2 ships a FOMOD
that matches 0.3.1's modules, so a patched scene is only installed when that
module is selected.

What it does
------------
1. Icons. 0.3.1 ships no icons of its own and reuses shared OCreatures and
   OStim icons. This patch adds icons under:

     interface/OStim/icons/WVLIcons/

   and, for the modules you tick, copies of those 0.3.1 scene files with
   only the navigation icon fields pointed at the new paths. Shared
   OCreatures and OStim icon files are not overwritten. OStim's return,
   next and climax icons are left untouched.

2. Human-first Female Werewolf scenes. OStim (and OStimNet) put the male
   partner first when it builds a cast, but 0.3.1's Female Werewolf sex
   scenes are all [female werewolf, human male]. Starting a scene as a man
   with a female werewolf then fails with "no valid animations" / "no
   starting animation found".

   For each Female Werewolf module you tick, this patch adds a second copy
   of that module's scenes with new ids (WVLP_...MH), the two actors swapped
   ([human male, female werewolf]), and OStim's animationIndex set so each
   actor still plays the original animation event already registered by
   0.3.1 (the event name is the speed animation plus "_" plus that index:
   WVL_..._S1_0 on the werewolf, WVL_..._S1_1 on the human). Tags, actions
   (with actor, target and performer indices swapped), speeds and the same
   random-start eligibility as the originals are kept. Navigations stay
   inside the new copies.

   A human-first idle (WVLP_WerewolfIdleMH) and hub (WVLP_FWWWerewolfHubMH)
   are included in each Female Werewolf module you tick, so the menu works
   without depending on a particular OCreatures Reforged version or on any
   other animation pack. The idle uses a stage-1 animation from that
   module (HCOS: standing embrace; MNC: missionary) so the animation
   already exists if that module is installed. Tick both MNC and HCOS if
   you installed both; the hub then lists every series you have.

The original 0.3.1 scene files are not removed. Female-werewolf-first
scenes stay in place for casts that still use that order.
