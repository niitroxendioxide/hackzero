--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

--
local World = workspace:FindFirstChild("World")
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Classes = Client.Classes

local Types = require(Shared.Types)
local CutsceneClass = require(Classes.Cutscene)
local CutsceneEffects = require(Client.Libraries.CutsceneEffects)
local AnimLib = require(Client.Libraries.Animation)

--
local EntranceCutscene = CutsceneClass.new("TrainingAreaTest", 3)

function EntranceCutscene.Sequence(self: Types.CutsceneClass, Data: {Model})
    local EnvData = EntranceCutscene:GetPlayerEnvironment()

    print('Yo i am a cutscene')

    CutsceneEffects:HideHUD(EntranceCutscene.__Time)
end

return EntranceCutscene