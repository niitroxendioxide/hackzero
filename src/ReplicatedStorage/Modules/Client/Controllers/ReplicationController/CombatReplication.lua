--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Structures = require(ReplicatedStorage.Modules.Client.Libraries.Structures)
local AgentTypes = require(ReplicatedStorage.Modules.Shared.Types.Agents)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local GameEnum = require(Shared.GameEnum)
local Enemies = require(Shared.Libraries.Enemies)
local Effects = require(Client.Libraries.Effects)
local InterfaceStates = require(Client.Packages.InterfaceStates)
local InterfaceController = require(Client.Controllers.InterfaceController)

local DestructiblesDatabase = require(Shared.Database.Destructibles)


--
local Controller = {}

function Controller:UseSkill(Buffer: buffer)
	local Skill = buffer.readu8(Buffer, 1)
	local EnemyId = buffer.readu8(Buffer, 2)
	local StateId = buffer.readu8(Buffer, 3)
	local UserId = buffer.readu8(Buffer,4)

	local State = StateId == 1 and 'Begin' or 'End'
	local ActiveAgent = Characters:GetCurrent(UserId)
	local Key = GameEnum.KeyLookup(GameEnum.Skills, Skill)
	local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))

	if UserId == Players.LocalPlayer:GetAttribute('ReplicationId') and Skill ~= GameEnum.Skills.Quick_Assist then
		CharacterMoveset:Release(Key, ActiveAgent)

		return
	end

	local AgentEnemy = Enemies:GetEnemy(EnemyId)

	if AgentEnemy and Key ~= 'Dodge' then
		local XZ = Vector3.new(1, 0, 1)

		local LookAt = CFrame.lookAt(ActiveAgent:GetPivot().Position * XZ, AgentEnemy:GetPivot().Position * XZ).LookVector
		ActiveAgent:Look(LookAt)
	end

	if Key == 'Dodge' then
		for _, Character in Characters:GetCharacters(UserId) do
			Character:SetKey('Sprint', true)
			Character:SetKey('Jog', true)
		end
	end

	if State == 'Begin' then
		CharacterMoveset:Begin(Key, ActiveAgent, true)
	else
		CharacterMoveset:Release(Key, ActiveAgent, true)
	end
end

function Controller:EnemyUseSkill(Buffer: buffer)
	local Skill = buffer.readu8(Buffer, 1)
	local EnemyId = buffer.readu8(Buffer, 2)
	local State = buffer.readu8(Buffer, 3) == 1 and 'Begin' or 'End'
	
	local Key = 'Skill '..Skill
	local Enemy = Enemies:GetEnemy(EnemyId)
	local CharacterMoveset = Movesets:Get(Enemy.Name, true)

	CharacterMoveset:Begin(Key, Enemy, State)
end



