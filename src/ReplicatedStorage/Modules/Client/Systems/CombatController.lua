--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
--local Shared = ReplicatedStorage.Modules.Shared

local Inputs = require(Client.Libraries.Inputs)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
--local Replicator = require(Client.Libraries.Replicator)

--local GameEnum = require(Shared.GameEnum)

--
local Controller = {
	__Abilities = {"Basic_Attack", "Dodge", "Swap_Forth", "Swap_Back", "Ultimate"},
}

function Controller:Init()
	
	Movesets:Init()
	
	for _, Key in Controller.__Abilities do
		Inputs:Bind(Key, {
			Release = true,
			Callback = function(State: 'Begin' | 'End')
				local UserId = Players.LocalPlayer.UserId
				local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))

				if State == 'Begin' then
					CharacterMoveset:Begin(Key, Characters:GetCurrent(UserId))
				else
					CharacterMoveset:Release(Key, Characters:GetCurrent(UserId))
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