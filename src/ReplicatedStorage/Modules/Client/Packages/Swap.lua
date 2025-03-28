--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players  = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local AbilityClass = require(Client.Classes.Ability)
local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)

local CharacterLibrary = require(Client.Libraries.Characters)
local Replicator = require(Client.Libraries.Replicator)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass, Key: string)
	local Direction = Key == 'Swap Back' and -1 or Key == 'Swap Forth' and 1 or 0
	if Direction == 0 then return end
	
	CharacterLibrary:Switch(Players.LocalPlayer.UserId, -1)

	Replicator:Replicate(GameEnum.Replication.CharacterSwitch, -1)
end

return Ability
