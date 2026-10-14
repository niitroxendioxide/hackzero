const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

const Shared = ReplicatedStorage.Modules.Shared
const Services = ServerStorage.Modules.Services
const Libraries = ServerStorage.Modules.Libraries

const GameEnum = require(Shared.GameEnum)
const PlayersLibrary = require(Libraries.Players)
const Replicator = require(Libraries.Replicator)
const Movesets = require(Libraries.Movesets)
const AgentService = require(Services.Combat.AgentService)
const AbilityService = require(Services.Combat.AbilityService)
const CleanserService = require(Services.Match.CleanserService)

const ATTRIBUTE = 'Corruption'
const TICK = 0.5
const POISON_THRESHOLD = 50
const POISON_INTERVAL = 2
const POISON_PERCENT = 0.02
const ENERGY_DRAIN_CHANCE = 0.35
const ENERGY_DRAIN_PERCENT = 0.2
const CORRUPT_CHANCE = 0.25
const STRIP_TIME = 2
const CANCEL_DELAY = 0.3

const SAFE_SKILLS = {
    [GameEnum.Skills.Basic_Attack] = true,
    [GameEnum.Skills.Dodge] = true,
}

type Config = {
    Rate: number?,
    Decay: number?,
}

const Service = {
    __Mission = nil :: any,
    __Config = nil :: Config?,
    __Values = {} :: {[Player]: number},
    __Thread = nil :: thread?,
    __Random = Random.new(),
}

const function Poison(Player: Player)
    for _, Agent in AgentService:GetCharacters(Player) do
        if not Agent:IsAlive() then
            continue
        end

        const Health, MaxHealth = Agent:GetHealth()
        const Amount = math.min(MaxHealth * POISON_PERCENT, Health - 1)

        if Amount >= 1 then
            Agent:TakeDamage(Amount)
        end
    end
end

const function Step(dt: number)
    const Config = Service.__Config :: Config

    for _, StagePlayer in PlayersLibrary:GetAll() do
        const Player = StagePlayer:GetBase()
        const Agent = AgentService:GetCurrentCharacter(Player)
        if not Agent then
            continue
        end

        local Value = Service.__Values[Player] or 0
        const Protected, Cleansed = CleanserService:IsProtected(Agent:GetPivot().Position)

        if Cleansed then
            Value -= (Config.Decay or 5) * dt
        elseif not Protected then
            Value += (Config.Rate or 1) * dt
        end

        Value = math.clamp(Value, 0, 100)
        Service.__Values[Player] = Value

        if Value >= 100 and Service.__Mission and not Service.__Mission:GetProgressValue('Max_Corruption_Reached') then
            Service.__Mission:SetProgressValue('Max_Corruption_Reached', true)
        end

        const Shown = math.floor(Value)
        if Player:GetAttribute(ATTRIBUTE) ~= Shown then
            Player:SetAttribute(ATTRIBUTE, Shown)
        end
    end
end

const function Loop()
    local SincePoison = 0

    while Service.__Mission and not Service.__Mission:IsFinished() do
        Step(TICK)

        SincePoison += TICK
        if SincePoison >= POISON_INTERVAL then
            SincePoison = 0

            for Player, Value in Service.__Values do
                if Value >= POISON_THRESHOLD and Player.Parent then
                    Poison(Player)
                end
            end
        end

        task.wait(TICK)
    end

    Service:Clear()
end

const function CorruptCast(Agent: any)
    if Service.__Random:NextNumber() < 0.5 then
        Agent.__Corrupted_Until = os.clock() + STRIP_TIME
    else
        task.delay(CANCEL_DELAY, function()
            const Skill = Agent:GetCurrentSkill()
            const Moveset = Movesets:Get(Agent.Name)

            if Skill and Moveset then
                Moveset:CancelSkill(Skill, Agent, {ClientInstruction = false})
            end
        end)
    end

    Replicator:Effect('Corrupted', {Agent}, true)
end

const function OnSkillCasted(Agent: any, SkillId: number, _Enemy, StateId: number)
    if not Service.__Config or StateId ~= GameEnum.AbilityStates.Begin or SAFE_SKILLS[SkillId] then
        return
    end

    const Player = Agent.__Player_Assigned
    if not Player or (Service.__Values[Player] or 0) < 100 then
        return
    end

    if Service.__Random:NextNumber() < ENERGY_DRAIN_CHANCE then
        Agent:UseEnergy(Agent:GetEnergy() * ENERGY_DRAIN_PERCENT)
    end

    if Service.__Random:NextNumber() < CORRUPT_CHANCE then
        CorruptCast(Agent)
    end
end

function Service:Bind(Mission: any, Config: Config?)
    if not Config then
        return
    end

    Service.__Mission = Mission
    Service.__Config = table.clone(Config)
    Service.__Thread = task.spawn(Loop)

    AbilityService.SkillCasted:Connect(OnSkillCasted)
end

function Service:SetRate(Rate: number)
    if Service.__Config then
        Service.__Config.Rate = Rate
    end
end

function Service:Add(Player: Player, Amount: number)
    Service.__Values[Player] = math.clamp((Service.__Values[Player] or 0) + Amount, 0, 100)
end

function Service:Get(Player: Player): number
    return Service.__Values[Player] or 0
end

function Service:Clear()
    for Player in Service.__Values do
        Player:SetAttribute(ATTRIBUTE, nil)
    end

    table.clear(Service.__Values)
    Service.__Config = nil
end

return Service
