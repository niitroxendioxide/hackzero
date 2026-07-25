--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Characters = require(ReplicatedStorage.Modules.Client.Libraries.Characters)
local Enemies = require(Shared.Libraries.Enemies)
local EnemyDatabase = require(Shared.Database.Enemies)
local EnemyClass = require(Client.Classes.Enemy)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Client.Libraries.Effects)

--
local Controller = {}

function Controller:AddEnemy(Buffer: buffer, At: Vector3, Buffs: { {string | number} })
	local EnemyId = buffer.readu8(Buffer, 1)
	local EnemyNameId = buffer.readu8(Buffer, 2)
	local Level = buffer.readu8(Buffer, 3)

	local Name = EnemyDatabase:GetEnemyFromId(EnemyNameId)
	if not Name then return end

	if Enemies:GetEnemy(EnemyId) ~= nil then
		Controller:RemoveEnemy(Buffer)
	end


	---
	local NewEnemy = EnemyClass.new(At, Name, Level)
	NewEnemy:Init(EnemyId)

	if typeof(Buffs) == 'table' then
		for _, Buff in Buffs do
			NewEnemy:AddEffect({
				Type = Buff[1], 
				Value = Buff[2],
				Time = -1,
			})
		end
	end

	Effects:Play('EnemyStats', NewEnemy)
	Enemies:AddEnemy(EnemyId, NewEnemy)
end

function Controller:RemoveEnemy(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)

	local Enemy = Enemies:GetEnemy(EnemyId)

	Enemies:RemoveEnemy(EnemyId)

	Effects:Play('Death', Enemy)

	Enemy:Destroy()
end

function Controller:MoveEnemy(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local X = buffer.readi8(Buffer, 2) / 100
	local Z = buffer.readi8(Buffer, 3) / 100
	local Speed = buffer.readu8(Buffer, 4)
	local Time = buffer.readu16(Buffer, 5) / 1000
	local Rebuilt = Vector3.new(X, 0, Z)

	if Time == 0 then
		Time = nil
	end

	if Speed == 0 then
		Speed = nil
	end

	local Enemy = Enemies:GetEnemy(EnemyId)
	
	if not Enemy then return end

	Enemy:Move(Rebuilt, Time , Speed)
end

function Controller:RotateEnemy(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local X = buffer.readf32(Buffer, 2)
	local Z = buffer.readf32(Buffer, 6)

	local Enemy = Enemies:GetEnemy(EnemyId)
	if not Enemy then return end

	Enemy:Rotate(Vector3.new(X, Enemy:GetPivot().Y, Z))
end

function Controller:PivotEnemy(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local X = buffer.readf32(Buffer, 2)
	local Z = buffer.readf32(Buffer, 6)
	local Y = buffer.readi16(Buffer, 10) / 100

	local Enemy = Enemies:GetEnemy(EnemyId)
	if not Enemy then return end

	Enemy:PivotTo(Vector3.new(X, Y, Z))
end

function Controller:StateSwitchEnemy(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local NewState = GameEnum.Agent_States[buffer.readu8(Buffer, 2)]
	local Time = buffer.readu16(Buffer, 3) / 100

	local Enemy = Enemies:GetEnemy(EnemyId)
	if not Enemy then
		return
	end

	Enemy:SwitchState(NewState, Time)
end

function Controller:EnterDaze(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)

	local Enemy = Enemies:GetEnemy(EnemyId)
	if not Enemy then return end

	if Enemy.__Status.__Daze <= 0 then
		Enemy.__Status:Daze(Enemy.__Status.__Max_Daze)
	end

	Enemy:EnterDazedState()
end

function Controller:BeginGrabEnemy(Buffer: buffer, Offset: CFrame)
    local EnemyId = buffer.readu8(Buffer, 1) -- EnemyId
    local PlayerRepId = buffer.readu8(Buffer, 2) -- PlayerReplicationId
    local AgentId = buffer.readu8(Buffer, 3) -- AgentRelativeId

	local EnemyObject = Enemies:GetEnemy(EnemyId)
	local BaseAgent = Characters:GetAgent(PlayerRepId, AgentId)

	if not EnemyObject or not BaseAgent then
		return;
	end

	EnemyObject:FollowAgentGrab(BaseAgent, Offset or CFrame.new())
end

function Controller:EndGrabEnemy(Buffer)
	local EnemyId = buffer.readu8(Buffer, 1) -- EnemyId
    local PlayerRepId = buffer.readu8(Buffer, 2) -- PlayerReplicationId
    local AgentId = buffer.readu8(Buffer, 3) -- AgentRelativeId

	local EnemyObject = Enemies:GetEnemy(EnemyId)
	local BaseAgent = Characters:GetAgent(PlayerRepId, AgentId)

	if not EnemyObject or not BaseAgent then
		return;
	end
	
	EnemyObject:FollowAgentGrab(nil)
end

return Controller
