Scriptname OBL_Main extends Quest
{OStim Beast Lite - optional male-only aroused body swap for werewolves, vampire lords and (Growl core) werebears.
Event-driven: ostim_thread_start / ostim_thread_end / player load. No polling.
MiscUtil.FileExists is a real PapyrusUtil SE API (verified against Papyrus Index).}

Armor Property OBL_WerewolfAddon Auto
Armor Property OBL_VampireLordAroused Auto
Race Property WerewolfBeastRace Auto
Race Property DLC1VampireBeastRace Auto
GlobalVariable Property OBL_SwapEnabled Auto
GlobalVariable Property OBL_OCreaturesPresent Auto

; Paths relative to Skyrim root (where SkyrimSE.exe lives), as required by MiscUtil.FileExists.
String Property WerewolfMesh = "Data/Meshes/MoreNastyCritters/werewolf/Addon_Dog_Black_Hard.nif" Auto
String Property VampireLordMesh = "Data/Meshes/MoreNastyCritters/vampirelord/vampirelord_Hard.nif" Auto

Actor[] Swapped
Armor[] SwappedItem
Armor[] PriorSkin ; what to put back for whole-skin (vampire lord) swaps; None for addon-only
Bool HaveWerewolfMesh
Bool HaveVampireMesh
; 1.0 (Growl core only): werebear aroused skin for players without OCR, same file OCR uses
Armor WerebearAroused
Race WerebearBeastRace
String WerebearMesh = "Data/Meshes/MoreNastyCritters/werebear/werebearHard.nif"
Bool HaveWerebearMesh

Event OnInit()
	Setup()
EndEvent

