local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

--
local Libraries = ServerStorage.Modules.Libraries
local Shared = ReplicatedStorage.Modules.Shared

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Ping = require(ServerStorage.Modules.Libraries.Ping)
local ClockUtil = require(Shared.Utility.Clock)
local Replicator = require(Libraries.Replicator)
local AgentsLibrary = require(Libraries.Agents)

local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Signal = require(Shared.Utility.Signal)
local EnemyStatus = require(Shared.Classes.Enemy.EnemyStatus)
local MovementClass = require(Shared.Classes.Enemy.EnemyMovement)
local EnemyDatabase = require(Shared.Database.Enemies)

local EnemyLibrary = require(Shared.Libraries.Enemies)
local MovesetLibrary = require(Libraries.Movesets)
local Targets = require(Libraries.Targets)


--
local Rng = Random.new()
local ServerEnemy = {} :: {new: (At: Vector3, Name: string) -> (), [string]: (self: Types.ServerEnemyClass, any) -> (any)}
ServerEnemy.__index = ServerEnemy
ServerEnemy.__tostring = function()
	return 'EnemyClass'
end

function ServerEnemy.new(At: Vector3, Name: string, Level: number)	
	local EnemyDBData = EnemyDatabase:GetEnemyData(Name)

	local self = setmetatable({}, ServerEnemy)
	self.Died = Signal.new()

	--
	self.__Name = Name or 'Default'
	self.__Level = Level or 1
	self.__Movement = MovementClass.new(At, EnemyDBData.Stats.Movement_Speed, EnemyDBData.Appearance.Height)
	self.__Status = EnemyStatus.new(self.__Name, self.__Level)

	self.__LastMovement = os.clock()
	self.__EnemyId = -1
	self.__Next = 1
	self.__TargetRepeatedCount = 0;
	self.__Next_Attack = 'Skill 1'
	self.__Tags = {}
	self.__Snapfix = os.clock()

	return self
end

function ServerEnemy:GetSkillLevel()
	return 0
end

function ServerEnemy:SetWorldSpeed(Speed: number, Time: number?)
	self.__Movement:SetWorldSpeed(Speed, Time)

	Replicator:SetEnemySpeed(self.__EnemyId, Speed, Time)
end

function ServerEnemy:GetStat(Stat: string)
	if Stat == 'Speed' then
		return 1
	end

	return self.__Status:GetStat(Stat)
end

function ServerEnemy:GetEnergy(): number
	return 0
end

function ServerEnemy:Destroy()
	self.__Movement:Destroy()

	if self.Died then
		self.Died:DisconnectAll()
	end

	if self.__Thread then
		self.__Thread:Disconnect()
	end
end

function ServerEnemy:EnterDazedState()
	self:Move(Vector3.zero)

	return self.__Status:EnterDazedState()
end

function ServerEnemy:SetGrabbedBy(Caster: AgentTypes.ServerAgentClass, Offset: CFrame)
	if Caster == nil then
		self.__Movement:SetFollowPart(nil, nil)

		return
	end

	self.__Movement:SetFollowPart(Caster:GetHitbox(), Offset)
end

function ServerEnemy:Attack()
	local MovesetData = EnemyDatabase:GetMovesetData(self.__Name)
	local Target = self:GetTarget()

	if Target == nil then
		return
	end

	if self.__Status:IsKnocked() or not self.__Status:IsAlive() or self.__Movement.__World_Speed <= 0 or self:IsAirborne() then
		return
	end

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Camera.Destructibles}
	Params.FilterType = Enum.RaycastFilterType.Include

	local At = self:GetPivot()
	local LookAt = CFrame.lookAt(At.Position, Target:GetPivot().Position)
	local LookAtRay = workspace:Raycast(At.Position, LookAt.LookVector * 1000, Params)
	if LookAtRay then
		return 
	end

	local CanAttackTarget = Targets:CanAttackTarget(Target, self)

	if not CanAttackTarget or Target:HasTag("Invulnerability") or self:IsGrabbed() then
		return
	end

	local OwnId = self.__EnemyId
	local TargetPlayer = Target.__Player_Assigned :: Player
	local Moveset = MovesetLibrary:Get(self.__Name, true)

	local Ranges = {}
	for SkillName, Skill in MovesetData do
		if Skill.Base and Skill.Base.Range then
			Ranges[SkillName] = Skill.Base.Range
		else
			Ranges[SkillName] = 1000
		end
	end

	local DistanceToTarget = (Target:GetPivot().Position - self:GetPivot().Position).Magnitude
	local SkillPool = {}

	for SkillName, SkillRange in Ranges do
		if SkillRange >= DistanceToTarget then
			if not Moveset:Verify(self, SkillName) then
				continue
			end

			table.insert(SkillPool, {
				Name = SkillName,
				Weight = (DistanceToTarget - SkillRange)
			})
		end
	end

	local SkillToUse = SkillPool[1]
	if #SkillPool > 1 then
		for _, SkillObject in SkillPool do
			if SkillObject.Weight > SkillToUse.Weight then
				SkillToUse = SkillObject
			end
		end
	end

	if SkillToUse ~= nil then
		local ReplicationSkillId = Moveset:GetSkillId(SkillToUse.Name)
		local Success = Moveset:Begin(SkillToUse.Name, self, {
			Target = Target,
		})

		Targets:RefreshLastAttackedTime(Target, self)

		if Success then
			Replicator:EnemyUseSkill(OwnId, ReplicationSkillId, 'Begin', Target)
		end
	end
