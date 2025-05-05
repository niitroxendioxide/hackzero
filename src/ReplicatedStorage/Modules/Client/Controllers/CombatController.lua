--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Inputs = require(Client.Libraries.Inputs)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local Places = require(Shared.Places)
--local Replicator = require(Client.Libraries.Replicator)

--local GameEnum = require(Shared.GameEnum)

--
local Controller = {
	__Abilities = {"Basic_Attack", "Dodge", "Swap_Forth", "Swap_Back", "Ultimate"},
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
				local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
				local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))
				local CurrentAgent = Characters:GetCurrent(UserId)

				if CurrentAgent == nil then
					print("Input rejected. Character is null")
					return
				end

				--print("Pre-ability", State, Key, CharacterMoveset)
				if State == 'Begin' then
					CharacterMoveset:Begin(Key, CurrentAgent)
				else
					CharacterMoveset:Release(Key, CurrentAgent)
				end

				if Key == 'Dodge' then
					for _, Character in Characters:GetCharacters(UserId) do
						Character:SetKey('Sprint', true)
						Character:SetKey('Jog', true)
					end
				end
			end,
		})
	end
end

return Controller