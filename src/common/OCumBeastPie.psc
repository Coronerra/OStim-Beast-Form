Scriptname OCumBeastPie extends Quest
{OCum Beast Pie + Beast Load - That Guy (Coronerra).
1) Beast Pie (0.1): keeps the Tull/Liquid pie through a partner's beast form.
2) Beast Load (0.5): when a male werewolf, werebear or Vampire Lord climaxes in any OStim scene (player or NPC-only), OCum's own
   handler still runs, and this adds the cum OCum skips for creature scenes (their metadata only says
   vaginalsex/analsex/blowjob, so footjobs, handjobs and "aircum" scenes get nothing, and vaginal/anal
   overlays and meshes are off by default in OCum). Decals go through OCum's own functions, so OCum's
   cleanup timer and bathing still clear them. Tull/Liquid meshes are worn as long as OCum's decals last.
0.8.1: cum on the face only for oral/facial finishes and outside sprays, never for an internal (vaginal/anal) finish.
No OCumMaleScript.pex replacement, no new records.}

Race WerewolfRace
Race WerebearRace
Race VampireLordRace

; ---- Beast Load settings (new in 0.5; defaults apply to existing saves) ----
bool Property BeastLoadEnabled = true Auto Hidden
bool Property HugeLoad = true Auto Hidden          ; "Big loads" (1.0: werewolves & werebears only): max layers on every area + full mesh set + refill
bool Property BeastMeshes = true Auto Hidden       ; Tull/Liquid meshes even when OCum's meshes are off
bool Property ExtraCumShot = true Auto Hidden      ; OCum cum-shot spurts for footjob/handjob/aircum scenes
bool Property StackRounds = true Auto Hidden       ; each climax in the same session adds layers + meshes
int Property MaxRounds = 5 Auto Hidden             ; rounds after which coverage stops growing

OCumMaleScript OCumMale
OCumScript OCumMain
Keyword AppliedCumKeyword
Faction ChestStage
Faction ChestSlot
Faction ButtStage
Faction ButtSlot
Faction BellyStage
Faction BellySlot

Event OnInit()
	Setup()
EndEvent

Function Setup()
	WerewolfRace = Game.GetFormFromFile(0x000CDD84, "Skyrim.esm") As Race
	WerebearRace = Game.GetFormFromFile(0x0001E17B, "Dragonborn.esm") As Race
	VampireLordRace = Game.GetFormFromFile(0x0000283A, "Dawnguard.esm") As Race
	OCumMale = Game.GetFormFromFile(0x00000F38, "OCum.esp") As OCumMaleScript
	OCumMain = Game.GetFormFromFile(0x00000800, "OCum.esp") As OCumScript
	AppliedCumKeyword = Game.GetFormFromFile(0x00000F16, "OCum.esp") As Keyword
	ChestStage = Game.GetFormFromFile(0x00000F3C, "OCum.esp") As Faction
	ChestSlot = Game.GetFormFromFile(0x00000F3D, "OCum.esp") As Faction
	ButtStage = Game.GetFormFromFile(0x00000F3E, "OCum.esp") As Faction
	ButtSlot = Game.GetFormFromFile(0x00000F3F, "OCum.esp") As Faction
	BellyStage = Game.GetFormFromFile(0x00000F40, "OCum.esp") As Faction
	BellySlot = Game.GetFormFromFile(0x00000F41, "OCum.esp") As Faction
	UnregisterForAllModEvents()
	RegisterForModEvent("ocumtl_pie", "OnPie")
	RegisterForModEvent("ostim_actor_orgasm", "OnBeastOrgasm")
	RegisterForModEvent("obf_beastload_mesh", "OnBeastLoadMesh")
	; 1.0.1: one line per game load for OStimBeastForm.log
	OBF_Log.Line("OBF BeastLoad", "setup: OCum " + OBF_Log.YesNo(OCumMale && OCumMain) + " | Beast Load " + OBF_Log.YesNo(BeastLoadEnabled) + " | big loads " + OBF_Log.YesNo(HugeLoad) + " | beast meshes " + OBF_Log.YesNo(BeastMeshes) + " | extra cum shot " + OBF_Log.YesNo(ExtraCumShot) + " | stack rounds " + OBF_Log.YesNo(StackRounds) + " (max " + MaxRounds + ")")
