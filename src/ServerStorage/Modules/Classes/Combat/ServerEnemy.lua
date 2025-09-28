local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

--
local Libraries = ServerStorage.Modules.Libraries
local Shared = ReplicatedStorage.Modules.Shared

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
	self.__Movement = MovementClass.new(At, nil, EnemyDBData.Appearance.Height)
	self.__Status = EnemyStatus.new(self.__Name, self.__Level)

	self.__LastMovement = os.clock()
	self.__EnemyId = -1
	self.__Next = 1
	self.__Next_Attack = 'Skill 1'
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

function ServerEnemy:Attack()
	local MovesetData = EnemyDatabase:GetMovesetData(self.__Name)
	local Target = self:GetTarget()

	if not Target or self.__Status:IsKnocked() or not self.__Status:IsAlive() or self.__Movement.__World_Speed <= 0 then
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

	if not Targets:CanAttackTarget(Target, self) then
		return
	end

	local Moveset = MovesetLibrary:Get(self.__Name, true)

	local Ranges = {}
	for SkillName, Skill in MovesetData do
		if Skill.Base and Skill.Base.Range then
			Ranges[SkillName] = Skill.Base.Range
		end
	end

	local DistanceToTarget = (Target:GetPivot().Position - self:GetPivot().Position).Magnitude
	local SkillPool = {}

	for SkillName, SkillRange in Ranges do
		if SkillRange >= DistanceToTarget then
			if not Moveset:Verify(self, SkillName) then
				return
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
		local PlayerPing = Ping:Get(Target.__Player_Assigned) :: number

		local SplitSkillId = string.split(SkillToUse.Name, ' ')
		local ReplicationSkillId = tonumber(SplitSkillId[2], 10)

		Targets:RefreshLastAttackedTime(Target, self)
		Replicator:EnemyUseSkill(self.__EnemyId, ReplicationSkillId, 'Begin')

		task.wait(PlayerPing)
		Moveset:Begin(SkillToUse.Name, self)
	end
end

function ServerEnemy:Init(Key: number)
	if not Key then
		return warn('Cannot initialize an enemy with an empty id')
	end

	self.__EnemyId = Key

	self.Name = `"{self.__Name}"-id:{self.__EnemyId}`

	--
	local NextAttack = os.clock()
	local Clock = os.clock()
	self.__Snapfix = os.clock()
	self.__Thread = ClockUtil:Heartbeat(function(delta: number)
		--
		if self:GetState() == 'Attacking' and os.clock() - Clock > 1/30 then
			Clock = os.clock()
			self:TrackCurrentTarget()
		elseif os.clock() - Clock > 1/3 and self:GetState() == 'Idle' then
			Clock = os.clock()
			self:FindRandomAggro()
		end

		if os.clock() - self.__Snapfix > 3.5 then
			self.__Snapfix = os.clock()
			Replicator:PivotEnemy(self.__EnemyId, self:GetPivot())
		end

		if os.clock() - NextAttack >= 1 then
			NextAttack = os.clock()
			self:Attack()
		end

		if (self.__Current_Target and (self.__Current_Target:GetPivot().Position - self:GetPivot().Position).Magnitude < 4.5) or self:GetState() ~= 'Idle' then
			self:Move(Vector3.zero)
		end

		if (os.clock() - self.__LastMovement > self.__Next) and self:GetState() == 'Idle' then
			local Frontback = -1 --Rng:NextInteger(-1, 1)
			if self:GetTarget() and (self:GetTarget():GetPivot().Position - self:GetPivot().Position).Magnitude >= 45 then
				Frontback = -1
			end

			self:Move(Vector3.new(Rng:NextInteger(-1, 1), 0, Frontback))
		end

		self.__Movement:Update(delta)
	end)

	return;
end

function ServerEnemy:GetId(): number
	return self.__EnemyId
end

function ServerEnemy.Stun(self: Types.ServerEnemyClass, Time: number, is_airborne: boolean): ()
	self.__Next = Time + 0.15
	self.__LastMovement = os.clock()

	--
	self:Move(vector.zero)
	self:SwitchState( not is_airborne and 'Stunned' or 'Airborne' , Time)
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

function ServerEnemy:Knockback(Dir: Vector3, Pow: number, Time: number)
	local Velocity = self:GetPivot():VectorToWorldSpace(Dir) * Pow

	return self.__Movement:Knockback(Velocity, Time)
end

function ServerEnemy:GetTarget()
	return self.__Current_Target
end

function ServerEnemy.Move(self: Types.ServerEnemyClass, Direction: Vector3 | vector)
	if self.__Current_Target and (self.__Current_Target:GetPivot().Position - self:GetPivot().Position).Magnitude < 4.5 and (Direction :: Vector3).Z < 0 then
		return
	end

	if self.__Status:IsKnocked() then
		return
	end

	--
	self.__Movement:Move(Direction)
	self.__LastMovement = os.clock()

	self.__Next = Rng:NextNumber(0.5, 3.5)

	Replicator:MoveEnemy(self.__EnemyId, Direction)
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
	local Agents = AgentsLibrary:GetActiveAgents()
	local At = self.__Movement.__Position
	local MaxDistance = 120 --math.huge
	local Chosen: AgentTypes.ServerAgentClass = nil

	for _, Agent in Agents do
		local Distance = (Agent:GetPivot().Position - At).Magnitude

		if Distance < MaxDistance then
			MaxDistance = Distance
			Chosen = Agent
		end
	end

	if Chosen then
		At = Chosen:GetPivot().Position

		self.__Current_Target = Chosen
		self:Rotate(At)
	end
end

function ServerEnemy:Rotate(Direction: Vector3 | AgentTypes.ServerAgentClass)
	if self.__Movement.__World_Speed <= 0 or self.__Status:IsKnocked() then return end

	if typeof(Direction) == 'CFrame' then
		Direction = Direction.Position
	end

	Replicator:RotateEnemy(self.__EnemyId, Direction)

	return self.__Movement:Rotate(Direction)
end

function ServerEnemy:TakeDamage(number: number): boolean
	self.__Status:Damage(number)

	if not(self.__Status:IsAlive()) and EnemyLibrary:GetEnemy(self.__EnemyId) == self then
		local Key = EnemyLibrary:RemoveEnemy(self)

		Replicator:RemoveEnemy(Key)
		self.Died:Fire()
		self:Destroy()

		return true
	end

	return false;
end

function ServerEnemy:Kill()
	self:TakeDamage(9e12)
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
