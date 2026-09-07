--[[
    Server component for DungeonEx/Intro.

    Components under `Components/Maps/<Stage>/<Act>` are picked up by `StageHandlers` and
    handed to the mission that runs that act, so this is where a stage gets to react to its
    own run without any of it living in MatchService.

    On a procedural run the payload carries the seed the map was built from and the rooms
    the generator placed. Rolling off that seed (`Payload.Seed`, or `Mission:GetSeed()`)
    keeps a run reproducible: the same seed rebuilds the same layout *and* dresses it the
    same way.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local GameEnum = require(Shared.GameEnum)
local StageClass = require(Classes.Game.Stage)
local StageTypes = require(Shared.Types.Stages)

local DungeonIntro = StageClass.new()

DungeonIntro:OnBuild(function(Builder)
    local Room = Builder:PickFurthestRoom();

    Builder:AddEvent(Room, {
        Objective = "Defeat {objective[KillEnemies]} enemies";
        Goal = {
            ['KillEnemies'] = 20,
        },
        Enemies = {
            [1] = {
                {Name = "Sorcerer", Amount = 3, Level = 60},
                {Name = "SandShinobi", Amount = 5, Level = 60},
            },
            
            [2] = {
                {Name = "Sorcerer", Amount = 4, Level = 60},
                {Name = "SandShinobi", Amount = 2, Level = 60},
            },

            [3] = {
                {Name = "Saiyan", Amount = 4, Level = 60},
                {Name = "Sorcerer", Amount = 2, Level = 60},
            },
        },
    })
end)

DungeonIntro:AddHook(GameEnum.StageHook.Begin, function(_Mission: StageTypes.MissionClass, Payload)
    if not Payload.Procedural then
        return
    end

    local Rooms = Payload.Rooms or {}
    local RoomCount = 0

    for _, Room in Rooms do
        if not Room.IsHall then
            RoomCount += 1
        end
    end

    print(string.format("[DungeonEx/Intro] seed %d, %d rooms", Payload.Seed, RoomCount))
end)

return DungeonIntro
