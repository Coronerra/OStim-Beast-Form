Scriptname OBFHerm_Main extends Quest
{OStim Beast Form Merged 0.7 - Hermaphrodite (Fruta) option, formerly TWO Herm Patch 0.1 - That Guy (Coronerra).
Soft-detects TWO Extras herm/urta and, when the player is a werewolf in that form,
applies this patch's condition so OStim uses the herm actor property (penis + vagina).
Also runs the aroused addon and Beast Load / cum shot path that the published plugins
skip for female-sex actors. Event-driven: no polling.}

Spell Property OBFHerm_ConditionAbility Auto
Race Property WerewolfBeastRace Auto

GlobalVariable HermVal
Spell ToggleSpell
MagicEffect ToggleEffect
Armor AddonArmor
String AddonMesh
GlobalVariable SwapEnabled
OCumBeastPie Pie
OCumScript OCumMain
Bool HaveExtras
Bool HaveSwap
Bool OcrPresent
Actor SwappedActor
Armor SwappedItem

Event OnInit()
	Setup()
EndEvent

Function Setup()
	RestoreSwap()
	UnregisterForAllModEvents()
	HaveExtras = false
	HaveSwap = false
	OcrPresent = false
	Pie = None
	OCumMain = None
	HermVal = None
	ToggleSpell = None
	ToggleEffect = None
	AddonArmor = None
	AddonMesh = ""
	SwapEnabled = None

	; Soft-detect only. WerewolvesExtras is not a master; if it is missing this quest still loads and does nothing.
	if Game.GetModByName("WerewolvesExtras.esp") == 255
		OBF_Log.Line("OBF Herm", "setup: TWO Extras (WerewolvesExtras.esp) not loaded - the herm patch does nothing")
		SyncCondition()
		return
	endif
	HermVal = Game.GetFormFromFile(0xC09, "WerewolvesExtras.esp") as GlobalVariable
	ToggleSpell = Game.GetFormFromFile(0xC0E, "WerewolvesExtras.esp") as Spell
	ToggleEffect = Game.GetFormFromFile(0xC0B, "WerewolvesExtras.esp") as MagicEffect
	if !HermVal
		OBF_Log.Line("OBF Herm", "setup: TWO Extras loaded but its herm global was not found - the herm patch does nothing")
		SyncCondition()
		return
	endif
	HaveExtras = true

	OcrPresent = Game.GetModByName("OCreatures.esp") != 255

	String bf = ""
	if Game.GetModByName("OStim_Beast_Form_Merged.esp") != 255
		bf = "OStim_Beast_Form_Merged.esp"
	elseif Game.GetModByName("OStim_Beast_Form_TWO.esp") != 255
		bf = "OStim_Beast_Form_TWO.esp"
	endif

	if bf != ""
		; FormIDs are the same in Merged 0.6 and TWO Edition 0.2; still resolved from the plugin that is actually loaded.
		AddonArmor = Game.GetFormFromFile(0x835, bf) as Armor
		SwapEnabled = Game.GetFormFromFile(0x831, bf) as GlobalVariable
		OBL_Main obl = Game.GetFormFromFile(0x837, bf) as OBL_Main
		; 0.7: read the mesh from the aroused item's armor addon, so the installer's softbody choice
		; (GT Softbody or TWO's hard canine) is followed. Older logic is the fallback.
		if AddonArmor
			ArmorAddon aa = AddonArmor.GetNthArmorAddon(0)
			if aa
				String p = aa.GetModelPath(false, false)
				if p != ""
					AddonMesh = "Data/Meshes/" + p
				endif
			endif
		endif
		if AddonMesh != ""
			; resolved from the record
		elseif obl && obl.WerewolfMesh != ""
			AddonMesh = obl.WerewolfMesh
		elseif bf == "OStim_Beast_Form_TWO.esp"
			AddonMesh = "Data/Meshes/actors/werewolfbeast/character assets/CreatureFramework/CanineRedHard.nif"
		else
			AddonMesh = "Data/Meshes/MoreNastyCritters/werewolf/Addon_Dog_Black_Hard.nif"
		endif
		Bool haveMesh = AddonArmor && AddonMesh != "" && MiscUtil.FileExists(AddonMesh)
		if AddonArmor && haveMesh && !OcrPresent
			if !SwapEnabled || SwapEnabled.GetValue() >= 1
				HaveSwap = true
			endif
		endif
		Pie = Game.GetFormFromFile(0x822, bf) as OCumBeastPie
	endif

	if Game.GetModByName("OCum.esp") != 255
		OCumMain = Game.GetFormFromFile(0x800, "OCum.esp") as OCumScript
	endif

	if HaveSwap
		RegisterForModEvent("ostim_thread_start", "OnThreadStart")
		RegisterForModEvent("ostim_thread_end", "OnThreadEnd")
	endif
	if Pie
		RegisterForModEvent("ostim_actor_orgasm", "OnBeastOrgasm")
	endif
	OBF_Log.Line("OBF Herm", "setup: TWO Extras yes | herm/urta toggle on " + OBF_Log.YesNo(IsHermValOn()) + " | Beast Form plugin " + bf + " | OCreatures " + OBF_Log.YesNo(OcrPresent) + " | aroused addon swap " + OBF_Log.YesNo(HaveSwap) + " (" + AddonMesh + ") | Beast Load " + OBF_Log.YesNo(Pie != None) + " | OCum " + OBF_Log.YesNo(OCumMain != None))

	SyncCondition()
EndFunction

bool Function IsHermValOn()
	if !HaveExtras || !HermVal
		return false
	endif
	int v = HermVal.GetValue() as int
	return v == 1 || v == 2
EndFunction

bool Function IsPlayerHermWerewolf(Actor a)
	if !a || a != Game.GetPlayer()
		return false
	endif
	if !IsHermValOn()
		return false
	endif
	Race r = a.GetRace()
	return r && r == WerewolfBeastRace
EndFunction

Function SyncCondition()
	Actor player = Game.GetPlayer()
	if !player || !OBFHerm_ConditionAbility
		return
	endif
	bool want = IsPlayerHermWerewolf(player)
	bool has = player.HasSpell(OBFHerm_ConditionAbility)
	if want && !has
		player.AddSpell(OBFHerm_ConditionAbility, false)
		OBF_Log.Line("OBF Herm", "herm werewolf condition ON (player is a herm / urta werewolf)")
	elseif !want && has
		player.RemoveSpell(OBFHerm_ConditionAbility)
		OBF_Log.Line("OBF Herm", "herm werewolf condition OFF")
	endif
	if !want
		RestoreSwap()
	endif
EndFunction

Function SyncConditionSoon()
	; TWO's toggle script writes TWO_PlayerHermVal in OnEffectStart. A short wait lets that land first.
	Utility.Wait(0.15)
	SyncCondition()
EndFunction

Function OnToggleMaybe(Form akForm)
	if !HaveExtras || !akForm
		return
	endif
	if (ToggleSpell && akForm == ToggleSpell) || (ToggleEffect && akForm == ToggleEffect)
		SyncConditionSoon()
	endif
EndFunction

Event OnThreadStart(string EventName, string StrArg, float ThreadID, Form Sender)
	if !HaveSwap || OcrPresent
		return
	endif
	Actor player = Game.GetPlayer()
	if !IsPlayerHermWerewolf(player)
		return
	endif
	if player.GetActorBase().GetSex() == 0
		return ; OBL_Main already equips male-sex werewolves
	endif
	Actor[] acts = OThread.GetActors(ThreadID as int)
	if !acts
		return
	endif
	int i = 0
	bool inThread = false
	while i < acts.Length
		if acts[i] == player
			inThread = true
			i = acts.Length
		else
			i += 1
		endif
	endwhile
	if inThread
		EquipAddon(player)
	endif
EndEvent

Event OnThreadEnd(string EventName, string Json, float ThreadID, Form Sender)
	RestoreSwap()
EndEvent

Function EquipAddon(Actor a)
	if !a || !AddonArmor || SwappedActor
		return
	endif
	SwappedActor = a
	SwappedItem = AddonArmor
	if a.GetItemCount(AddonArmor) == 0
		a.AddItem(AddonArmor, 1, true)
	endif
	int tries = 0
	while tries < 3 && !a.IsEquipped(AddonArmor)
		a.EquipItem(AddonArmor, false, true)
		tries += 1
	endwhile
EndFunction

Function RestoreSwap()
	Actor a = SwappedActor
	Armor item = SwappedItem
	SwappedActor = None
	SwappedItem = None
	if !a || !item
		return
	endif
	a.UnequipItem(item, false, true)
	int n = a.GetItemCount(item)
	if n > 0
		a.RemoveItem(item, n, true)
	endif
EndFunction

Event OnBeastOrgasm(string eventName, string strArg, float numArg, Form sender)
	; OCumBeastPie returns early when GetSex() != 0. Reuse its public functions for the player herm/urta only.
	Actor orgasmer = sender as Actor
	if !Pie || !Pie.BeastLoadEnabled || !orgasmer
		return
	endif
	if !IsPlayerHermWerewolf(orgasmer)
		return
	endif
	if orgasmer.GetLeveledActorBase().GetSex() == 0
		return ; already handled by OCumBeastPie
	endif
	if !Pie.IsBeast(orgasmer)
		return
	endif

	int tid = numArg as int
	string sid = strArg
	if sid == ""
		sid = OThread.GetScene(tid)
	endif
	int pos = OThread.GetActorPosition(tid, orgasmer)

	bool oral = OMetadata.HasAnySceneTagCSV(sid, "blowjob,oral,cuminmouth,facefuck,facial,facecum,deepthroat") || OMetadata.FindAnyActionForTargetCSV(sid, pos, "blowjob,deepthroating,penilelicking") != -1 || OMetadata.FindAnyActionForActorCSV(sid, pos, "rubbingpenisagainstface,facial") != -1 || OMetadata.FindAnyActionCSV(sid, "blowjob,deepthroating") != -1
	bool anal = OMetadata.HasAnySceneTagCSV(sid, "anal,analcreampie") || OMetadata.FindAnyActionForActorCSV(sid, pos, "analsex") != -1
	bool vag = OMetadata.HasAnySceneTagCSV(sid, "vaginal,creampie,knotted") || OMetadata.FindAnyActionForActorCSV(sid, pos, "vaginalsex,wwfvaginalsex") != -1
	bool foot = OMetadata.HasSceneTag(sid, "footjob") || OMetadata.FindAnyActionCSV(sid, "footjob") != -1
	bool hand = OMetadata.HasAnySceneTagCSV(sid, "handjob,masturbation") || OMetadata.FindAnyActionCSV(sid, "handjob,malemasturbation") != -1
	bool outside = foot || hand || OMetadata.HasAnySceneTagCSV(sid, "aircum,cumonbody,chestcum,boobjob,titjob,wastedcum,cumshot,pullout")

	if outside && !OMetadata.HasAnySceneTagCSV(sid, "creampie,knotted,analcreampie")
		vag = false
		anal = false
	endif
	bool guessed = false
	if !oral && !anal && !vag && !outside
		outside = true
		guessed = true
	endif

	OBF_Log.Line("OBF Herm", orgasmer.GetDisplayName() + " climax, thread " + tid + ", scene " + sid)

	int intensity = 3
	int layers = 1
	if Pie.HugeLoad
		intensity = 4
		layers = 3
	endif

	Utility.Wait(1.0)
	Actor[] acts = OThread.GetActors(tid)
	if acts
		int i = acts.Length
		while i > 0
			i -= 1
			Actor t = acts[i]
			if t && t != orgasmer && !Pie.IsBeast(t)
				Pie.PrepTarget(t)
				bool face = Pie.FaceFinish(sid, pos, OThread.GetActorPosition(tid, t), oral, vag, anal, outside, guessed)
				Pie.GlazeActorFace(orgasmer, t, tid, sid, intensity, layers, oral, vag, anal, foot, hand, outside, face)
			endif
		endwhile
	endif

	if Pie.ExtraCumShot && tid == 0 && outside && (!OCumMain || !OCumMain.disableCumShot)
		orgasmer.SendModEvent("ocum_play_cum_shoot_effect", "", 1.0)
		if Pie.HugeLoad
			orgasmer.SendModEvent("ocum_play_cum_shoot_effect", "", 1.0)
		endif
	endif

	if Pie.HugeLoad && OCumMain
		Utility.Wait(3.0)
		float mx = OCumMain.GetMaxCumStoragePossible(orgasmer)
		OCumMain.AdjustStoredCumAmount(orgasmer, mx, 0.0)
	endif
EndEvent
