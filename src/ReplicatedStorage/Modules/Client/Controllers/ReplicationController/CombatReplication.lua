--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local CombatController = require(ReplicatedStorage.Modules.Client.Controllers.CombatController)
local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Structures = require(ReplicatedStorage.Modules.Client.Libraries.Structures)
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local AgentTypes = require(ReplicatedStorage.Modules.Shared.Types.Agents)
local Math = require(ReplicatedStorage.Modules.Shared.Utility.Math)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local GameEnum = require(Shared.GameEnum)
local Enemies = require(Shared.Libraries.Enemies)
local Effects = require(Client.Libraries.Effects)
local InterfaceStates = require(Client.Packages.InterfaceStates)
local InterfaceController = require(Client.Controllers.InterfaceController)

local AgentsDatabase = require(Shared.Database.Characters)
local DestructiblesDatabase = require(Shared.Database.Destructibles)
local EnemyOverheadGui = require(Client.Libraries.EnemyStatusIndicator)


--
local Colliders = {}
local Controller = {}

function Controller:UseSkill(Buffer: buffer, Extra: {})
	local Skill = buffer.readu8(Buffer, 1)
	local EnemyId = buffer.readu8(Buffer, 2)
	local StateId = buffer.readu8(Buffer, 3)
	local UserId = buffer.readu8(Buffer,4)
	local IsCancel = buffer.readu8(Buffer, 5) == 1

	local State = GameEnum.KeyLookup(GameEnum.AbilityStates, StateId)
	local ActiveAgent = Characters:GetCurrent(UserId)
	local Key = GameEnum.KeyLookup(GameEnum.Skills, Skill)
	local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))

	if UserId == Players.LocalPlayer:GetAttribute('ReplicationId') and Skill ~= GameEnum.Skills.Quick_Assist then
		if State == "Release" then
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
		ActiveAgent:Look(LookAt, true, true)
	end

	if Key == 'Dodge' then
		for _, Character in Characters:GetCharacters(UserId) do
			Character:SetKey('Sprint', true)
			Character:SetKey('Jog', true)
		end
	end

	local Context = {IsSignal = true, Buffer = Extra, Target = AgentEnemy, Enemy = AgentEnemy, IsCancel = IsCancel}
	if State == 'Begin' then
		if not CharacterMoveset:HasSkill(Key) and Key == "Dodge" then
			Movesets:RunFromTemplate(Key, ActiveAgent, {IsSignal = true, IsCancel = IsCancel})

			return
		end

		CharacterMoveset:EmulateHooks(Key, State, ActiveAgent, Context)
		CharacterMoveset:Begin(Key, ActiveAgent, Context)
	elseif State == "Release" then
		CharacterMoveset:EmulateHooks(Key, 'Release', ActiveAgent, Context)
		CharacterMoveset:Release(Key, ActiveAgent, Context)
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
	local BaseOffset = CFrame.new(TriggerObject:GetAttribute("AreaOffset") or Vector3.new()) :: CFrame

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
        Part.CFrame = (TriggerObject:GetPivot() * BaseOffset) * Offset
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
	local SkillId = buffer.readu8(Buffer, 1)
	local EnemyId = buffer.readu8(Buffer, 2)
	local State = buffer.readu8(Buffer, 3) == 1 and 'Begin' or 'End'
	local PlayerId, TargetId = Math:Decodeu2u6(Buffer, 4)

	local Enemy = Enemies:GetEnemy(EnemyId)
	local CharacterMoveset = Movesets:Get(Enemy.Name, true)

	if not CharacterMoveset then
		return;
	end

	local Target = nil;
	if TargetId > 0 then
		Target = Characters:GetAgent(PlayerId, TargetId)
	end

	local SkillName = CharacterMoveset:GetSkillById(SkillId)

	if State == 'Begin' then
		CharacterMoveset:Begin(SkillName, Enemy, {Target = Target, IsSignal = true})
	else
		CharacterMoveset:Release(SkillName, Enemy, {Target = Target, IsSignal = true})
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
	
	if PlayerId == Players.LocalPlayer:GetAttribute('ReplicationId') then
		Effects:Play('Dodge', Statics.Dodge_Invulnerability_Time)
	else
		Effects:Play('Indicator', AgentObject, {Text = 'DODGE', Critical = true})
	end
