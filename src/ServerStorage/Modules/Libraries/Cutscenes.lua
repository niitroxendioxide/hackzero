--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Signal = require(Shared.Utility.Signal)

-- Type defs
type ActiveCutsceneData = {
    CutsceneName: string,
    MaxTimeout: number,
    Finished: typeof(Signal.new()),
    Created: number,
}

type QueueCutsceneData = {
    CutsceneName: string,
    Created: number,
}

local Users = {
    __Queue = {} :: {[Player]: QueueCutsceneData},
    __Active = {} :: {[Player]: ActiveCutsceneData},
}


local CutscenesServer = {}
type ServerCutsceneLibrary = typeof(CutscenesServer)

-- Private
local function AcceptPlayer(Player: Player, TimeoutTime: number)
    local WasInQueue = Users.__Queue[Player]
    if not WasInQueue or typeof(TimeoutTime) == 'nil' or TimeoutTime > 100 then
        return
    end

    local Thread: thread?;
    local Event = Signal.new()
    Event:Once(function()
        if Thread then
            task.cancel(Thread)
            Thread = nil;
        end

        Users.__Active[Player] = nil
    end)

    -- setting
    Users.__Active[Player] = {
        CutsceneName = WasInQueue.CutsceneName,
        MaxTimeout = TimeoutTime,
        Finished = Event,
        Created = os.clock(),
    }

    Users.__Queue[Player] = nil

    Thread = task.delay(TimeoutTime, function()
        Event:Fire()
    end)
end

local function Finish(Player: Player)
    local Data = Users.__Active[Player]
    if not Data then
        return
    end

    Data.Finished:Fire();
end

local function IsInQueue(Player: Player)
    return Users.__Queue[Player]
end

local function AddToQueue(Player: Player, Name: string): QueueCutsceneData?
    local Data = {
        CutsceneName = Name,
        Created = os.clock(),
    }

    if IsInQueue(Player) then
        -- edge case where the queue wasn't cleared(?) just in case.
        local PreexistingData = Users.__Queue[Player]
        if os.clock() - PreexistingData.Created < 1 then
            return
        end
    end

    Users.__Queue[Player] = Data

    return Data
end

-- Public
function CutscenesServer.Init(self: ServerCutsceneLibrary)
    Network.new("Cutscene", "Event")
    Network:On("Cutscene", function(Player: Player, Type: number, Data: {[string]: any})
        if Type == GameEnum.CutsceneStatus.Finished then
            Finish(Player)
        elseif Type == GameEnum.CutsceneStatus.Received then
            AcceptPlayer(Player, Data.TimeoutTime)
        end
    end)
end

--[[
    Play a cutscene for a specific player

    @param Player Player to show cutscene for
    @param CutsceneName Cutscene to show
    @return `State` : `boolean` Whether or not the cutscene played out successfuly
]]
function CutscenesServer.Attempt(self: ServerCutsceneLibrary, Player: Player, CutsceneName: string): boolean
    local AddedData = AddToQueue(Player, CutsceneName)
    if not AddedData then
        return false
    end

    Network:Fire("Cutscene", Player, GameEnum.CutsceneStatus.Received, CutsceneName)

    repeat
        task.wait()
    until not IsInQueue(Player)

    local WaitingForCutsceneStatus = CutscenesServer:WaitFor(Player)

    return WaitingForCutsceneStatus
end

--[[
    Attempt to play a cutscene for each group, since the cutscenes play individually this function is asynchronous, so the return contains a signal
    @param Group A group of players to play the cutscene for
    @param CutsceneName The name of the cutscene to play
]]
function CutscenesServer.AttemptGroup(self: ServerCutsceneLibrary, Group: {Player}, CutsceneName: string): RBXScriptSignal
    local Signal = Signal.new()
    print(Group)

    --
    for _, Player in Group do
        if typeof(Player) ~= 'Instance' or not Player:IsA("Player") then
            continue
        end

        task.spawn(function()
            local Finished = CutscenesServer:Attempt(Player, CutsceneName)

            if Finished then
                Signal:Fire()
            end
        end)
    end

    return Signal
end

--[[
    Wait until a player is out of a cutscene
    @param Player The player to wait for
    @return `State` : `boolean` Whether the player was or not in a cutscene
]]
function CutscenesServer.WaitFor(self: ServerCutsceneLibrary, Player: Player): boolean
    if not Users.__Active[Player] then
        return false
    end

    local UserInfo = Users.__Active[Player]
    local MaxTimeout = UserInfo.MaxTimeout

    local FinishedState = false;
    UserInfo.Finished:Connect(function(): ()
        FinishedState = true
    end)

    repeat
        task.wait()
    until (FinishedState == true) or (os.clock() - UserInfo.Created) > MaxTimeout

    return true
end

return CutscenesServer
