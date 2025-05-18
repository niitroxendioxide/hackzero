--
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules

local DriveDatabase = require(Shared.Database.Drives)
local DataService = require(Modules.Services.Data.DataService)
local PlayerDriveDataClass = require(Modules.Classes.Data.PlayerDriveData)

--
return function(Caster: TextSource, Parameters: {})

    local DriveName = Parameters[1]
    if not DriveName then
        return
    end

    --
    if not DriveDatabase:Verify(DriveName) then
        return
    end

    local Player = Players:GetPlayerByUserId(Caster.UserId)
    local RandomDrive = PlayerDriveDataClass.randomize(DriveName)

    print(RandomDrive)
    DataService:AddDrive(Player, RandomDrive)
    DataService:UpdatePlayerDrives(Player)
end