EndFunction

bool Function BigLoadBeast(Actor act)
	; 1.0: werewolves and werebears get Big Loads, Vampire Lords don't
	Race r = act.GetRace()
	return r && (r == WerewolfRace || r == WerebearRace)
EndFunction

bool Function IsBeast(Actor act)
	Race r = act.GetRace()
	return r && (r == WerewolfRace || r == WerebearRace || r == VampireLordRace)
EndFunction

float Function PieSeconds()
	return 60.0
EndFunction

float Function HoldSeconds()
	return 1800.0 ; 1.0.4: overall cap for holding the pie through a beast form (30 min script time)
EndFunction

int Function HoldUnloadChecks()
	return 20 ; 1.0.4: 20 checks x 3 s = 60 s with the partner's 3D unloaded
EndFunction

; ======================= 1) Beast Pie (unchanged from 0.1) =======================

Event OnPie(string eventName, string strArg, float numArg, Form sender)
	Actor act = sender As Actor
	if !act
		return
	endif

	int kind = numArg As int
	string key = "OCumBP_Stamp" + kind
	int stamp = StorageUtil.GetIntValue(act, key, 0) + 1
	StorageUtil.SetIntValue(act, key, stamp)

	float waited = 0.0
	bool beast = IsBeast(act)
	while !beast && waited < PieSeconds()
		Utility.Wait(2.0)
		waited += 2.0
		if StorageUtil.GetIntValue(act, key, 0) != stamp
			return
		endif
		beast = IsBeast(act)
	endwhile

	if !beast
		return
	endif

	OBF_Log.Line("OCumBeastPie", "kind " + kind + ": " + act.GetDisplayName() + " is in beast form, holding the pie")

	; 1.0.4: the hold has exits. Stamp/dead/deleted as before, plus: 3D unloaded for ~60 s (partner left in
	; another cell), or an overall cap, so this event can never wait forever.
	float held = 0.0
	int unloaded = 0
	while IsBeast(act) || !act.Is3DLoaded()
		Utility.Wait(3.0)
		held += 3.0
		if StorageUtil.GetIntValue(act, key, 0) != stamp || act.IsDead() || act.IsDeleted()
			return
		endif
		if act.Is3DLoaded()
			unloaded = 0
		else
			unloaded += 1
			if unloaded >= HoldUnloadChecks()
				OBF_Log.Line("OCumBeastPie", "kind " + kind + ": " + act.GetDisplayName() + " stayed unloaded for " + (unloaded * 3) + " s, pie hold given up")
				return
			endif
		endif
		if held >= HoldSeconds()
			OBF_Log.Line("OCumBeastPie", "kind " + kind + ": " + act.GetDisplayName() + " still in beast form after " + held + " s, pie hold given up")
			return
		endif
	endwhile

	Utility.Wait(2.0)
	if StorageUtil.GetIntValue(act, key, 0) != stamp
		return
	endif

	if !NiOverride.HasOverlays(act)
		NiOverride.AddOverlays(act)
		Utility.Wait(0.1)
	endif
	NiOverride.ApplyNodeOverrides(act)

	OBF_Log.Line("OCumBeastPie", "kind " + kind + ": " + act.GetDisplayName() + " reverted, pie restarted for 60 s")
	act.SendModEvent("ocumtl_pie", "", kind As float)
EndEvent

; ======================= 2) Beast Load =======================
; finish bits: 1 vaginal/anal pie, 2 oral/face, 4 body glaze, 8 no face (0.8.1); ItemMask() turns them (+ round) into item bits

