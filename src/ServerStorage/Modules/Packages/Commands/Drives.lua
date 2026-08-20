--
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules

local Network = require(Shared.Network)
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

    local Success, Err = DataService:AddDrive(Player, RandomDrive)
    if not Success then
        Network:Fire("ServerError", Player, if typeof(Err) == 'string' then Err else `Cannot add artifact past 1024 limit.`)

        return
    end

    DataService:UpdatePlayerDrives(Player)
end
