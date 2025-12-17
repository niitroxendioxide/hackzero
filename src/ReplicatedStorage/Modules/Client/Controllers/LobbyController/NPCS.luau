--!strict

--[[
    @niitroxendioxide 2025-10

    Generates NPCs that walk around the lobby
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local UIController = require(Client.Controllers.InterfaceController)
local Appearance = require(Client.Classes.Appearance)
local Prompts = require(Client.Libraries.Prompts)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Shared.Utility.Effects)


-- typedef
type Character = {
    Id: string,
    Model: any,
    Position: vector | Vector3,
    Direction: vector | Vector3,
    MoveTime: number,
    MoveStarted: number,
    UntilNext: number,
    Created: number,
    Lifetime: number,
    Collider: BasePart,

    Moving: boolean,
    Available: boolean,
    Talking: boolean,
}

--- Constants / Statics
local RNG = Random.new()
local MAX_NPC_COUNT = 6
local SPAWN_RATE = 2
local MIN_SPAWN_RANGE = 12
local MAX_SPAWN_RANGE = 80



local Controller = {
    __Inited = false,
    __Present_Npcs = {} :: { Character },
}

function MainThread(): ()
    local SpawnClock = os.clock()

    while true do
        local Delta = task.wait()

        if os.clock() - SpawnClock > SPAWN_RATE then
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
        Update(Character, Delta)
    end
end

function Update(NPC: Character, Delta: number): ()
    if (os.clock() - NPC.Created) >= NPC.Lifetime and not NPC.Talking then
        return RemoveNPC(NPC.Id)
    end

    local HasMovementEnded = os.clock() - NPC.MoveStarted > NPC.MoveTime
    if HasMovementEnded then
        NPC.Moving = false
        local IsOver = os.clock() - NPC.MoveStarted
        local CanStartMoving = IsOver > NPC.UntilNext
        if not CanStartMoving then return end

        NPC.Direction = CFrame.Angles(0, RNG:NextNumber(-math.pi * 2, math.pi * 2), 0).LookVector

        NPC.MoveStarted = os.clock()
        NPC.UntilNext = RNG:NextNumber(3, 5)
        NPC.MoveTime = RNG:NextNumber(1, 2)
        NPC.Moving = true
    end

    if not NPC.Moving or NPC.Talking then
        return
    end

    local Movement = (NPC.Direction :: vector) * 8 * Delta
    local NewPosition = NPC.Position :: vector + Movement :: vector
    NPC.Position = NewPosition
    NPC.Collider.CFrame = CFrame.lookAlong(NPC.Position:: Vector3, NPC.Direction :: Vector3)
end

function HandleNewNPCCreation(): ()
    if #Controller.__Present_Npcs >= MAX_NPC_COUNT then
        return
    end

    local NewNpc = NewCharacter()
    if not NewNpc then
        return
    end

    local Prompt = Prompts:CreatePromptOnPart(NewNpc.Collider, GameEnum.InteractionType.LobbyNPC, "Talk", "Agent")
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

    local BaseCF = (BaseChar:FindFirstChild("HumanoidRootPart") :: BasePart):GetPivot()
    local RandomId = HttpService:GenerateGUID(false)
    local DirCF = BaseCF * CFrame.Angles(0, RNG:NextNumber(-math.pi * 2, math.pi * 2), 0)
    local Len = RNG:NextInteger(MIN_SPAWN_RANGE, MAX_SPAWN_RANGE)

    local BasePos = DirCF * CFrame.new(0, 0, -Len)
    local IsColliding = Effects:CastMapRaycast(DirCF.Position, DirCF.LookVector * Len)
    if IsColliding then
        BasePos = DirCF * CFrame.new(0, 0, -(IsColliding.Distance - 2))
    end


    local Base = Instance.new("Part")
    Base.Size = Vector3.new(1, 1, 1)
    Base.Anchored = true
    Base.CanCollide = false
    Base.Transparency = 1
    Base.CFrame = BasePos
    Base.Parent = workspace.World.Entities.Colliders

    local Model = Appearance.new("SecretAgent", "Agents", true)
    Model:JoinTo(Base, 45)

    local Char: Character = {
        Id = RandomId,
        Model = Model,
        Position = BasePos.Position,
        Direction = -DirCF.LookVector,
        MoveTime = 1,
        MoveStarted = os.clock(),
        Created = os.clock(),
        Lifetime = RNG:NextNumber(14, 36),
        UntilNext = RNG:NextNumber(2, 4),
        Collider = Base,

        Available = true,
        Moving = true,
    } :: Character

    return Char
end

function Controller:Init()
    if Controller.__Inited then
        return
    end

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

    Prompts:DisableAll()

    NPC.Collider.CFrame = CFrame.lookAlong(NPC.Position:: Vector3, -Direction)
    NPC.Talking = true

    local CurrentIndex = 1
    local Dialogues = {
        "Hello! I need some help",
        "So, I want you to go into those places and get back my suitcase",
        "Thanks in advance!",
    }

    local Available = DialogueComponent:OpenDialogue("Agent Worker", Dialogues)
    if not Available then
        return
    end
    
    DialogueComponent:BoxSkipped(function()
        if CurrentIndex >= #Dialogues then
            DialogueComponent:CloseDialogue()
            NPC.Talking = false
            Prompts:EnableAll()

            return
        end
        

        CurrentIndex += 1
        DialogueComponent:DisplayDialogue(Dialogues[CurrentIndex])
    end)
end


return Controller;