Event OnBeastOrgasm(string eventName, string strArg, float numArg, Form sender)
	; cheap exit for every non-beast orgasm (keeps the VM light)
	Actor orgasmer = sender As Actor
	if !orgasmer || !IsBeast(orgasmer)
		return
	endif
	if !BeastLoadEnabled || !OCumMale || !OCumMain
		OBF_Log.Line("OBF BeastLoad", OBF_Log.Who(orgasmer) + " climax: no load (Beast Load off in the MCM, or OCum not found)")
		return
	endif
	if !OBF_Detect.Ours("load")
		; 1.1.0: another system owns the beast climax load (OCreatures Reforged or a claim) - no double marks
		OBF_Log.Line("OBF BeastLoad", OBF_Log.Who(orgasmer) + " climax: Beast Load stands down (" + OBF_Detect.OwnerText("load") + ")")
		return
	endif

	if orgasmer.GetLeveledActorBase().GetSex() != 0
		OBF_Log.Line("OBF BeastLoad", OBF_Log.Who(orgasmer) + " climax: female beast, no load")
		return ; female beasts (WWF) don't cum on anyone
	endif

	; every thread, also NPC-only scenes (independent of OCum's NPC scene option)
	int tid = numArg As int

	string sid = strArg
	if sid == ""
		sid = OThread.GetScene(tid)
	endif
	int pos = OThread.GetActorPosition(tid, orgasmer)

	; creature packs tag their scenes better than they fill in actions, so read both
	; 0.8.1: in blowjob/deepthroating/penilelicking the beast is the action's target (the actor is the mouth)
	bool oral = OMetadata.HasAnySceneTagCSV(sid, "blowjob,oral,cuminmouth,facefuck,facial,facecum,deepthroat") || OMetadata.FindAnyActionForTargetCSV(sid, pos, "blowjob,deepthroating,penilelicking") != -1 || OMetadata.FindAnyActionForActorCSV(sid, pos, "rubbingpenisagainstface,facial") != -1 || OMetadata.FindAnyActionCSV(sid, "blowjob,deepthroating") != -1
	bool anal = OMetadata.HasAnySceneTagCSV(sid, "anal,analcreampie") || OMetadata.FindAnyActionForActorCSV(sid, pos, "analsex") != -1
	bool vag = OMetadata.HasAnySceneTagCSV(sid, "vaginal,creampie,knotted") || OMetadata.FindAnyActionForActorCSV(sid, pos, "vaginalsex,wwfvaginalsex") != -1
	bool foot = OMetadata.HasSceneTag(sid, "footjob") || OMetadata.FindAnyActionCSV(sid, "footjob") != -1
	bool hand = OMetadata.HasAnySceneTagCSV(sid, "handjob,masturbation") || OMetadata.FindAnyActionCSV(sid, "handjob,malemasturbation") != -1
	bool outside = foot || hand || OMetadata.HasAnySceneTagCSV(sid, "aircum,cumonbody,chestcum,boobjob,titjob,wastedcum,cumshot,pullout")

	; a scene tagged footjob/aircum that only lists vaginalsex is really an outside finish
	if outside && !OMetadata.HasAnySceneTagCSV(sid, "creampie,knotted,analcreampie")
		vag = false
		anal = false
	endif
	bool guessed = false
	if !oral && !anal && !vag && !outside
		outside = true ; unknown metadata ("default", none, lickingvagina): treat as a finish on her body
		guessed = true ; ...but not on her face (0.8.1)
	endif

	OBF_Log.Line("OBF BeastLoad", "" + orgasmer.GetDisplayName() + " climax, thread " + tid + ", scene " + sid + ", oral " + oral + " vaginal " + vag + " anal " + anal + " outside " + outside)

	; 1.0: Big Loads are for werewolves and werebears only (Vampire Lords get the normal load)
	bool big = HugeLoad && BigLoadBeast(orgasmer)
	OBF_Log.Line("OBF BeastLoad", "load: big " + big + ", beast meshes " + BeastMeshes + ", stack rounds " + StackRounds + ", thread " + tid)
	int intensity = 3
	int layers = 1
	if big
		intensity = 4
		layers = 3
	endif

	Utility.Wait(1.0) ; let OCum's own handler pick its overlay slots first (no double-booked slots)
	Actor[] acts = OThread.GetActors(tid)
	int i = acts.Length
	while i > 0
		i -= 1
		Actor t = acts[i]
		if t && t != orgasmer && !IsBeast(t)
			PrepTarget(t)
			bool face = FaceFinish(sid, pos, OThread.GetActorPosition(tid, t), oral, vag, anal, outside, guessed)
			GlazeActorFace2(orgasmer, t, tid, sid, intensity, layers, oral, vag, anal, foot, hand, outside, face, big)
		endif
	endwhile

	if ExtraCumShot && tid == 0 && outside && !OCumMain.disableCumShot
		; OCum skips its spurts when the scene lists vaginalsex/blowjob; an empty scene id bypasses that check
		orgasmer.SendModEvent("ocum_play_cum_shoot_effect", "", 1.0)
		if big
			orgasmer.SendModEvent("ocum_play_cum_shoot_effect", "", 1.0)
		endif
	endif

	if big
		; beasts don't run dry: top the store back up after OCum has drained it
		Utility.Wait(3.0)
		float mx = OCumMain.GetMaxCumStoragePossible(orgasmer)
		OCumMain.AdjustStoredCumAmount(orgasmer, mx, 0.0)
	endif
EndEvent

Function PrepTarget(Actor t)
	; NPC-only threads: OCum may not have prepared her (its NPC scene option is off by default)
	if !NiOverride.HasOverlays(t)
		NiOverride.AddOverlays(t)
	endif
	; multi-round stacking: a session ends when she is clean, or OCum's timer has passed since the last round
	float now = Utility.GetCurrentRealTime()
	float last = StorageUtil.GetFloatValue(t, "OBF_BL_Last", -1.0)
	bool clean = AppliedCumKeyword && !OCumMain.disableCumDecal && !t.HasMagicEffectWithKeyword(AppliedCumKeyword)
	if clean || last < 0.0 || now < last || now - last > OCumMain.cumCleanupTimer * 60.0 + 30.0
		StorageUtil.SetIntValue(t, "OBF_BL_Round", 0)
		StorageUtil.UnsetIntValue(t, "OBF_BL_Set") ; new session: start the mesh set fresh
	endif
	StorageUtil.SetFloatValue(t, "OBF_BL_Last", now)
	; OCum's own cleanup timer is left alone (re-casting its spell can make OCumEffect loop while in a scene)
	if ChestStage && clean
		; clean body: restart OCum's layer stages so belly/chest/butt climb again (NPC threads never reset them)
		t.SetFactionRank(ChestStage, 0)
		t.SetFactionRank(ButtStage, 0)
		t.SetFactionRank(BellyStage, 0)
		t.SetFactionRank(ChestSlot, -1)
		t.SetFactionRank(ButtSlot, -1)
		t.SetFactionRank(BellySlot, -1)
	endif
EndFunction

; ---- 0.8.1: face only for oral/facial finishes and outside sprays, never for an internal finish ----
bool Function FaceFinish(string sid, int pos, int tp, bool oral, bool vag, bool anal, bool outside, bool guessed)
	; actions are per stage, so this reads the climax stage. An internal finish always wins: some converted
	; gangbangs list him inside her and in her mouth at once.
	if pos >= 0 && OMetadata.FindAnyActionForActorCSV(sid, pos, "vaginalsex,wwfvaginalsex,analsex") != -1
		return false ; he is inside her (or another partner): the body spill-over stays, the face stays clean
	endif
	if tp >= 0 && pos >= 0
		if OMetadata.FindAnyActionForActorAndTargetCSV(sid, tp, pos, "blowjob,deepthroating,penilelicking,handjob,footjob,boobjob") != -1 || OMetadata.FindAnyActionForActorAndTargetCSV(sid, pos, tp, "facial,rubbingpenisagainstface") != -1
			return true ; her mouth, face, hands, feet or breasts are on him: oral finish or outside spray
		endif
	endif
	if pos >= 0 && (OMetadata.FindAnyActionForActorCSV(sid, pos, "facial,rubbingpenisagainstface") != -1 || OMetadata.FindAnyActionForTargetCSV(sid, pos, "blowjob,deepthroating,penilelicking") != -1)
		return false ; another partner's face takes it
	endif
	; no action ties him to anyone: the scene's tags decide, an internal tag wins over an oral one
	if vag || anal
		return false
	endif
	if oral
		return true
	endif
	return outside && !guessed
EndFunction

; kept for callers compiled against 0.8 and earlier
Function GlazeActor(Actor orgasmer, Actor t, int tid, string sid, int intensity, int layers, bool oral, bool vag, bool anal, bool foot, bool hand, bool outside)
	GlazeActorFace(orgasmer, t, tid, sid, intensity, layers, oral, vag, anal, foot, hand, outside, !vag && !anal && (oral || outside))
EndFunction

Function GlazeActorFace(Actor orgasmer, Actor t, int tid, string sid, int intensity, int layers, bool oral, bool vag, bool anal, bool foot, bool hand, bool outside, bool face)
	; kept with its 0.8.1 signature for the Herm download, which calls it
	GlazeActorFace2(orgasmer, t, tid, sid, intensity, layers, oral, vag, anal, foot, hand, outside, face, HugeLoad && BigLoadBeast(orgasmer))
EndFunction

Function GlazeActorFace2(Actor orgasmer, Actor t, int tid, string sid, int intensity, int layers, bool oral, bool vag, bool anal, bool foot, bool hand, bool outside, bool face, bool big)
	if oral && !face
		; tagged oral but not on her face (he is inside her or someone else): body only
		oral = false
		outside = true
	endif
	int meshSet = 0
	if !face
		meshSet = 8 ; no face meshes (see ItemMask)
	endif
	int n = 0
	int rnd = 1
	if StackRounds
		rnd = StorageUtil.GetIntValue(t, "OBF_BL_Round", 0) + 1
		if rnd > MaxRounds
			rnd = MaxRounds
		endif
		StorageUtil.SetIntValue(t, "OBF_BL_Round", rnd)
	endif
	; every extra round adds a layer per region (OCum's stage textures cap themselves at their heaviest)
	layers = layers + rnd - 1
	if layers > 6
		layers = 6
	endif
	int heavy = 3 + rnd
	if heavy > 6
		heavy = 6
	endif

	if vag
		OCumMale.SendCumAppliedEvents(tid, orgasmer, t, 30.0, "vagina", sid)
		OCumMale.CumOntoArea(t, "VaginalCreampie" + Utility.RandomInt(heavy - 2, heavy), "Body") ; OCum only does this when its vag/anal overlay option is on
		OCumMale.ApplyCumThighs(t, -1)
		meshSet = Math.LogicalOr(meshSet, 1)
	endif
	if anal
		OCumMale.SendCumAppliedEvents(tid, orgasmer, t, 30.0, "rectum", sid)
		if rnd > 1
			OCumMale.CumOntoArea(t, "Anal" + Utility.RandomInt(3, 4), "Body")
		endif
		OCumMale.CumOntoArea(t, "Anal" + Utility.RandomInt(3, 4), "Body")
		meshSet = Math.LogicalOr(meshSet, 1)
	endif
	if oral
		; Design: a beast does not get swallowed - face, mouth, neck and chest, dripping
		OCumMale.SendCumAppliedEvents(tid, orgasmer, t, 30.0, "face", sid)
		n = 0
		while n < layers
			OCumMale.ApplyCumFacial(t, 4, -1)
			OCumMale.ApplyCumBoob(t, intensity, -1)
			n += 1
		endwhile
		OCumMale.ApplyCumMouth(t, 4, -1)
		if rnd > 1
			OCumMale.ApplyCumMouth(t, 4, -1)
		endif
		OCumMale.CumOntoArea(t, "BreastFace" + Utility.RandomInt(1, 2), "Face")
		meshSet = Math.LogicalOr(meshSet, 2)
	endif
	if outside
		OCumMale.SendCumAppliedEvents(tid, orgasmer, t, 30.0, "chest", sid)
		if foot
			OCumMale.ApplyCumFeet(t, 4, -1)
		endif
		if hand
			OCumMale.ApplyCumHands(t, -1)
		endif
		n = 0
		while n < layers
			OCumMale.ApplyCumBelly(t, intensity, -1)
			OCumMale.ApplyCumBoob(t, intensity, -1)
			n += 1
		endwhile
		OCumMale.ApplyCumThighs(t, -1)
		if big && face
			OCumMale.ApplyCumFacial(t, 4, -1) ; full-body spray reaches the face; never on internal finishes
		endif
		meshSet = Math.LogicalOr(meshSet, 4)
	endif

	if big
		; a beast-sized load runs everywhere: belly, chest and butt stages climb toward OCum's heaviest textures
		n = 0
		while n < layers
			OCumMale.ApplyCumBelly(t, 4, -1)
			OCumMale.ApplyCumButt(t, 4, -1)
			n += 1
		endwhile
		meshSet = Math.LogicalOr(meshSet, 4)
	endif

	if BeastMeshes && t.GetLeveledActorBase().GetSex() == 1
		t.SendModEvent("obf_beastload_mesh", "", ItemMask(meshSet, rnd, big) As float)
	endif
EndFunction

; ---- meshes: own loop per actor (mod event = own thread), lives as long as OCum's decals ----

Form[] Function MeshItems()
	; looked up once per climax. No two share a slot: Tull 0x807 and 0x803 are both slot 59, so only one is used.
	Form[] f = new Form[8]
	if Game.IsPluginInstalled("TullAnimatedCreampie.esp")
		f[0] = Game.GetFormFromFile(0x807, "TullAnimatedCreampie.esp")        ; 59 creampie
		f[1] = Game.GetFormFromFile(0x809, "TullAnimatedCreampie.esp")        ; 60 creampie drip
		f[4] = Game.GetFormFromFile(0x803, "TullAnimatedCreampie.esp")        ; 59 oral (only without 0x807)
	endif
	if Game.IsPluginInstalled("[Predator] Liquid Pack v2.esp")
		f[2] = Game.GetFormFromFile(0x803, "[Predator] Liquid Pack v2.esp")   ; 47 bottom
		f[3] = Game.GetFormFromFile(0x808, "[Predator] Liquid Pack v2.esp")   ; 43 bottom SMP
		f[5] = Game.GetFormFromFile(0x804, "[Predator] Liquid Pack v2.esp")   ; 55 face
		f[6] = Game.GetFormFromFile(0x809, "[Predator] Liquid Pack v2.esp")   ; 57 face SMP
		f[7] = Game.GetFormFromFile(0xD63, "[Predator] Liquid Pack v2.esp")   ; 36 torso
	endif
	return f
EndFunction

int Function ItemMask(int meshSet, int rnd, bool big)
	; item bits (see MeshItems): 0 Tull807/59  1 Tull809/60  2 LP803/47  3 LP808/43  4 Tull803/59  5 LP804/55  6 LP809/57  7 LPD63/36
	bool pie = Math.LogicalAnd(meshSet, 1) != 0
	bool face = Math.LogicalAnd(meshSet, 2) != 0
	bool body = Math.LogicalAnd(meshSet, 4) != 0
	bool noFace = Math.LogicalAnd(meshSet, 8) != 0 ; 0.8.1: internal finish, keep the face clean
	int m = 0
	if pie
		m = Math.LogicalOr(m, 7)          ; 0,1,2
		if big
			m = Math.LogicalOr(m, 8)      ; 3
		endif
	endif
	if face
		m = Math.LogicalOr(m, 96)         ; 5,6
		if !pie
			m = Math.LogicalOr(m, 16)     ; 4 (slot 59 only when the creampie item is not used)
		endif
		if big
			m = Math.LogicalOr(m, 128)    ; 7
		endif
	endif
	if body
		m = Math.LogicalOr(m, 132)        ; 2,7
		if big
			m = Math.LogicalOr(m, 32)     ; 5
		endif
	endif
	; stacking: each round after the first adds two more items in this order of least-contested slots
	; 60 (misc), 47, 55, 57, 36, 43; then whichever slot-59 item fits
	int extra = (rnd - 1) * 2
	int k = 0
	while extra > 0 && k < 7
		int bit = 0
		if k == 0
			bit = 2
		elseif k == 1
			bit = 4
		elseif k == 2
			bit = 32
		elseif k == 3
			bit = 64
		elseif k == 4
			bit = 128
		elseif k == 5
			bit = 8
		elseif Math.LogicalAnd(m, 17) == 0
			bit = 1
		endif
		if noFace && (bit == 32 || bit == 64)
			bit = 0
		endif
		if bit && Math.LogicalAnd(m, bit) == 0
			m = Math.LogicalOr(m, bit)
			extra -= 1
		endif
		k += 1
	endwhile
	if noFace
		m = Math.LogicalAnd(m, 143) ; drop face items 4,5,6 (Tull oral, Liquid face, Liquid face SMP)
	endif
	return m
EndFunction

bool Function MeshWanted(int idx, int mask)
	if idx == 4 && Math.LogicalAnd(mask, 1) != 0
		return false ; slot 59 is taken by the creampie item
	endif
	return Math.LogicalAnd(mask, Math.LeftShift(1, idx)) != 0
EndFunction

Event OnBeastLoadMesh(string eventName, string strArg, float numArg, Form sender)
	Actor act = sender As Actor
	if !act
		return
	endif
	if !Game.IsPluginInstalled("TullAnimatedCreampie.esp") && !Game.IsPluginInstalled("[Predator] Liquid Pack v2.esp")
		return ; neither mesh mod installed: decals only, no log spam
	endif

	; merge with a set that is already running on her, and take over from older loops
	int meshSet = Math.LogicalOr(StorageUtil.GetIntValue(act, "OBF_BL_Set", 0), numArg As int)
	StorageUtil.SetIntValue(act, "OBF_BL_Set", meshSet)
	int stamp = StorageUtil.GetIntValue(act, "OBF_BL_Stamp", 0) + 1
	StorageUtil.SetIntValue(act, "OBF_BL_Stamp", stamp)

	Form[] items = MeshItems()
	Utility.Wait(1.0) ; let OCum/OCumTL finish their own equips first
	float cap = 600.0
	if OCumMain.cumCleanupTimer > 0.0
		cap = OCumMain.cumCleanupTimer * 60.0 + 30.0
	endif
	float waited = 0.0
	float afterScene = 0.0
	bool alive = true
	bool followDecals = AppliedCumKeyword && !OCumMain.disableCumDecal

	while alive
		if StorageUtil.GetIntValue(act, "OBF_BL_Stamp", 0) != stamp
			return ; a newer climax on her owns the meshes now
		endif
		; stop OCumTL's own 60 s removal (and its slot-59 fight) while we hold the set
		StorageUtil.AdjustIntValue(act, "OCumTL_Stamp0", 1)
		StorageUtil.AdjustIntValue(act, "OCumTL_Stamp1", 1)

		bool inScene = OActor.IsInOStim(act)
		; re-equip during the scene (OStim strips at scene changes); after it only while she is naked,
		; so her own armor is never fought over
		if inScene || !act.GetWornForm(0x00000004)
			EquipSet(act, meshSet, items)
		endif

		float step = 2.0
		if !inScene && afterScene >= 10.0
			step = 10.0
		endif
		Utility.Wait(step)
		waited += step
		if !inScene
			afterScene += step
		endif

		if act.IsDead() || act.IsDeleted()
			alive = false
		elseif !inScene && afterScene > 4.0 && followDecals && !act.HasMagicEffectWithKeyword(AppliedCumKeyword)
			alive = false ; OCum's decals are gone (timer ran out or she bathed)
		elseif !inScene && !followDecals && act.IsSwimming()
			alive = false ; OCum decals are off: the meshes still wash off in water
		elseif !inScene && afterScene > cap
			alive = false
		endif
	endwhile

	if StorageUtil.GetIntValue(act, "OBF_BL_Stamp", 0) != stamp
		return
	endif
	int i = 0
	while i < 8
		Form it = items[i]
		if it
			act.UnequipItem(it, false, true)
			act.RemoveItem(it, 99, true, None)
		endif
		i += 1
	endwhile
	StorageUtil.UnsetIntValue(act, "OBF_BL_Set")
	StorageUtil.UnsetIntValue(act, "OBF_BL_Round")
	OBF_Log.Line("OBF BeastLoad", "meshes removed from " + act.GetDisplayName())
EndEvent

Function EquipSet(Actor act, int meshSet, Form[] items)
	int i = 0
	while i < 8
		if MeshWanted(i, meshSet)
			Form it = items[i]
			if it && !act.IsEquipped(it)
				act.EquipItem(it, false, true)
			endif
		endif
		i += 1
	endwhile
EndFunction
