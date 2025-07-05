--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Math = require(ReplicatedStorage.Modules.Shared.Utility.Math)
local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Network = require(Shared.Network)
local Characters = require(Database.Characters)
local Enemies = require(Database.Enemies)
local Gears = require(Database.Gears)
local GameEnum = require(Shared.GameEnum)
local Agents = require(script.Parent.Agents)

--
local _ReplicatePlayerToo = false
local Replicator = {}

--[[
	@return AgentId
	@return ReplicationId
]]
local function GetPlayerIds(Agent: AgentTypes.ServerAgentClass): (number, number)
	local Player = Agent.__Player_Assigned
	local RepId = Player:GetAttribute("ReplicationId") :: number
	local AgentId = Agents:GetIdForPlayer(RepId, Agent) :: number

	return AgentId, RepId
end

function Replicator:Effect(Name: string, Data: {}, Targets: boolean | {})
	local BufferObject = buffer.create(1 + #Name)
	buffer.writeu8(BufferObject, 0, GameEnum.Replication.PlayVisualEffect)
	buffer.writestring(BufferObject, 1, Name)

	for Key, Value in Data do
		if tostring(Value) == 'ServerAgentClass' then
			local PlayerId = Value.__Player_Assigned:GetAttribute('ReplicationId')
			local AgentId = Agents:GetIdForPlayer(PlayerId, Value)

			local NewValue = buffer.create(2)
			buffer.writeu8(NewValue, 0, AgentId)
			buffer.writeu8(NewValue, 1, PlayerId)

			Data[Key] = NewValue
		end
	end

	if Targets == true then
		Network:FireForAll('ReliableReplication', BufferObject, table.unpack(Data))
	elseif typeof(Targets) == 'table' then
		for _, Target in Targets do
			Network:Fire('ReliableReplication', Target, BufferObject, table.unpack(Data))
		end
	end
end

function Replicator:AddAgent(Player: Player, AgentClass: AgentTypes.ServerAgentClass, Target: Player?, At: CFrame?)
	--print(Table:printTable(AgentClass))
	local Object = buffer.create(6)
	buffer.writeu8(Object, 0, GameEnum.Replication.AddAgent)
	buffer.writeu8(Object, 1, Characters:GetIdForCharacter(AgentClass.Name))
	buffer.writeu8(Object, 2, Player:GetAttribute("ReplicationId") :: number)

	if Target then
		Network:Fire('Replicate', Target, Object, At)
	else
		Network:FireForAll('Replicate', Object)
	end
end

function Replicator:RemoveAgent(Player: Player, Name: string)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.RemoveAgent)
	buffer.writeu8(Object, 1, Characters:GetIdForCharacter(Name))
	buffer.writeu8(Object, 2, Player:GetAttribute("ReplicationId") :: number)

	Network:FireForAll('Replicate', Object)
end

function Replicator:Move(Player: Player, Target: Player?)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.Move)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)


	if Target then
		Network:Fire('Replicate', Target, Object)
	else
		Network:FireForAllBut(Player, 'Replicate', Object)
	end
end

function Replicator:PivotTo(Player: Player, At: CFrame, Target: Player?)
	local Object = buffer.create(12)
	buffer.writeu8(Object, 0, GameEnum.Replication.PivotTo)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)
	buffer.writef32(Object, 2, At.X)
	buffer.writef32(Object, 6, At.Z)
	buffer.writei16(Object, 10, At.Y * 100)

	if Target then
		Network:Fire('Replicate', Target, Object, At)
	else
		Network:FireForAllBut(Player, 'Replicate', Object, At)
	end
end

function Replicator:Stop(Player: Player)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.Stop)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)

	Network:FireForAllBut(Player, 'Replicate', Object)
end

function Replicator:Rotate(Player: Player, Direction: Vector3, Target: Player?)
	local Angle = math.deg(math.atan2(Direction.X, Direction.Z))

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.Rotate)
	buffer.writei16(Object, 1, Angle * 180)
	buffer.writeu8(Object, 3,  Player:GetAttribute("ReplicationId") :: number)

	if Target then
		Network:Fire('Replicate', Target, Object)
	else
		Network:FireForAllBut(Player, 'Replicate', Object)
	end
end

function Replicator:KeySwitch(Player: Player, Key: string, Value: boolean, Target: Player?)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.KeySwitch)
	buffer.writeu8(Object, 1, GameEnum.Agent_Keys[Key])
	buffer.writeu8(Object, 2,  Player:GetAttribute("ReplicationId") :: number)

	if Target then
		Network:Fire('Replicate', Target, Object, Value)
	else
		Network:FireForAllBut(Player, 'Replicate', Object, Value)
	end
end

