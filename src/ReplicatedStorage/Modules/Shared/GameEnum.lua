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
		UpdateEnergy = 14,
		UpdateUltBar = 15,
		AddEffect = 16,
		RemoveEffect = 17,
		AddGear = 18,
		RemoveGear = 19,
		KillAgent = 20,
		HitAgent = 21,
		FillMeter = 22,
		ProcessDodge = 23,

		-- Enemy
		AddEnemy = 26,
		RemoveEnemy = 27,
		MoveEnemy = 28,
		RotateEnemy = 29,
		PivotEnemy = 30,
		StateSwitchEnemy = 31,
		SetEnemySpeed = 32,

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
		PromptAssist = 58,

		--
		ClearPlayerData = 150,
		PlayVisualEffect = 151,
		SetColliderArea = 152,

		--
		CreateDestructible = 80,
		DestroyDestructible = 81,
		HitDestructible = 82,

		CreateChest = 83,
		CreateNPC = 84,
		PlayEventDialogue = 85,
		CreateCompanion = 86,
		MoveCompanion = 87,
	},

	InteractionType = {
		Chest = 1,
		NPC = 2,
	},

	MarketplaceRequestTypes = {
		BuyProduct = 1,
		BuyGamepass = 2,
	},

	Meter_States = {
		Fill = 1,
		Empty = 2,
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

	ChestInteractions = {
		Open = 1,
	},

	NPCInteractions = {
		Talk = 1,
		End = 2,
		Event = 3,
	},

	AttackData = {
		Movement_Time = 1,
		Hit_Time = 2,
		End_Lag = 3,
		Movement_Length = 4,
		Movement_Strength = 5,
	},

	Afflictions = {
		Physical = 0,
		Fire = 1,
		Ice = 2,
		Wind = 3,
		Energy = 4,
		Earth = 5,
		Water = 6,
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

	AbilityStates = {
		Begin = 1,
		End = 2,
		Cancel = 3,
	},

	Boost_Effects = {
		DODGE_FLOW_TRIGGER = 'DodgeFlowStateTrigger',
		SWITCH_ASSIST_DODGE = 'DodgeAssistFollowup',
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
		RequestMapsAvailable = 13,
	},

	FetchRequests = {
		Agents = 105,
		Parties = 205,
		Quests = 305,
	},

	NotificationTypes = {
		PartyInvite = 1,
		ObtainedCharacter = 2,
	},

	QuestTypes = {
		Daily = 1,
		Main = 2,
		Interactions = 3,
		World = 4,
	},

	MatchEvents = {
		SetupStage = 0,
		BeginEvent = 1,
		EndEvent = 2,
		ProgressUpd = 3,
		MatchEnded = 4,
		MatchBegin = 5,
		RequestMatchLeave = 6,
		RequestMatchRepeat = 7,
		MarkClientLoaded = 8,
		PlayerDied = 9,
	},

	SummonRequests = {
		SummonOne = 1,
		SummonTen = 2,
		SummonResult = 3,
	},

	MatchResults = {
		Victory = 1,
		Loss = 2,
	},

	ItemDataEvent = {
		GetAllArtifacts = 1,
		UpdateArtifact = 2,
		GetAllDrives = 3,
		UpdateDrive = 4,
		GetCurrencies = 5,
		GetAllItems = 6,
	},

	ShareDataEvent = {
		MatchArtifacts = 1,
		MatchDrives = 2,
		MatchAgents = 3,
	},

	CutsceneStatus = {
		Received = 1,
		Finished = 2,
	},

	AgentEvent = {
		UpdateArtifactSlot = 1,
		UpdateDrive = 2,
		LevelAgent = 3,
		EvolveAgent = 4,
		LoadAll = 5,
		UpgradeAgentSkill = 6,
		AscendAgent = 7,
	},

	ChangeEvents = {
		Add = 1,
		Remove = 2,
		Update = 3,
	},

	SubStats = {
		["Health%"] = 1,
		["Health"] = 2,
		["Attack"] = 3,
		["Attack%"] = 4,
		["Defense"] = 5,
		["Defense%"] = 6,
		["Crit_Rate"] = 7,
		["Crit_Damage"] = 8,
		["Penetration"] = 9,
		["Affliction_Aptitude"] = 10,
	},

	MainStats = {
		["Attack%"] = 1,
		["Health%"] = 2,
		["Defense%"] = 3,
		["Crit_Rate"] = 4,
		["Crit_Damage"] = 5,
		["Pen_Ratio"] = 6,
		["Affliction_Aptitude"] = 3,
	},

	MainStatsAllowed = {
		Slot1 = {

		},
	},

	Tiers = {
		["Mythical"] = 1,
		["Legendary"] = 2,
		["Rare"] = 3,
		["Common"] = 4,
	},

	AFKEvent = {
		GiveCurrency = 1,
		GiveItem = 2,
	},

	Difficulties = {
		Easy = "EASY",
		Medium = "MEDIUM",
		Hard = "HARD",
		Challenge = "EXTREME"
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
	end,

	Random = function(self: {[string]: any}, Key: "Tiers" | "SubStats" | "Boost_Effects" | 'MainStats')
		local keys = {}
		for key in self[Key] do
			table.insert(keys, key)
		end

		return keys[math.random(1, #keys)]
	end
}