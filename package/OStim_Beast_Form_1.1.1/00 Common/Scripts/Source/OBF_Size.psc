Scriptname OBF_Size Hidden
{OStim Beast Form 1.1.0 - anatomy size menu helpers (visual size only). That Guy (Coronerra).
Global functions. Size is a NiOverride node scale on the root bone of the male genital chain, applied when an OStim scene starts and
removed when it ends. It is a visual change: whether PPA follows it was not verified in game (see the README), so the MCM says so.
Table: Data/SKSE/Plugins/StorageUtilData/OStimBeastForm/sizes.json (stringList "labels", floatList "scales", optional stringList "nodes").
Per-actor override: StorageUtil float OBF_SizeScale on the actor, or ModEvent OBF_RequestSize. Male anatomy only. Children never.}

string Function SceneKey() global
	return "OBF_Size"
EndFunction

bool Function HasTable() global
	if !OBF_Log.HasPapyrusUtil() || !JsonUtil.JsonExists("OStimBeastForm/sizes")
		return false
	endif
	int n = JsonUtil.StringListCount("OStimBeastForm/sizes", "labels")
	return n > 0 && n <= 12 && JsonUtil.FloatListCount("OStimBeastForm/sizes", "scales") >= n
EndFunction

int Function Count() global
	if HasTable()
		return JsonUtil.StringListCount("OStimBeastForm/sizes", "labels")
	endif
	return 6
EndFunction

string Function Label(int i) global
	if HasTable()
		return JsonUtil.StringListGet("OStimBeastForm/sizes", "labels", i)
	endif
	if i == 0
		return "XS"
	elseif i == 1
		return "S"
	elseif i == 2
		return "M"
	elseif i == 3
		return "L"
	elseif i == 4
		return "XL"
	endif
	return "XXL"
EndFunction

float Function Scale(int i) global
	if HasTable()
		return Clamp(JsonUtil.FloatListGet("OStimBeastForm/sizes", "scales", i))
	endif
	if i == 0
		return 0.8
	elseif i == 1
		return 0.9
	elseif i == 2
		return 1.0
	elseif i == 3
		return 1.15
	elseif i == 4
		return 1.3
	endif
	return 1.5
EndFunction

float Function Clamp(float s) global
	if s < 0.5
		return 0.5
	elseif s > 2.0
		return 2.0
	endif
	return s
EndFunction

; scale for an actor: per-actor override, then per-kind MCM, then global MCM, then the optional deterministic variation
float Function Resolve(OBF_Main m, Actor a) global
	if OBF_Log.HasPapyrusUtil()
		float ov = StorageUtil.GetFloatValue(a, "OBF_SizeScale", 0.0)
		if ov > 0.0
			return Clamp(ov)
		endif
	endif
	string kind = OBF_Detect.KindOf(a)
	int idx = m.SizeGlobal
	if kind == "werewolf" && m.SizeWolf >= 0
		idx = m.SizeWolf
	elseif kind == "werebear" && m.SizeBear >= 0
		idx = m.SizeBear
	elseif kind == "vampirelord" && m.SizeVamp >= 0
		idx = m.SizeVamp
	endif
	if idx >= Count()
		idx = Count() - 1
	endif
	if idx < 0
		idx = 0
	endif
	float s = Scale(idx)
	if m.SizeVariation > 0
		; deterministic from the actor's FormID and a per-save seed: no re-roll, nothing stored per actor
		int h = Math.LogicalAnd(Math.LogicalXor(a.GetFormID(), m.SizeSeed), 1023)
		float v = (h as float / 1023.0) - 0.5
		float amt = 0.05
		if m.SizeVariation > 1
			amt = 0.15
		endif
		s = s * (1.0 + v * 2.0 * amt)
	endif
	return Clamp(s)
EndFunction

string Function NodeAt(string kind, int i) global
	string f = "OStimBeastForm/sizes"
	if OBF_Log.HasPapyrusUtil() && JsonUtil.JsonExists(f) && JsonUtil.StringListCount(f, "nodes") > 0
		if i < JsonUtil.StringListCount(f, "nodes")
			return JsonUtil.StringListGet(f, "nodes", i)
		endif
		return ""
	endif
	if i == 0
		return "WWD 1"
	elseif i == 1
		return "NPC GenitalsBase [GenBase]"
	elseif i == 2 && kind == "vampirelord"
		return "VLDickBase"
	endif
	return ""
EndFunction

bool Function Eligible(Actor a) global
	if !a || OBF_Detect.IsMinor(a)
		return false
	endif
	if OBF_Detect.KindOf(a) == "none"
		return false
	endif
	return a.GetLeveledActorBase().GetSex() == 0
EndFunction

