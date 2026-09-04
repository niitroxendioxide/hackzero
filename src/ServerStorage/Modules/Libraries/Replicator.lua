--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Ping = require(ServerStorage.Modules.Libraries.Ping)
local Companions = require(Shared.Types.Companions)
local CompanionsDatabase = require(Shared.Database.Companions)
local Math = require(ReplicatedStorage.Modules.Shared.Utility.Math)
local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Network = require(Shared.Network)
local Characters = require(Database.Characters)
local Enemies = require(Database.Enemies)
local Gears = require(Database.Gears)
local GameEnum = require(Shared.GameEnum)
local Agents = require(script.Parent.Agents)
local EffectSerdes = require(Shared.Libraries.EffectSerdes)

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

function Replicator:AddTag(Agent: AgentTypes.ServerAgentClass, Tag: string, Time: number)
	local AgentId, PlrId = GetPlayerIds(Agent)

	local Buffer = buffer.create(5)
	buffer.writeu8(Buffer, 0, GameEnum.Replication.AddTag)
	buffer.writeu8(Buffer, 1, PlrId)
	buffer.writeu8(Buffer, 2, AgentId)
	buffer.writeu16(Buffer, 3, math.clamp((Time or 0) * 100, 0, 65535))

	Network:FireForAll("Replicate", Buffer, Tag)
end

function Replicator:RemoveTag(Agent: AgentTypes.ServerAgentClass, Tag: string)
	local AgentId, PlrId = GetPlayerIds(Agent)

	local Buffer = buffer.create(3)
	buffer.writeu8(Buffer, 0, GameEnum.Replication.RemoveTag)
	buffer.writeu8(Buffer, 1, PlrId)
	buffer.writeu8(Buffer, 2, AgentId)

	Network:FireForAll("Replicate", Buffer, Tag)
end

function Replicator:Effect(Name: string, Data: {}, Targets: boolean | {})
	local EffectIdBits = EffectSerdes:ForName(Name)
	if (EffectIdBits == nil) then
		Debugger:WarnLine("Replicator::Effect", `Packet not fired, effect id null for "{Name}"`, 1)

		return;
	end

	local BufferObject = buffer.create(1 + EffectSerdes.IdByteSize)
	buffer.writeu8(BufferObject, 0, GameEnum.Replication.PlayVisualEffect)
	buffer.writebits(BufferObject, 8, EffectSerdes.IdByteSize * 8, EffectIdBits)

	for Key, Value in Data do
		if tostring(Value):match('ServerAgentClass') then
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

function Replicator:AddAgent(Player: Player, AgentClass: AgentTypes.ServerAgentClass, Target: Player?, At: CFrame?, OverrideArtifacts: {}?)
	--print(Table:printTable(AgentClass))
	local Object = buffer.create(6)
	buffer.writeu8(Object, 0, GameEnum.Replication.AddAgent)
	buffer.writeu8(Object, 1, Characters:GetIdForCharacter(AgentClass.Name))
	buffer.writeu8(Object, 2, Player:GetAttribute("ReplicationId") :: number)
	buffer.writeu8(Object, 3, AgentClass.__Level or 1)

	if Target then
		Network:Fire('Replicate', Target, Object, At, OverrideArtifacts)
	else
		Network:FireForAll('Replicate', Object, At, OverrideArtifacts)
	end
end

function Replicator:RemoveAgent(Player: Player, Name: string)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.RemoveAgent)
	buffer.writeu8(Object, 1, Characters:GetIdForCharacter(Name))
	buffer.writeu8(Object, 2, Player:GetAttribute("ReplicationId") :: number)

	Network:FireForAll('Replicate', Object)
end

--[[
	Move and Stop are the same 3 byte packet with the Moving bit flipped. The
	movement byte names the agent and carries its speed keys, so a receiver
	applies it to the agent the sender meant rather than to whichever agent it
	currently believes is active.
]]
function Replicator:Move(Player: Player, MovementByte: number, Target: Player?)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.Move)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)
	buffer.writeu8(Object, 2, MovementByte)

	if Target then
		Network:Fire('ReliableReplication', Target, Object)
	else
		Network:FireForAllBut(Player, 'ReliableReplication', Object)
	end
