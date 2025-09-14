local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared
local RandomNameGen = require(ReplicatedStorage.Modules.Client.Utility.RandomNameGen)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local World = require(ReplicatedStorage.Modules.Shared.World)
local Appearance = require(script.Parent.Appearance)
local Animator = require(script.Animator)
local Types = require(Shared.Types.Companions)

--
local FRAME_CONSTANT = 60
function CreateColliderObject(At: CFrame)
    local Parent = workspace.World.Entities:FindFirstChild('Companions') or Instance.new("Folder")
    Parent.Name = "Companions"
    Parent.Parent = workspace.World.Entities

    local Part = Instance.new("Part")
    Part.CFrame = At
    Part.CanCollide = false
    Part.CanQuery = false
    Part.Anchored = true
    Part.Name = "ColliderCompanion"
    Part.Transparency = 1
    Part.Size = vector.one * 2
    Part.Parent = Parent

    return Part
end

--
local ClientCompanionClass = {}
ClientCompanionClass.__index = ClientCompanionClass

function ClientCompanionClass.new(Name: string, At: CFrame, UUID: string): Types.ClientCompanionClass
    local self = setmetatable({}, ClientCompanionClass)
    self.Name = Name
    self.__Goal = At
    self.__Collider = CreateColliderObject(At)
    self.__Appearance = Appearance.new(Name, "Companions")
    self.__Animator = Animator.new(self, Name)
    self.__Connection = nil
    self.__Moving = false
    self.__Owner_Id = -1
    self.__UUID = UUID

    return self
end

function ClientCompanionClass.GetName(self: Types.ClientCompanionClass): string
    return RandomNameGen(self.__UUID)
end

function ClientCompanionClass.IsOwner(self: Types.ClientCompanionClass, Player: Player): boolean
    return self.__Owner_Id == (Player:GetAttribute("ReplicationId") :: number)
end

function ClientCompanionClass.Init(self: Types.ClientCompanionClass, Key: number, OwnerId: number)
    if self.__Connection then return end

    self.__Owner_Id = OwnerId
    self.__Appearance:JoinTo(self.__Collider)
    self.__Animator:Init()

    --[[self.__Connection = RunService.Heartbeat:Connect(function(Delta: number)
    end)]]
end

function ClientCompanionClass.GetModel(self: Types.ClientCompanionClass)
    return self.__Appearance:GetModel()
end

function ClientCompanionClass.SetMoving(self: Types.ClientCompanionClass, State: boolean)
    self.__Moving = State
end

function ClientCompanionClass.IsMoving(self: Types.ClientCompanionClass)
    return self.__Moving
end

function ClientCompanionClass.Move(self: Types.ClientCompanionClass, At: CFrame): ()
    local CorrectedCFrame = At

    local Cast = workspace:Raycast(At.Position, At.UpVector * -10, World:GetMapParams())
    if Cast then
        CorrectedCFrame = CFrame.lookAlong(Cast.Position + Cast.Normal*3, -CorrectedCFrame.LookVector)
    end

    self.__Goal = CorrectedCFrame


    Effects:Tween(self.__Collider, {1/6}, {CFrame = self.__Goal})
end

return ClientCompanionClass
