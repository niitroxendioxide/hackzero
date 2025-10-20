
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services

local DestructibleService = require(Services.Match.DestructibleService)
local GameEnum = require(Shared.GameEnum)
local StageClass = require(Classes.Game.Stage)

local HuecoMundoIntro = StageClass.new()

HuecoMundoIntro:AddHook(GameEnum.StageHook.Begin, function() 
    print("I hook the beginning of the mission!")
end)

HuecoMundoIntro:ForTrigger("Room_2", function(Trigger: BasePart)
    print("I create a crystal!")

    DestructibleService:Create("Crystals", Trigger.CFrame * CFrame.new(-24, -38, 25))
    DestructibleService:Create("Crystals", Trigger.CFrame * CFrame.new(31, -38, 25))
end)

return HuecoMundoIntro
















