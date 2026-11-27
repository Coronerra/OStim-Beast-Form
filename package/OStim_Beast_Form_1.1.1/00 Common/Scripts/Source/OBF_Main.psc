Scriptname OBF_Main extends Quest
{OStim Beast Form 1.1.1 (final release) - lets the player start OStim scenes in vanilla werewolf beast form and freezes the beast-form timer during scenes. By coronerra.
1.1.0 adds new Hidden properties and global helper scripts only (OBF_Detect, OBF_Hooks, OBF_Size, OBF_Combat, OBF_BodyCheck, OBF_Gesture); every 1.0.5 property and variable keeps its name.
1.1.1 (final release) changes only the startup log wording for OCreatures detection.}

; ---------- settings (changed from the MCM) ----------
; 1.0.4: default is Up Arrow (DX scancode 200) for NEW games only. This is an Auto Hidden property, so a save keeps
; whatever it already stored (0 = unbound stays unbound). No ESP bakes a value for it. 0 = unbound.
int Property StartKey = 200 Auto Hidden
bool Property GuardAllScenes = true Auto Hidden ; also freeze timer for scenes started by others (OStimNet/SkyrimNet, OStim hotkey)
bool Property StopCombatOnStart = false Auto Hidden
float Property SearchRadius = 200.0 Auto Hidden
bool Property DebugMessages = false Auto Hidden