end

function Replicator:PivotTo(Agent: AgentTypes.ServerAgentClass, At: CFrame, Target: Player?)
	local Player = Agent.__Player_Assigned;
	local RepId = Player:GetAttribute("ReplicationId")
	local AgentId = Agents:GetIdForPlayer(RepId, Agent)

	local PlayerPing = math.floor(Ping:Get(Player) * 1000)

	local Object = buffer.create(17)
	buffer.writeu8(Object, 0, GameEnum.Replication.PivotTo)
	buffer.writeu8(Object, 1, RepId :: number)
	buffer.writeu8(Object, 2, AgentId)
	Math:EncodeCFrame(At, Object, 3)
	buffer.writeu16(Object, 15, PlayerPing)

	if Target then
		Network:Fire('Replicate', Target, Object)
	else
		Network:FireForAllBut(Player, 'Replicate', Object)
	end
end

function Replicator:Stop(Player: Player, MovementByte: number, Target: Player?)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.Stop)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)
	buffer.writeu8(Object, 2, MovementByte)

	if Target then
		Network:Fire('ReliableReplication', Target, Object)
	else
		Network:FireForAllBut(Player, 'ReliableReplication', Object)
	end
end

function Replicator:Rotate(Player: Player, AgentId: number, Direction: Vector3, Target: Player?)
	local Angle = math.deg(math.atan2(Direction.X, Direction.Z))

	local Object = buffer.create(5)
	buffer.writeu8(Object, 0, GameEnum.Replication.Rotate)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)
	buffer.writeu8(Object, 2, AgentId)
	buffer.writei16(Object, 3, Angle * 180)

	if Target then
		Network:Fire('ReliableReplication', Target, Object)
	else
		Network:FireForAllBut(Player, 'ReliableReplication', Object)
	end
end

function Replicator:KeySwitch(Player: Player, Key: string, Value: boolean, Target: Player?)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.KeySwitch)
	buffer.writeu8(Object, 1, GameEnum.Agent_Keys[Key] :: number)
	buffer.writeu8(Object, 2,  Player:GetAttribute("ReplicationId") :: number)

	if Target then
		Network:Fire('Replicate', Target, Object, Value)
	else
		Network:FireForAllBut(Player, 'Replicate', Object, Value)
	end
end

function Replicator:UpdateMeter(Agent: AgentTypes.ServerAgentClass, MeterId: number, Amount: number, Percent: number)
	local Player = Agent.__Player_Assigned
	local PlayerRepId = Player:GetAttribute("ReplicationId") :: number
	local Id = Agents:GetIdForPlayer(PlayerRepId, Agent) :: number

	local Object = buffer.create(9)
	buffer.writeu8(Object, 0, GameEnum.Replication.FillMeter)
	buffer.writeu8(Object, 1, PlayerRepId)
	buffer.writeu8(Object, 2, Id)
	buffer.writeu8(Object, 3, MeterId)
	buffer.writeu8(Object, 4, math.floor(Percent * 255))
	buffer.writef32(Object, 5, Amount)

	Network:FireForAll('Replicate', Object)
end

function Replicator:CreateMeter(Agent: AgentTypes.ServerAgentClass, Name: string, Data: {[any]: any})
	local Player = Agent.__Player_Assigned
	local PlayerRepId = Player:GetAttribute("ReplicationId") :: number
	local Id = Agents:GetIdForPlayer(PlayerRepId, Agent) :: number

	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.CreateMeter)
	buffer.writeu8(Object, 1, PlayerRepId)
	buffer.writeu8(Object, 2, Id)

	Network:FireForAll('Replicate', Object, Name, Data)
end

function Replicator:SyncVelocities(Player: Player, Target: Player, ...)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.SyncVelocities)
	buffer.writeu8(Object, 1,  Player:GetAttribute("ReplicationId") :: number)

	Network:Fire('Replicate', Target, Object, ...)
end

