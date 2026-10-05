--[[
	@class EntityController

	Client end of the 'Entities' channel (`GameEnum.EntityReplication`), the server end being
	`Libraries/EntityReplicator`. It covers match entities that are neither agents nor enemies,
	recruits for now: their client copies live in `Libraries/Recruits`, and this feeds them
	whatever the server sends.
]]
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Client = ReplicatedStorage.Modules.Client
const Shared = ReplicatedStorage.Modules.Shared

const GameEnum = require(Shared.GameEnum)
const Network = require(Shared.Network)
const Places = require(Shared.Places)
const Math = require(Shared.Utility.Math)
const Statics = require(Shared.Database.Statics)
const RecruitsDatabase = require(Shared.Database.Recruits)
const Recruits = require(Client.Libraries.Recruits)
const RecruitClass = require(Client.Classes.Recruit)
const ReplicationController = require(script.Parent.ReplicationController)

const CHANNEL = 'Entities'

--
const Handlers = {} :: {[number]: (Buffer: buffer, ...any) -> ()}

Handlers[GameEnum.EntityReplication.CreateRecruit] = function(Buffer: buffer, Visuals: {[string]: any}?)
    const Id = buffer.readu8(Buffer, 1)
    const Name = RecruitsDatabase:FromId(buffer.readu8(Buffer, 3)) or 'Template'

    --- Same id again means the server reused it, the old copy is stale.
    const Existing = Recruits:Remove(Id)
    if Existing then
        Existing:Destroy()
    end

    const New = RecruitClass.new(Id, Name, Math:DecodeCFrame(Buffer, 6), Visuals)
    New:SetOwner(buffer.readu8(Buffer, 2))
    New:SetShield(buffer.readu8(Buffer, 4), buffer.readu8(Buffer, 5))
    New:Init()

    Recruits:Add(New)
end

Handlers[GameEnum.EntityReplication.RemoveRecruit] = function(Buffer: buffer)
    const Removed = Recruits:Remove(buffer.readu8(Buffer, 1))
    if Removed then
        Removed:Destroy(buffer.readu8(Buffer, 2))
    end
end

Handlers[GameEnum.EntityReplication.MoveRecruit] = function(Buffer: buffer)
    const Recruit = Recruits:Get(buffer.readu8(Buffer, 1))
    if not Recruit then
        return
    end

    const Direction = Vector3.new(buffer.readi8(Buffer, 2) / 100, 0, buffer.readi8(Buffer, 3) / 100)

    Recruit:Move(Direction, buffer.readu8(Buffer, 4))
end

Handlers[GameEnum.EntityReplication.SnapRecruit] = function(Buffer: buffer)
    const Recruit = Recruits:Get(buffer.readu8(Buffer, 1))
    if not Recruit then
        return
    end

    local At = Math:DecodeCFrame(Buffer, 2)
    const Teleport = buffer.readu8(Buffer, 14) == 1

    if not Teleport then
        --- It kept walking while the packet was on its way, a one-way trip's worth.
        const Latency = math.clamp(ReplicationController:GetPing() / 2000, 0, Statics.Replication_Max_Extrapolation)

        At += Recruit.__Movement:GetVelocity() * Latency
    end

    Recruit:Sync(At, Teleport)
end

Handlers[GameEnum.EntityReplication.HitRecruit] = function(Buffer: buffer)
    const Recruit = Recruits:Get(buffer.readu8(Buffer, 1))
    if not Recruit then
        return
    end

    Recruit:DisplayHit(buffer.readu8(Buffer, 2), buffer.readu8(Buffer, 3))
end

Handlers[GameEnum.EntityReplication.SetRecruitShield] = function(Buffer: buffer)
    const Recruit = Recruits:Get(buffer.readu8(Buffer, 1))
    if not Recruit then
        return
    end

    Recruit:SetShield(buffer.readu8(Buffer, 2), buffer.readu8(Buffer, 3))
end

Handlers[GameEnum.EntityReplication.SetRecruitOwner] = function(Buffer: buffer)
    const Recruit = Recruits:Get(buffer.readu8(Buffer, 1))
    if not Recruit then
        return
    end

    Recruit:SetOwner(buffer.readu8(Buffer, 2))
end

Handlers[GameEnum.EntityReplication.SetRecruitState] = function(Buffer: buffer)
    const Recruit = Recruits:Get(buffer.readu8(Buffer, 1))
    const State = GameEnum.RecruitStates[buffer.readu8(Buffer, 2)]

    if Recruit and State then
        Recruit:SetState(State)
    end
end

--
const Controller = {}

function Controller:Init()
    if not Places:CanFight() then
        return
    end

    Network:On(CHANNEL, function(Buffer: buffer, ...)
        const Handler = Handlers[buffer.readu8(Buffer, 0)]

        if Handler then
            Handler(Buffer, ...)
        end
    end)
end

return Controller
