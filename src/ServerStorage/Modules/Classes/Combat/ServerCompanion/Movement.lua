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
    self.__Direction = vector.create(0, 0, -1)
    self.__Follow_Object = nil
    self.__Collider = nil
    self.__Area = nil
    self.__Can_Move = true
    self.__Speed = Speed or 32
    self.__Moving = false
    self.__Clock = os.clock()
    self.__Movement_Length = 1

    return self
end

function CompanionMovementClass.GetPivot(self: Types.CompanionMovementClass)
    return CFrame.lookAlong(self.__Position::Vector3, self.__Direction::Vector3)
end

function CompanionMovementClass.CreateCollider(self: Types.CompanionMovementClass): ()
    local ParentFolder = workspace.Camera:FindFirstChild('Companions') or Instance.new("Folder")
    ParentFolder.Name = "Companions"
    ParentFolder.Parent = workspace.Camera

    local Collider = Instance.new("Part")
    Collider.Size = vector.one * 2
    Collider.CFrame = self:GetPivot()
    Collider.Anchored = true
    Collider.CanQuery = false
    Collider.CanCollide = false
    Collider.Transparency = 0.85
    Collider.Color = Color3.new(1, 0, 1)
    Collider.Parent = ParentFolder

    self.__Collider = Collider

    return Collider
end

function CompanionMovementClass.PivotTo(self: Types.CompanionMovementClass, At: CFrame)
    self.__Position = At.Position
    self.__Direction = At.LookVector
end

function CompanionMovementClass.GetCollider(self: Types.CompanionMovementClass): BasePart
    return self.__Collider
end

function CompanionMovementClass.IsMoving(self: Types.CompanionMovementClass)
    return self.__Moving
end

function CompanionMovementClass.Update(self: Types.CompanionMovementClass, Delta: number): ()

    if not self.__Moving and self.__Can_Move then
        if self.__Area then
            local Size = self.__Area.Size
            local At = self.__Area:GetPivot()
            local Goal = At * CFrame.new(Rng:NextNumber(-Size.X/2, Size.X/2), Rng:NextNumber(-Size.Y/2, Size.Y/2), Rng:NextNumber(-Size.Z/2, Size.Z/2))

            self.__Goal = vector.create(Goal.Position.X, Goal.Position.Y, Goal.Position.Z)

            self.__Movement_Length = Rng:NextNumber(2.75, 5)
        elseif self.__Follow_Object then

            local PivotPosition = (self.__Follow_Object :: AgentTypes.AgentClass):GetPivot().Position

            self.__Movement_Length = Rng:NextNumber(0.5, 1.75)
            self.__Goal = vector.create(Rng:NextNumber(-14, 14) + PivotPosition.X, PivotPosition.Y, Rng:NextNumber(-14, 14) + PivotPosition.Z)
        end

        self.__Moving = true
        self.__Can_Move = false
        self.__Clock = os.clock()

    elseif (os.clock() - self.__Clock >= self.__Movement_Length) then
        self.__Moving = false
        self.__Can_Move = false

        task.delay(Rng:NextNumber(0.6, 1.5), function()
            self.__Can_Move = true
        end)

    end

    if not self.__Moving then return end

    local Direction = vector.normalize(self.__Goal::vector - self.__Position::vector)
    local Displacement = Direction * self.__Speed * Delta
    local NextPosition = (self.__Position + Displacement) :: vector

    if vector.magnitude(NextPosition - self.__Goal) > vector.magnitude(self.__Goal::vector - self.__Position::vector) then
        self.__Moving = false

        return
    end

    self.__Position += Displacement
    self.__Direction = Direction

    self.__Collider.CFrame = self:GetPivot()
end

function CompanionMovementClass.GetGoal(self: Types.CompanionMovementClass)
    return CFrame.lookAlong(self.__Goal::Vector3, self.__Direction::Vector3)
end

function CompanionMovementClass.SetArea(self: Types.CompanionMovementClass, Box: BasePart): ()
    self.__Area = Box
end

function CompanionMovementClass.Follow(self: Types.CompanionMovementClass, Agent: AgentTypes.AgentClass | AgentTypes.ServerAgentClass): ()
    self.__Follow_Object = Agent
end

return CompanionMovementClass
