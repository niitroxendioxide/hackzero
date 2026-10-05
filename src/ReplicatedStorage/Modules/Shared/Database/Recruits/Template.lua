--[[
	Defaults for every recruit. Other modules in this folder only declare what differs, and a
	mission's overrides (`RecruitService:Create(Name, Owner, At, Overrides)`) go on top.
]]
return {
	Display_Name = 'Civilian',

	--- Model under `Assets.Characters.Recruits`, falls back to the shared Template rig.
	Model = 'Template',

	Appearance = {
		Height = 3.15,
	},

	Stats = {
		--- Counted in hits, not damage: every hit takes `Shield_Hits` off it (1 unless the attack is flagged).
		Shield = 5,

		--- Studs per second it walks at. Agents jog at 20-25.
		Walk_Speed = 20,

		--- Shield regained per second while out of combat.
		Shield_Regen_Rate = 0.25,

		--- Seconds out of combat, and since the last hit, before the shield starts coming back.
		Shield_Regen_Delay = 4,

		--- Seconds a hit leaves it immune to more hits, so a barrage only lands once.
		Hit_Invulnerability = 0.6,

		--- Seconds it stops in place after being hit.
		Flinch_Time = 0.35,

		--- Enemies see it this many times farther away than it is when picking a target, so the
		--- players draw aggro first. 1 is "same as an agent".
		Aggro_Weight = 1.5,
	},

	Follow = {
		--- Holds still while whoever it follows is this close.
		Distance = 7,

		--- Spacing between the points of the trail it walks behind whoever it follows.
		Crumb_Spacing = 2,

		--- Past this distance from whoever it follows (or from its hiding spot) it teleports back.
		Leash = 80,

		--- Seconds of trying to walk without getting anywhere before it teleports back.
		Stuck_Time = 2,
	},

	Combat = {
		--- How far in from the arena walls the corner it hides in sits.
		Corner_Inset = 6,
	},

	On_Defeat = {
		--- Ends the run as a loss. The Escort mission turns this on for its escort.
		Fail_Mission = false,

		--- Written to the mission state, same rules as a destructible's (a `"Key+"` key adds).
		SetValues = nil,
	},
}
