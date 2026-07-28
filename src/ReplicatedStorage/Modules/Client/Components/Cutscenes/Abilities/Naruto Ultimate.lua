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
local EffectsLibrary = require(Client.Libraries.Effects)
local Dir = "Characters.Naruto.Abilities.Ultimate."

--
local Cutscene = CutsceneClass.new("Naruto Ultimate", 1.45)

local Offsets = {
    CFrame.new(-3.638, 0, 4.661) * CFrame.Angles(0, math.rad(-11.25), 0),
    CFrame.new(-9.578, 0, 8.26) * CFrame.Angles(0, math.rad(-33.75), 0),
    CFrame.new(5.97, 0, 3.997) * CFrame.Angles(0, math.rad(22.5), 0),
    CFrame.new(4.85, 0, 10.932) * CFrame.Angles(0, math.rad(11.25), 0),
}

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
        local CloneAnimation = AnimLib:GetAnim(Dir..'ClonePose')

        task.delay(0.4, function()
            EffectsLibrary:Play("Naruto_Clone", Agent, 0.9, Offsets[3], {Object = CloneAnimation, Speed = 1, Weight = 1})
            EffectsLibrary:Play("Naruto_Clone", Agent, 0.9, Offsets[4], {Object = CloneAnimation, Speed = 1, Weight = 1})

            task.wait(0.383)
            EffectsLibrary:Play("Naruto_Clone", Agent, 0.9, Offsets[1], {Object = CloneAnimation, Speed = 1, Weight = 1})
            EffectsLibrary:Play("Naruto_Clone", Agent, 0.9, Offsets[2], {Object = CloneAnimation, Speed = 1, Weight = 1 })
        end)
    end

    Cutscene:SetFOV(45)
    Cutscene:SetFOV(35, {0.167, 'Quad', 'In'})

    task.delay(0.167, function()
        Cutscene:SetFOV(25, {0.133, 'Linear'})

        task.wait(0.133)
        Cutscene:SetFOV(20, {0.183, 'Sine', 'Out'})
    end)

    local CameraAnimObj = AnimLib:GetAnim(Dir..'Camera')

    Cutscene:AnimateCamera(AgentModel, CameraAnimObj)
end

return Cutscene