function Replicator:UpdateMeter(Agent: AgentTypes.ServerAgentClass, MeterId: number, Amount: number)
	local Player = Agent.__Player_Assigned
	local PlayerRepId = Player:GetAttribute("ReplicationId") :: number
	local Id = Agents:GetIdForPlayer(PlayerRepId, Agent) :: number

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.FillMeter)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu8(Object, 2, MeterId)
	buffer.writeu8(Object, 3, math.ceil(Amount * 255))

	Network:Fire('Replicate', Player, Object)
end

function Replicator:SyncVelocities(Player: Player, Target: Player, ...)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.SyncVelocities)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)

	Network:Fire('Replicate', Target, Object, ...)
end

function Replicator:CharacterSwitch(Player: Player, Index: number, Direction: number, TargetId: number)
	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.CharacterSwitch)
	Math:Encodeu2u6(Index, Direction, Object, 1)
	buffer.writeu8(Object, 2,  Player:GetAttribute("ReplicationId") :: number)
	buffer.writeu8(Object, 3, TargetId or 0)

	Network:FireForAllBut(Player, 'Replicate', Object)
end

function Replicator:SetColliderArea(Player: Player, State: boolean, Trigger)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.SetColliderArea)
	buffer.writeu8(Object, 1, State and 1 or 0)
	buffer.writeu8(Object, 2, Player:GetAttribute("ReplicationId") :: number)

	Network:FireForAll("ReliableReplication", Object, Trigger)
end

function Replicator:AddEffect(Agent: AgentTypes.ServerAgentClass, EffectParameters: AgentTypes.EffectParameters)
	local Player = Agent.__Player_Assigned
	local PlayerRepId = Player:GetAttribute("ReplicationId") :: number
	local Id = Agents:GetIdForPlayer(PlayerRepId, Agent) :: number

	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.AddEffect)
	buffer.writeu8(Object, 1,  PlayerRepId)
	buffer.writei8(Object, 2, Id)

	Network:FireForAll('Replicate', Object, EffectParameters)
end

function Replicator:RemoveEffect(Agent: AgentTypes.ServerAgentClass, EffectId: number)
	local Player = Agent.__Player_Assigned
	local PlayerRepId = Player:GetAttribute("ReplicationId") :: number
	local Id = Agents:GetIdForPlayer(PlayerRepId, Agent) :: number

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.RemoveEffect)
	buffer.writeu8(Object, 1, PlayerRepId)
	buffer.writei8(Object, 2, Id)
	buffer.writeu8(Object, 3, EffectId)

	Network:FireForAll('Replicate', Object)
end

function Replicator:AddEnemy(Id: number, Enemy: Types.ServerEnemyClass, Target: Player?)
	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.AddEnemy)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu8(Object, 2, Enemies:GetIdForEnemy(Enemy.__Name))
	buffer.writeu8(Object, 3, Enemy.__Status.__Level)

	if not Target then
		Network:FireForAll('Replicate', Object, Enemy:GetPivot().Position)
	else
		Network:Fire('Replicate', Target, Object, Enemy:GetPivot().Position)
	end
end

function Replicator:PivotEnemy(Id: number, At: Vector3 | CFrame, TargetPlayer: Player?)
	local Object = buffer.create(12)
	buffer.writeu8(Object, 0, GameEnum.Replication.PivotEnemy)
	buffer.writeu8(Object, 1, Id)
	buffer.writef32(Object, 2, At.X)
	buffer.writef32(Object, 6, At.Z)
	buffer.writei16(Object, 10, At.Y * 100)

	if TargetPlayer then
		Network:Fire('Replicate', TargetPlayer, Object)
		return
	end

	Network:FireForAll('Replicate', Object)
end


function Replicator:MoveEnemy(Id: number, Direction: Vector3, TargetPlayer: Player?)
	--local Angle = math.deg(math.atan2(Direction.X, Direction.Z))

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.MoveEnemy)
	buffer.writeu8(Object, 1, Id)
	buffer.writei8(Object, 2, Direction.X * 100)
	buffer.writei8(Object, 3, Direction.Z * 100)

	if TargetPlayer then
		Network:Fire('Replicate', TargetPlayer, Object)
		return
	end

	Network:FireForAll('Replicate', Object)
end

function Replicator:RotateEnemy(Id: number, Target: AgentTypes.ServerAgentClass | Vector3, TargetPlayer: Player?)
	local At = (typeof(Target) == 'Vector3' and Target) or (Target :: AgentTypes.ServerAgentClass):GetPivot()
	local Object = buffer.create(10)
	buffer.writeu8(Object, 0, GameEnum.Replication.RotateEnemy)
	buffer.writeu8(Object, 1, Id)
	buffer.writef32(Object, 2, At.X)
	buffer.writef32(Object, 6, At.Z)

	if TargetPlayer then
		Network:Fire('Replicate', TargetPlayer, Object)
		return
	end

	Network:FireForAll('Replicate', Object)