end

function ServerEnemy:Init(Key: number)
	if not Key then
		return warn('Cannot initialize an enemy with an empty id')
	end

	self.__Enemy_Active = true
	self.__EnemyId = Key

	self.Name = `"{self.__Name}"-id:{self.__EnemyId}`

	--
	self.__Clocks = {
		Base = os.clock(),
		Focus = os.clock(),
		Rotation = os.clock(),
	}
	self.__Snapfix = os.clock() + Rng:NextNumber(0, 1)

	self.__Movement:SnapToFirstGround()

	return;
end

function ServerEnemy.Update(self: Types.ServerEnemyClass, delta: number)
	local Clock = self.__Clocks.Base
	local RandomRotation = self.__Clocks.Rotation
	local FocusTarget = self.__Clocks.Focus

	local CurrentTarget = self:GetTarget()
	local IsAttacking = self:GetState() == 'Attacking'
	if IsAttacking and os.clock() - Clock > 1/30 then
		self.__Clocks.Base = os.clock()
		self:TrackCurrentTarget()
	elseif os.clock() - Clock > 1 / 5 and self:GetState() == 'Idle' then
		self.__Clocks.Base = os.clock()

		if CurrentTarget then
			self:Rotate(CurrentTarget:GetPivot().Position)
		else
			if os.clock() - RandomRotation > 1.5 then
				self.__Clocks.Rotation = os.clock()
				local RandomPos = (self:GetPivot() * CFrame.Angles(0, Random.new():NextNumber(-math.pi, math.pi), 0) * CFrame.new(0, 0, -5)).Position

				self:Rotate(RandomPos)
			end
		end
	end
	
	local TargetActive = if CurrentTarget ~= nil then (CurrentTarget:IsActive() or CurrentTarget:HasTag('CanBeTargetted')) else false
	if not IsAttacking and (os.clock() - FocusTarget > 1 / 2) or (os.clock() - FocusTarget > 1 / 6 and not TargetActive) then
		self.__Clocks.Focus = os.clock()
		self:FindRandomAggro()
	end

	if os.clock() - self.__Snapfix > 1 / 5 or self:IsAbilityMoving() then
		self.__Snapfix = os.clock()
		Replicator:PivotEnemy(self.__EnemyId, self:GetPivot())
	end

	local DistanceToTarget = (CurrentTarget and (CurrentTarget:GetPivot().Position - self:GetPivot().Position).Magnitude) or 12
	if DistanceToTarget > 120 then
		self.__Current_Target = nil
	end

	if (os.clock() - self.__LastMovement > self.__Next) and self:GetState() == 'Idle' then
		self.__LastMovement = os.clock()

		self.__Next = Rng:NextNumber(0.5, 3)

		local Frontback = Rng:NextInteger(-1, 1)
		if DistanceToTarget >= 22.5 then
			Frontback = -1
		end

		self:Move(Vector3.new(Rng:NextInteger(-1, 1), 0, Frontback))
	end

	if (DistanceToTarget < 5) or self:GetState() ~= 'Idle' then
		self:Move(Vector3.zero)
	end

	self.__Movement:Update(delta)
end

function ServerEnemy:GetId(): number
	return self.__EnemyId
end

function ServerEnemy:IsAirborne()
	return self:GetState() == 'Airborne'
end

