local ReplicatedStorage = game:GetService('ReplicatedStorage')

--
local Shared = ReplicatedStorage.Modules.Shared

local Signal = require(Shared.Utility.Signal)
local EnemyLibrary = require(Shared.Libraries.Enemies)

--
const TURRET_COLOR = Color3.fromRGB(171, 97, 255)
const TURRET_TRANSPARENCY = 0.5
const DEFAULT_SIZE = vector.create(2, 5, 2)

export type TurretData = {
	Lifetime: number,
	Range: number,
	Interval: number,
	Size: vector?,
}

--
local ServerTurret = {}
ServerTurret.__index = ServerTurret
ServerTurret.__tostring = function()
	return 'TurretClass'
end

local function GetFolder(): Folder
	local Entities = workspace.World.Entities
	local Folder = Entities:FindFirstChild('Turrets')

	if not Folder then
		Folder = Instance.new('Folder')
		Folder.Name = 'Turrets'
		Folder.Parent = Entities
	end

	return Folder
end

function ServerTurret.new(Owner: any, At: CFrame, Data: TurretData)
	local self = setmetatable({}, ServerTurret)
	self.Destroyed = Signal.new()

	self.__Owner = Owner
	self.__Pivot = At
	self.__Range = Data.Range
	self.__Interval = Data.Interval
	self.__Active = true

	local Part = Instance.new('Part')
	Part.Name = 'Turret'
	Part.Size = Data.Size or DEFAULT_SIZE
	Part.CFrame = At
	Part.Color = TURRET_COLOR
	Part.Material = Enum.Material.SmoothPlastic
	Part.Transparency = TURRET_TRANSPARENCY
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false
	Part.CastShadow = false
	Part.Parent = GetFolder()

	self.__Part = Part
	self.__Lifetime_Thread = task.delay(Data.Lifetime, function()
		self:Destroy()
	end)

	return self
end

function ServerTurret.Start(self, GetTarget: (Turret: any) -> any?, OnFire: (Turret: any, Target: any) -> ())
	self.__Fire_Thread = task.spawn(function()
		while self.__Active do
			task.wait(self.__Interval)

			if not self.__Active then
				break
			end

			local Target = GetTarget(self)
			if self:CanFireAt(Target) then
				OnFire(self, Target)
			end
		end
	end)
end

function ServerTurret.CanFireAt(self, Target: any): boolean
	if Target == nil or not Target:IsAlive() or EnemyLibrary:GetEnemy(Target:GetId()) ~= Target then
		return false
	end

	return self:IsInRange(Target)
end

function ServerTurret.IsInRange(self, Target: any): boolean
	return (Target:GetPivot().Position - self.__Pivot.Position).Magnitude <= self.__Range
end

function ServerTurret.SetInterval(self, Interval: number)
	self.__Interval = Interval
end

function ServerTurret.GetOwner(self)
	return self.__Owner
end

function ServerTurret.GetPivot(self): CFrame
	return self.__Pivot
end

function ServerTurret.IsAlive(self): boolean
	return self.__Active
end

function ServerTurret.Destroy(self)
	if not self.__Active then
		return
	end

	self.__Active = false

	if self.__Lifetime_Thread ~= coroutine.running() then
		task.cancel(self.__Lifetime_Thread)
	end

	if self.__Fire_Thread and self.__Fire_Thread ~= coroutine.running() then
		task.cancel(self.__Fire_Thread)
	end

	self.__Part:Destroy()
	self.Destroyed:Fire(self)
end

return ServerTurret
