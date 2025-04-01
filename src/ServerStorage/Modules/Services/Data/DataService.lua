--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Packages = ServerStorage.Modules.Packages
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local ProfileTemplate = require(Database.Data.ProfileTemplate)

local ProfileStore = require(Packages.Data.ProfileStore)
local DataStore = ProfileStore.New("Testing0", ProfileTemplate)

--
local Service = {
    __Profiles = {} :: {[Player]: typeof(ProfileStore:StartSessionAsync())},
}

local function RecursiveSearch(Data: {}, Key: string): ({}, string)
    local Split = string.split(Key, "/")
    local End = Data;
    local FinalKey = Split[#Split];

    for Key = 1, #Split - 1 do
        local RealKey = Split[Key]

        if End[RealKey] == nil then break end

        End = End[RealKey]
    end

    return End, FinalKey
end

function Service:Init()

end

function Service:AddPlayer(Player: Player)
    local RetrievedProfile = DataStore:StartSessionAsync(`{Player.UserId}`, {
        Cancel = function()
            return Player.Parent ~= Players
        end,
    })

    -- Handling new profile session or failure to start it:

    if RetrievedProfile ~= nil then

        RetrievedProfile:AddUserId(Player.UserId) -- GDPR compliance
        RetrievedProfile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

        RetrievedProfile.OnSessionEnd:Connect(function()
            Service.__Profiles[Player] = nil
            Player:Kick(`Profile session ended. Rejoin (Data disconnected)`)
        end)

        if Player.Parent == Players then
            Service.__Profiles[Player] = RetrievedProfile
        else
        -- The player has left before the profile session started
            RetrievedProfile:EndSession()
        end

    else
        Player:Kick(`Profile load fail - Please rejoin`)
    end
end

function Service:RemovePlayer(Player: Player)
    local SavedProfile = Service.__Profiles[Player]
    if SavedProfile ~= nil then
        SavedProfile:EndSession()
    end
end

function Service:GetDataFor(Player: Player): Types.PlayerProfileData
    local Data = Service.__Profiles[Player]
    if Data == nil then
        return {} :: Types.PlayerProfileData;
    end

    return Data
end

function Service:Set(Player: Player, GivenKey: string, Value: any)
    local Data = Service:GetDataFor(Player)
    local Dir, Key = RecursiveSearch(Data, GivenKey)

    if typeof(Value) ~= Dir[Key] then
        return warn("Invalid type given for key:", GivenKey, `value expected: {typeof(Dir[Key])}, given: {typeof(Value)}`)
    end

    Dir[Key] = Value

    return;
end

function Service:Get(Player: Player, GivenKey: string)
    local Data = Service:GetDataFor(Player)
    local Dir, Key = RecursiveSearch(Data, GivenKey)

    return Dir[Key]
end

function Service:Add(Player: Player, GivenKey: string, Object: {}): ()
    local Data = Service:GetDataFor(Player)
    local Dir, Key = RecursiveSearch(Data, GivenKey)

    if typeof(Dir[Key]) ~= "table" then
        return warn(`Cannot add object to table because directory {GivenKey} is not a table`)
    end

    table.insert(Dir[Key], Object)

    return;
end

return Service