end

function Replicator:RemoveEnemy(Key: number)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.RemoveEnemy)
	buffer.writeu8(Object, 1, Key)

	Network:FireForAll('Replicate', Object)
end

function Replicator:EnemyUseSkill(EnemyId: number, SkillId: number, State: string)
	local Object = buffer.create(8)
	buffer.writeu8(Object, 0, GameEnum.Replication.EnemyUseSkill)
	buffer.writeu8(Object, 1, SkillId)
	buffer.writeu8(Object, 2, EnemyId)
	buffer.writeu8(Object, 3, State == 'Begin' and 1 or 0)

	Network:FireForAll('Replicate', Object)
end

function Replicator:ProcessDodge(Agent: AgentTypes.ServerAgentClass)
	local Player = Agent.__Player_Assigned
	local Id: number = Player:GetAttribute('ReplicationId')
	local AgentId = Agents:GetIdForPlayer(Id, Agent)

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.ProcessDodge)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu8(Object, 2, AgentId)

	Network:FireForAll('Replicate', Object)
end

function Replicator:UseSkill(Player: Player, SkillId: number, IncludePlayer: boolean, EnemyNumber: number, StateId: number)
	local Object = buffer.create(8)
	buffer.writeu8(Object, 0, GameEnum.Replication.UseSkill)
	buffer.writeu8(Object, 1, SkillId)
	buffer.writeu8(Object, 2, EnemyNumber or 255)
	buffer.writeu8(Object, 3, StateId)
	buffer.writeu8(Object, 4,  Player:GetAttribute("ReplicationId") :: number)

	if IncludePlayer then
		Network:FireForAll('Replicate', Object)
	else
		Network:FireForAllBut(Player, 'Replicate', Object)
	end

end

function Replicator:ClearPlayerData(Player: Player)
	local Object = buffer.create(2)

	buffer.writeu8(Object, 0, GameEnum.Replication.ClearPlayerData)
	buffer.writeu8(Object, 1, Player:GetAttribute("ReplicationId") :: number)

	Network:FireForAll("Replicate", Object)
end

function Replicator:UpdateCurrentEnergy(Player: Player, Agent: AgentTypes.ServerAgentClass)
	local Object = buffer.create(4)
	local Energy = Agent.__Status:GetEnergy()

	local Id = Agents:GetIdForPlayer(Player:GetAttribute("ReplicationId") :: number, Agent) :: number

	--
	buffer.writeu8(Object, 0, GameEnum.Replication.UpdateEnergy)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu16(Object, 2, math.floor(Energy * 600))

	Network:Fire("Replicate", Player, Object)
end

function Replicator:UpdateUltBar(Player: Player, Agent: AgentTypes.ServerAgentClass)
	local Object = buffer.create(4)
	local UltBar = Agent.__Status:GetUltimate()

	local Id = Agents:GetIdForPlayer(Player:GetAttribute("ReplicationId") :: number, Agent) :: number

	--
	buffer.writeu8(Object, 0, GameEnum.Replication.UpdateUltBar)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu16(Object, 2, math.floor(UltBar * 600))

	Network:Fire("Replicate", Player, Object)
end

function Replicator:DisplayDamage(Enemy: Types.ServerEnemyClass, Damage: number, Critical: boolean?, Affliction: string, Burst: boolean?)
	local Object = buffer.create(9)
	buffer.writeu8(Object, 0, GameEnum.Replication.DisplayDamage)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, GameEnum.Afflictions[Affliction] or GameEnum.Afflictions.Default)
	buffer.writeu8(Object, 3, Critical and 1 or 0)
	buffer.writeu8(Object, 4, Burst and 1 or 0)
	buffer.writef32(Object, 5, Damage)

	Network:FireForAll('Replicate', Object)
end

function Replicator:PromptAssist(Player: Player, Agent: AgentTypes.ServerAgentClass, Time: number, EnemyTarget: number)
	local RepId = Player:GetAttribute("ReplicationId") :: number
	local Id = Agents:GetIdForPlayer(RepId, Agent) :: number

	--
	local Object = buffer.create(4)

	buffer.writeu8(Object, 0, GameEnum.Replication.PromptAssist)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu8(Object, 2, math.floor(Time * 10))
	buffer.writeu8(Object, 3, EnemyTarget)

	Network:Fire("Replicate", Player, Object)
end

