----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Libraries = ServerStorage.Modules.Libraries;
local Shared = ReplicatedStorage.Modules.Shared;

local Debugger = require(Shared.Utility.Debugger)
local Enemies = require(Shared.Libraries.Enemies)
local String = require(Shared.Utility.String)

local BehaviorTypes = require(Shared.Types.Behaviors)
local AbilityTypes = require(Shared.Types.Abilities)

local Replicator = require(Libraries.Replicator)
local Behaviors = require(Libraries.Behaviors)
local Movesets = require(Libraries.Movesets)
local Targets = require(Libraries.Targets)

local EnemyDatabase = require(Shared.Database.Enemies)

---- Privates
local function CreateBehaviorConnector(): (BehaviorTypes.EntityBehavior, BehaviorTypes.EntityBehaviorState)
    local BehaviorConnector = {}
    local BehaviorState: BehaviorTypes.EntityBehaviorState = {
        EntityId = 0,
        PhaseCount = 0,
        LastUpdate = os.clock(),

        RanPhases = { 
            Base = true
        },
        CurrentPhase = {
            Name = "Base",
            Priority = 0
        },
        LastUsedPattern = {
            Name = "",
            UseCount = 1,
        },
        CurrentPattern = "",
        PatternProgress = 1,

        Cooldowns = {},
        Skills = {},
        OncePatterns = {},
        Phases = {},
        Patterns = {},
        PatternRanges = {},
        Events = {},
        PhasePatterns = {},
    }

    ---
    function BehaviorConnector.When(_, _)
        return Debugger:DebugLine("BehaviorConnector.When", "Method not implemented", 1)
    end

    function BehaviorConnector.Phase(Name: string, Priority: number, Condition: () -> ())
        if BehaviorState.Phases[Name] ~= nil then
            Debugger:DebugLine("BehaviorConnector.Phase", `Phase {Name} is already bound to a condition.`, 1)

            return
        end

        
        BehaviorState.PhaseCount += 1;
        BehaviorState.Phases[Name] = {
            Priority = Priority or 0,
            Condition = Condition,
        }
    end

    function BehaviorConnector.DefinePattern(Name: string, Pattern: BehaviorTypes.PatternData)
        if BehaviorState.Patterns[Name] ~= nil then
            Debugger:DebugLine("BehaviorConnector.DefinePattern", `Pattern {Name} already defined.`, 1)

            return
        end

        for _, SkillName in Pattern.Skills do
            if BehaviorState.Skills[SkillName] then
                continue
            end

            BehaviorState.Skills[SkillName] = true
        end

        BehaviorState.Cooldowns[Name] = {
            Time = 0,
            Turns = 0,
        }
        BehaviorState.Patterns[Name] = Pattern
    end

    function BehaviorConnector.SetBasePatterns(Patterns: { BehaviorTypes.PatternOption })
        BehaviorConnector.SetPatterns('Base', Patterns)
    end

    function BehaviorConnector.SetPatterns(Phase: string, Patterns: { BehaviorTypes.PatternOption })
        if (BehaviorState.Phases[Phase] == nil and Phase ~= 'Base') then
            Debugger:DebugLine("BehaviorConnector.SetPatterns", `Phase {Phase} not defined.`, 1)

            return
        end

        BehaviorState.PhasePatterns[Phase] = Patterns
    end

    function BehaviorConnector.OnPatternUsed(PatternName: string, Handler: () -> ())
        return Debugger:DebugLine("BehaviorConnector.OnPatternUsed", "Method not implemented", 1)
    end
    
    return BehaviorConnector :: BehaviorTypes.EntityBehavior, BehaviorState :: BehaviorTypes.EntityBehaviorState
end

local function CreateState(Entity: AbilityTypes.ServerEnemy): (BehaviorTypes.EntityState)
    local EntityState = {}

    EntityState.Health = function()
        return Entity:GetHealth()
    end

    EntityState.HealthPercent = function()
        local Hp, Max = Entity:GetHealth(), Entity:GetStat("Max_Health")

        return math.floor((Hp / Max) * 100)
    end

    return EntityState :: BehaviorTypes.EntityState
end

