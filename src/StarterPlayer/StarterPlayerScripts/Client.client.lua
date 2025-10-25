local ReplicatedStorage = game:GetService('ReplicatedStorage')
-- Something idk

--
local Modules =  ReplicatedStorage.Modules
local Client = Modules.Client
local Framework = require(Modules.Framework)

Framework:Init(Modules.Shared.Database, Client.Libraries, Client.Controllers)