function ServerEnemy.ApplyTrueStun(self: Types.ServerEnemyClass, Duration: number)
	if self:IsTrueStun() then
		return
	end

	self:Move(vector.zero);
	self:SwitchState('TrueStun', Duration)
end

function ServerEnemy.Stun(self: Types.ServerEnemyClass, Time: number, is_airborne: boolean): ()
	if self:IsFrozen() or self:IsTrueStun() then
		return
	end

	self.__Next = Time + 0.15
	self.__LastMovement = os.clock()
	
	--
	self:Move(vector.zero)
	
	if self:GetState() == 'Airborne' and not is_airborne then
		return;
	end

	self:SwitchState(is_airborne and 'Airborne' or 'Stunned', Time)
end

function ServerEnemy:SwitchState(State: string, Time: number)
	Replicator:SwitchStateEnemy(self.__EnemyId, State, Time)

	return self.__Status:SwitchState(State, Time)
end

function ServerEnemy:GetState(): Types.State
	return self.__Status.__State
end

function ServerEnemy:TimeSinceLastPivot(): number
	return os.clock() - self.__Snapfix
end

function ServerEnemy:PivotTo(Pivot: CFrame)
	self.__Snapfix = os.clock()

	Replicator:PivotEnemy(self.__EnemyId, Pivot)
	self.__Movement:PivotTo(Pivot)
end

function ServerEnemy:Knockback(Dir: Vector3, Pow: number, Time: number, WorldRelative: boolean)
	local Velocity = self:GetPivot():VectorToWorldSpace(Dir) * Pow
	if WorldRelative then
		Velocity = vector.normalize(Dir :: vector) * Pow;
	end

	return self.__Movement:Knockback(Velocity, Time)
end

function ServerEnemy.AddEffect(self: Types.ServerEnemyClass, Data: Types.EnemyEffectParameters)
	self.__Status:AddEffect(Data)

	if Data.Type == "Speed" then
		self:SetWorldSpeed(self.__Status:GetStat("Speed"), Data.Time)
	end
end

function ServerEnemy.AddTag(self: Types.ServerEnemyClass, Tag: string, Time: number)
	local Index = table.find(self.__Tags, Tag)
	if Index then
		table.remove(self.__Tags, Index)
	end
	
	if not self.__Tag_Threads then
		self.__Tag_Threads = {}
	end

	if self.__Tag_Threads[Tag] then
		task.cancel(self.__Tag_Threads[Tag])
		self.__Tag_Threads[Tag] = nil
	end

	table.insert(self.__Tags, Tag)

	Replicator:AddTagEnemy(self, Tag)
	if typeof(Time) == 'number' and Time > 0 then
		self.__Tag_Threads[Tag] = task.delay(Time, function()
			self:RemoveTag(Tag)
		end)
	end
end

function ServerEnemy.RemoveTag(self: Types.ServerEnemyClass, Tag: string)
	local Index = table.find(self.__Tags, Tag)
	if Index then
		table.remove(self.__Tags, Index)

		Replicator:RemoveTagEnemy(self, Tag)
	end
end

function ServerEnemy.HasTag(self: Types.ServerEnemyClass, Tag: string)
	return table.find(self.__Tags, Tag) ~= nil
end

function ServerEnemy.GetEffect(self: Types.ServerEnemyClass, Tag: string)
	return self.__Status:GetEffect(Tag)
end

function ServerEnemy.RemoveEffect(self: Types.ServerEnemyClass, Id: string)
	return self.__Status:RemoveEffect(Id)
end

function ServerEnemy:GetTarget()
	return self.__Current_Target
end

function ServerEnemy.IsAbilityMoving(self: Types.ServerEnemyClass): boolean
	if self.__Movement_Lock and (os.clock() - self.__Movement_Lock.Start) < (self.__Movement_Lock.Time) then
		return true;
	end

	return false;
end

function ServerEnemy.IsFrozen(self: Types.ServerEnemyClass)
	return self.__Status:IsFrozen()
end

function ServerEnemy.Move(self: Types.ServerEnemyClass, Direction: Vector3 | vector, LockFor: number?, Speed: number?)
	if self.__Current_Target and (self.__Current_Target:GetPivot().Position - self:GetPivot().Position).Magnitude < 4.5 and (Direction :: Vector3).Z < 0 then
		return
	end

	if self:IsAbilityMoving() then
		return
	end

	if self.__Status:IsKnocked() or self:IsGrabbed() then
		return
	end

	if self:IsFrozen() or self:IsTrueStun() then
		self.__Movement:Move(vector.zero)

		return
	end

	--
	if typeof(LockFor) == 'number' then
		self.__Movement_Lock = {
			Time = LockFor,
			Start = os.clock(),
			Speed = Speed,
		}
		
		self.__Movement:SetWalkSpeed(Speed, LockFor)
	end

	self.__Movement:Move(Direction)

	Replicator:MoveEnemy(self.__EnemyId, Direction, LockFor, Speed)