; node scale on every listed bone the actor really has. Returns how many bones were scaled.
int Function Apply(Actor a, float s) global
	if !a || !OBF_Detect.NiOverrideReady() || !a.Is3DLoaded()
		return 0
	endif
	string kind = OBF_Detect.KindOf(a)
	int done = 0
	int i = 0
	while i < 8
		string node = NodeAt(kind, i)
		if node != "" && NetImmerse.HasNode(a, node, false)
			NiOverride.AddNodeTransformScale(a, false, false, node, SceneKey(), s)
			NiOverride.UpdateNodeTransform(a, false, false, node)
			done += 1
		endif
		i += 1
	endwhile
	return done
EndFunction

Function Remove(Actor a) global
	if !a || !OBF_Detect.NiOverrideReady()
		return
	endif
	string kind = OBF_Detect.KindOf(a)
	int i = 0
	while i < 8
		string node = NodeAt(kind, i)
		if node != ""
			NiOverride.RemoveNodeTransformScale(a, false, false, node, SceneKey())
			NiOverride.UpdateNodeTransform(a, false, false, node)
		endif
		i += 1
	endwhile
EndFunction

; ostim_thread_start: scale the male beasts in the scene (any thread, player or NPC-only)
Function ThreadStart(OBF_Main m, int tid) global
	if !m.SizeEnabled || !OBF_Detect.Ours("size") || !OBF_Detect.NiOverrideReady() || !OBF_Log.HasPapyrusUtil()
		return
	endif
	Actor[] acts = OThread.GetActors(tid)
	if !acts
		return
	endif
	int i = 0
	while i < acts.Length
		Actor a = acts[i]
		if Eligible(a)
			float s = Resolve(m, a)
			int n = Apply(a, s)
			StorageUtil.FormListAdd(None, "OBF_Sized", a, false)
			if a == Game.GetPlayer()
				StorageUtil.SetStringValue(None, "OBF_PlayerSizeLabel", ScaleLabel(s))   ; read by Beast Aware (SkyrimNet state)
			endif
			OBF_Log.Line("OBF", "size " + s + " on " + OBF_Log.Who(a) + ": " + n + " bone(s)")
			OBF_Hooks.Fire("OBF_SizeChanged", ScaleLabel(s), s, a)
		endif
		i += 1
	endwhile
EndFunction

; ostim_thread_end: put back the actors we scaled
Function ThreadEnd(Actor[] acts) global
	if !acts || !OBF_Log.HasPapyrusUtil()
		return
	endif
	int i = 0
	while i < acts.Length
		Actor a = acts[i]
		if a && StorageUtil.FormListFind(None, "OBF_Sized", a) >= 0
			Remove(a)
			StorageUtil.FormListRemove(None, "OBF_Sized", a, true)
			if a == Game.GetPlayer()
				StorageUtil.UnsetStringValue(None, "OBF_PlayerSizeLabel")
			endif
		endif
		i += 1
	endwhile
EndFunction

; load / MCM off: nothing stays scaled
Function RestoreAll() global
	if !OBF_Log.HasPapyrusUtil()
		return
	endif
	int n = StorageUtil.FormListCount(None, "OBF_Sized")
	while n > 0
		n -= 1
		Actor a = StorageUtil.FormListGet(None, "OBF_Sized", n) as Actor
		if a
			Remove(a)
		endif
	endwhile
	StorageUtil.FormListClear(None, "OBF_Sized")
	StorageUtil.UnsetStringValue(None, "OBF_PlayerSizeLabel")
EndFunction

string Function ScaleLabel(float s) global
	int best = 0
	float bd = 99.0
	int i = 0
	while i < Count()
		float d = Scale(i) - s
		if d < 0.0
			d = -d
		endif
		if d < bd
			bd = d
			best = i
		endif
		i += 1
	endwhile
	return Label(best)
EndFunction

; ModEvent OBF_RequestSize: strArg = label (or empty), numArg = scale (0 = use the label); sender = the actor
Function Request(OBF_Main m, string label, float scale, Form sender) global
	Actor a = sender as Actor
	if !a || !OBF_Log.HasPapyrusUtil() || OBF_Detect.IsMinor(a) || OBF_Detect.KindOf(a) == "none"
		return
	endif
	float s = scale
	if s <= 0.0
		int i = 0
		while i < Count()
			if Label(i) == label
				s = Scale(i)
			endif
			i += 1
		endwhile
	endif
	if s <= 0.0
		StorageUtil.UnsetFloatValue(a, "OBF_SizeScale")
		OBF_Log.Line("OBF", "size request: override cleared on " + OBF_Log.Who(a))
		return
	endif
	StorageUtil.SetFloatValue(a, "OBF_SizeScale", Clamp(s))
	OBF_Log.Line("OBF", "size request: " + Clamp(s) + " for " + OBF_Log.Who(a))
	if m && m.SizeEnabled && OBF_Detect.Ours("size") && OActor.IsInOStim(a) && Eligible(a)
		Apply(a, Clamp(s))
		StorageUtil.FormListAdd(None, "OBF_Sized", a, false)
		OBF_Hooks.Fire("OBF_SizeChanged", ScaleLabel(Clamp(s)), Clamp(s), a)
	endif
EndFunction
