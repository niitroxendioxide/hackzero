--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local DestructiblesDatabase = require(Shared.Database.Destructibles)

--
type Destructible = {

    __Type: string,
    __Position: Vector3,
    __Collider: BasePart,
    __Health: number,
    __Id: number,

    Destroy: (self: Destructible) -> (),
    Compress: (self: Destructible) -> (buffer),

    GetCollider: (self: Destructible) -> (BasePart),
    GetPosition: (self: Destructible) -> (Vector3),

    --[[
        Sets up the destructible and it's stats
    ]]
    Spawn: (self: Destructible, Id: number) -> (),
    TakeDamage: (self: Destructible, Amount: number) -> (),
}

--
local function CreateColliderAt(Position: Vector3)
    local Newpart = Instance.new("Part")
    Newpart.Position = Position
    Newpart.Size = Vector3.one * 2
    Newpart.Anchored = true
    Newpart.CanCollide = true
    Newpart.Transparency = 1
    Newpart.Color = Color3.new(0, 0, 1)
    Newpart.Name = "DestructibleCollider"
    Newpart.Parent = workspace.Camera.Destructibles

    return Newpart
end

--
local DestructibleClass = {}
DestructibleClass.__index =  DestructibleClass;

function DestructibleClass.new(Type: string, Position: Vector3)
    local self = setmetatable({}, DestructibleClass)
    self.__Position = Position or Vector3.new()
    self.__Collider = CreateColliderAt(self.__Position)
    self.__Health = 0
    self.__Type = Type
    self.__Id = 0

    return self
end

function DestructibleClass.Spawn(self: Destructible, Id: number)
    local Data = DestructiblesDatabase:GetData(self.__Type)

    self.__Collider.Size = Data.Size

    self.__Health = Data.Health
    self.__Id = Id
end

function DestructibleClass.Compress(self: Destructible)
    if self.__Id < 1 then
        return
    end

    local Object = buffer.create(12)
    buffer.writeu8(Object, 0, self.__Id)
    buffer.writeu8(Object, 1, DestructiblesDatabase:GetId(self.__Type))
    buffer.writef32(Object, 2, self.__Position.X)
    buffer.writef32(Object, 6, self.__Position.Z)
    buffer.writei16(Object, 10, math.floor(self.__Position.Y * 10))

    return Object
end

function DestructibleClass.TakeDamage(self: Destructible)
    
end

function DestructibleClass:Destroy()
    -- send signal to destroy here too !!
    self.__Collider:Destroy()
end

return DestructibleClass