end

function ServerEnemy:TrackCurrentTarget()
	local CurrentTarget = self.__Current_Target
	if not CurrentTarget then return end

	local At = CurrentTarget:GetPivot().Position

	At = At + (CurrentTarget:GetTotalVelocity() * 1/15)

	--
	self:Rotate(At)
end

function ServerEnemy:FindRandomAggro()
	local Agents = AgentsLibrary:GetAllAliveAgents()
	local At = self.__Movement.__Position
	local MaxDistance = 120 --math.huge
	local CurrentDistance = MaxDistance
	local Chosen: AgentTypes.ServerAgentClass = nil

	local Options = {}
	for _, Agent in Agents do
		if not Agent:IsActive() and not(Agent:HasTag('CanBeTargetted')) then
			continue
		end

		local Distance = (Agent:GetPivot().Position - At).Magnitude

		if Distance < CurrentDistance then
			table.insert(Options, {Agent, Distance})
			CurrentDistance = Distance
			Chosen = Agent
		elseif Distance < MaxDistance then
			table.insert(Options, {Agent, Distance})
		end
	end

	if #Options > 1 and (self.__Last_Target == Chosen) then
		local DifferenceIsHigher = math.abs(Options[2][2] - Options[1][2]) > 10;

		if not DifferenceIsHigher or (self.__TargetRepeatedCount > 2) then
			self.__TargetRepeatedCount = 0;
			table.sort(Options, function(OptA, OptB): boolean  
				return OptA[2] < OptB[2]
			end)

			for idx, Option in Options do
				if Option[1] == Chosen then 
					table.remove(Options, idx)
					break 
				end
			end
			
			Chosen = Options[1][1];
		else
			self.__TargetRepeatedCount += 1;
		end
	end

	if Chosen then
		At = Chosen:GetPivot().Position

		self:Rotate(At)

		self.__Last_Target = Chosen
		self.__Current_Target = Chosen
	end
end

function ServerEnemy:Rotate(Direction: Vector3 | AgentTypes.ServerAgentClass)
	if self.__Movement.__World_Speed <= 0 then return end

	if typeof(Direction) == 'CFrame' then
		Direction = Direction.Position
	end

	Replicator:RotateEnemy(self.__EnemyId, Direction)

	return self.__Movement:Rotate(Direction)
end

function ServerEnemy:TakeDamage(number: number): boolean
	self.__Status:Damage(number)

	if not(self:IsAlive()) and EnemyLibrary:GetEnemy(self.__EnemyId) == self then
		local Key = EnemyLibrary:RemoveEnemy(self)

		Replicator:RemoveEnemy(Key)
		self.Died:Fire()
		self:Destroy()

		return true
	end

	return false;
end

function ServerEnemy:IsAlive()
	return self.__Status:IsAlive()
end

function ServerEnemy:GetHealth()
	return self.__Status:GetHealth()
end

function ServerEnemy:IsTrueStun()
	return self:GetState() == 'TrueStun';
end

function ServerEnemy:Kill()
	self:TakeDamage(9e99)
end

function ServerEnemy:TakeDaze(number: number)
	return self.__Status:Daze(number)
end

function ServerEnemy:TakeAffliction(Type: string, Amount: number, Damage: number)
	return self.__Status:FillAffliction(Type, Amount, Damage)
end

function ServerEnemy:GetAffliction(Type: string)
	return self.__Status:GetAffliction(Type)
end
function ServerEnemy:GetAfflictionStackedDamage(Type)
	return self.__Status:GetAfflictionStackedDamage(Type)
end

function ServerEnemy.IsGrabbed(self: Types.ServerEnemyClass)
	return self.__Movement:GetFollowPart() ~= nil
end

function ServerEnemy:ResetAffliction(Type: Types.Element)
	Replicator:ResetAffliction(self, Type)

	return self.__Status:ResetAffliction(Type)
end

function ServerEnemy:GetHitbox()
	return self.__Movement:GetHitbox()
end

function ServerEnemy:GetPivot()
	return self.__Movement:GetPivot()
end

return ServerEnemy
