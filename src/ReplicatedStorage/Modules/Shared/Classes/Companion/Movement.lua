--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Companions)
local AgentTypes = require(Shared.Types.Agents)


---
local Rng = Random.new()

local CompanionMovementClass = {}
CompanionMovementClass.__index = CompanionMovementClass

function CompanionMovementClass.new(Speed: number): Types.CompanionMovementClass
    local self = setmetatable({}, CompanionMovementClass)
    self.__Goal = vector.create(0, 0, 0)
    self.__Position = vector.create(0, 0, 0)
    self.__Direction = vector.create(0, 0, 0)
    self.__Follow_Object = nil
    self.__Collider = nil
    self.__Area = nil
    self.__Can_Move = true
    self.__Speed = Speed
    self.__Moving = false
    self.__Clock = os.clock()
    self.__Movement_Length = 1

    return self
end

function CompanionMovementClass.CreateCollider(self: Types.CompanionMovementClass): ()
    local ParentFolder = workspace.World.Entities:FindFirstChild('Companions') or Instance.new("Folder")
    ParentFolder.Name = "Companions"
    ParentFolder.Parent = workspace.World.Entities

    local Collider = Instance.new("Part")
    Collider.Size = vector.one * 2
    Collider.CFrame = self.__Position
    Collider.Anchored = true
    Collider.CanQuery = false
    Collider.CanCollide = false
    Collider.Color = Color3.new(1, 0, 1)
    Collider.Parent = ParentFolder

    self.__Collider = Collider

    return Collider
end

function CompanionMovementClass.PivotTo(self: Types.CompanionMovementClass, At: CFrame)
    return CFrame.lookAlong(self.__Position :: Vector3, self.__Direction :: Vector3)
end

function CompanionMovementClass.GetCollider(self: Types.CompanionMovementClass): BasePart
    return self.__Collider
end

function CompanionMovementClass.Update(self: Types.CompanionMovementClass, Delta: number): ()

    if not self.__Moving and self.__Can_Move then

        if self.__Area then
            local Size = self.__Area.Size
            local At = self.__Area:GetPivot()
            local Goal = At * CFrame.new(Rng:NextNumber(-Size.X/2, Size.X/2), Rng:NextNumber(-Size.Y/2, Size.Y/2), Rng:NextNumber(-Size.Z/2, Size.Z/2))

            self.__Goal = vector.create(Goal.Position.X, Goal.Position.Y, Goal.Position.Z)
        elseif self.__Follow_Object then
            self.__Goal = (self.__Follow_Object :: AgentTypes.AgentClass):GetPivot().Position
        end

        self.__Moving = true
        self.__Can_Move = false
        self.__Clock = os.clock()
        self.__Movement_Length = Rng:NextNumber(4, 6)

    elseif self.__Moving and (os.clock() - self.__Clock >= self.__Movement_Length) then

        self.__Moving = true
        self.__Can_Move = false

        task.delay(Rng:NextNumber(0.6, 1.5), function()
            self.__Can_Move = true
        end)

    end

    local Distance = vector.magnitude((self.__Position :: vector) - (self.__Goal :: vector))
    if Distance <= 0 then
        return
    end

    local Direction = vector.normalize(self.__Goal::vector - self.__Position::vector)

    self.__Position += Direction * self.__Speed
    self.__Direction = Direction

    self.__Collider.CFrame = self:GetPivot()
end

function CompanionMovementClass.SetArea(self: Types.CompanionMovementClass, Box: BasePart): ()
    self.__Area = Box
end

function CompanionMovementClass.Follow(self: Types.CompanionMovementClass, Agent: AgentTypes.AgentClass | AgentTypes.ServerAgentClass): ()
    self.__Follow_Object = Agent
end

return CompanionMovementClass
