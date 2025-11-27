--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Structures = require(ReplicatedStorage.Modules.Client.Libraries.Structures)
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local AgentTypes = require(ReplicatedStorage.Modules.Shared.Types.Agents)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local GameEnum = require(Shared.GameEnum)
local Enemies = require(Shared.Libraries.Enemies)
local Effects = require(Client.Libraries.Effects)
local InterfaceStates = require(Client.Packages.InterfaceStates)
local InterfaceController = require(Client.Controllers.InterfaceController)

local AgentsDatabase = require(Shared.Database.Characters)
local DestructiblesDatabase = require(Shared.Database.Destructibles)


--
local Colliders = {}
local Controller = {}

function Controller:UseSkill(Buffer: buffer, Extra: {})
	local Skill = buffer.readu8(Buffer, 1)
	local EnemyId = buffer.readu8(Buffer, 2)
	local StateId = buffer.readu8(Buffer, 3)
	local UserId = buffer.readu8(Buffer,4)

	local State = GameEnum.KeyLookup(GameEnum.AbilityStates, StateId)
	local ActiveAgent = Characters:GetCurrent(UserId)
	local Key = GameEnum.KeyLookup(GameEnum.Skills, Skill)
	local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))

	if UserId == Players.LocalPlayer:GetAttribute('ReplicationId') and Skill ~= GameEnum.Skills.Quick_Assist then
		if State == "End" then
			CharacterMoveset:Release(Key, ActiveAgent)
		elseif State == "Cancel" then
			CharacterMoveset:CancelSkill(Key, ActiveAgent)
		end

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
		if not CharacterMoveset:HasSkill(Key) and Key == "Dodge" then
			Movesets:RunFromTemplate(Key, ActiveAgent, {IsSignal = true})

			return
		end

		CharacterMoveset:Begin(Key, ActiveAgent, {IsSignal = true, Buffer = Extra})
	elseif State == "End" then
		CharacterMoveset:Release(Key, ActiveAgent, {IsSignal = true, Buffer = Extra})
	elseif State == "Cancel" then
		CharacterMoveset:CancelSkill(Key, ActiveAgent)
	end
end

function Controller:SetColliderArea(Buffer: buffer, TriggerObject: BasePart)
	local State = buffer.readu8(Buffer, 1) == 1
	local RepId = buffer.readu8(Buffer, 2) -- use this for yk.. the stuff!

	if Colliders[TriggerObject] then
		if not State then
			Effects:Play("Barrier", TriggerObject.Name..'barrier', Colliders[TriggerObject], TriggerObject.Position, false)

			for _, Agent in Characters:GetCharacters(RepId) do
				Agent:SetLimitArea(nil)
				Agent:SetColliderGroupEnabled(Colliders[TriggerObject], false)
			end

			for _, Obj in Colliders[TriggerObject] do
				Obj:Destroy()
			end

			Colliders[TriggerObject] = nil
		end

		return
	end

	if not TriggerObject then
		return
	end

	local SIZE_K = workspace.World.Map.Design:GetAttribute("Generated") and 1.1 or 1.25
	local Size = (TriggerObject:GetAttribute("AreaSize") or (TriggerObject.Size * SIZE_K)) :: Vector3

    local Sizes = {
        Vector3.new(Size.X + 1, Size.Y, 1), CFrame.new(0, 0, -Size.Z/2 - 1),
        Vector3.new(Size.X + 1, Size.Y, 1), CFrame.new(0, 0, Size.Z/2 - 1),
        Vector3.new(1, Size.Y, Size.Z + 1), CFrame.new(-Size.X/2 - 1, 0, 0),
        Vector3.new(1, Size.Y, Size.Z + 1), CFrame.new(Size.X/2 - 1, 0, 0)
    }

	Colliders[TriggerObject] = {}

	local Parent = workspace.Camera:FindFirstChild("Area_Colliders") or Instance.new("Folder")
	Parent.Name = "Area_Colliders"
	Parent.Parent = workspace.Camera

	for i = 1, #Sizes, 2 do
        local PartSize = Sizes[i]
        local Offset = Sizes[i + 1]

        local Part = Instance.new("Part")
        Part.Size = PartSize
        Part.CFrame = TriggerObject:GetPivot() * Offset
        Part.Transparency = 1
        Part.Color = Color3.new(0.403922, 0.133333, 0.992157)
        Part.Name = TriggerObject.Name .. 'ColliderPart'
		Part.CanCollide = false
        Part.Anchored = true
        Part.Parent = Parent

        table.insert(Colliders[TriggerObject], Part)
    end

	Effects:Play("Barrier", TriggerObject.Name..'barrier', Colliders[TriggerObject], TriggerObject.Position, true)

	for _, Agent in Characters:GetCharacters(RepId) do
		Agent:SetLimitArea(TriggerObject)
		Agent:SetColliderGroupEnabled(Colliders[TriggerObject], true)
	end