--[[
	Broadcast a resolved character switch.

	Carries the destination CFrame so receivers never have to reproduce the
	server's random draws, and goes to everyone *including* the owner: for them
	it is a correction against what they already predicted, which CorrectTo
	discards when the prediction was right.

	Reliable, because a dropped switch would leave the owner and the server
	permanently disagreeing about which agent is active.
]]
function Replicator:CharacterSwitch(Player: Player, Index: number, TargetId: number?, At: CFrame)
	local Object = buffer.create(16)
	buffer.writeu8(Object, 0, GameEnum.Replication.CharacterSwitch)
	buffer.writeu8(Object, 1, Index)
	buffer.writeu8(Object, 2,  Player:GetAttribute("ReplicationId") :: number)
	buffer.writeu8(Object, 3, TargetId or 0)
	Math:EncodeCFrame(At, Object, 4)

	Network:FireForAll('ReliableReplication', Object)
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

function Replicator:ChangeEffect(Agent: AgentTypes.ServerAgentClass, Tag: string, Amt: number, Restart: boolean?)
	local Player = Agent.__Player_Assigned
	local PlayerRepId = Player:GetAttribute("ReplicationId") :: number
	local Id = Agents:GetIdForPlayer(PlayerRepId, Agent) :: number

	local Object = buffer.create(5 + #Tag)
	buffer.writeu8(Object, 0, GameEnum.Replication.ChangeEffect)
	buffer.writeu8(Object, 1, PlayerRepId)
	buffer.writei8(Object, 2, Id)
	buffer.writei8(Object, 3, Amt)
	buffer.writeu8(Object, 4, (Restart == true) and 1 or 0)
	buffer.writestring(Object, 5, Tag, #Tag)

	Network:FireForAll('Replicate', Object)
end

function Replicator:AddEnemy(Id: number, Enemy: Types.ServerEnemyClass, Buffs: { {string | number} }, Target: Player?)
	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.AddEnemy)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu8(Object, 2, Enemies:GetIdForEnemy(Enemy.__Name))
	buffer.writeu8(Object, 3, Enemy.__Status.__Level)

	if Target == nil then
		Network:FireForAll('Replicate', Object, Enemy:GetPivot().Position, Buffs)
	else
		Network:Fire('Replicate', Target, Object, Enemy:GetPivot().Position, Buffs)
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
		Network:Fire('ReliableReplication', TargetPlayer, Object)
		return
	end

	Network:FireForAll('ReliableReplication', Object)
end


function Replicator:MoveEnemy(Id: number, Direction: Vector3 | vector, ForTime: number?, Speed: number?, TargetPlayer: Player?)
	--local Angle = math.deg(math.atan2(Direction.X, Direction.Z))

	local Object = buffer.create(7)
	buffer.writeu8(Object, 0, GameEnum.Replication.MoveEnemy)
	buffer.writeu8(Object, 1, Id)
	buffer.writei8(Object, 2, (Direction :: Vector3).X * 100)
	buffer.writei8(Object, 3, (Direction :: Vector3).Z * 100)
	buffer.writeu8(Object, 4, (Speed or 0))
	buffer.writeu16(Object, 5, (ForTime or 0) * 1000)

	if TargetPlayer then
		Network:Fire('ReliableReplication', TargetPlayer, Object)
		return
	end

	Network:FireForAll('ReliableReplication', Object)
end

function Replicator:RotateEnemy(Id: number, Target: AgentTypes.ServerAgentClass | Vector3, TargetPlayer: Player?)
	local At = (typeof(Target) == 'Vector3' and Target) or (Target :: AgentTypes.ServerAgentClass):GetPivot()
	local Object = buffer.create(10)
	buffer.writeu8(Object, 0, GameEnum.Replication.RotateEnemy)
	buffer.writeu8(Object, 1, Id)
	buffer.writef32(Object, 2, At.X)
	buffer.writef32(Object, 6, At.Z)

	if TargetPlayer then
		Network:Fire('ReliableReplication', TargetPlayer, Object)
		return
	end

	Network:FireForAll('ReliableReplication', Object)
end

function Replicator:RemoveEnemy(Key: number)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.RemoveEnemy)
	buffer.writeu8(Object, 1, Key)

	Network:FireForAll('Replicate', Object)
