--[[
	Namekian villager, an ally to protect: spawned by a mission event's `Allies` list, it
	shuffles around near where it spawned and the run is lost if it goes down.
]]
return {
	Display_Name = 'Namekian',
	Model = 'Namekian',
	Ally = true,

	Stats = {
		Shield = 6,
		Walk_Speed = 6,
		Shield_Regen_Rate = 0,

		--- Enemies only go for it when nobody is much closer.
		Aggro_Weight = 3,
	},

	On_Defeat = {
		Fail_Mission = true,
	},
}
