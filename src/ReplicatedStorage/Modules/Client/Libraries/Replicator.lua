local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

--
local Controller = {
	__LastRotationValue = Vector3.zAxis,
	__LastUpdate = os.clock(),
	__ReplicationFrequency = 5,
}

function Controller:Replicate(Action: number, ...)
	local Args = table.pack(...)
	local EventName = 'Replicate';
	local Buffer
	if Action == GameEnum.Replication.Move or Action == GameEnum.Replication.Stop then
		Buffer = buffer.create(1)
	elseif Action == GameEnum.Replication.KeySwitch then
		Buffer = buffer.create(2)
		local Key = Args[1]

		Args = {}
		buffer.writeu8(Buffer, 1, Key)
	elseif Action == GameEnum.Replication.Rotate then
		local Rotation = Args[1]

		if Rotation == Controller.__LastRotationValue or (Rotation - Controller.__LastRotationValue).Magnitude < 0.005 then
			return
		end

		Controller.__LastRotationValue = Rotation

		local Vec = Args[1].Unit
		local Angle = math.deg(math.atan2(Vec.X, Vec.Z))


		Buffer = buffer.create(3)
		buffer.writei16(Buffer, 1, Angle * 180)

		Args = {}
	elseif Action == GameEnum.Replication.PivotTo then
		if (os.clock() -  Controller.__LastUpdate < Controller.__ReplicationFrequency) and not(Args[2] == true) then
			return
		end

		Controller.__LastUpdate = os.clock()

		local At = Args[1]
		Buffer = buffer.create(12)
		buffer.writef32(Buffer, 2, At.X)
		buffer.writef32(Buffer, 6, At.Z)
		buffer.writei16(Buffer, 10, At.Y * 100)

		Args = {}
	elseif Action == GameEnum.Replication.CharacterSwitch then
		Buffer = buffer.create(2)

		buffer.writei8(Buffer, 1, Args[1])

		Args = {}
	elseif Action == GameEnum.Replication.UseSkill then
		Buffer = buffer.create(3)

		buffer.writei8(Buffer, 1, Args[1])
		buffer.writei8(Buffer, 2, Args[2] or 0)

		EventName = 'Ability'
		Args = {}
	end

	buffer.writeu8(Buffer, 0, Action)

	Network:Fire(EventName, Buffer, table.unpack(Args))
end

return Controller
