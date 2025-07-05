--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Classes = Client.Classes

local Types = require(Shared.Types)
local CutsceneClass = require(Classes.Cutscene)
local CutsceneEffects = require(Client.Libraries.CutsceneEffects)

--
local EntranceCutscene = CutsceneClass.new("TrainingAreaTest", 3)

function EntranceCutscene.Sequence(self: Types.CutsceneClass, Data: {Model})
    CutsceneEffects:HideHUD(EntranceCutscene.__Time)
end

return EntranceCutscene