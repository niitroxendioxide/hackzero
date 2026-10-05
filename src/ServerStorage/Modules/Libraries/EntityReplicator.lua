--[[
	Packets for the 'Entities' channel: match entities that are neither agents nor enemies,
	recruits for now. Same idea as Replicator, with its own enum (`GameEnum.EntityReplication`)
	and its own remote so it grows without touching the agent and enemy packets. Read by
	`Client/Controllers/EntityController`.

	Every packet starts `[action u8][entity id u8]`. Anything taking a `Target` sends to that
	player alone (a late joiner being caught up), everyone otherwise.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local Network = require(Shared.Network)
local Math = require(Shared.Utility.Math)
local Types = require(Shared.Types.Recruits)
local RecruitsDatabase = require(Shared.Database.Recruits)

--
local CHANNEL = 'Entities'

local EntityReplicator = {
	CHANNEL = CHANNEL,
}

local function Send(Object: buffer, Target: Player?, ...: any)
	if Target then
		Network:Fire(CHANNEL, Target, Object, ...)
	else
		Network:FireForAll(CHANNEL, Object, ...)
	end
end

local function Header(Size: number, Action: number, Recruit: Types.ServerRecruitClass): buffer
	local Object = buffer.create(Size)
	buffer.writeu8(Object, 0, Action)
	buffer.writeu8(Object, 1, Recruit:GetId())

	return Object
end

local function GetOwnerId(Recruit: Types.ServerRecruitClass): number
	local Owner = Recruit:GetOwner()
	if not Owner then
		return 0
	end

	return (Owner:GetAttribute('ReplicationId') :: number?) or 0
end

local function ToByte(Value: number): number
	return math.clamp(math.round(Value), 0, 255)
end

--- Spawns it on the client: owner, kind, shield and where it stands, plus what to draw it as.
function EntityReplicator:CreateRecruit(Recruit: Types.ServerRecruitClass, Target: Player?)
	local Data = Recruit:GetData()
	local Shield, MaxShield = Recruit:GetShield()

	local Object = Header(18, GameEnum.EntityReplication.CreateRecruit, Recruit)
	buffer.writeu8(Object, 2, GetOwnerId(Recruit))
	buffer.writeu8(Object, 3, RecruitsDatabase:GetId(Recruit.Name) or 0)
	buffer.writeu8(Object, 4, ToByte(Shield))
	buffer.writeu8(Object, 5, ToByte(MaxShield))
	Math:EncodeCFrame(Recruit:GetPivot(), Object, 6)

	--- Sent as resolved, so a mission overriding the model or the name shows up as such.
	Send(Object, Target, {
		Model = Data.Model,
		Display_Name = Data.Display_Name,
		Height = Data.Appearance.Height,
	})
end

--- @param Reason `GameEnum.EntityRemoveReason`, a defeat plays its death.
function EntityReplicator:RemoveRecruit(Recruit: Types.ServerRecruitClass, Reason: number)
	local Object = Header(3, GameEnum.EntityReplication.RemoveRecruit, Recruit)
	buffer.writeu8(Object, 2, Reason)

	Send(Object)
end

--- The heading it walks on (zero to stop). The client keeps integrating it until the next one.
function EntityReplicator:MoveRecruit(Recruit: Types.ServerRecruitClass, Target: Player?)
	local Direction, Speed = Recruit:GetDirection()

	local Object = Header(5, GameEnum.EntityReplication.MoveRecruit, Recruit)
	buffer.writei8(Object, 2, math.clamp(math.round(Direction.X * 100), -100, 100))
	buffer.writei8(Object, 3, math.clamp(math.round(Direction.Z * 100), -100, 100))
	buffer.writeu8(Object, 4, ToByte(Speed))

	Send(Object, Target)
end

--- Where the server has it. `Teleport` makes the client snap rather than smooth the error out.
function EntityReplicator:SnapRecruit(Recruit: Types.ServerRecruitClass, Teleport: boolean?, Target: Player?)
	local Object = Header(15, GameEnum.EntityReplication.SnapRecruit, Recruit)
	Math:EncodeCFrame(Recruit:GetPivot(), Object, 2)
	buffer.writeu8(Object, 14, if Teleport then 1 else 0)

	Send(Object, Target)
end

--- @param Perpetrator Whoever hit it, its enemy id travels so the client can play it from there.
function EntityReplicator:HitRecruit(Recruit: Types.ServerRecruitClass, Hits: number, Perpetrator: any?)
	local Shield = Recruit:GetShield()
	local AttackerId = if typeof(Perpetrator) == 'table' and Perpetrator.GetId then Perpetrator:GetId() else 0

	local Object = Header(5, GameEnum.EntityReplication.HitRecruit, Recruit)
	buffer.writeu8(Object, 2, ToByte(Hits))
	buffer.writeu8(Object, 3, ToByte(Shield))
	buffer.writeu8(Object, 4, ToByte(AttackerId))

	Send(Object)
end

function EntityReplicator:SetRecruitShield(Recruit: Types.ServerRecruitClass, Target: Player?)
	local Shield, MaxShield = Recruit:GetShield()

	local Object = Header(4, GameEnum.EntityReplication.SetRecruitShield, Recruit)
	buffer.writeu8(Object, 2, ToByte(Shield))
	buffer.writeu8(Object, 3, ToByte(MaxShield))

	Send(Object, Target)
end

function EntityReplicator:SetRecruitOwner(Recruit: Types.ServerRecruitClass, Target: Player?)
	local Object = Header(3, GameEnum.EntityReplication.SetRecruitOwner, Recruit)
	buffer.writeu8(Object, 2, GetOwnerId(Recruit))

	Send(Object, Target)
end

function EntityReplicator:SetRecruitState(Recruit: Types.ServerRecruitClass, Target: Player?)
	local Object = Header(3, GameEnum.EntityReplication.SetRecruitState, Recruit)
	buffer.writeu8(Object, 2, table.find(GameEnum.RecruitStates, Recruit:GetState()) or 1)

	Send(Object, Target)
end

return EntityReplicator
