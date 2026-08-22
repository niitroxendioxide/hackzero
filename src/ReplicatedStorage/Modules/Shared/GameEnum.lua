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
		ChangeEffect = 161,
		RemoveEffect = 17,
		AddGear = 18,
		RemoveGear = 19,
		KillAgent = 20,
		HitAgent = 21,
		FillMeter = 22,
		CreateMeter = 23,
		ProcessDodge = 24,
		AddTag = 25,
		RemoveTag = 26,

		-- Enemy
		AddEnemy = 27,
		RemoveEnemy = 28,
		MoveEnemy = 29,
		RotateEnemy = 30,
		PivotEnemy = 31,
		StateSwitchEnemy = 32,
		SetEnemySpeed = 33,

		-- Combat
		EnemyUseSkill = 49,
		UseSkill = 50,
		DisplayDamage = 51,
		Knockback = 52,
		DamageAgent = 53,
		HealAgent = 100,
		FillAffliction = 54,
		ResetAffliction = 55,
		DazeEnemy = 56,
		EnterDaze = 57,
		PromptAssist = 58,
		ChainAttack = 59,
		UseChainAttack = 60,
		CancelChainAttack = 61,
		MatchAirborne = 62,

		--
		CreateDestructible = 80,
		DestroyDestructible = 81,
		HitDestructible = 82,

		CreateChest = 83,
		CreateNPC = 84,
		PlayEventDialogue = 85,
		CreateCompanion = 86,
		MoveCompanion = 87,
		SetMovingStatusCompanion = 88,

		BeginGrabEnemy = 89,
		EndGrabEnemy = 90,
		NewSwitch = 91,

		AddTagEnemy = 92,
		RemoveTagEnemy = 93,

		-- 
		ClearPlayerData = 150,
		SetColliderArea = 152,
		PlayVisualEffect = 250,
	},

	ChaosControlAction = {
		Fetch = 1,
		Begin = 2,
		Amount = 3,
		Cancel = 4,
		Select = 5,
	},

	ChaosControlTab = {
		DailyImprovement = 1,
		ApocalypseTower = 2,
		AgentExperience = 3,
	},

	Device = {
		Mobile = 1,
		Desktop = 2,
		Console = 3,
		VR = 4,
	},

	InteractionType = {
		Chest = 1,
		NPC = 2,
		LobbyNPC = 3,
		UIInteraction = 4,
	},

	MarketplaceRequestTypes = {
		BuyProduct = 1,
		BuyGamepass = 2,
	},

	AudioGroups = {
		Effects = 'Effects',
		Voices = 'Voices',
		Music = 'Music',
		Ambience = 'Ambience',
	},

	AudioPriorities = {
		High = 'High',
		Low = 'Low',
		Medium = 'Medium',
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
		Movement_Linear = 6,
	},

	AbilityHooks = {
		BeforeBeginConnection = 1,
		BeforeReleaseConnection = 2,
		BeforeCancel = 2,
	},

	ArtifactEvents = {
		SkillCasted = '_skc',
		AgentSwitchedIn = "_agswi", 
		AgentHurt = "_agh",
	},

	Afflictions = {
		Physical = 0,
		Fire = 1,
		Ice = 2,
		Wind = 3,
		Energy = 4,
		Earth = 5,
		Water = 6,
		Antimatter = 7,
		Electric = 8,
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
		Release = 2,
		Cancel = 3,
	},

	Quests = {
		Claim = 1,
		Reroll = 2,
	},

	AirborneMatchState = {
		None = 0,
		Raised = 1,
		Grounded = 2,
		Same = 3,
	},

	Boost_Effects = {
		DODGE_FLOW_TRIGGER = 'DodgeFlowStateTrigger',
		SWITCH_ASSIST_DODGE = 'DodgeAssistFollowup',
	},

	Agent_States = {"Attacking", "Dashing", "Idle", "Frozen", "Stunned", "Airborne", "TrueStun"},
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
		ChangeStage = 13,
		SetReady = 14,
		CancelReady = 15,
		Queue = 16,
		RemoveReady = 17,
		SelectCompanion = 18,
	},

	FetchRequests = {
		Agents = 105,
		Parties = 205,
		Quests = 305,
		Stages = 405,
		Companions = 406,
		ChaosControl = 407,	},

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
		SingularPlayerLeave = 10,
		UpdateWave = 11,
		SetMissionId = 12,
	},

	SummonDropTypes = {
		Agent = 1,
		Companion = 2,
		Drive = 3,
		Artifact = 4,
		Emote = 5,
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
		AddNewArtifacts = 11,
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

	BuildEvent = {
		UpdateArtifactSlot = 1,
		UpdateDrive = 2,
		LevelAgent = 3,
		EvolveAgent = 4,
		LoadAll = 5,
		UpgradeAgentSkill = 6,
		AscendAgent = 7,
		LevelCompanion = 8,
	},

	SellEvent = {
		SellArtifacts = 1,
	},

	ChangeEvents = {
		Add = 1,
		Remove = 2,
		Update = 3,
	},

	GearEvent = {
		Prompt = 1,
		Choose = 2,
		Give = 3,
	},

	SubStats = {
		["Health%"] = 1,
		["Health"] = 2,
		["Attack"] = 3,
		["Attack%"] = 4,
		["Defense"] = 5,
		["Defense%"] = 6,
		["Critical_Rate"] = 7,
		["Critical_Damage"] = 8,
		["Penetration"] = 9,
		["Affliction_Aptitude"] = 10,
		["Daze"] = 11,
		--[[
		["Affliction_Damage%"] = 12,
		["Energy_Regeneration%"] = 12,
		["Skill_Damage_1"] = 43,
		["Skill_Damage_2"] = 44,
		["Skill_Damage_3"] = 45,
		["Skill_Damage_4"] = 46,
		["Skill_Damage_5"] = 47,
		["Skill_Damage_6"] = 48,
		--]]
	},

	GearHookType = {
		BeforeHit = 1,
		AfterHit = 2,
		HitDataSetup = 3,
		BeforeAffliction = 4,
		AfterAffliction = 5,
		OnAfflictionBurst = 6,
		StructureDestroyed = 7,
		OnDodge = 8,
		OnChainAttack = 9,
		OnEnergyGained = 10,
		OnUltimateUsed = 11,
		OnDazeInflicted = 12,
		OnEnemyDazed = 13,
	},

	MainStats = {
		["Attack%"] = 1,
		["Health%"] = 2,
		["Defense%"] = 3,
		["Critical_Rate"] = 4,
		["Critical_Damage"] = 5,
		["Pen_Ratio"] = 6,
		["Affliction_Aptitude"] = 7,
		["Daze%"] = 9,
		["Health"] = 10,
		["Defense"] = 11,
		["Attack"]  = 12,
	},

	MainStatsAllowed = {
		Slot1 = {

		},
	},

	Tiers = {
		["Mythical"] = 1,
		["Legendary"] = 2,
		["Epic"] = 3,
		["Rare"] = 4,
		["Common"] = 5,
	},

	AFKEvent = {
		GiveCurrency = 1,
		GiveItem = 2,
	},

	Difficulties = {
		Easy = "EASY",
		Medium = "MEDIUM",
		Hard = "HARD",
		Challenge = "EXTREME",
		Passive = "PASSIVE",
	},

	Interactables = {
		Chests = {
			Default = 1,
		}
	},

	StageHook = {
		Begin = 1,
		TriggerEnter = 2,
		BreakStructure = 3,
	},

	EntityBehaviorEvent = {
		PhaseEntered = 1,
		PatternUsed = 2,
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