end

function Replicator:PromptChainAttack(Agent: AgentTypes.ServerAgentClass, Target: AgentTypes.Enemy)
	local Id: number = (Agent.__Player_Assigned :: Player):GetAttribute('ReplicationId') :: number
	local AgentId = Agents:GetIdForPlayer(Id, Agent)
	
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.ChainAttack)
	buffer.writeu8(Object, 1, AgentId)
	buffer.writeu8(Object, 2, Target:GetId())

	Network:Fire('Replicate', Agent.__Player_Assigned, Object)
end

function Replicator:EnemyUseSkill(EnemyId: number, SkillId: number, State: string, Target: AgentTypes.ServerAgentClass)
	local Id: number = (Target.__Player_Assigned :: Player):GetAttribute('ReplicationId') :: number
	local AgentId = Agents:GetIdForPlayer(Id, Target)

	local Object = buffer.create(8)
	buffer.writeu8(Object, 0, GameEnum.Replication.EnemyUseSkill)
	buffer.writeu8(Object, 1, SkillId or 0)
	buffer.writeu8(Object, 2, EnemyId or 0)
	buffer.writeu8(Object, 3, State == 'Begin' and 1 or 0)
	Math:Encodeu2u6(Id, AgentId, Object, 4)
	

	Network:FireForAll('ReliableReplication', Object)
end

function Replicator:ProcessDodge(Agent: AgentTypes.ServerAgentClass)
	local Player = Agent.__Player_Assigned
	local Id: number = Player:GetAttribute('ReplicationId')
	local AgentId = Agents:GetIdForPlayer(Id, Agent)

	local Object = buffer.create(4)
	buffer.writeu8(Object, 0, GameEnum.Replication.ProcessDodge)
	buffer.writeu8(Object, 1, Id)
	buffer.writeu8(Object, 2, AgentId)

	Network:FireForAll('ReliableReplication', Object)
end

function Replicator:UseSkill(Player: Player, SkillId: number, IncludePlayer: boolean, EnemyNumber: number, StateId: number, IsCancel: boolean, Extra: {any}?)
	local Object = buffer.create(8)
	buffer.writeu8(Object, 0, GameEnum.Replication.UseSkill)
	buffer.writeu8(Object, 1, SkillId)
	buffer.writeu8(Object, 2, EnemyNumber or 255)
	buffer.writeu8(Object, 3, StateId)
	buffer.writeu8(Object, 4,  Player:GetAttribute("ReplicationId") :: number)
	buffer.writeu8(Object, 5, IsCancel == true and 1 or 0)

	if IncludePlayer then
		Network:FireForAll('ReliableReplication', Object, Extra)
	else
		Network:FireForAllBut(Player, 'ReliableReplication', Object, Extra)
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
	local Object = buffer.create(14)
	buffer.writeu8(Object, 0, GameEnum.Replication.DisplayDamage)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, GameEnum.Afflictions[Affliction] or GameEnum.Afflictions.Default)
	buffer.writeu8(Object, 3, Critical and 1 or 0)
	buffer.writeu8(Object, 4, Burst and 1 or 0)
	buffer.writef32(Object, 5, Damage)
	buffer.writef32(Object, 9, Enemy.__Status:GetHealth())

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

function Replicator:Knockback(Enemy: Types.ServerEnemyClass, Direction: Vector3, Power: number, Time: number, WorldRelative: boolean?)

	local Object = buffer.create(5)
	buffer.writeu8(Object, 0, GameEnum.Replication.Knockback)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, Power)
	buffer.writeu8(Object, 3, math.floor(Time * 10))
	buffer.writeu8(Object, 4, WorldRelative == true and 1 or 0)

	Network:FireForAll('Replicate', Object, Direction)
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