local function EntityCanAttackTarget(Entity: AbilityTypes.ServerEnemy): boolean
    local EntityTarget = Entity:GetTarget()
    if EntityTarget == nil then
        return false --, "No Target"
    end

    if Entity.__Status:IsKnocked() or not Entity:IsAlive() or Entity.__Movement.__World_Speed <= 0 or Entity.__Status:IsAirborne() then
		return false --, 'Knocked'
	end

    if Entity:GetState() == 'Attacking' then
        return false --, 'Already attacking'
    end

    if not Targets:CanAttackTarget(EntityTarget, Entity) then
        return false --, "same"
    end

    if EntityTarget:HasTag("Invulnerability") or Entity:IsGrabbed() then
		return false --, "Target denied (Invulnerable, Grabbed)"
	end

    local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Camera.Destructibles}
	Params.FilterType = Enum.RaycastFilterType.Include

	local At = Entity:GetPivot()
	local LookAt = CFrame.lookAt(At.Position, EntityTarget:GetPivot().Position)
	local LookAtRay = workspace:Raycast(At.Position, LookAt.LookVector * 1000, Params)
	if LookAtRay then
		return false --, "Behind structure"
	end

    return true
end

local function UpdateEntityBehavior(Behavior: BehaviorTypes.EntityBehaviorState, Entity: AbilityTypes.ServerEnemy)
    local EntityName = Entity.__Name
    local NewPhase, CurrentPriority = 'Base', 0;
    for PhaseName, PhaseData in Behavior.Phases do
        local Priority = PhaseData.Priority;
        
        if Priority > CurrentPriority and PhaseData.Condition() and (Behavior.RanPhases[PhaseName] ~= true) then
            NewPhase = PhaseName
            CurrentPriority = Priority
        end
    end

    if NewPhase ~= 'Base' then
        Behavior.RanPhases[NewPhase] = true
        Behavior.OncePatterns = {}
        Behavior.CurrentPhase = {
            Name = NewPhase,
            Priority = CurrentPriority,
        }
    end

    ---
    local CurrentPhaseId = Behavior.CurrentPhase.Name
    local PhasePatternPool = Behavior.PhasePatterns[CurrentPhaseId]

    if string.len(Behavior.CurrentPattern) <= 0 then
        local Choices = {}
        local SinglePattern = #PhasePatternPool == 1

        for Index, PatternObject in PhasePatternPool do
            local PatternData = Behavior.Patterns[PatternObject.Name]
            local MaxChainUsages = (PatternData.MaxChainUsages or 0)
            local LastPatternPickedTime = Behavior.Cooldowns[PatternObject.Name].Time

            if typeof(PatternData.CooldownTime) == 'number' and (os.clock() - LastPatternPickedTime < PatternData.CooldownTime) then
                continue
            end

            -- skip in case the patern will be used too many times
            if (Behavior.LastUsedPattern.Name == PatternObject.Name) 
                and (Behavior.LastUsedPattern.UseCount + 1) > (1 + MaxChainUsages) 
                and (not SinglePattern) 
            then
                continue
            end

            if Behavior.OncePatterns[PatternObject.Name] then
                continue
            end
            
            for _= 1, math.max(PatternObject.Weight or 1, 1) do
                table.insert(Choices, Index)
            end
        end

        local RandomIndex = Choices[math.random(1, #Choices)]
        if #Choices == 0 then
            RandomIndex = 1;
        end

        local Pattern = PhasePatternPool[RandomIndex]
        if Pattern.Once then
            Behavior.OncePatterns[Pattern.Name] = true;
        end

        Behavior.PatternProgress = 1;
        Behavior.CurrentPattern = Pattern.Name;

        ---
        local PatternCooldownTime = Behavior.Patterns[Behavior.CurrentPattern].CooldownTime;
        if typeof(PatternCooldownTime) == 'number' then
            Behavior.Cooldowns[Behavior.CurrentPattern].Time = os.clock()
        end
    end

    local CurrentPatternData = Behavior.Patterns[Behavior.CurrentPattern]
    local PatternRange = (Behavior.PatternRanges[Behavior.CurrentPattern] or 10)

    local CanAttack = EntityCanAttackTarget(Entity)
    if CanAttack then
        local EntityTarget = Entity:GetTarget()
        local InRange = (EntityTarget:GetPivot().Position - Entity:GetPivot().Position).Magnitude <= PatternRange
        if not InRange then
            return;
        end

        local Moveset = Movesets:Get(EntityName, true)
        local CurrentIndex = Behavior.PatternProgress
        local SkillName = CurrentPatternData.Skills[CurrentIndex]
        local NextSkill = CurrentPatternData.Skills[CurrentIndex + 1]

        Targets:MarkTarget(EntityTarget, Entity)

        Behavior.PatternProgress += 1;

        if NextSkill == nil then
            Targets:FreeTarget(EntityTarget)

            local IsSame = Behavior.LastUsedPattern.Name == Behavior.CurrentPattern
            if IsSame then
                Behavior.LastUsedPattern.UseCount += 1;
            else
                Behavior.LastUsedPattern.Name = Behavior.CurrentPattern;
                Behavior.LastUsedPattern.UseCount = 1;
            end
            
            Behavior.CurrentPattern = ''
        end

        local AttackerId = Entity:GetId()
		local ReplicationSkillId = Moveset:GetSkillId(SkillName)

		Targets:RefreshLastAttackedTime(EntityTarget, Entity)
		Replicator:EnemyUseSkill(AttackerId, ReplicationSkillId, 'Begin', EntityTarget)

		Moveset:Begin(SkillName, Entity, {
			Target = EntityTarget,
		})
    end
end

----
local Service = {
    BehaviorStates = {} :: { BehaviorTypes.EntityBehaviorState },
    BehaviorDefault = {} :: { {EntityId: number, UpdateClock: number} },

    BehaviorRanChecks = {},
}

function Service:Init()

    RunService.Heartbeat:Connect(function(Delta: number)
        for _, Default in Service.BehaviorDefault do
            local Entity = Enemies:GetEnemy(Default.EntityId)

            if Default.UpdateClock >= 1 then
                Default.UpdateClock = os.clock()

                Entity:Attack()
            end
        end


        for Index = #Service.BehaviorStates, 1, -1 do
            local Behavior = Service.BehaviorStates[Index];
            local Entity = Enemies:GetEnemy(Behavior.EntityId)

            if Entity == nil or not Entity:IsAlive() then
                table.remove(Service.BehaviorStates, Index)

                continue
            end

            ---
            if (os.clock() - Behavior.LastUpdate) < 1 / 8 then
                continue
            end

            Behavior.LastUpdate = os.clock()

            UpdateEntityBehavior(Behavior, Entity)
        end
    end)

end

function Service:InitializeBehaviors(Entity: AbilityTypes.ServerEnemy)
    local EntityBehaviorId = Entity.__Name
    local BehaviorLoader = Behaviors:GetBehavior(EntityBehaviorId)
    local EntityState = CreateState(Entity)
    local Connector, BehaviorState = CreateBehaviorConnector()
    
    if BehaviorLoader == nil then
        table.insert(Service.BehaviorDefault, {
            EntityId = Entity:GetId(),
            UpdateClock = os.clock()
        })

        return
    end

    local MovesetInformation = EnemyDatabase:GetMovesetData(EntityBehaviorId)

    BehaviorLoader(Connector, EntityState)

    if Service.BehaviorRanChecks[EntityBehaviorId] ~= true then
        Service.BehaviorRanChecks[EntityBehaviorId] = true

        for StoredSkillName in BehaviorState.Skills do
            local Normalized = String:NormalizeSkillName(StoredSkillName)

            for RealName in MovesetInformation do
                if String:NormalizeSkillName(RealName) == Normalized and (RealName ~= StoredSkillName) then
                    Debugger:DebugLine(`{EntityBehaviorId}_Behavior`, `"{StoredSkillName}" isn't a valid skill. Did you mean "{RealName}"?`)
                end
            end
        end
    end

    for PatternId, Pattern in BehaviorState.Patterns do
        local FirstSkill = Pattern.Skills[1];
        local Range = 10;

        if MovesetInformation[FirstSkill] ~= nil and MovesetInformation[FirstSkill].Base ~= nil then
            Range = (MovesetInformation[FirstSkill].Base.Range or Range)
        end
        
        BehaviorState.PatternRanges[PatternId] = Range
    end

    if BehaviorState.PhasePatterns.Base == nil then
        Debugger:WarnLine("EntityBehavior", `{EntityBehaviorId} behavior was not given a Base pattern.`, 1)
    end

    BehaviorState.EntityId = Entity:GetId()

    table.insert(Service.BehaviorStates, BehaviorState)
end

return Service