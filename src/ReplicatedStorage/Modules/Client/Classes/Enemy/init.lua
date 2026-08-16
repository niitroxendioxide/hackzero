--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Enemies = require(ReplicatedStorage.Modules.Shared.Database.Enemies)
local Agents = require(ReplicatedStorage.Modules.Shared.Types.Agents)
local ClockUtil = require(Shared.Utility.Clock)

local EnemyStatus = require(Shared.Classes.Enemy.EnemyStatus)
local Types = require(Shared.Types)
local AnimatorClass = require(script:WaitForChild('Animator'))
local MovementClass = require(Shared.Classes.Enemy.EnemyMovement)
local AppearanceClass = require(Client.Classes.Appearance)
local Fusion = require(Client.Libraries.Fusion)
local EnemyOverheadGui = require(Client.Libraries.EnemyStatusIndicator)

--
local EnemyClass = {} :: {new: (At: Vector3, Name: string) -> Types.EnemyClass, [string]: (self: Types.EnemyClass, any) -> any}
EnemyClass.__index = EnemyClass
EnemyClass.__tostring = function(_)
	return 'EnemyClass'
end

function EnemyClass.new(At: Vector3, Name: string, Level: number): Types.EnemyClass
	local EnemyDBData = Enemies:GetEnemyData(Name)
	local self = setmetatable({}, EnemyClass)
	self.Name = Name or 'EnemyTemplate'

	--
	self.__Status = EnemyStatus.new(self.Name, Level)
	self.__Movement = MovementClass.new(At, EnemyDBData.Stats.Movement_Speed, EnemyDBData.Appearance.Height)
	self.__Animator = AnimatorClass.new(self, self.Name)
	self.__Appearance = AppearanceClass.new(self.Name, 'Enemies')
	self.__EnemyId = 0
	self.__Tags = {}

	self.__Daze = Fusion.Value({}, 0)
	self.__Health = Fusion.Value({}, self.__Status:GetHealth())
	self.__Affliction = Fusion.Value({}, 0)
	self.__Affliction_Type = Fusion.Value({}, 'None')

	return self
end

function EnemyClass:SetWorldSpeed(Speed: number, Time: number?)
	self.__Movement:SetWorldSpeed(Speed, Time)
end

function EnemyClass.IsKnocked(self)
	return self.__Status:IsKnocked()
end

function EnemyClass:Destroy()
	self.__Movement:Destroy()

	if self.__Thread then
		self.__Thread:Disconnect()
	end

	self.__Appearance:Destroy()
end

function EnemyClass:IsAirborne()
	return self.__Appearance:IsRaised()
end

function EnemyClass:IsVisible()
	return self.__Appearance:IsVisible()
end

function EnemyClass:SetVisible(State: boolean)
	return self.__Appearance:SetVisible(State)
end


--
function EnemyClass:TakeDamage(number: number)
	self.__Status:Damage(number)

	--
	local Health = self.__Status.__Health

	self.__Health:set(Health)
end

function EnemyClass:SetHealth(Health: number)
	self.__Status:SetHealth(Health)
	self.__Health:set(Health)
end

function EnemyClass:GetEnergy(): number
	return 0
end

function EnemyClass:TakeDaze(number: number)
	self.__Status:Daze(number)

	--
	local Daze = math.floor(self.__Status.__Daze)

	self.__Daze:set(Daze)
end

function EnemyClass:TakeAffliction(Type: string, Amount: number)
	self.__Status:FillAffliction(Type, Amount)

	--
	local Affliction = self.__Status:GetAffliction(Type)

	self.__Affliction:set(Affliction)
	self.__Affliction_Type:set(Type)
end

function EnemyClass:GetAfflictionType()
	return Fusion.peek(self.__Affliction_Type)
end

function EnemyClass:GetAffliction(Type: string)
	return self.__Status:GetAffliction(Type)
end

function EnemyClass:ResetAffliction(Type: string)
	self.__Status:ResetAffliction(Type)

	--
	local Affliction = self.__Status:GetAffliction(Type)

	self.__Affliction:set(Affliction, true)
	self.__Affliction_Type:set(Type, true)
end

