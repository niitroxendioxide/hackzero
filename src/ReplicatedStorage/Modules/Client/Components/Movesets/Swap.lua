--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players  = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Characters = require(ReplicatedStorage.Modules.Shared.Database.Characters)
local AbilityClass = require(Client.Classes.Ability)
local Types = require(Shared.Types.Agents)
local GameEnum = require(Shared.GameEnum)

local CharacterLibrary = require(Client.Libraries.Characters)
local Replicator = require(Client.Libraries.Replicator)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass, Key: string)
	local Direction = Key == 'Swap Back' and -1 or Key == 'Swap Forth' and 1 or 0
	if Direction == 0 then return end

	local Plr = Players.LocalPlayer
	local Localplr = Plr:GetAttribute("ReplicationId")
	local TargetId = Direction == 1 and CharacterLibrary:GetCharacterTarget(Plr) or nil

	local SuccessSwitching, NewIndex = CharacterLibrary:Switch(Localplr, Direction, TargetId)
	if not SuccessSwitching then
		return
	end

	if TargetId then
		self:Effect("Switch")
	end

	local NewAgent = CharacterLibrary:GetCurrent(Localplr)
	if TargetId then
		local MovesetData = Characters:GetMovesetData(NewAgent.Name)
		local QuickAssist = MovesetData["Quick Assist"] or {Base = {Attack_State_Time = 1}}

		NewAgent:AddTag('Switching', QuickAssist.Base.Attack_State_Time or 1)
	end

	Replicator:Replicate(GameEnum.Replication.CharacterSwitch, NewIndex, Direction, NewAgent:GetRotation())
end

return Ability