Function Setup()
	if Swapped.Length == 0
		Swapped = new Actor[16]
		SwappedItem = new Armor[16]
		PriorSkin = new Armor[16]
	endif
	RestoreAll()
	UnregisterForAllModEvents()
	if Game.GetModByName("OCreatures.esp") != 255
		; OCR or Revived present — they own the aroused swap. Step aside.
		OBL_OCreaturesPresent.SetValue(1)
		OBF_Log.Line("OBF Lite", "setup: OCreatures found, it handles the aroused bodies (this swap stands down)")
		return
	endif
	OBL_OCreaturesPresent.SetValue(0)
	if OBL_SwapEnabled.GetValue() < 1
		OBF_Log.Line("OBF Lite", "setup: no OCreatures, aroused body swap is off in the MCM")
		return
	endif
	; 0.7: the werewolf aroused mesh is whatever OBL_WerewolfAddonAA points at in the loaded plugin
	; (GT Softbody or TWO's own hard canine, picked in the installer). Read it from the record so
	; saves that stored an older WerewolfMesh value keep working after the softbody choice changes.
	WerewolfMesh = AddonMeshPath(OBL_WerewolfAddon, WerewolfMesh)
	; FileExists only sees loose files, not BSA contents. Missing mesh = skip that swap.
	HaveWerewolfMesh = MiscUtil.FileExists(WerewolfMesh)
	HaveVampireMesh = MiscUtil.FileExists(VampireLordMesh)
	HaveWerebearMesh = false
	WerebearAroused = None
	if Game.GetModByName("OStim_Beast_Form_Merged.esp") != 255
		WerebearAroused = Game.GetFormFromFile(0x83E, "OStim_Beast_Form_Merged.esp") as Armor
		WerebearBeastRace = Game.GetFormFromFile(0x0001E17B, "Dragonborn.esm") as Race
		if WerebearAroused && WerebearBeastRace
			WerebearMesh = AddonMeshPath(WerebearAroused, WerebearMesh)
			HaveWerebearMesh = MiscUtil.FileExists(WerebearMesh)
		endif
	endif
	OBF_Log.Line("OBF Lite", "setup: no OCreatures, aroused body swap on | werewolf mesh " + OBF_Log.YesNo(HaveWerewolfMesh) + " (" + WerewolfMesh + ") | vampire lord mesh " + OBF_Log.YesNo(HaveVampireMesh) + " (" + VampireLordMesh + ") | werebear mesh " + OBF_Log.YesNo(HaveWerebearMesh) + " (loose files only; a missing mesh skips that swap)")
	if HaveWerewolfMesh || HaveVampireMesh || HaveWerebearMesh
		RegisterForModEvent("ostim_thread_start", "OnThreadStart")
		RegisterForModEvent("ostim_thread_end", "OnThreadEnd")
	endif
EndFunction

; Path of the item's first armor addon (male, third person), as "Data/Meshes/...". Fallback if none.
String Function AddonMeshPath(Armor item, String fallback)
	if item
		ArmorAddon aa = item.GetNthArmorAddon(0)
		if aa
			String p = aa.GetModelPath(false, false)
			if p != ""
				return "Data/Meshes/" + p
			endif
		endif
	endif
	return fallback
EndFunction

Event OnThreadStart(string EventName, string StrArg, float ThreadID, Form Sender)
	Actor[] acts = OThread.GetActors(ThreadID as int)
	if !acts
		return
	endif
	int i = 0
	while i < acts.Length
		Actor a = acts[i]
		ActorBase ab = None
		if a
			ab = a.GetLeveledActorBase() ; 1.0.4: leveled NPCs report the right sex
		endif
		if ab && ab.GetSex() == 0
			Race r = a.GetRace()
			if r == WerewolfBeastRace && HaveWerewolfMesh
				EquipAddon(a, OBL_WerewolfAddon)
			elseif r == DLC1VampireBeastRace && HaveVampireMesh
				EquipSkin(a, OBL_VampireLordAroused)
			elseif HaveWerebearMesh && r == WerebearBeastRace
				EquipSkin(a, WerebearAroused)
			endif
		endif
		i += 1
	endwhile
EndEvent

Event OnThreadEnd(string EventName, string Json, float ThreadID, Form Sender)
	Actor[] acts = OJSON.GetActors(Json)
	if !acts
		return
	endif
	int i = 0
	while i < acts.Length
		int k = Swapped.Find(acts[i])
		if acts[i] && k >= 0
			Restore(k)
		endif
		i += 1
	endwhile
EndEvent

Function EquipAddon(Actor a, Armor item)
	int k = OpenSlot(a)
	if k < 0
		return
	endif
	Swapped[k] = a
	SwappedItem[k] = item
	PriorSkin[k] = None
	TryEquip(a, item)
EndFunction

Function EquipSkin(Actor a, Armor item)
	int k = OpenSlot(a)
	if k < 0
		return
	endif
	; Remember race skin so we can put it back. Whole-skin swap replaces worn body.
	Swapped[k] = a
	SwappedItem[k] = item
	PriorSkin[k] = a.GetRace().GetSkin()
	TryEquip(a, item)
EndFunction

int Function OpenSlot(Actor a)
	if Swapped.Find(a) >= 0
		return -1
	endif
	return Swapped.Find(None)
EndFunction

Function TryEquip(Actor a, Armor item)
	OBF_Log.Line("OBF Lite", "aroused body on " + OBF_Log.Who(a))
	if a.GetItemCount(item) == 0
		a.AddItem(item, 1, true)
	endif
	int tries = 0
	while tries < 3 && !a.IsEquipped(item)
		a.EquipItem(item, false, true)
		tries += 1
	endwhile
EndFunction

Function Restore(int k)
	Actor a = Swapped[k]
	Armor item = SwappedItem[k]
	Armor prior = PriorSkin[k]
	Swapped[k] = None
	SwappedItem[k] = None
	PriorSkin[k] = None
	if !a || !item
		return
	endif
	a.UnequipItem(item, false, true)
	int n = a.GetItemCount(item)
	if n > 0
		a.RemoveItem(item, n, true)
	endif
	if prior
		; Re-equip race skin after whole-skin swap. Bounded, not a poll.
		int tries = 0
		while tries < 3 && !a.IsEquipped(prior)
			a.EquipItem(prior, false, true)
			tries += 1
		endwhile
	endif
EndFunction

Function RestoreAll()
	int k = 0
	while k < Swapped.Length
		if Swapped[k]
			Restore(k)
		endif
		k += 1
	endwhile
EndFunction