function EnemyClass:EnterDazedState()
	return self.__Status:EnterDazedState(function(Value: number)
		self.__Daze:set(Value)
		EnemyOverheadGui:UpdateDaze(self:GetId(), Fusion.peek(self.__Daze))
	end)
end

function EnemyClass:SwitchState(State: string, Time: number): ()
	if State == 'Airborne' then
		self.__Appearance:Raise(16, Time);
	end

	return self.__Status:SwitchState(State, Time);
end

function EnemyClass:GetId(): number
	return self.__EnemyId
end

function EnemyClass:GetCollider()
	return self.__Movement.__Enemy_Collider
end

--
function EnemyClass:GetStat(n: Types.Stat): number
	if n == 'Speed' then
		return 1
	end

	return self.__Status:GetStat(n)
end

function EnemyClass:GetState()
	return self.__Status:GetState()
end

function EnemyClass:GetModel()
	return self.__Appearance:GetModel()
end

function EnemyClass:GetDirection()
	return self.__Movement.__Direction
end

function EnemyClass:IsMoving()
	return self.__Movement.__Direction.Magnitude > 0 and self.__Movement.__World_Speed > 0
end

function EnemyClass:IsWalking()
	return self.__Movement:MovementInLastStep()
end

function EnemyClass:Move(Direction: Vector3, ForTime: number?, Speed: number?)
	if ForTime then
		self.__Movement:SetWalkSpeed(Speed, ForTime)
	end

	return self.__Movement:Move(Direction)
end

function EnemyClass:AddEffect(Data)
	local Obj = self.__Status:AddEffect(Data)

	if Data.Type == 'Max_Health' then
		local Health = self.__Status:GetHealth()
		self.__Health:set(Health)
	end

	return Obj
end

function EnemyClass:RemoveEffect(Effect)
	return self.__Status:RemoveEffect(Effect)
end

function EnemyClass.AddTag(self: Types.EnemyClass, Tag: string)
	self:RemoveTag(Tag)
	table.insert(self.__Tags, Tag)
end

function EnemyClass.RemoveTag(self: Types.EnemyClass, Tag: string)
	local Index = table.find(self.__Tags, Tag)
	if Index then
		table.remove(self.__Tags, Index)
	end
end

function EnemyClass.HasTag(self: Types.EnemyClass, Tag: string)
	return table.find(self.__Tags, Tag) ~= nil
end

function EnemyClass:Rotate(Target)
	return self.__Movement:Rotate(Target)
end

function EnemyClass:Hit(Data: {})
	return self.__Animator:Hit(Data)
end

function EnemyClass:GetAnimator(): Types.AnimatorController
	return self.__Animator
end

function EnemyClass:PivotTo(Vector: Vector3)
	self.__Movement.__Position = Vector
end

function EnemyClass:GetPivot(): CFrame
	return self.__Movement:GetPivot()
end

function EnemyClass:GetHitbox()
	return self.__Movement:GetHitbox()
end

function EnemyClass.FollowAgentGrab(self: Types.EnemyClass, Agent: Agents.AgentClass, Offset: CFrame)
	if Agent == nil then
		self.__Movement:SetFollowPart(nil, nil)

		return;
	end

	local Hitbox = Agent:GetHitbox()

	self.__Movement:SetFollowPart(Hitbox, Offset)
end

function EnemyClass.IsGrabbed(self: Types.EnemyClass)
	local GrabPart = self.__Movement:GetFollowPart()

	return (GrabPart ~= nil)
end

function EnemyClass:Init(Key: number)
	self.__EnemyId = Key
	--
	self.__Appearance:Tilt(90)
	self.__Appearance:JoinTo(self.__Movement.__Collider)
	self.__Animator:Init()

	self.__Movement:SnapToFirstGround()
	self.__Appearance:SetRotationResponsiveness(30)
end

function EnemyClass:Update(Delta: number)
	if self.__Status:GetState() ~= 'Idle' then
		self:Move(Vector3.zero)
	end

	self.__Movement:Update(Delta)
end

function EnemyClass:Knockback(Dir: Vector3, Pow: number, Time: number)
	local Velocity = self:GetPivot():VectorToWorldSpace(Dir) * Pow

	return self.__Movement:Knockback(Velocity, Time)
end

return EnemyClass