end


function Controller:DisplayDamage(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Type = buffer.readu8(Buffer, 2)
	local Critical = buffer.readu8(Buffer, 3) == 1
	local Burst = buffer.readu8(Buffer, 4) == 1
	local Amount = buffer.readf32(Buffer, 5)
	local EnemyHealth = buffer.readf32(Buffer, 9)

	local EnemyObject = Enemies:GetEnemy(EnemyId)

	if EnemyObject == nil then
		Type = 'Shatter'
		EnemyObject = Enemies.__Last_Enemy_Pos[EnemyId]
	else
		EnemyOverheadGui:UpdateHealth(EnemyId, EnemyHealth)
		EnemyObject:SetHealth(EnemyHealth)
	end

	if Burst and Type ~= GameEnum.Afflictions.Ice then
		Effects:Play("AfflictionBurst", EnemyObject, Type, {})
	end

	local ExtraTime = Burst and 1.5 or 0.75
	Effects:Play('Indicator', EnemyObject, {Affliction = Type, Critical = Critical, Number = math.floor(Amount), Burst = Burst, VanishTime = ExtraTime})
end

function Controller:DazeEnemy(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Amount = buffer.readu16(Buffer, 2) / 325

	local EnemyObject = Enemies:GetEnemy(EnemyId)

	if EnemyObject == nil then
		return
	end

	EnemyObject:TakeDaze(Amount)
	EnemyOverheadGui:UpdateDaze(EnemyId, EnemyObject.__Status.__Daze)
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

function Controller:Knockback(Buffer: buffer, Direction: Vector3)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Strength = buffer.readu8(Buffer, 2)
	local Time = buffer.readu8(Buffer, 3) / 10

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

	local CurrentActiveAffliction = EnemyObject:GetAfflictionType();
	EnemyObject:TakeAffliction(Type, Amount)

	if Type == CurrentActiveAffliction then
		CurrentActiveAffliction = nil;
	else
		CurrentActiveAffliction = Type;
	end

	local CurrentAfflictionFill = EnemyObject:GetAffliction(Type);
	EnemyOverheadGui:UpdateAffliction(EnemyId, CurrentAfflictionFill, CurrentActiveAffliction)
end

function Controller:ResetAffliction(Buffer: buffer)
	local EnemyId = buffer.readu8(Buffer, 1)
	local Type = GameEnum.KeyLookup(GameEnum.Afflictions, buffer.readu8(Buffer, 2))

	local EnemyObject = Enemies:GetEnemy(EnemyId)

	if EnemyObject == nil then
		return
	end

	local CurrentActiveAffliction = EnemyObject:GetAfflictionType();
	if Type == CurrentActiveAffliction then
		CurrentActiveAffliction = nil;
	end

	EnemyObject:ResetAffliction(Type)
	EnemyOverheadGui:UpdateAffliction(EnemyId, 0, CurrentActiveAffliction)
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

function Controller:ChangeEffect(Buffer: buffer)
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local RepId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)
	local Amount = buffer.readi8(Buffer, 3)
	local Restart = (buffer.readu8(Buffer, 4) == 1)
	local Tag = buffer.readstring(Buffer, 5, buffer.len(Buffer) - 5)

	local Agent = Characters:GetAgent(RepId, AgentId)
	local _, EffectObj = Agent:ChangeEffect(Tag, Amount, Restart)

	if UserId == RepId then
		InterfaceStates.EffectReset:Fire(AgentId, EffectObj)
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

	Characters:QueueNextSwitchTo(AgentId)
	Characters:SetCharacterTarget(Players.LocalPlayer, EnemyTargetId, Time)
	Moveset:PopUpAgent(Agent.Name)

	local Switched = false;
	local Connection = Characters.SwitchedToAssist:Once(function()
		Switched = true
		Characters:SetCharacterTarget(Players.LocalPlayer, nil)
		Moveset:DeletePopUp()
	end)

	task.wait(Time)
	if Switched then
		return
	end

	Connection:Disconnect()
	Characters:QueueNextSwitchTo(0)
	Moveset:DeletePopUp()
end

function Controller:CreateDestructible(Buffer: buffer, Pivot: CFrame)
	local Id = buffer.readu8(Buffer, 1)
	local Type = DestructiblesDatabase:FromId(buffer.readu8(Buffer, 2))

	Structures.Create(Type, {
		Id = Id,
		At = Pivot,
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
	local HitTracks = Assets.Animations.Enemies.Hit:GetChildren()
	table.sort(HitTracks, function(a0, a1): boolean  
		return a0.Name < a1.Name;
	end)

	local Track;
	if buffer.readu8(Buffer, 4) > 0 then
		Track = HitTracks[buffer.readu8(Buffer, 4)]
	else
		for k = #HitTracks, 1, -1 do
			local STrack = HitTracks[k];
			if tonumber(STrack.Name) < 9 then
				continue
			end

			table.remove(HitTracks, k)
		end

		Track = HitTracks[math.random(1, #HitTracks)]
	end

	Animation:Play(AgentObject:GetModel(), Track)
end


-- Only runs for a local player, so it doesn\'t matter :3
function Controller:FillMeter(Buffer: buffer)
	local ReplicationId = Players.LocalPlayer:GetAttribute('ReplicationId') :: number
	local MainUIHUD = InterfaceController:GetComponent("Main")

	local PlayerId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)
	local MeterId = buffer.readu8(Buffer, 3)
	local MeterName = '';
	local Percent = buffer.readu8(Buffer, 4) / 255
	local Value = buffer.readf32(Buffer, 5)

	local AgentObject = Characters:GetAgent(PlayerId, AgentId)
	local MovesetData = AgentsDatabase:GetMovesetData(AgentObject.Name)
	if MovesetData.Passive then
		for Idx, Meter in MovesetData.Passive.Meters do
			if Meter.Id == MeterId then
				MeterName = Idx
			end
		end
	end

	AgentObject:SetMeter(MeterName, Value)

	if PlayerId == ReplicationId then
		MainUIHUD:UpdateAgentMeter(AgentId, MeterName, Percent, Value)
	end
end

function Controller:CreateMeter(Buffer: buffer, Name: string, MeterCreationData: {[string]: any})
	local ReplicationId = Players.LocalPlayer:GetAttribute('ReplicationId') :: number
	local PlayerId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)

	local AgentObject = Characters:GetAgent(PlayerId, AgentId)
	if not AgentObject then
		return;
	end

	AgentObject:CreateMeter(Name, MeterCreationData)

	if PlayerId == ReplicationId then
		local MainUIHUD = InterfaceController:GetComponent("Main")
		local Data = AgentsDatabase:GetMovesetData(AgentObject.Name)

		if not Data or not Data.Passive then
			return
		end

		local MeterName: string = nil
		for MeterNameLoop, MeterData in Data.Passive.Meters do
			if MeterData.Id == MeterCreationData.Id then
				MeterName = MeterNameLoop
			end
		end

		if not MeterName then return end

		MainUIHUD:UpdateAgentMeter(AgentId, MeterName, 0, 0)
	end
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
	local AgentId = buffer.readu8(Buffer, 1)
	local EnemyId = buffer.readu8(Buffer, 2)
	local ChainAttackComponent = InterfaceController:GetComponent("ChainAttack")

	---
	local CharactersToPrompt = Characters:GetCharacters()
	local Options = {};
	local AllNames = {};

	for idx, Agent in CharactersToPrompt do
		table.insert(AllNames, Agent.Name)
		if idx == AgentId or not Agent:IsAlive() then
			continue
		end

		table.insert(Options, Agent.Name)
	end

	if #Options < 2 then
		Options[2] = Options[1]
	end

	local CentreAgent = Characters:GetAgent(Players.LocalPlayer:GetAttribute("ReplicationId"), AgentId)
	local Position = table.find(AllNames, CentreAgent.Name);

	if Position == 1 or Position == 3 then
		Options = {Options[2], Options[1]}
	end


	Effects:Play("Chain")

	
	ChainAttackComponent:Show(Options)

	---
	task.wait(0.25)

	CombatController:EnterChainAttackPrompt(EnemyId)
	CombatController.ChainAttackActionChosen:Once(function(OptionChosen: number)
		ChainAttackComponent:Choose(OptionChosen)
	end)
end

return Controller
