Scriptname OBFHerm_PlayerAlias extends ReferenceAlias
{Player events for the TWO Herm Patch. Forwards transform, load, and herm-toggle to the quest.}

Event OnPlayerLoadGame()
	(GetOwningQuest() as OBFHerm_Main).Setup()
EndEvent

Event OnRaceSwitchComplete()
	(GetOwningQuest() as OBFHerm_Main).SyncConditionSoon()
EndEvent

Event OnSpellCast(Form akSpell)
	(GetOwningQuest() as OBFHerm_Main).OnToggleMaybe(akSpell)
EndEvent

Event OnMagicEffectApply(ObjectReference akCaster, MagicEffect akEffect)
	(GetOwningQuest() as OBFHerm_Main).OnToggleMaybe(akEffect)
EndEvent