end

function Controller:EnemyUseSkill(Buffer: buffer)
	local Skill = buffer.readu8(Buffer, 1)
	local EnemyId = buffer.readu8(Buffer, 2)
	local State = buffer.readu8(Buffer, 3) == 1 and 'Begin' or 'End'

	local Key = 'Skill '..Skill
	local Enemy = Enemies:GetEnemy(EnemyId)
	local CharacterMoveset = Movesets:Get(Enemy.Name, true)

	if State == 'Begin' then
		CharacterMoveset:Begin(Key, Enemy)
	else
		CharacterMoveset:Release(Key, Enemy)
	end
end

function Controller:ProcessDodge(Buffer: buffer)
	local PlayerId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)

	local AgentObject = Characters:GetAgent(PlayerId, AgentId)
	if not AgentObject then
		return
	end

	AgentObject:RemoveTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER)
	AgentObject:AddTag('Dodge_Counter_Tag', Statics.Dodge_Counter_React_Time)
	AgentObject:AddTag('Invulnerability', Statics.Dodge_Invulnerability_Time)
	Effects:Play('Dodge', Statics.Dodge_Invulnerability_Time)
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
	local Rotation = math.rad(buffer.readi16(Buffer, 13) / 100)

	local Position = Vector3.new(X, Y, Z)

	Structures.Create(Type, {
		Id = Id,
		At = Position,
		Rotation = Rotation,
	})
end

function Controller:DestroyDestructible(Buffer: buffer)
	local Id = buffer.readu8(Buffer, 1)
	local Type = DestructiblesDatabase:FromId(buffer.readu8(Buffer, 2))

	Structures.Destroy(Type, {
		Id = Id,
	})
end

function Controller:HitDestructible(Buffer: buffer)
	local Id = buffer.readu8(Buffer, 1)
	local Type = DestructiblesDatabase:FromId(buffer.readu8(Buffer, 2))

	Structures.Hit(Type, Id)
end

function Controller:HitAgent(Buffer: buffer)
	local AgentId = buffer.readu8(Buffer, 1)
	local PlayerId = buffer.readu8(Buffer, 2)
	local Time = buffer.readu8(Buffer, 3) / 10

	local AgentObject = Characters:GetAgent(PlayerId, AgentId)
	if not AgentObject then
		return
	end

	local CharacterMoveset = Movesets:Get(AgentObject.Name)
	local CurrentAgentSkill = AgentObject:GetCurrentSkill()
	if CurrentAgentSkill ~= nil then
		CharacterMoveset:CancelSkill(CurrentAgentSkill, AgentObject, {Hit = true})
	end

	AgentObject:SwitchState('Stunned', Time)

	Effects:Play("Hit", AgentObject, {
		HueShiftFilter = function(p: ParticleEmitter)
			if p.Name == "Shorter impact 2" then
				return -47
			elseif p.Name == "Impact13" then
				return -40
			end

			return -30
		end
	})

	--
	local HitTracks = Assets.Animations.General.Hit:GetChildren()
	Animation:Play(AgentObject:GetModel(), HitTracks[math.random(1, #HitTracks)])
end


-- Only runs for a local player, so it doesn\'t matter :3
function Controller:FillMeter(Buffer: buffer)
	local ReplicationId = Players.LocalPlayer:GetAttribute('ReplicationId') :: number
	local MainUIHUD = InterfaceController:GetComponent("Main")

	local AgentId = buffer.readu8(Buffer, 1)
	local Meter = buffer.readu8(Buffer, 2)
	local Percent = buffer.readu8(Buffer, 3) / 255

	local AgentObject = Characters:GetAgent(ReplicationId, AgentId)
	local Data = AgentsDatabase:GetMovesetData(AgentObject.Name)

	if not Data or not Data.Passive then
		return
	end

	local MeterName: string = nil
	for MeterNameLoop, MeterData in Data.Passive.Meters do
		if MeterData.Id == Meter then
			MeterName = MeterNameLoop
		end
	end
	if not MeterName then return end

	MainUIHUD:UpdateAgentMeter(AgentId, MeterName, Percent)
end

function Controller:SetEnemySpeed(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Speed = buffer.readu8(Buffer, 2) / 100
	local Time = buffer.readu8(Buffer, 3) / 10

	if Time == 0 then
		Time = nil
	end

	local EnemyObject = Enemies:GetEnemy(EnemyId)
	EnemyObject:SetWorldSpeed(Speed, Time)
end

function Controller:ChainAttack(Buffer: buffer)
	print("YOU SHOULD CHAIN TEH ATTACSK")
end

return Controller
