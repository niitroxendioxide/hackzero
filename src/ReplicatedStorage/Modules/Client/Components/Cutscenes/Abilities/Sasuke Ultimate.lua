--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Client.Classes

local AgentTypes = require(Shared.Types.Agents)
local CutsceneClass = require(Classes.Cutscene)
local CutsceneEffects = require(Client.Libraries.CutsceneEffects)
local AnimLib = require(Client.Libraries.Animation)
local Dir = "Characters.Sasuke.Abilities.Ultimate."

--
local Cutscene = CutsceneClass.new("Sasuke Ultimate", 1.6)

Cutscene:FilterCameraUsage(function(Agent: AgentTypes.AgentClass)
    if Agent.__Player_Assigned == Players.LocalPlayer then
        return true
    end

    return false
end)

function Cutscene:Sequence(Agent: AgentTypes.AgentClass)
    Cutscene:SetCameraUser(Agent.__Player_Assigned)

    local AgentModel = Agent:GetModel()
    if Cutscene:IsCameraUser() then
        CutsceneEffects:HideHUD(Cutscene.__Time)
        CutsceneEffects:ShowActionBars(1.5, .15, 0.45)
    end

    Cutscene:SetFOV(15, {0.4, 'Cubic'})

    task.delay(0.4, function()
        Cutscene:SetFOV(10, {0.233, 'Cubic', 'InOut'})

        task.wait(0.266)
        Cutscene:SetFOV(45)
        
        task.wait(0.05)
        Cutscene:SetFOV(65, {0.07, 'Linear'})
    end)

    local CameraAnimObj = AnimLib:GetAnim(Dir..'Camera')

    Cutscene:AnimateCamera(AgentModel, CameraAnimObj)
end

return Cutscene