function Controller:DisplayDamage(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Type = buffer.readu8(Buffer, 2)
	local Critical = buffer.readu8(Buffer, 3) == 1
	local Burst = buffer.readu8(Buffer, 4) == 1
	local Amount = buffer.readf32(Buffer, 5)

	local EnemyObject = Enemies:GetEnemy(EnemyId)
	
	if EnemyObject == nil then
		Type = 'Shatter'
		EnemyObject = Enemies.__Last_Enemy_Pos[EnemyId]
	else
		EnemyObject:TakeDamage(Amount)
	end
	
	Effects:Play('Indicator', EnemyObject, {Affliction = Type, Critical = Critical, Number = math.floor(Amount), Burst = Burst})
end

function Controller:DazeEnemy(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Amount = buffer.readu16(Buffer, 2) / 325
	
	local EnemyObject = Enemies:GetEnemy(EnemyId)

	if EnemyObject == nil then
		return
	end

	EnemyObject:TakeDaze(Amount)
end

function Controller:DamageAgent(Buffer: buffer)
	local Agent = buffer.readu8(Buffer, 1)
	local PlayerId = buffer.readu8(Buffer, 2)
	local Damage = buffer.readf32(Buffer, 3)

	local ActiveAgent = Characters:GetAgent(PlayerId, Agent)

	ActiveAgent:TakeDamage(Damage)

	if PlayerId == Players.LocalPlayer:GetAttribute("ReplicationId") then
		local Health, Max = ActiveAgent:GetHealth()

		InterfaceStates.Health[Agent]:set(Health / Max)
	end

	--
	Effects:Play('Indicator', ActiveAgent, {Affliction = 'Enemy', Crit = false, Number = math.floor(Damage)})

	return ActiveAgent
end


function Controller:KillAgent(Buffer: buffer)
	local _PlayerId = buffer.readu8(Buffer, 2)
	local GivenAgent = Controller:DamageAgent(Buffer)

	local Object = Animation:GetAnim("Characters.Dying")

	if Object then
		Animation:Play(GivenAgent:GetModel(), Object, 0)
		GivenAgent:Kill();
	end
end

function Controller:Knockback(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Direction = GameEnum.KeyLookup(GameEnum.Knockback_Directions, buffer.readu8(Buffer, 2))
	local Strength = buffer.readu8(Buffer, 3)
	local Time = buffer.readu8(Buffer, 4) / 10

	local EnemyObject = Enemies:GetEnemy(EnemyId)

	if not EnemyObject then
		return
	end

	EnemyObject:Knockback(Direction, Strength, Time)
end

function Controller:FillAffliction(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Type = GameEnum.KeyLookup(GameEnum.Afflictions, buffer.readu8(Buffer, 2))
	local Amount = buffer.readi16(Buffer, 3) / 500

	local EnemyObject = Enemies:GetEnemy(EnemyId)

	if EnemyObject == nil then
		return
	end

	EnemyObject:TakeAffliction(Type, Amount)
end

function Controller:ResetAffliction(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Type = GameEnum.KeyLookup(GameEnum.Afflictions, buffer.readu8(Buffer, 2))

	local EnemyObject = Enemies:GetEnemy(EnemyId)

	if EnemyObject == nil then
		return
	end

	EnemyObject:ResetAffliction(Type)
end

function Controller:AddEffect(Buffer: buffer, Effect: AgentTypes.EffectParameters)
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local RepId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)

	local Agent = Characters:GetAgent(RepId, AgentId)
	local EffectObj = Agent:AddEffect(Effect)

	if UserId == RepId then
		InterfaceStates.EffectAdded:Fire(AgentId, EffectObj)
	end
end

function Controller:RemoveEffect(Buffer: buffer)
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local RepId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)
	local EffectId = buffer.readu8(Buffer, 3)

	local Agent = Characters:GetAgent(RepId, AgentId)

	Agent:RemoveEffect(EffectId)

	if UserId == RepId then
		InterfaceStates.EffectRemoved:Fire(AgentId, EffectId)
	end
end

function Controller:PromptAssist(Buffer: buffer)
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local Moveset = InterfaceController:GetComponent("Moveset")
	local AgentId = buffer.readu8(Buffer, 1)
	local Time = buffer.readu8(Buffer, 2) /  10
	local EnemyTargetId = buffer.readu8(Buffer, 3)

	local Agent = Characters:GetAgent(UserId, AgentId)
	if not Agent then
		return
	end

	Characters:SetCharacterTarget(Players.LocalPlayer, EnemyTargetId, Time)
	Moveset:PopUpAgent(Agent.Name)

	task.wait(Time)
	Moveset:DeletePopUp()
end

function Controller:CreateDestructible(Buffer: buffer)
	local Id = buffer.readu8(Buffer, 1)
	local Type = DestructiblesDatabase:FromId(buffer.readu8(Buffer, 2))
	local X = buffer.readf32(Buffer, 3)
	local Z = buffer.readf32(Buffer, 7)
	local Y = buffer.readi16(Buffer, 11) / 10

	local Position = Vector3.new(X, Y, Z)

	Structures.Create(Type, {
		Id = Id,
		At = Position,
	})
end

return Controller