function Replicator:Knockback(Enemy: Types.ServerEnemyClass, Direction: Vector3, Power: number, Time: number)

	local Object = buffer.create(5)
	buffer.writeu8(Object, 0, GameEnum.Replication.Knockback)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, GameEnum.Knockback_Directions[Direction])
	buffer.writeu8(Object, 3, Power)
	buffer.writeu8(Object, 4, math.floor(Time * 10))

	Network:FireForAll('Replicate', Object)
end

function Replicator:DamageAgent(Agent: AgentTypes.ServerAgentClass, Damage: number)
	local RepId = Agent.__Player_Assigned:GetAttribute("ReplicationId")
	local AgentIndex = table.find(Agents:GetAll(RepId), Agent)

	local Object = buffer.create(7)
	buffer.writeu8(Object, 0, GameEnum.Replication.DamageAgent)
	buffer.writeu8(Object, 1, AgentIndex)
	buffer.writeu8(Object, 2, RepId)
	buffer.writef32(Object, 3, Damage)

	Network:FireForAll('Replicate', Object)
end

function Replicator:KillAgent(Agent: AgentTypes.ServerAgentClass, Damage: number)
	local RepId = Agent.__Player_Assigned:GetAttribute("ReplicationId")
	local AgentIndex = table.find(Agents:GetAll(RepId), Agent)

	local Object = buffer.create(7)
	buffer.writeu8(Object, 0, GameEnum.Replication.KillAgent)
	buffer.writeu8(Object, 1, AgentIndex)
	buffer.writeu8(Object, 2, RepId)
	buffer.writef32(Object, 3, Damage)

	Network:FireForAll('Replicate', Object)
end

function Replicator:HitAgent(Agent: AgentTypes.ServerAgentClass, Time: number)
	local RepId = Agent.__Player_Assigned:GetAttribute("ReplicationId")
	local AgentIndex = table.find(Agents:GetAll(RepId), Agent)

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.HitAgent)
	buffer.writeu8(Object, 1, AgentIndex)
	buffer.writeu8(Object, 2, RepId)
	buffer.writeu8(Object, 3, Time * 10)

	Network:FireForAll('Replicate', Object)
end


function Replicator:FillAffliction(Enemy: Types.ServerEnemyClass, Type: Types.Element | string, Amount: number)
	local Object = buffer.create(5)
	buffer.writeu8(Object, 0, GameEnum.Replication.FillAffliction)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, GameEnum.Afflictions[Type])
	buffer.writei16(Object, 3, Amount * 500)

	Network:FireForAll('Replicate', Object)
end


function Replicator:ResetAffliction(Enemy: Types.ServerEnemyClass, Type: Types.Element)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.ResetAffliction)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, GameEnum.Afflictions[Type])

	Network:FireForAll('Replicate', Object)
end

function Replicator:DazeEnemy(Enemy: Types.ServerEnemyClass, Daze: number)
	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.DazeEnemy)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu16(Object, 2, Daze * 325)

	Network:FireForAll('Replicate', Object)
end

function Replicator:EnterDaze(Enemy: Types.ServerEnemyClass)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.EnterDaze)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)

	Network:FireForAll('Replicate', Object)
end

function Replicator:SwitchStateEnemy(EnemyId: number, State: string, Time: number)
	local Object = buffer.create(5)
	buffer.writeu8(Object, 0, GameEnum.Replication.StateSwitchEnemy)
	buffer.writeu8(Object, 1, EnemyId)
	buffer.writeu8(Object, 2, table.find(GameEnum.Agent_States, State) :: number)
	buffer.writeu16(Object, 3, Time * 100)

	Network:FireForAll('Replicate', Object)
end


function Replicator:AddGear(Agent: AgentTypes.ServerAgentClass, GearName: string)
	local GearId = Gears:GetIdFor(GearName)
	local AgentId, RepId = GetPlayerIds(Agent)

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.AddGear)
	buffer.writeu8(Object, 1, RepId)
	buffer.writeu8(Object, 2, AgentId)
	buffer.writeu8(Object, 3, GearId)

	Network:FireForAll('Replicate', Object)
end

function Replicator:RemoveGear(Agent: AgentTypes.ServerAgentClass, GearName: string)
	local GearId = Gears:GetIdFor(GearName)
	local AgentId, RepId = GetPlayerIds(Agent)

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.RemoveGear)
	buffer.writeu8(Object, 1, RepId)
	buffer.writeu8(Object, 2, AgentId)
	buffer.writeu8(Object, 3, GearId)

	Network:FireForAll('Replicate', Object)
end

function Replicator:SetEnemySpeed(EnemyId: number, Speed: number, Time: number?)
	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.SetEnemySpeed)
	buffer.writeu8(Object, 1, EnemyId)
	buffer.writeu8(Object, 2, Speed * 100)
	buffer.writeu8(Object, 3, (Time or 0) * 10)

	Network:FireForAll('Replicate', Object)
end

return Replicator
