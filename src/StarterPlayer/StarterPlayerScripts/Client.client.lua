local ReplicatedStorage = game:GetService('ReplicatedStorage')
-- Something idk

--
local Modules =  ReplicatedStorage.Modules
local Client = Modules.Client
local Framework = require(Modules.Framework)

Framework:Init(Modules.Shared.Database, Modules.Shared.Libraries, Client.Libraries, Client.Controllers)