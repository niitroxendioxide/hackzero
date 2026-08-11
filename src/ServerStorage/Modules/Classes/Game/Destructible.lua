--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Signal = require(Shared.Utility.Signal)
local Network = require(Shared.Network)
local StructureList = require(Modules.Libraries.StructureList)
local DestructibleTypes = require(Shared.Types.Structures)
local DestructiblesDatabase = require(Shared.Database.Destructibles)

--
type Destructible = DestructibleTypes.DestructibleServerEntity

--
local function CreateColliderAt(GivenCFrame)
    local Newpart = Instance.new("Part")
    Newpart.CFrame = GivenCFrame
    Newpart.Size = Vector3.one * 2
    Newpart.Anchored = true
    Newpart.CanCollide = true
    Newpart.Transparency = .5
    Newpart.Color = Color3.new(0, 0, 1)
    Newpart.Name = "DestructibleCollider"
    Newpart.Parent = workspace.Camera.Destructibles

    return Newpart
end

--
local DestructibleClass = {}
DestructibleClass.__index =  DestructibleClass;
DestructibleClass.__tostring = function()
    return 'DestructibleClass'
end

function DestructibleClass.new(Type: string, At: CFrame)
    local self = setmetatable({}, DestructibleClass)
    self.Destroyed = Signal.new()

    self.__CFrame = At;
    self.__Collider = CreateColliderAt(At)
    self.__Health = 0
    self.__Type = Type
    self.__Id = 0

    return self
end

function DestructibleClass.GetId(self: Destructible)
    return 9000 + self.__Id;
end

function DestructibleClass.HasTag(self: Destructible)
    return false
end

function DestructibleClass.AddTag(self: Destructible)
    return
end

function DestructibleClass.RemoveTag(self: Destructible)
    return
end

function DestructibleClass.IsAirborne(self: Destructible)
    return false
end

function DestructibleClass.GetState(self: Destructible)
    return 'Idle'
end

function DestructibleClass.GetPivot(self: Destructible)
    return self.__CFrame
end


function DestructibleClass.Spawn(self: Destructible, Id: number)
    local Data = DestructiblesDatabase:GetData(self.__Type)

    self.__Collider.CFrame *= CFrame.new(0, Data.Size.Y/2, 0)
    self.__Collider.Size = Data.Size

    self.__Health = Data.Health
    self.__Id = Id

    StructureList:Add(self)
end

function DestructibleClass.Compress(self: Destructible, OnlyId: boolean)
    if self.__Id < 1 then
        return
    end

    -- Don't need to send all the info for just destroying or hitting it, so why do it :v
    if OnlyId then
        local Obj = buffer.create(2)
        buffer.writeu8(Obj, 0, self.__Id)
        buffer.writeu8(Obj, 1, DestructiblesDatabase:GetId(self.__Type))

        return  Obj
    end

    local Object = buffer.create(2)
    buffer.writeu8(Object, 0, self.__Id)
    buffer.writeu8(Object, 1, DestructiblesDatabase:GetId(self.__Type))

    return Object, self.__A
end

function DestructibleClass.TakeDamage(self: Destructible, Perpetrator: Types.GenericClass, Damage: number)
    local NewHealth = self.__Health - Damage

    self.__Health = NewHealth

    if NewHealth <= 0 then
        self.Destroyed:Fire(Perpetrator)
        self:Destroy()

        return true
    end

    -- hit structure, very hardcoded but whatever man
    local BufferObj = self:Compress(true)
    local BufferLen = buffer.len(BufferObj)
    local NewBuffer = buffer.create(BufferLen + 1)
    buffer.writeu8(NewBuffer, 0, GameEnum.Replication.HitDestructible)
    buffer.copy(NewBuffer, 1, BufferObj, 0, BufferLen)

    Network:FireForAll("Replicate", NewBuffer)

    return false
end

function DestructibleClass.GetCollider(self: Destructible)
    return self.__Collider
end

function DestructibleClass.Destroy(self: Destructible)
    -- send signal to destroy here too !!
    StructureList:Remove(self)

    self.__Collider:Destroy()
end

return DestructibleClass