function Replicator:HealAgent(Agent: AgentTypes.ServerAgentClass, CurrentHealth: number)
	local RepId = Agent.__Player_Assigned:GetAttribute("ReplicationId")
	local AgentIndex = table.find(Agents:GetAll(RepId), Agent)

	local Object = buffer.create(7)
	buffer.writeu8(Object, 0, GameEnum.Replication.HealAgent)
	buffer.writeu8(Object, 1, AgentIndex)
	buffer.writeu8(Object, 2, RepId)
	buffer.writef32(Object, 3, CurrentHealth)

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

function Replicator:HitAgent(Agent: AgentTypes.ServerAgentClass, Time: number, HitAnim: number)
	local RepId = Agent.__Player_Assigned:GetAttribute("ReplicationId")
	local AgentIndex = table.find(Agents:GetAll(RepId), Agent)

	local Object = buffer.create(5)
	buffer.writeu8(Object, 0, GameEnum.Replication.HitAgent)
	buffer.writeu8(Object, 1, AgentIndex)
	buffer.writeu8(Object, 2, RepId)
	buffer.writeu8(Object, 3, Time * 10)
	buffer.writeu8(Object, 4, HitAnim or 0)

	Network:FireForAll('Replicate', Object)
end


function Replicator:FillAffliction(Enemy: Types.ServerEnemyClass, Type: Types.Element | string, Amount: number)
	local Object = buffer.create(5)
	buffer.writeu8(Object, 0, GameEnum.Replication.FillAffliction)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, GameEnum.Afflictions[Type] :: number)
	buffer.writei16(Object, 3, Amount * 500)

	Network:FireForAll('Replicate', Object)
end


function Replicator:ResetAffliction(Enemy: Types.ServerEnemyClass, Type: Types.Element)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.ResetAffliction)
	buffer.writeu8(Object, 1, Enemy.__EnemyId)
	buffer.writeu8(Object, 2, GameEnum.Afflictions[Type] :: number)

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

function Replicator:AddTagEnemy(Enemy: Types.ServerEnemyClass, Tag: string)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.AddTagEnemy)
	buffer.writeu8(Object, 1, Enemy:GetId())

	Network:FireForAll('Replicate', Object, Tag)
end

function Replicator:RemoveTagEnemy(Enemy: Types.ServerEnemyClass, Tag: string)
	local Object = buffer.create(2)
	buffer.writeu8(Object, 0, GameEnum.Replication.RemoveTagEnemy)
	buffer.writeu8(Object, 1, Enemy:GetId())

	Network:FireForAll('Replicate', Object, Tag)
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


function Replicator:CreateCompanion(CompanionObject: Companions.CompanionClass)
	local OwnerId = CompanionObject.__Owner.__Player_Assigned:GetAttribute("ReplicationId")
	local CompanionNameId = CompanionsDatabase:GetIdFor(CompanionObject.__Name)
	local Object = buffer.create(16)
	buffer.writeu8(Object, 0, GameEnum.Replication.CreateCompanion)
	buffer.writeu8(Object, 1, CompanionObject.__Key)
	buffer.writeu8(Object, 2,  OwnerId:: number)
	buffer.writeu8(Object, 3, CompanionNameId :: number)
	Math:EncodeCFrame(CompanionObject:GetPivot(), Object, 4)

	Network:FireForAll("ReliableReplication", Object, CompanionObject.__UUID)
end

function Replicator:MoveCompanion(CompanionObject: Companions.CompanionClass, Goal: CFrame)
	local Object = buffer.create(14)
	buffer.writeu8(Object, 0, GameEnum.Replication.MoveCompanion)
	buffer.writeu8(Object, 1, CompanionObject.__Key)
	Math:EncodeCFrame(Goal, Object, 2)

	Network:FireForAll("ReliableReplication", Object)
end

function Replicator:SetMovingStatusCompanion(CompanionObject: Companions.CompanionClass, Status: boolean)
	local Object = buffer.create(3)
	buffer.writeu8(Object, 0, GameEnum.Replication.SetMovingStatusCompanion)
	buffer.writeu8(Object, 1, CompanionObject.__Key)
	buffer.writeu8(Object, 2, Status and 1 or 0)

	Network:FireForAll("ReliableReplication", Object)
end

return Replicator
