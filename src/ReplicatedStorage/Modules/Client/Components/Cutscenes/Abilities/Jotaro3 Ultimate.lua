--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Client.Classes

local AgentTypes = require(Shared.Types.Agents)
local CutsceneClass = require(Classes.Cutscene)
local CutsceneEffects = require(Client.Libraries.CutsceneEffects)
local AnimLib = require(Client.Libraries.Animation)
local Dir = "Characters.Jotaro3.Abilities.Ultimate."

--
local Cutscene = CutsceneClass.new("Jotaro3 Timestop", 0.85)

function Cutscene:Sequence(Agent: AgentTypes.AgentClass)
    Cutscene:SetCameraUser(Agent.__Player_Assigned)

    local AgentModel = Agent:GetModel()
    if Cutscene:IsCameraUser() then
        CutsceneEffects:HideHUD(Cutscene.__Time)
    end

    Cutscene:SetFOV(92, {0.433})

    task.delay(0.433, function()
        Cutscene:SetFOV(25, {0.1, 'Back'})
    end)

    local CameraAnimObj = AnimLib:GetAnim(Dir..'Camera')
    local AgentAnimObj = AnimLib:GetAnim(Dir..'Agent')

    AnimLib:Play(AgentModel, AgentAnimObj)
    local _ = Cutscene:AnimateCamera(AgentModel, CameraAnimObj)
end

return Cutscene