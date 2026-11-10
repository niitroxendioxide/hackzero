--[[
	Namekian villager, an ally to protect: spawned by a mission event's `Allies` list (or a
	posed scene model, see SceneService). In the fight it runs for a corner, flees somewhere
	safer whenever it is hit, and the run is lost if it goes down.
]]
return {
	Display_Name = 'Namekian',
	Model = 'Namekian',
	Ally = true,

	Stats = {
		Shield = 6,
		Run_Speed = 32,
		Shield_Regen_Rate = 0,

		--- Enemies only go for it when nobody is much closer.
		Aggro_Weight = 3,
	},

	On_Defeat = {
		Fail_Mission = true,
	},
}
