--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Inputs = require(Client.Libraries.Inputs)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local Places = require(Shared.Places)
local InterfaceController = require(Client.Controllers.InterfaceController)
--local Replicator = require(Client.Libraries.Replicator)

--local GameEnum = require(Shared.GameEnum)

--
local Controller = {
	__Abilities = {"Basic_Attack", "Dodge", "Swap_Forth", "Swap_Back", "Ultimate", "Special"},
}

function Controller:Init()
	if not Places:CanFight() then
		return;
	end

	Movesets:Init()

	for _, Key in Controller.__Abilities do
		Inputs:Bind(Key, {
			Release = true,
			Callback = function(State: 'Begin' | 'End')
				Controller:HandleInput(Key, State)
			end,
		})
	end
end

function Controller:HandleInput(Key: string, State: string)
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))
	local CurrentAgent = Characters:GetCurrent(UserId)

	if CurrentAgent == nil then
		return
	end

	--print("Pre-ability", State, Key, CharacterMoveset)
	local Success;
	if State == 'Begin' then
		Success = CharacterMoveset:Begin(Key, CurrentAgent)
	else
		Success = CharacterMoveset:Release(Key, CurrentAgent)
	end

	--
	if Success then
		local SkillInfo = CharacterMoveset:GetInfoForSkill(Key)

		if SkillInfo.Base and SkillInfo.Base.Cooldown then
			local Moveset = InterfaceController:GetComponent("Moveset")

			Moveset:PlayCooldown(Key, SkillInfo.Base.Cooldown)
		end
	end

	if Key == 'Dodge' then
		for _, Character in Characters:GetCharacters(UserId) do
			Character:SetKey('Sprint', true)
			Character:SetKey('Jog', true)
		end
	end
end

return Controller