--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

--
local World = workspace:FindFirstChild("World")
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets.Characters
local Classes = Client.Classes

local Types = require(Shared.Types)
local CutsceneClass = require(Classes.Cutscene)
local CutsceneEffects = require(Client.Libraries.CutsceneEffects)
local AnimLib = require(Client.Libraries.Animation)

--
local EntranceCutscene = CutsceneClass.new("Entrance", 2.9)

function EntranceCutscene.Sequence(self: Types.CutsceneClass, Data: {Model})
    local EnvData = EntranceCutscene:GetPlayerEnvironment()

    CutsceneEffects:HideHUD(2.9)

    local Track = EntranceCutscene:AnimateCamera(EnvData.CFrame, 'Entrance.Camera')
    local AnimObj = AnimLib:GetAnim('Cutscenes.Entrance.Agents.' .. EnvData.AgentName)
    AnimLib:Play(EnvData.Model, AnimObj)

    EntranceCutscene:Wait(math.max(Track.Length, 2.9))
    EntranceCutscene:End()
end

return EntranceCutscene