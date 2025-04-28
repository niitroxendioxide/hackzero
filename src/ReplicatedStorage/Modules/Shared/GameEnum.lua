return {
	Replication = {
		-- Characters
		AddAgent = 0,
		RemoveAgent = 1,
		Rotate = 2,
		Move = 3,
		Stop = 4,
		CharacterSwitch = 5,
		SyncVelocities = 6,
		PivotTo = 7,
		StateSwitch = 10,
		KeySwitch = 11,

		-- Enemy
		AddEnemy = 15,
		RemoveEnemy = 16,
		MoveEnemy = 17,
		RotateEnemy = 18,
		PivotEnemy = 19,
		StateSwitchEnemy = 21,

		-- Combat
		EnemyUseSkill = 49,
		UseSkill = 50,
		DisplayDamage = 51,
		Knockback = 52,
		DamageAgent = 53,
		FillAffliction = 54,
		ResetAffliction = 55,
		DazeEnemy = 56,
		EnterDaze = 57,
	},


	Skills = {
		Basic_Attack = 1,
		Dodge = 2,
		Chain_Attack = 3,
		Dodge_Counter = 4,
		Quick_Assist = 5,
		Ultimate = 6,
		Special = 7,
		EX_Special = 8,
	},

	Afflictions = {
		Physical = 0,
		Fire = 1,
		Ice = 2,
		Wind = 3,
		Energy = 4,
		Earth = 5,
		Default = 70,
	},

	Agent_Keys = {
		Sprint = 1,
		Jog = 2,
	},

	Knockback_Directions = {
		[Vector3.new(1, 0, 0)] = 1,
		[Vector3.new(-1, 0, 0)] = 2,
		[Vector3.new(0, 0, -1)] = 3,
		[Vector3.new(0, 0, 1)] = 4,
		[Vector3.new(1, 0, 1)] = 5,
		[Vector3.new(1, 0, -1)] = 6,
		[Vector3.new(-1, 0, 1)] = 7,
		[Vector3.new(-1, 0, -1)] = 8,
	},

	Boost_Effects = {
		DODGE_FLOW_TRIGGER = 'DodgeFlowStateTrigger'
	},
	Agent_States = {"Attacking", "Dashing", "Idle", "Frozen", "Stunned"},
	PartyStates = {
		Idle = 1,
		Queueing = 2,
		Teleporting = 3,
	},

	PartyManaging = {
		Create = 1,
		Join = 2,
		Leave = 3,
		Update = 4,
		Start = 5,
		Failed = 6,
		ChangeTeam = 7,
		Invite = 8,
		AcceptInvite = 9,
		RejectInvite = 10,
		PlayerJoined = 11,
		PlayerLeft = 12,
	},

	FetchRequests = {
		Agents = 105,
		Parties = 205,
	},

	NotificationTypes = {
		PartyInvite = 1,
		ObtainedCharacter = 2,
	},

	MatchEvents = {
		SetupStage = 0,
		BeginEvent = 1,
		EndEvent = 2,
		ProgressUpd = 3,
		MatchEnded = 4,
		RequestMatchLeave = 5,
		RequestMatchRepeat = 6,
	},

	SummonRequests = {
		SummonOne = 1,
		SummonTen = 2,
		SummonResultOne = 3,
		SummonResultTen = 4,
	},

	MatchResults = {
		Victory = 1,
		Loss = 2,
	},

	KeyLookup = function(Table: {}, val: number)
		for Key, Value in Table do
			if Value == val then
				return Key
			end
		end

		return;
	end,

	ValueNameFrom = function(self: {KeyLookup: ({}, any) -> (any)}, TableName, Value): ()
		local Table = self[TableName]

		return self.KeyLookup(Table, Value)
	end
}