; ---------- 1.1.0 settings (new Hidden properties; SettingsVersion migration sets them explicitly on 1.0.5 saves) ----------
int Property SettingsVersion = 0 Auto Hidden
bool Property PauseNearbyFights = false Auto Hidden   ; combat pause for other fighters (off until turned on: OStim's own combat handling was not checked)
float Property FeedHours = 0.25 Auto Hidden            ; climax feeds the beast timer, hours per climax (0 = off)
float Property FeedCapHours = 2.0 Auto Hidden          ; feeding never raises the remaining time above this many hours
bool Property GestureKey = false Auto Hidden           ; gesture start key (tap / hold + arrow / double tap), default off
bool Property SizeEnabled = false Auto Hidden          ; anatomy size menu, default off (visual size only)
int Property SizeGlobal = 2 Auto Hidden                ; index into the size table (default M = 1.0)
int Property SizeWolf = -1 Auto Hidden                 ; per kind, -1 = use the global step
int Property SizeBear = -1 Auto Hidden
int Property SizeVamp = -1 Auto Hidden
int Property SizeVariation = 0 Auto Hidden             ; 0 none, 1 small, 2 large (deterministic per actor)
int Property SizeSeed = 0 Auto Hidden
int Property InstalledAnimSet = 0 Auto Hidden          ; animation-registration reminder

; ---------- runtime ----------
Race WerewolfBeastRace
Race WerebearBeastRace
GlobalVariable ShiftBackTime
Keyword ActorTypeNPC
bool guardActive = false
float savedRemaining = 0.0
int guardedThread = -1
bool busy = false
bool ourPending = false
; 1.1.0 runtime (not Auto, not Hidden properties; 0 means "none" so old saves need no initial value)
bool gestureHeld = false
bool awaitingSecond = false
int pendingSlot = 0
int lastSlot = 0
string lastScene = ""
Actor lastPartner
bool bodyChecked = false

int Function AnimSetVersion()
	return 1 ; bump whenever this mod's animation set changes (1.1.0 ships the same animations as 1.0.5)
EndFunction

Event OnInit()
	Maintenance()
EndEvent

Function Maintenance()
	WerewolfBeastRace = Game.GetFormFromFile(0x000CDD84, "Skyrim.esm") as Race
	WerebearBeastRace = Game.GetFormFromFile(0x0001E17B, "Dragonborn.esm") as Race
	ShiftBackTime = Game.GetFormFromFile(0x0002BA19, "Skyrim.esm") as GlobalVariable
	ActorTypeNPC = Game.GetFormFromFile(0x00013794, "Skyrim.esm") as Keyword
	MigrateSettings()
	gestureHeld = false
	awaitingSecond = false
	pendingSlot = 0
	OBF_Detect.ClearClaims()
	OBF_Size.RestoreAll()       ; nothing stays scaled across a load; a running scene re-applies on its next thread start
	OBF_Combat.Reset()
	OBF_BodyCheck.NewLoad()
	bodyChecked = false
	RegisterKeys()
	RegisterForModEvent("ostim_thread_start", "OnOStimThreadStart")
	RegisterForModEvent("ostim_thread_end", "OnOStimThreadEnd")
	RegisterForModEvent("ostim_actor_orgasm", "OnOStimOrgasm")
	RegisterForModEvent("OBF_Claim", "OnClaim")
	RegisterForModEvent("OBF_RequestSize", "OnRequestSize")
	RegisterForModEvent("OBF_RequestStart", "OnRequestStart")
	; a save made mid-scene: make sure we never leave the timer frozen
	if guardActive && !OActor.IsInOStim(Game.GetPlayer())
		EndGuard()
	endif
	LogStartup()     ; 1.0.1: OStimBeastForm.log
	ApplyInstallerFlag()
	AnimReminder()
	OBF_Hooks.Fire("OBF_Ready", "110", 110.0, None)   ; hook contract version, unchanged in 1.1.1 so other mods' checks keep working; claimers re-send OBF_Claim after this
EndFunction

; 1.1.0: one-time defaults on a save that has not seen 1.1.0 yet. Settings 1.0.5 already had are never touched.
Function MigrateSettings()
	if SettingsVersion >= 110
		return
	endif
	PauseNearbyFights = false
	FeedHours = 0.25
	FeedCapHours = 2.0
	GestureKey = false
	SizeEnabled = false
	SizeGlobal = 2
	SizeWolf = -1
	SizeBear = -1
	SizeVamp = -1
	SizeVariation = 0
	SizeSeed = Utility.RandomInt(1, 1000000)
	SettingsVersion = 110
	OBF_Log.Line("OBF", "settings migrated to 1.1.0 defaults (1.0.5 settings kept)")
EndFunction

; the installer's "Use Riotguard/custom bodies even with OCR" tick drops a small json file; it only sets the MCM default, once
Function ApplyInstallerFlag()
	if !OBF_Log.HasPapyrusUtil()
		return
	endif
	if JsonUtil.JsonExists("OStimBeastForm/installer") && JsonUtil.GetIntValue("OStimBeastForm/installer", "custombody", 0) == 1
		if !StorageUtil.HasIntValue(None, "OBF_BodyCustom")
			StorageUtil.SetIntValue(None, "OBF_BodyCustom", 1)
			OBF_Log.Line("OBF", "installer flag: custom bodies even with OCR (MCM default set once)")
		endif
	endif
	string note = OBF_BodyCheck.OcrIniNote()
	if note != ""
		Debug.Notification("Beast Form: " + note)
		OBF_Log.Line("OBF", "body priority: " + note)
	endif
EndFunction

Function AnimReminder()
	if InstalledAnimSet != AnimSetVersion()
		InstalledAnimSet = AnimSetVersion()
		Debug.Notification("Beast Form: if beast animations do not play, run Pandora (or Nemesis) once and reload your save.")
		OBF_Log.Line("OBF", "animation set " + AnimSetVersion() + " is new for this save: reminded to run Pandora/Nemesis")
	endif
EndFunction

Function RegisterKeys()
	UnregisterForAllKeys()
	if StartKey > 0 && OBF_Detect.Ours("key")
		RegisterForKey(StartKey)
	endif
EndFunction

; ---------- 1.0.1: log file (OBF_Log) ----------
string Function CoreName()
	if OBF_Log.Loaded("OStim_Beast_Form_Merged.esp")
		return "Growl core C"
	elseif OBF_Log.Loaded("OStim_Beast_Form_TWO.esp")
		if OBF_Log.Loaded("Werewolves.esp")
			return "TWO core B"
		endif
		return "vanilla core A"
	endif
	return "no Beast Form plugin loaded"
EndFunction

string Function SceneOK(string id)
	return OBF_Log.YesNo(OMetadata.GetActorCount(id) > 0)
EndFunction

Function LogStartup()
	OBF_Log.Session(CoreName())
	if !OBF_Log.On()
		return
	endif
	string t = "OBF"
	OBF_Log.Line(t, "startup: " + CoreName() + " | SKSE " + SKSE.GetVersion() + "." + SKSE.GetVersionMinor() + "." + SKSE.GetVersionBeta() + " | PapyrusUtil yes | powerofthree " + OBF_Log.YesNo(SKSE.GetPluginVersion("powerofthree's Papyrus Extender") > 0) + " | OStim " + OBF_Log.YesNo(OBF_Log.Loaded("OStim.esp")) + " | OCum " + OBF_Log.YesNo(OBF_Log.Loaded("OCum.esp")))
	OBF_Log.Line(t, "startup: OCreatures detected " + OBF_Log.YesNo(OBF_Detect.OCRActive()) + " (OCreatures.esp " + OBF_Log.YesNo(OBF_Log.Loaded("OCreatures.esp")) + ", Reforged Menu plugin " + OBF_Log.YesNo(OBF_Detect.ReforgedActive()) + ") | Growl " + OBF_Log.YesNo(OBF_Detect.GrowlActive()) + " | TWO (Werewolves.esp) " + OBF_Log.YesNo(OBF_Detect.TwoActive()) + " | TWO Extras " + OBF_Log.YesNo(OBF_Log.Loaded("WerewolvesExtras.esp")) + " | Monster Facial Animation " + OBF_Log.YesNo(OBF_Log.Loaded("MonsterLipSync1.esp")) + " | optional couple animation pack (WVLAnimObj.esp) " + OBF_Log.YesNo(OBF_Log.Loaded("WVLAnimObj.esp")) + " | SkyrimNet " + OBF_Log.YesNo(OBF_Detect.SkyrimNetActive()) + " | OStimNet " + OBF_Log.YesNo(OBF_Detect.OStimNetActive()) + " | NiOverride " + OBF_Log.YesNo(OBF_Detect.NiOverrideReady()) + " | Herm patch " + OBF_Log.YesNo(OBF_Log.Loaded("OStim_Beast_Form_TWO_Herm_Patch.esp")))
	OBF_Log.Line(t, "startup: duties (key/timer/load/size/prompt/combat): " + OBF_Detect.OwnerText("key") + " / " + OBF_Detect.OwnerText("timer") + " / " + OBF_Detect.OwnerText("load") + " / " + OBF_Detect.OwnerText("size") + " / " + OBF_Detect.OwnerText("prompt") + " / " + OBF_Detect.OwnerText("combat"))
	Race vl = Game.GetFormFromFile(0x0000283A, "Dawnguard.esm") as Race
	Race pr = Game.GetPlayer().GetRace()
	string prn = "none"
	if pr
		prn = pr.GetName()
	endif
	OBF_Log.Line(t, "startup: races: werewolf " + OBF_Log.YesNo(WerewolfBeastRace != None) + " | werebear (Dragonborn) " + OBF_Log.YesNo(WerebearBeastRace != None) + " | vampire lord (Dawnguard) " + OBF_Log.YesNo(vl != None) + " | beast-form timer global " + OBF_Log.YesNo(ShiftBackTime != None) + " | player now: " + prn + ", beast form " + OBF_Log.YesNo(IsPlayerBeast()))
	if OBF_Log.Loaded("OCreatures.esp")
		Keyword wk = Game.GetFormFromFile(0x00005C58, "OCreatures.esp") as Keyword
		Keyword vk = Game.GetFormFromFile(0x00005C57, "OCreatures.esp") as Keyword
		OBF_Log.Line(t, "startup: OCR keywords on races: werewolf " + OBF_Log.YesNo(WerewolfBeastRace && wk && WerewolfBeastRace.HasKeyword(wk)) + " | vampire lord " + OBF_Log.YesNo(vl && vk && vl.HasKeyword(vk)))
	endif
	GlobalVariable bw = None
	if OBF_Log.Loaded("OStim_Beast_Form_Merged.esp")
		bw = Game.GetFormFromFile(0x839, "OStim_Beast_Form_Merged.esp") as GlobalVariable
	endif
	string bws = "n/a"
	if bw
		bws = OBF_Log.YesNo(bw.GetValue() >= 1.0)
	endif
	OBF_Log.Line(t, "startup: scenes registered: OBFWerewolfIdleMF " + SceneOK("OBFWerewolfIdleMF") + " | OBFWerewolfIdleFF " + SceneOK("OBFWerewolfIdleFF") + " | OBFVampireLordIdleFM " + SceneOK("OBFVampireLordIdleFM") + " | OBLWerewolfHubFM " + SceneOK("OBLWerewolfHubFM") + " | OBLVampireLordHubFM " + SceneOK("OBLVampireLordHubFM") + " | OCR stand-in OCrWerewolfIdleFM " + SceneOK("OCrWerewolfIdleFM") + " | Beast couples hub OBFWVLCCHubMF " + SceneOK("OBFWVLCCHubMF") + " | couple scene WVLmmgwerewolvesmissionary-1 (only from a couple animation pack, if you have one) " + SceneOK("WVLmmgwerewolvesmissionary-1"))
	OBF_Log.Line(t, "startup: MCM: start key " + StartKey + " | gesture key " + OBF_Log.YesNo(GestureKey) + " | pause timer for all scenes " + OBF_Log.YesNo(GuardAllScenes) + " | pause nearby fights " + OBF_Log.YesNo(PauseNearbyFights) + " | climax feeds timer " + FeedHours + " h (cap " + FeedCapHours + " h) | size menu " + OBF_Log.YesNo(SizeEnabled) + " | werebears use werewolf scenes " + bws + " | debug messages " + OBF_Log.YesNo(DebugMessages))
EndFunction

; any OStim scene with a werewolf, werebear or vampire lord in it (start only, one line)
Function LogBeastScene(int tid)
	if !OBF_Log.On()
		return
	endif
	Actor[] acts = OThread.GetActors(tid)
	if !acts
		return
	endif
	Race vl = Game.GetFormFromFile(0x0000283A, "Dawnguard.esm") as Race
	int beasts = 0
	string who = ""
	int i = 0
	while i < acts.Length
		if acts[i]
			Race r = acts[i].GetRace()
			if r && (r == WerewolfBeastRace || r == WerebearBeastRace || r == vl)
				beasts += 1
			endif
			if who != ""
				who += ", "
			endif
			who += OBF_Log.Who(acts[i])
		endif
		i += 1
	endwhile
	if beasts == 0
		return
	endif
	string kind = "beast scene"
	if beasts >= 2
		kind = "beast couple scene"
	endif
	OBF_Log.Line("OBF", kind + " started: thread " + tid + ", scene " + OThread.GetScene(tid) + ", actors: " + who)
EndFunction

Function SetStartKey(int newKey)
	StartKey = newKey
	RegisterKeys()
EndFunction

bool Function IsPlayerBeast()
	Actor player = Game.GetPlayer()
	Race r = player.GetRace()
	; 1.0: werebears (Dragonborn / Growl) count too
	return r && (r == WerewolfBeastRace || r == WerebearBeastRace)
EndFunction

Function Note(string msg)
	Debug.Notification("Beast Form: " + msg)
	OBF_Log.Line("OBF", "start key: " + msg)     ; 1.0.1
EndFunction

; ---------- hotkey ----------
Event OnKeyDown(int keyCode)
	if Utility.IsInMenuMode()
		return
	endif
	if keyCode == StartKey
		if busy || !OBF_Detect.Ours("key")
			return
		endif
		if GestureKey
			GestureBegin()
			return
		endif
		busy = true
		TryStart()
		busy = false
	elseif gestureHeld
		int s = OBF_Gesture.SlotOfKey(keyCode)
		if s > 0
			pendingSlot = s
		endif
	endif
EndEvent

; ---------- 1.1.0 gesture start key (default off): tap, hold + arrow, double tap ----------
Function GestureBegin()
	if OActor.IsInOStim(Game.GetPlayer())
		return
	endif
	if awaitingSecond
		UnregisterForUpdate() ; the second press is in progress: its release decides, so the 0.35 s window cannot expire under it
	endif
	gestureHeld = true
	pendingSlot = 0
	int s = 1
	while s <= 4
		int k = OBF_Gesture.KeyOfSlot(s)
		if k != StartKey
			RegisterForKey(k)
		endif
		s += 1
	endwhile
EndFunction

Function GestureEnd()
	gestureHeld = false
	int s = 1
	while s <= 4
		int k = OBF_Gesture.KeyOfSlot(s)
		if k != StartKey
			UnregisterForKey(k)
		endif
		s += 1
	endwhile
EndFunction

Event OnKeyUp(int keyCode, float holdTime)
	if keyCode != StartKey || !gestureHeld
		return
	endif
	int slot = pendingSlot
	GestureEnd()
	if slot > 0
		awaitingSecond = false
		StartGesture(slot, false)
	elseif holdTime < 0.4
		if awaitingSecond
			awaitingSecond = false
			StartGesture(0, true)
		else
			awaitingSecond = true
			RegisterForSingleUpdate(0.35)
		endif
	elseif awaitingSecond
		; a tap followed by a long hold with no arrow: the first tap meant a normal start
		awaitingSecond = false
		StartGesture(0, false)
	endif
EndEvent

Function StartGesture(int slot, bool addFollower)
	if busy
		return
	endif
	busy = true
	TryStartWith(slot, addFollower, None)
	busy = false
EndFunction

Function TryStart()
	TryStartWith(0, false, None)
EndFunction

; slot 0 = any fitting scene, 1..4 = gesture category; forced = a target chosen by another mod (OBF_RequestStart), still fully checked
Function TryStartWith(int slot, bool addFollower, Actor forced)
	Actor player = Game.GetPlayer()
	if !IsPlayerBeast()
		OBF_Log.Line("OBF", "start key pressed outside beast form - ignored")
		return ; key does nothing outside beast form
	endif
	if OActor.IsInOStim(player)
		Note("already in a scene.")
		return
	endif
	if player.IsInCombat()
		if StopCombatOnStart
			player.StopCombat()
			Utility.Wait(0.5)
		endif
		if player.IsInCombat()
			Note("can't start while in combat.")
			return
		endif
	endif

	Actor target = forced
	if !target
		target = FindTarget()
	endif
	if !target
		Note("no valid partner in front of you.")
		return
	endif
	string why = RefuseReason(target)
	if why != ""
		Note(why)
		return
	endif

	Actor follower = None
	if addFollower
		follower = OBF_Gesture.NearestFollower(player, target, SearchRadius * 4.0)
		if follower && RefuseReason(follower) != ""
			follower = None
		endif
	endif
	Actor[] actors
	if follower
		actors = new Actor[3]
		actors[0] = player
		actors[1] = target
		actors[2] = follower
	else
		actors = new Actor[2]
		actors[0] = player
		actors[1] = target
	endif
	; F5: sweep over the final list before OStim sees it
	if OBF_Detect.AnyMinor(actors)
		Note("not allowed.")
		return
	endif
	if !OActor.VerifyActors(actors)
		Note("OStim says " + target.GetDisplayName() + " can't be used.")
		return
	endif
	string sceneID = ""
	if slot > 0
		string avoid = ""
		if lastPartner == target && lastSlot == slot
			avoid = lastScene
		endif
		sceneID = OBF_Gesture.PickScene(actors, slot, avoid)
		if sceneID == ""
			Note("no scene in that category fits you and " + target.GetDisplayName() + ".")
			return
		endif
	else
		sceneID = OLibrary.GetRandomScene(actors)
	endif
	if sceneID == ""
		Note("no werewolf scene installed for you and " + target.GetDisplayName() + ".")
		return
	endif

	; F5: last check where the scene is created
	if OBF_Detect.AnyMinor(actors)
		Note("not allowed.")
		return
	endif
	int builder = OThreadBuilder.Create(actors)
	if builder < 0
		Note("OStim could not create the scene.")
		return
	endif
	Actor[] doms = new Actor[1]
	doms[0] = player
	OThreadBuilder.SetDominantActors(builder, doms)
	OThreadBuilder.SetStartingAnimation(builder, sceneID)
	OThreadBuilder.NoFurniture(builder)
	ourPending = true
	int tid = OThreadBuilder.Start(builder)
	if tid < 0
		ourPending = false
		Note("OStim refused to start the scene " + sceneID + ".")
	else
		lastPartner = target
		lastSlot = slot
		lastScene = sceneID
		OBF_Log.Line("OBF", "start key: started " + sceneID + " with " + OBF_Log.Who(target) + " (category " + slot + ", " + actors.Length + " actors)")
		if DebugMessages
			Debug.Notification("Beast Form: started " + sceneID)
		endif
	endif
EndFunction

Actor Function FindTarget()
	Actor player = Game.GetPlayer()
	Actor cross = Game.GetCurrentCrosshairRef() as Actor
	if cross && cross != player
		return cross
	endif
	; fallback (1.0.4): one PapyrusUtil cell scan, then the closest valid NPC in front of the player.
	; RefuseReason (child checks included) runs on every candidate.
	Actor[] found = MiscUtil.ScanCellNPCs(player, SearchRadius, None, true)
	if !found
		return None
	endif
	Actor best = None
	float bestDist = SearchRadius + 1.0
	int i = 0
	while i < found.Length
		Actor a = found[i]
		if a && a != player && RefuseReason(a) == ""
			float h = player.GetHeadingAngle(a)
			if h > -60.0 && h < 60.0
				float d = player.GetDistance(a)
				if d < bestDist
					best = a
					bestDist = d
				endif
			endif
		endif
		i += 1
	endwhile
	return best
EndFunction

; returns "" if the target is allowed, else the reason
string Function RefuseReason(Actor a)
	if !a
		return "no target."
	endif
	; never minors: vanilla flag + OStim's own child check + race name (OBF_Detect.IsMinor)
	if OBF_Detect.IsMinor(a)
		return "not allowed."
	endif
	if a.IsDead()
		return a.GetDisplayName() + " is dead."
	endif
	if a.IsDisabled() || a.IsDeleted()
		return "no valid target."
	endif
	if ActorTypeNPC && !a.HasKeyword(ActorTypeNPC)
		return a.GetDisplayName() + " isn't a humanoid NPC."
	endif
	if a.IsInCombat()
		return a.GetDisplayName() + " is in combat."
	endif
	if OActor.IsInOStim(a)
		return a.GetDisplayName() + " is already in a scene."
	endif
	return ""
EndFunction

; ---------- ModEvents we accept (OBF_Claim, OBF_RequestSize, OBF_RequestStart) ----------
Event OnClaim(string eventName, string duty, float numArg, Form sender)
	OBF_Detect.SetClaim(duty, numArg > 0.5)
	RegisterKeys()
EndEvent

Event OnRequestSize(string eventName, string label, float numArg, Form sender)
	OBF_Size.Request(Self, label, numArg, sender)
EndEvent

; strArg = "up" / "down" / "left" / "right" or empty; sender = the target actor. Same refusals and child checks as the key.
Event OnRequestStart(string eventName, string slotName, float numArg, Form sender)
	Actor t = sender as Actor
	if !t || busy
		return
	endif
	busy = true
	TryStartWith(OBF_Gesture.SlotFromName(slotName), false, t)
	busy = false
EndEvent

; ---------- beast-form timer guard ----------
Event OnOStimThreadStart(string eventName, string strArg, float numArg, Form sender)
	int tid = numArg as int
	LogBeastScene(tid)      ; 1.0.1
	OBF_Size.ThreadStart(Self, tid)   ; 1.1.0: size menu, any thread, only when switched on and ours
	if tid == 0
		BeastSceneBegin(tid)
	endif
	if tid != 0 || guardActive
		ourPending = false
		return ; thread 0 is always the player thread
	endif
	if !IsPlayerBeast() || !GuardAllScenes && !ourPending
		return
	endif
	ourPending = false
	BeginGuard(tid)
EndEvent

; 1.1.0: the player's scene has a beast in it: hook event, one body check per load, optional combat pause
Function BeastSceneBegin(int tid)
	Actor[] acts = OThread.GetActors(tid)
	if !acts
		return
	endif
	Actor beast = None
	int i = 0
	while i < acts.Length
		Actor a = acts[i]
		if a && OBF_Detect.KindOf(a) != "none"
			if !beast || a.GetLeveledActorBase().GetSex() == 1
				beast = a
			endif
		endif
		i += 1
	endwhile
	if !beast
		return
	endif
	OBF_Hooks.Fire("OBF_SceneStart", OBF_Detect.KindOf(beast), tid as float, Game.GetPlayer())
	if !bodyChecked
		bodyChecked = true
		OBF_BodyCheck.Run(beast, "first beast scene")
	endif
	if PauseNearbyFights && OBF_Detect.Ours("combat")
		OBF_Combat.Pause(acts)
	endif
EndFunction

Event OnOStimThreadEnd(string eventName, string json, float numArg, Form sender)
	int tid = numArg as int
	OBF_Size.ThreadEnd(OJSON.GetActors(json))
	if tid == 0
		OBF_Combat.Resume()
		OBF_Hooks.Fire("OBF_SceneEnd", OBF_Detect.KindOf(Game.GetPlayer()), 0.0, Game.GetPlayer())
	endif
	if guardActive && tid == guardedThread
		EndGuard()
	endif
EndEvent

; 1.1.0: climax feeds the beast timer (hours per climax, capped) and counts for Beast Aware
Event OnOStimOrgasm(string eventName, string sceneID, float numArg, Form sender)
	if (numArg as int) != 0 || !IsPlayerBeast()
		return
	endif
	if OBF_Log.HasPapyrusUtil()
		StorageUtil.AdjustIntValue(None, "OBF_MatingCount", 1)
	endif
	if !guardActive || FeedHours <= 0.0 || !OBF_Detect.Ours("timer")
		return
	endif
	float cap = FeedCapHours / 24.0
	if savedRemaining >= cap
		return
	endif
	float add = FeedHours / 24.0
	if savedRemaining + add > cap
		add = cap - savedRemaining
	endif
	savedRemaining += add
	PushTimer()
	OBF_Log.Line("OBF", "climax fed the beast timer: +" + (add * 24.0) + " h (remaining " + (savedRemaining * 24.0) + " h)")
	OBF_Hooks.Fire("OBF_Feed", OBF_Detect.KindOf(Game.GetPlayer()), add * 24.0, Game.GetPlayer())
EndEvent

; the player finished a race switch (called from OBF_PlayerAlias)
Function RaceSwitched()
	if IsPlayerBeast()
		OBF_BodyCheck.Run(Game.GetPlayer(), "race switch")
	endif
EndFunction

Function BeginGuard(int tid)
	if !ShiftBackTime || !OBF_Detect.Ours("timer")
		return
	endif
	float now = Utility.GetCurrentGameTime()
	savedRemaining = ShiftBackTime.GetValue() - now
	if savedRemaining < 0.01
		savedRemaining = 0.01 ; ~15 game minutes so we never revert the instant the scene ends
	endif
	guardActive = true
	guardedThread = tid
	OBF_Log.Line("OBF", "beast-form timer paused for thread " + tid)
	OBF_Hooks.Fire("OBF_TimerPaused", OBF_Detect.KindOf(Game.GetPlayer()), savedRemaining * 24.0, Game.GetPlayer())
	PushTimer()
	RegisterForSingleUpdate(5.0)
	if DebugMessages
		Debug.Notification("Beast Form: beast timer paused.")
	endif
EndFunction

Function PushTimer()
	; same mechanism as feeding: move the shift-back time forward
	ShiftBackTime.SetValue(Utility.GetCurrentGameTime() + savedRemaining + 0.0417) ; + 1 game hour margin
EndFunction

Event OnUpdate()
	if awaitingSecond
		; the double-tap window closed with a single tap: a normal start
		awaitingSecond = false
		StartGesture(0, false)
		if guardActive
			RegisterForSingleUpdate(5.0)
		endif
		return
	endif
	if !guardActive
		return
	endif
	if !OThread.IsRunning(guardedThread) || !OActor.IsInOStim(Game.GetPlayer())
		EndGuard()
		return
	endif
	if IsPlayerBeast()
		PushTimer()
	endif
	RegisterForSingleUpdate(5.0)
EndEvent

Function EndGuard()
	if guardActive && ShiftBackTime && IsPlayerBeast()
		ShiftBackTime.SetValue(Utility.GetCurrentGameTime() + savedRemaining)
	endif
	if guardActive
		OBF_Log.Line("OBF", "beast-form timer resumed")
		OBF_Hooks.Fire("OBF_TimerResumed", OBF_Detect.KindOf(Game.GetPlayer()), savedRemaining * 24.0, Game.GetPlayer())
	endif
	guardActive = false
	guardedThread = -1
	if DebugMessages
		Debug.Notification("Beast Form: beast timer resumed.")
	endif
EndFunction
