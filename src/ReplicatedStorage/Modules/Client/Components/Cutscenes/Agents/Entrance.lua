--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

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
   
    if AnimObj then 
        AnimLib:Play(EnvData.Model, AnimObj)
    end
    
    EntranceCutscene:Wait(math.max(Track.Length, 2.9))
    EntranceCutscene:End()
end

return EntranceCutscene