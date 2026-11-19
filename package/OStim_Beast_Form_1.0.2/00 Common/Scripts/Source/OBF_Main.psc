Scriptname OBF_Main extends Quest
{OStim Beast Form 1.0.1 - lets the player start OStim scenes in vanilla werewolf beast form and freezes the beast-form timer during scenes. By coronerra.}

; ---------- settings (changed from the MCM) ----------
int Property StartKey = 0 Auto Hidden          ; 0 = unbound
bool Property GuardAllScenes = true Auto Hidden ; also freeze timer for scenes started by others (OStimNet/SkyrimNet, OStim hotkey)
bool Property StopCombatOnStart = false Auto Hidden
float Property SearchRadius = 200.0 Auto Hidden
bool Property DebugMessages = false Auto Hidden

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

Event OnInit()
	Maintenance()
EndEvent

Function Maintenance()
	WerewolfBeastRace = Game.GetFormFromFile(0x000CDD84, "Skyrim.esm") as Race
	WerebearBeastRace = Game.GetFormFromFile(0x0001E17B, "Dragonborn.esm") as Race
	ShiftBackTime = Game.GetFormFromFile(0x0002BA19, "Skyrim.esm") as GlobalVariable
	ActorTypeNPC = Game.GetFormFromFile(0x00013794, "Skyrim.esm") as Keyword
	UnregisterForAllKeys()
	if StartKey > 0
		RegisterForKey(StartKey)
	endif
	RegisterForModEvent("ostim_thread_start", "OnOStimThreadStart")
	RegisterForModEvent("ostim_thread_end", "OnOStimThreadEnd")
	; a save made mid-scene: make sure we never leave the timer frozen
	if guardActive && !OActor.IsInOStim(Game.GetPlayer())
		EndGuard()
	endif
	LogStartup()     ; 1.0.1: OStimBeastForm.log
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
	OBF_Log.Line(t, "startup: OCreatures Reforged " + OBF_Log.YesNo(OBF_Log.Loaded("OCreatures.esp")) + " | Growl " + OBF_Log.YesNo(OBF_Log.Loaded("Growl - Werebeasts of Skyrim.esp")) + " | TWO (Werewolves.esp) " + OBF_Log.YesNo(OBF_Log.Loaded("Werewolves.esp")) + " | TWO Extras " + OBF_Log.YesNo(OBF_Log.Loaded("WerewolvesExtras.esp")) + " | Monster Facial Animation " + OBF_Log.YesNo(OBF_Log.Loaded("MonsterLipSync1.esp")) + " | Lirael's Werewolf and Vampire Lord OStim (WVLAnimObj.esp) " + OBF_Log.YesNo(OBF_Log.Loaded("WVLAnimObj.esp")) + " | SkyrimNet " + OBF_Log.YesNo(OBF_Log.Loaded("SkyrimNet.esp")) + " | OStimNet " + OBF_Log.YesNo(OBF_Log.Loaded("TT_OStimNet.esp") || SKSE.GetPluginVersion("OStimNet") > 0) + " | Herm patch " + OBF_Log.YesNo(OBF_Log.Loaded("OStim_Beast_Form_TWO_Herm_Patch.esp")))
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
	OBF_Log.Line(t, "startup: scenes registered: OBFWerewolfIdleMF " + SceneOK("OBFWerewolfIdleMF") + " | OBFWerewolfIdleFF " + SceneOK("OBFWerewolfIdleFF") + " | OBFVampireLordIdleFM " + SceneOK("OBFVampireLordIdleFM") + " | OBLWerewolfHubFM " + SceneOK("OBLWerewolfHubFM") + " | OBLVampireLordHubFM " + SceneOK("OBLVampireLordHubFM") + " | OCR stand-in OCrWerewolfIdleFM " + SceneOK("OCrWerewolfIdleFM") + " | Beast couples hub OBFWVLCCHubMF " + SceneOK("OBFWVLCCHubMF") + " | Lirael couple scene WVLmmgwerewolvesmissionary-1 " + SceneOK("WVLmmgwerewolvesmissionary-1"))
	OBF_Log.Line(t, "startup: MCM: start key " + StartKey + " | pause timer for all scenes " + OBF_Log.YesNo(GuardAllScenes) + " | werebears use werewolf scenes " + bws + " | debug messages " + OBF_Log.YesNo(DebugMessages))
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
	if StartKey > 0
		UnregisterForKey(StartKey)
	endif
	StartKey = newKey
	if StartKey > 0
		RegisterForKey(StartKey)
	endif
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
	if keyCode != StartKey || busy || Utility.IsInMenuMode()
		return
	endif
	busy = true
	TryStart()
	busy = false
EndEvent

Function TryStart()
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

	Actor target = FindTarget()
	if !target
		Note("no valid partner in front of you.")
		return
	endif
	string why = RefuseReason(target)
	if why != ""
		Note(why)
		return
	endif

	Actor[] actors = new Actor[2]
	actors[0] = player
	actors[1] = target
	if !OActor.VerifyActors(actors)
		Note("OStim says " + target.GetDisplayName() + " can't be used.")
		return
	endif
	string sceneID = OLibrary.GetRandomScene(actors)
	if sceneID == ""
		Note("no werewolf scene installed for you and " + target.GetDisplayName() + ".")
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
		OBF_Log.Line("OBF", "start key: started " + sceneID + " with " + OBF_Log.Who(target))
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
	; fallback: nearest candidate in front of the player
	Actor best = None
	float bestDist = SearchRadius + 1.0
	int i = 0
	while i < 12
		Actor a = Game.FindRandomActorFromRef(player, SearchRadius)
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
	; never minors: vanilla flag + OStim's own child check (race/name contains "Child")
	if a.IsChild() || OUtils.IsChild(a)
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

; ---------- beast-form timer guard ----------
Event OnOStimThreadStart(string eventName, string strArg, float numArg, Form sender)
	int tid = numArg as int
	LogBeastScene(tid)      ; 1.0.1
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


Event OnOStimThreadEnd(string eventName, string json, float numArg, Form sender)
	if guardActive && (numArg as int) == guardedThread
		EndGuard()
	endif
EndEvent

Function BeginGuard(int tid)
	if !ShiftBackTime
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
	endif
	guardActive = false
	guardedThread = -1
	if DebugMessages
		Debug.Notification("Beast Form: beast timer resumed.")
	endif
EndFunction
