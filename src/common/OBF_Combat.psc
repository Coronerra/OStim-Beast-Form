Scriptname OBF_Combat Hidden
{OStim Beast Form 1.1.0 - pause nearby fights while the player's scene runs, then resume them. That Guy (Coronerra).
Event-driven: Pause on ostim_thread_start (player thread), Resume on ostim_thread_end. One bounded MiscUtil.ScanCellNPCs call, at most 8 actors kept
(StorageUtil lists OBF_CombatHostile / OBF_CombatTarget). Nothing polls. At resume every actor is re-checked (alive, loaded, target alive, not in a scene).}

int Function Cap() global
	return 8
EndFunction

Function Pause(Actor[] scene) global
	if !scene || !OBF_Log.HasPapyrusUtil()
		return
	endif
	Actor player = Game.GetPlayer()
	StorageUtil.FormListClear(None, "OBF_CombatHostile")
	StorageUtil.FormListClear(None, "OBF_CombatTarget")
	Actor[] found = MiscUtil.ScanCellNPCs(player, 2500.0, None, true)
	if !found
		return
	endif
	int kept = 0
	int i = 0
	while i < found.Length && kept < Cap()
		Actor a = found[i]
		if a && a != player && scene.Find(a) < 0 && a.IsInCombat() && !a.IsDead()
			Actor t = a.GetCombatTarget()
			if t && scene.Find(t) >= 0
				StorageUtil.FormListAdd(None, "OBF_CombatHostile", a, false)
				StorageUtil.FormListAdd(None, "OBF_CombatTarget", t, false)
				a.StopCombat()
				a.StopCombatAlarm()
				kept += 1
			endif
		endif
		i += 1
	endwhile
	OBF_Log.Line("OBF", "combat pause: " + kept + " fighter(s) stood down for the scene")
EndFunction

Function Resume() global
	if !OBF_Log.HasPapyrusUtil()
		return
	endif
	int n = StorageUtil.FormListCount(None, "OBF_CombatHostile")
	int back = 0
	int i = 0
	while i < n
		Actor a = StorageUtil.FormListGet(None, "OBF_CombatHostile", i) as Actor
		Actor t = StorageUtil.FormListGet(None, "OBF_CombatTarget", i) as Actor
		if a && t && !a.IsDead() && !t.IsDead() && a.Is3DLoaded() && t.Is3DLoaded() && !a.IsDisabled() && !a.IsDeleted() && !OActor.IsInOStim(a) && !OActor.IsInOStim(t)
			a.StartCombat(t)
			back += 1
		endif
		i += 1
	endwhile
	StorageUtil.FormListClear(None, "OBF_CombatHostile")
	StorageUtil.FormListClear(None, "OBF_CombatTarget")
	if n > 0
		OBF_Log.Line("OBF", "combat pause: " + back + " of " + n + " fighter(s) resumed")
	endif
EndFunction

; game load: a save made mid-scene must not keep stale entries
Function Reset() global
	if OBF_Log.HasPapyrusUtil()
		StorageUtil.FormListClear(None, "OBF_CombatHostile")
		StorageUtil.FormListClear(None, "OBF_CombatTarget")
	endif
EndFunction
