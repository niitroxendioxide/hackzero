---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Effects = require(Shared.Utility.Effects)
local DistanceFade = require(Client.Libraries.DistanceFade)
local CharactersLib = require(Client.Libraries.Characters)

local Loops = {}
local ObjectCache = {}
local Threads = {}

local BarrierDefaultSettings = {
	["EdgeDistanceCalculations"] = true,
	["Texture"] = "rbxassetid://76340810197746",
	["TextureTransparency"] = .3,
	["BackgroundTransparency"] = 0.975,
	["TextureColor"] = Color3.fromRGB(255, 79, 25),
	["BackgroundColor"] = Color3.fromRGB(238, 56, 15),
	["TextureSize"] = Vector2.new(2, 1.9),
	["TextureOffset"] = Vector2.new(0, .5),
	["Brightness"] = 1,
    ["DistanceOuter"] = 10,
}

---
return function(Id: string, ObjectList: {BasePart}, Centre: Vector3, State: boolean): ()

    if ObjectCache[Id] then
        ObjectCache[Id]:Clear()
        
        for _, Connection in (Loops[Id] or {}) do
            Connection:Disconnect()
        end

        return
    end

    if not Loops[Id] then
        Loops[Id] = {}
    end

    local DistanceFadeObject = DistanceFade.new()
    DistanceFadeObject:UpdateSettings(BarrierDefaultSettings)

    local PartList = {}
    for _, Object in ObjectList do
        local SizeDifference = Object.Size.Y - 2
        local Direction = CFrame.lookAt(Object.Position, Centre).LookVector

        local Clone = Object:Clone()
        Clone.CFrame = Object.CFrame * CFrame.new(0, (-SizeDifference/2) + 5, 0)
        Clone.Size = Vector3.new(Object.Size.X, 2, Object.Size.Z)
        Clone.Anchored = true
        Clone.CanCollide = false
        Clone.CollisionGroup = "Effects"
        Clone.Parent = workspace.World.Effects

        local NormalId = Enum.NormalId.Back
        if Direction:Dot(Object.CFrame.RightVector) > 0.05 then
            NormalId = Enum.NormalId.Right
        elseif Direction:Dot(Object.CFrame.RightVector) < -0.05 then
            NormalId = Enum.NormalId.Left
        elseif Direction:Dot(Object.CFrame.LookVector) > 0.05 then
            NormalId = Enum.NormalId.Front
        end

        ---
        table.insert(Loops[Id], RunService.Heartbeat:Connect(function(a0: number)
            if not LocalPlayer.Character then
                return;
            end
            
            local Pivot = LocalPlayer.Character:GetPivot()

            Clone.Position = Clone.Position:Lerp(vector.create(Clone.Position.X, Pivot.Position.Y, Clone.Position.Z), a0 * 10)
        end))

        ---
        table.insert(PartList, Clone)
        Clone:SetAttribute("normal", NormalId)
        DistanceFadeObject:AddFace(Clone, NormalId)
    end

    ObjectCache[Id] = DistanceFadeObject

    Threads[Id] = RunService.Heartbeat:Connect(function(Delta: number)
        local Character = CharactersLib:GetCurrent()
        if not Character then
            return
        end

        local CurrentCentre = Character:GetPivot().Position

        DistanceFadeObject:Step(CurrentCentre)
    end)
end