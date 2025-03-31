--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database


local Types = require(Shared.Types)
local WorldData = require(Database.Worlds)

-- Methods
local Service = {}

function Service:IsInPlace(Place: Types.GamePlace): boolean
    if not (WorldData[Place]) then
        warn("Invalid place name given {", Place, "}");
        return false;
    end

    local PlaceId = game.PlaceId

    return PlaceId == WorldData[Place];
end

function Service:CanFight(): boolean
    local PlaceId = game.PlaceId

    return (PlaceId == WorldData.Mission or PlaceId == WorldData.Raid);
end

return Service