Scriptname BA_Main extends Quest
{Beast Aware - tells SkyrimNet NPCs when the player shifts into or out of beast form. by coronerra}

bool Property ModEnabled = true Auto
bool Property AnnounceShift = true Auto      ; event when shifting in
bool Property AnnounceRevert = true Auto     ; event when shifting back
bool Property NpcsReact = true Auto          ; true = DirectNarration (NPCs may react), false = silent persistent event
bool Property StateContext = true Auto       ; keep a "currently in beast form" note in scene context
bool Property DebugMessages = false Auto

int Property CurrentForm = 0 Auto Hidden     ; 0 none, 1 werewolf, 2 vampire lord, 3 werebear/other
Race WerewolfRace
Race WerebearRace        ; 1.0.4: DLC2WerebearBeastRace (Dragonborn.esm 0x1E17B), Growl uses it too
Race VampireLordRace
Keyword ActorTypeNPC     ; 1.0.4: human-looking races (also Growl's HRI_Alternate_Race_* "Lycanthrope" alts) are never beast forms
Keyword ActorTypeCreature
Keyword OcrWerewolfKw    ; 1.0.4: OCreatures Reforged race keywords (optional)
Keyword OcrVampireKw
Keyword GrowlWerecreatureKw ; 1.0.4: Growl's HRI_Lycan_Keyword_IsWerecreature (optional, looked up by editor ID)
float RefreshInterval = 30.0

Event OnInit()
	Maintenance()
EndEvent

Function Maintenance()
	WerewolfRace = Game.GetFormFromFile(0x000CDD84, "Skyrim.esm") as Race
	WerebearRace = Game.GetFormFromFile(0x0001E17B, "Dragonborn.esm") as Race
	VampireLordRace = Game.GetFormFromFile(0x0000283A, "Dawnguard.esm") as Race
	ActorTypeNPC = Game.GetFormFromFile(0x00013794, "Skyrim.esm") as Keyword
	ActorTypeCreature = Game.GetFormFromFile(0x00013795, "Skyrim.esm") as Keyword
	OcrWerewolfKw = None
	OcrVampireKw = None
	if OBF_Log.Loaded("OCreatures.esp")
		OcrWerewolfKw = Game.GetFormFromFile(0x00005C58, "OCreatures.esp") as Keyword
		OcrVampireKw = Game.GetFormFromFile(0x00005C57, "OCreatures.esp") as Keyword
	endif
	GrowlWerecreatureKw = None
	if OBF_Log.Loaded("Growl - Werebeasts of Skyrim.esp")
		GrowlWerecreatureKw = Keyword.GetKeyword("HRI_Lycan_Keyword_IsWerecreature")
	endif
	CheckForm(true)
	OBF_Log.Line("BeastAware", "setup: on " + OBF_Log.YesNo(ModEnabled) + " | SkyrimNet " + OBF_Log.YesNo(SkyrimNetReady()) + " | announce shift " + OBF_Log.YesNo(AnnounceShift) + " / revert " + OBF_Log.YesNo(AnnounceRevert) + " | NPCs react " + OBF_Log.YesNo(NpcsReact) + " | state note " + OBF_Log.YesNo(StateContext) + " | player form now " + CurrentForm + " (" + PlayerRaceName() + ")")
EndFunction

; ---- 1.0.4: SkyrimNet gate. Nothing below calls SkyrimNetApi unless this is true. ----
bool Function SkyrimNetReady()
	return OBF_Log.Loaded("SkyrimNet.esp")
EndFunction

; the 30 s state refresh runs only while it has something to do
bool Function RefreshWanted()
	; 1.1.0: when OCreatures Reforged (or another mod) owns the "prompt" duty, no state note is pushed (an empty state)
	return ModEnabled && StateContext && CurrentForm > 0 && SkyrimNetReady() && OBF_Detect.Ours("prompt")
EndFunction

; ---- 1.1.0: extra state for the note: size label, arousal band, climaxes in this form ----
string Function ArousalBand()
	Actor p = Game.GetPlayer()
	if !OActor.IsInOStim(p)
		return "calm"
	endif
	float x = OActor.GetExcitement(p)
	int t1 = 25
	int t2 = 60
	int t3 = 90
	if OBF_Log.HasPapyrusUtil() && JsonUtil.JsonExists("OStimBeastForm/arousal")
		t1 = JsonUtil.GetIntValue("OStimBeastForm/arousal", "low", t1)
		t2 = JsonUtil.GetIntValue("OStimBeastForm/arousal", "mid", t2)
		t3 = JsonUtil.GetIntValue("OStimBeastForm/arousal", "high", t3)
	endif
	if x < t1 as float
		return "low"
	elseif x < t2 as float
		return "rising"
	elseif x < t3 as float
		return "high"
	endif
	return "near the peak"
EndFunction

string Function StateExtras()
	string s = ""
	if OBF_Log.HasPapyrusUtil()
		string sz = StorageUtil.GetStringValue(None, "OBF_PlayerSizeLabel", "")
		if sz != ""
			s += " Size: " + sz + "."
		endif
	endif
	s += " Arousal: " + ArousalBand() + "."
	if OBF_Log.HasPapyrusUtil()
		int n = StorageUtil.GetIntValue(None, "OBF_MatingCount", 0)
		if n > 0
			s += " Climaxes in this form so far: " + n + "."
		endif
	endif
	return s
EndFunction

string Function PlayerRaceName()
	Race r = Game.GetPlayer().GetRace()
	if r
		return r.GetName()
	endif
	return "no race"
EndFunction

; 1.0.4: by race form and keyword, never by (translated) display name. Human-looking lycanthrope alt races
; (Growl HRI_Alternate_Race_*) carry ActorTypeNPC and are always 0.
int Function FormOfRace(Race r)
	if !r
		return 0
	endif
	if WerewolfRace && r == WerewolfRace
		return 1
	elseif WerebearRace && r == WerebearRace
		return 3
	elseif VampireLordRace && r == VampireLordRace
		return 2
	endif
	; other beast-form races (overhaul mods): must be creature-type and not NPC-type
	if !ActorTypeCreature || !r.HasKeyword(ActorTypeCreature)
		return 0
	endif
	if ActorTypeNPC && r.HasKeyword(ActorTypeNPC)
		return 0
	endif
	if OcrVampireKw && r.HasKeyword(OcrVampireKw)
		return 2
	elseif OcrWerewolfKw && r.HasKeyword(OcrWerewolfKw)
		return 1
	elseif GrowlWerecreatureKw && r.HasKeyword(GrowlWerecreatureKw)
		return 1
	endif
	return 0
EndFunction

int Function DetectForm()
	return FormOfRace(Game.GetPlayer().GetRace())
EndFunction

string Function BeastDesc(int f)
	if f == 2
		return "a vampire lord form with wings"
	elseif f == 3
		return "a massive, shaggy, bear-like werebear"
	endif
	return "a massive, hairy werewolf"
EndFunction

string Function FormName(int f)
	if f == 2
		return "Vampire Lord form"
	elseif f == 3
		return "werebear form"
	endif
	return "werewolf form"
EndFunction

string Function StateBody(int f)
	if f == 2
		return "their body has grown and changed into a vampire lord form with wings, far too large for any clothing or armor to fit"
	elseif f == 3
		return "a massive, shaggy, bear-like beast, far too large for any clothing or armor to fit"
	endif
	return "a towering, fur-covered beast far too large for any clothing or armor to fit"
EndFunction

string Function SeenAs(int f)
	if f == 2
		return "a huge vampire lord with wings"
	elseif f == 3
		return "a huge, shaggy werebear"
	endif
	return "a huge, hairy werewolf"
EndFunction

string Function ShiftText(int f, string nm)
	if f == 2
		; 1.0: simple Vampire Lord line
		return nm + "'s body grows and changes into a vampire lord form with wings, and their clothes fall away."
	endif
	return nm + " tore free of their clothes as their body swelled and twisted, stripping them off before they could rip, and grew into " + BeastDesc(f) + "."
EndFunction

string Function StateText(int f, string nm)
	return nm + " is in " + FormName(f) + ": " + StateBody(f) + ". Being unclothed is natural for this form, and their body is fully exposed. Anyone nearby sees " + SeenAs(f) + " and reacts to that (fear, awe, desire, or whatever fits them), and would not scold them for lacking clothes the way they would a naked human."
EndFunction

string Function RevertText(int f, string nm)
	string back = "human form"
	if f == 2
		back = "mortal form"
	endif
	return nm + " shrank back into " + back + ", left standing naked and exhausted among the remains of the change."
EndFunction

; onLoad = true: quiet resync after loading a save (no announcement)
Function CheckForm(bool onLoad)
	int f = DetectForm()
	int old = CurrentForm
	CurrentForm = f
	if f == old
		if RefreshWanted()
			PushState()
			RegisterForSingleUpdate(RefreshInterval)
		endif
		return
	endif
	if !ModEnabled
		OBF_Log.Line("BeastAware", "form " + old + " -> " + f + ", Beast Aware is off in the MCM: nothing sent")
		return
	endif
	Actor p = Game.GetPlayer()
	string nm = p.GetDisplayName()
	if f > 0 && old == 0
		if AnnounceShift && !onLoad
			Send(ShiftText(f, nm))
		endif
		if RefreshWanted()
			PushState()
			RegisterForSingleUpdate(RefreshInterval)
		endif
		Dbg("shift detected: form " + f + " (" + FormName(f) + ", race " + PlayerRaceName() + ")")
	elseif f == 0 && old > 0
		if OBF_Log.HasPapyrusUtil()
			StorageUtil.SetIntValue(None, "OBF_MatingCount", 0)   ; 1.1.0: the count is per form session
		endif
		if AnnounceRevert && !onLoad
			Send(RevertText(old, nm))
		endif
		UnregisterForUpdate()
		Dbg("revert detected")
	else
		; switched between two beast forms
		if AnnounceShift && !onLoad
			Send(ShiftText(f, nm))
		endif
		Dbg("form changed: " + f)
	endif
EndFunction

Function Send(string content)
	if !ModEnabled || !SkyrimNetReady()
		return ; 1.0.4: no SkyrimNetApi call without SkyrimNet
	endif
	Actor p = Game.GetPlayer()
	int rc
	if NpcsReact
		rc = SkyrimNetApi.DirectNarration(content, None, None)
	else
		rc = SkyrimNetApi.RegisterPersistentEvent(content, p, None)
	endif
	Dbg("event sent (rc " + rc + ")")
EndFunction

Function PushState()
	if !RefreshWanted()
		return ; 1.0.4: off, no state note wanted, not in beast form, or SkyrimNet missing: no API call
	endif
	Actor p = Game.GetPlayer()
	string d = StateText(CurrentForm, p.GetDisplayName()) + StateExtras()
	SkyrimNetApi.RegisterShortLivedEvent("beastaware_player_form", "beastaware_form", d, "", 45000, p, None)
EndFunction

Event OnUpdate()
	; safety net in case a race switch event was missed
	CheckForm(false)
EndEvent

Function Dbg(string s)
	OBF_Log.Line("BeastAware", s)       ; 1.0.1: OStimBeastForm.log
	if DebugMessages
		Debug.Notification("Beast Aware: " + s)
	endif
EndFunction
