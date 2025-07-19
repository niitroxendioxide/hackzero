---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)
local Viewports = require(Client.Utility.Viewports)

---
local DETAILS = {
    Jotaro3 = {
        ColorCorrectionData = {
            Saturation = -1.25,
            Contrast = 0,
            Brightness = -0.125,
            TintColor = Color3.fromRGB(254, 251, 219)
        }
    }
}
---
return function(Caster: Types.AgentClass, Type: string, Time: number): ()
    if not DETAILS[Type] then
        return
    end

    task.spawn(function()
        if Caster.__Player_Assigned ~= Players.LocalPlayer then
            return
        end

        for i = 1, 3 do
            local Bubble = Assets.Effects.General.Distortion.Bubble:Clone()
            Bubble.Size = vector.create(10, 10, 10)
            Bubble.Transparency = 1
            Bubble.Parent = workspace.World.Effects

            local id = 'bubbleeffect'..i
            local Time = 0.4
            RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value, function(d)
                Bubble.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -1)
            end)

            Effects:Tween(Bubble, {Time, 'Quad'}, {Transparency = 2, Size = vector.zero})
            Effects:CleanUp(Bubble, Time)

            task.delay(Time, function()
                RunService:UnbindFromRenderStep(id)
            end)

            task.wait(0.15)
        end

    end)

    --
    EffectsLib:Play('Timestop_Screen_Effect', Time, DETAILS[Type].ColorCorrectionData)

    local StandModel = workspace.World.Effects:FindFirstChild(Caster.PlayerId..'SPstandmodel')
    if not StandModel then
        return
    end

    local CharacterViewport = Viewports.new({
		Object = Caster:GetModel(),
		GetModelDescendants = true,
		ZIndex = 1,
		RenderedProperties = {'CFrame'},
	})

    if not CharacterViewport then
        return
    end

    Effects:ShakeCamera('Hit')

    CharacterViewport:Start()

    local Model = Instance.new('Model')
    Model.Name = 'Stand'
    Model.Parent = CharacterViewport._viewportobject

    local StandViewport = Viewports.new({
		Object = StandModel,
        ModelParent = Model,
		GetModelDescendants = true,
		ZIndex = 1,
		RenderedProperties = {'CFrame'},
	})

    StandViewport:Start()

    task.delay(Time, function()
        CharacterViewport:Destroy()
        StandViewport:Destroy()
    end)
end