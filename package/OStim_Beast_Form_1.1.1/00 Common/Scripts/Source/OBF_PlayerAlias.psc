Scriptname OBF_PlayerAlias extends ReferenceAlias

; New quest/new game and each save reload (including upgrades from 0.1).
Event OnInit()
    OBF_OCRCompat.RestoreKeywords()
EndEvent

Event OnPlayerLoadGame()
    OBF_OCRCompat.RestoreKeywords()
    (GetOwningQuest() as OBF_Main).Maintenance()
EndEvent

; 1.1.0: after a transformation the beast body is in place; one read-only female-body / bone check (OBF_BodyCheck)
Event OnRaceSwitchComplete()
    OBF_Main m = GetOwningQuest() as OBF_Main
    if m
        m.RaceSwitched()
    endif
EndEvent
