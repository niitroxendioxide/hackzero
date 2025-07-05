--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Effects = require(Shared.Utility.Effects)
local DestructiblesDatabase = require(Shared.Database.Destructibles)

-- typedefs
type ParsedData = {Id: number, At: Vector3}
type ObjectData = {Created: number, Id: number, Model: Model?, Position: Vector3, Collider: BasePart, Cache: {}}
type Handler = (Data: ObjectData) -> ()
type ClientDestructible = {
    __Name: string,
    __Instances: {ObjectData},
    __On_Create: Handler?,
    __On_Destroy: Handler?,
    __On_Hit: Handler?,

    OnHit: (self: ClientDestructible, Bind: Handler) -> (),
    OnCreate: (self: ClientDestructible, Bind: Handler) -> (),
    OnDestroy: (self: ClientDestructible, Bind: Handler) -> (),

    Create: (self: ClientDestructible, Data: {}) -> (),
    Destroy: (self: ClientDestructible, Data: {}) -> (),
}

-- private

local function CreateColliderAt(Position: Vector3, Size: Vector3)
    local Newpart = Instance.new("Part")
    Newpart.Position = Position + (Vector3.yAxis * Size.Y/2)
    Newpart.Size = Size
    Newpart.Anchored = true
    Newpart.CanCollide = true
    Newpart.Transparency = 1
    Newpart.Color = Color3.new(0, .5, 1)
    Newpart.Name = "DestructibleCollider"
    Newpart.Parent = workspace.World.Entities:FindFirstChild("Destructibles")

    return Newpart
end

--
local ClientDestructible = {}
ClientDestructible.__index = ClientDestructible
ClientDestructible.Parent = workspace.World.Map:FindFirstChild('Destructibles') or Instance.new("Folder", workspace.World.Map)

function ClientDestructible.new(Name: string)
    ClientDestructible.Parent.Name = "Destructibles"

    local self = setmetatable({}, ClientDestructible)
    self.__Name = Name
    self.__Instances = {}
    self.__On_Hit = nil
    self.__On_Create = nil
    self.__On_Destroy = nil

    return self
end

function ClientDestructible.OnCreate(self: ClientDestructible, Bind: Handler)
    self.__On_Create = Bind
end

function ClientDestructible.OnDestroy(self: ClientDestructible, Bind: Handler)
    self.__On_Destroy = Bind
end

function ClientDestructible.OnHit(self: ClientDestructible, Bind: Handler)
    self.__On_Hit = Bind
end

function ClientDestructible.Create(self: ClientDestructible, Parsed: ParsedData)
    if not self.__On_Create then
        return
    end

    --
    local DestructibleData = DestructiblesDatabase:GetData(self.__Name)
    local New_Object: ObjectData = {
        Id = Parsed.Id,
        Created = os.clock(),
        Position = Parsed.At,
        Collider = CreateColliderAt(Parsed.At, DestructibleData.Size),
        Cache = {},
    }
    --

    if self.__Instances[Parsed.Id] ~= nil then
        self:Destroy(Parsed)
    end

    self.__Instances[Parsed.Id] = New_Object

    self.__On_Create(New_Object)
end

function ClientDestructible.Hit(self: ClientDestructible, Id: number)
    if not self.__On_Hit then
        return
    end

    --

    local Object = self.__Instances[Id]

    self.__On_Hit(Object)
end

function ClientDestructible.Destroy(self: ClientDestructible, Parsed: ParsedData)
    if not self.__On_Destroy then
        warn("No destroyer function bound to destructible! Name: ", self.__Name)

        return
    end

    --
    local Id = Parsed.Id
    local InstanceExists = self.__Instances[Id]
    InstanceExists.Collider:Destroy()

    self.__On_Destroy(InstanceExists)

    for _, Object in InstanceExists.Cache do
        Effects:CleanUp(Object, 10)
    end

    --
    self.__Instances[Id] = nil
end

return ClientDestructible