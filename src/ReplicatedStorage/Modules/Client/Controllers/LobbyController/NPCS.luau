--!strict

--[[
    @niitroxendioxide 2025-10

    Generates NPCs that walk around the lobby
]]

const PathfindingService = game:GetService("PathfindingService")
const HttpService = game:GetService("HttpService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Client = ReplicatedStorage.Modules.Client
const Shared = ReplicatedStorage.Modules.Shared

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local LocalData = require(ReplicatedStorage.Modules.Client.Libraries.LocalData)
local Network = require(ReplicatedStorage.Modules.Shared.Network)
local Math = require(ReplicatedStorage.Modules.Shared.Utility.Math)
const UIController = require(Client.Controllers.InterfaceController)
const Appearance = require(Client.Classes.Appearance)
const Prompts = require(Client.Libraries.Prompts)
const GameEnum = require(Shared.GameEnum)
const Effects = require(Shared.Utility.Effects)
const TextForType = require(Client.Utility.TextForType);

--- // DIALOGUE DATA
const STARTING_DIALOGUES = {
    {
        Text = "Oh, What's up, are you new around here? Do you need anything?",
        Responses = {
            'Yes, I\'m trying to do favors to grow my reputation.',
            '...',
        },
    },

    {
        Text = "Hey, do you need anything?",
        Responses = {
            'Yes, i\'m a new dive-agent.',
            '...',
        },
    },

    {
        Text = "Hi.. Wait, are you a Dive-agent? I might have something for you",
        Responses = {
            'Yes, I do want ',
            '...',
        },
    },
}

const SUBSEQUENT_DIALOGUES = {
    {
        Text = "Alright, may you %s",
        Responses = {
            'Yes, I will.',
            'I don\'t think I can',
        }
    },

    {
        Text = "Oh, do you want tasks? Why don\'t you %s",
        Responses = {
            'Alright, I will.',
            'I don\'t think I can',
        }
    },

    {
        Text = "Could you please %s",
        Responses = {
            'Anything for you, let me get on it.',
            'Sorry, I cannot do that',
        }
    },
}

-- typedef
type Character = {
    Id: string,
    Model: any,
    Position: vector | Vector3,
    Direction: vector | Vector3,
    Created: number,
    Lifetime: number,
    Collider: BasePart,
    ChosenPath: number,

    Moving: boolean,
    Available: boolean,
    Talking: boolean,
    ProducedPath: Path,
    CurrentWaypointIndex: number,
    MoveGoal: PathWaypoint,

    Animations: { [string]: AnimationTrack },
}

--- Constants / Statics
const RNG = Random.new();
const MAX_NPC_COUNT = 16;
const SPAWN_TIME = 2.75;
const WALK_SPEED = 8;
const NPC_HEIGHT = Vector3.new(0, 3, 0)


const Controller = {
    __Inited = false,
    __Present_Npcs = {} :: { Character },
}

function MainThread(): ()
    local SpawnClock = os.clock()

    while true do
        local Delta = task.wait()

        if os.clock() - SpawnClock > (SPAWN_TIME) then
            SpawnClock = os.clock()
            HandleNewNPCCreation()
        end

        ProcessNpcMovements(Delta)

    end
end

function RemoveNPC(p_NPC_Id: string)
    for Index, Character in Controller.__Present_Npcs do
        if Character.Id == p_NPC_Id then
            table.remove(Controller.__Present_Npcs, Index)
            
            Character.Collider:Destroy()
            Character.Model:Destroy(true)

            break
        end
    end
end

function ProcessNpcMovements(Delta: number): ()
    for _, Character in Controller.__Present_Npcs do
        task.spawn(Update, Character, Delta)
    end
end

function Update(NPC: Character, Delta: number): ()
    if (os.clock() - NPC.Created) >= NPC.Lifetime and not NPC.Talking then
        return RemoveNPC(NPC.Id)
    end
    
    ---
    if not NPC.ProducedPath then
        local Paths = (workspace :: any).World.Map.AgentPaths:GetChildren();
        local Chosen = Paths[NPC.ChosenPath];

        local PathResult = PathfindingService:CreatePath({
            AgentRadius = 1.25,
            AgentHeight = 3,
            AgentCanJump = false,
            AgentCanClimb = false,
            WaypointSpacing = 3,
            Costs = {
                Avoid = math.huge,
            }
        })

        NPC.CurrentWaypointIndex = 0;

        local Success, ErMessage = pcall(function(...)
            return PathResult:ComputeAsync(Chosen.Start.Position, Chosen.End.Position)
        end)

        if Success and PathResult.Status == Enum.PathStatus.Success then
            NPC.ProducedPath = PathResult;
        else
            warn('Error when producing path:', ErMessage)
        end
    end

    ---
    if not NPC.ProducedPath or typeof(NPC.ProducedPath) ~= 'Instance' then
        return;
    end

    local Waypoints = NPC.ProducedPath:GetWaypoints() :: { PathWaypoint };
    local NextWaypoint = Waypoints[NPC.CurrentWaypointIndex + 1];
    if NPC.Moving == false and NextWaypoint ~= nil then
        NPC.Moving = true;
        NPC.MoveGoal = NextWaypoint;
        NPC.CurrentWaypointIndex += 1;
    end

    if (NextWaypoint == nil and not NPC.Moving) and not NPC.Talking then
        RemoveNPC(NPC.Id);
        
        return
    end

    if NPC.Talking or not NPC.Moving then
        if NPC.Talking then
            NPC.Animations.Walk:AdjustWeight(0.001);
        end

        return;
    end

    NPC.Moving = true;

    const UsedWalkSpeed = WALK_SPEED;
    const CurrentWaypoint = NPC.MoveGoal;
    local DistanceToWaypoint = (NPC.Position :: Vector3 -  CurrentWaypoint.Position).Magnitude;
    local Moved = CFrame.lookAt(NPC.Position :: Vector3, CurrentWaypoint.Position).LookVector;
    local Result = (Moved * UsedWalkSpeed * Delta);

    if NPC.Animations.Walk then
        NPC.Animations.Walk:AdjustSpeed(WALK_SPEED / 8);
        NPC.Animations.Walk:AdjustWeight(1);
    end

    if (Result.Magnitude >= DistanceToWaypoint) then
        NPC.Moving = false;
        NPC.Position += Result;
    else
        NPC.Position += Result;
        NPC.Direction = Moved.Unit;
    end

    local UsedPosition = NPC.Position :: Vector3 + NPC_HEIGHT
    const Ground = Effects:CastMapRaycast(UsedPosition, vector.create(0, -10))
    if Ground then
        UsedPosition = Ground.Position + NPC_HEIGHT;
    end

    NPC.Collider.CFrame = CFrame.lookAlong(UsedPosition, NPC.Direction :: Vector3)
end

function HandleNewNPCCreation(): ()
    if #Controller.__Present_Npcs >= MAX_NPC_COUNT then
        return
    end

    local NewNpc = NewCharacter()
    if not NewNpc then
        return
    end

    local Prompt = Prompts:CreatePromptOnPart(NewNpc.Collider, GameEnum.InteractionType.LobbyNPC, "Talk", "Agent", 9)
    Prompt:SetAttribute("NpcId", NewNpc.Id)

    task.delay(.5, function()
        NewNpc.Model:SetVisible(true)
    end)

    table.insert(Controller.__Present_Npcs, NewNpc)
end

function NewCharacter(): Character?
    local BaseChar = Players.LocalPlayer.Character :: Model
    if not BaseChar then
        return nil
    end

    local PossiblePaths = (workspace :: any).World.Map.AgentPaths:GetChildren()
    local TotalAmount = #PossiblePaths
    local Chosen = math.random(1, TotalAmount);

    local BaseCF = PossiblePaths[Chosen].Start.CFrame * CFrame.new(0, 3, 0);
    local RandomId = HttpService:GenerateGUID(false)


    local Base = Instance.new("Part")
    Base.Size = Vector3.new(1, 1, 1)
    Base.Anchored = true
    Base.CanCollide = false
    Base.Transparency = 1
    Base.CFrame = BaseCF
    Base.Parent = (workspace :: any).World.Entities.Colliders

    const Randomizer = Random.new(Math:ToSeedNumber(RandomId))
    const Appearance = Appearance.new("SecretAgent", "Agents", true, Randomizer)
    Appearance:JoinTo(Base, 45)

    const AnimList = {}
    const Model = Appearance:GetModel();
    local AnimationObject = Animation:GetMovementAnim('General', 'Walk')

    if typeof(AnimationObject) == 'Instance' and AnimationObject:IsA('Animation') then
        AnimList.Walk = Animation:Play(Model, AnimationObject, 0, 1, 1) :: AnimationTrack
        AnimList.Walk.Looped = true 
    end

    const MAX_LIFETIME = ((PossiblePaths[Chosen].Start.Position - PossiblePaths[Chosen].End.Position).Magnitude / WALK_SPEED) * 2.5
    local Char: Character = {
        Id = RandomId,
        Model = Appearance,
        Position = BaseCF.Position,
        Direction = BaseCF.LookVector,
        MoveTime = 1,
        MoveStarted = os.clock(),
        Created = os.clock(),
        Lifetime = MAX_LIFETIME,
        UntilNext = RNG:NextNumber(2, 4),
        Collider = Base,
        ChosenPath = Chosen,

        Available = true,
        Moving = false,
        Animations = AnimList,
    } :: Character

    return Char
end

const function RequestMissionCreation(UUID: string)
    Network:Fire("AgencyTasks", GameEnum.AgencyTaskEvent.RetrieveInfoForUUID, UUID)
end

const function AcceptGivenTask(UUID: string)
    Network:Fire("AgencyTasks", GameEnum.AgencyTaskEvent.AcceptUUIDMission, UUID)
end

function Controller:Init()
    if Controller.__Inited then
        return
    end

    ---
    Network:On("AgencyTasks", function(Type: number, Packet: { Id: string, Data: any } & { any })
        if Type == GameEnum.AgencyTaskEvent.RetrieveInfoForUUID then
            local UUID = Packet.Id;
            local Mission = Packet.Data;

            LocalData:AllocateUUIDMission(UUID, Mission);
        elseif Type == GameEnum.AgencyTaskEvent.RetrieveAllAccepted then
            LocalData:AllocateAllAcceptedTasks(Packet)
        end
    end)

    ---
    Controller.__Inited = true

    task.spawn(MainThread)
end

function Controller:GetById(Id: string): Character?
    for _, Npc in Controller.__Present_Npcs do
        if Npc.Id == Id then
            return Npc
        end
    end

    return nil;
end

function Controller:TalkToNPC(NpcId: string)
    local NPC = Controller:GetById(NpcId)
    if not NPC then
        return
    end

    local DialogueComponent = UIController:GetComponent("LobbyDialogue") :: {[string]: any}
    if not DialogueComponent then
        return
    end

    local UserCharacter = Players.LocalPlayer.Character :: Model
    local RootPos = (UserCharacter:FindFirstChild('HumanoidRootPart') :: BasePart).Position
    local Direction = CFrame.lookAt(RootPos * Vector3.new(1, 0, 1), (NPC.Position :: Vector3) * Vector3.new(1, 0, 1)).LookVector

    if LocalData:GetUUIDMission(NpcId, false) == nil then
        RequestMissionCreation(NpcId)
    end

    Prompts:DisableAll()

    local At = NPC.Position:: Vector3 + NPC_HEIGHT;
    local Ground = Effects:CastMapRaycast(At, vector.create(0, -12, 0))
    if Ground then
        At = Ground.Position + NPC_HEIGHT;
    end

    NPC.Collider.CFrame = CFrame.lookAlong(At, -Direction)
    NPC.Talking = true

    local CurrentIndex = 1

    local ChosenStarter = math.random(1, #STARTING_DIALOGUES)
    local Available = DialogueComponent:OpenDialogue("Agent ".. TextForType.GetNameForSeed(NpcId), STARTING_DIALOGUES[ChosenStarter])
    if not Available then
        return
    end

    const function Close()
        DialogueComponent:CloseDialogue()
        NPC.Talking = false
        Prompts:EnableAll()
    end
    
    DialogueComponent:BoxSkipped(function(OptionChosen: number)
        if OptionChosen == 1 and CurrentIndex > 1 then
            AcceptGivenTask(NpcId)
            Close()

            return
        end

        if (OptionChosen ~= 1) or (CurrentIndex > 1) then
            Close()

            return
        end

        local MissionInformation = LocalData:GetUUIDMission(NpcId, true, 5)
        if not MissionInformation then
            Close()

            return;
        end

        local FormattedText = TextForType.ForDialogue(MissionInformation);

        local NewDialogue = table.clone(SUBSEQUENT_DIALOGUES[ChosenStarter]);
        NewDialogue.Text = string.format(NewDialogue.Text, FormattedText);

        CurrentIndex += 1
        DialogueComponent:DisplayDialogue(NewDialogue)
    end)
end


return Controller;