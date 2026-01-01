local Agents = require('./Agents')

export type Signal<T...> = RBXScriptSignal & {Fire: (self: RBXScriptSignal, T...) -> ()}
export type Stage_Objective = "KillEnemies" | "TimeSurvive" | "PushLoad" | "ReachPlace" | "TalkTo" | "AllReachPlace"
export type Reward_Type = "Artifact" | "Gold" | "Gems" | "Agent"
export type Goal = {
	[Stage_Objective]: number,
}
export type EventHandlerState = {Dead: boolean, [string | Stage_Objective]: any}
export type Action = "KickPlayer"

--[[

## Stage Key Event
Events that happen in that stage, the first one is loaded and then the next one is changed to after the first one finishes, etc

### Objective description tags:
- {objective[n]} where `n` is the type of objective, returns the value of the objective
- {player} refers to the name of the player
- {time} updates the time as it changes

### Finished:
- Handler, which is passed a `Goal` type for the state at which the event was finished, be it completed or time limit, or death, etc.
- Handler returns a string that indicates the next stage

]]
export type Stage_Key_Event = {

	--[[
		Key/Name to a cutscene that plays as soon as a player reaches this area
	]]
	Cutscene: string?,
	Actions: {
		[Action]: string,
	},
	Objective: string,
	Goal: Goal,

	Dialogue: {DialogueObject}?,

	Active_Triggers: {string},

	Finished: (State: EventHandlerState) -> (string),

	-- Teleport all players to an area.
	Global: boolean?,

	-- Only used if Global is turned on
	EventPlace: string?,

	Enemies: {
		[number]: EnemySpawnData,--{string | number},
	},
	TimeLimit: number?,
}

export type DialogueObject = {
	Speaker: string,
	Text: string,
	NextDialogue: number?,
}

--[[
	Item obtainable in game, this item stays in your inventory, meaning you can take it
	from the match to use out, be it upgrades, artifacts, gold, etc.
]]
export type LootItem = {Type: LootType, Amount: number, Extra: LootExtraData?}

export type Marker = {
    Type: 'Trigger' | 'Chest' | 'Destructible' | 'NPC' | 'Switch',
	Name: string?, -- Rename, if you want to, can just keep the same.

	Destructible_Id: string?,
	ItemList: {
		LootItem
	}?,

	Dialogue: {DialogueObject}?,
}


export type Rating = "X" | "B" | "A" | "S" | "S+"
export type EnemySpawnData = {
	Name: string,
	Amount: number,
	Level: number,

	Buffs: {},
}


export type Stage_Survival = {
	Maximum: number,
	Time_Limit: number,

	Rewards: {
		Handler: (Objectives: {[string]: boolean}) -> (Rating),
		Items: {LootItem},
	},

	Enemies: {
		[number]: EnemySpawnData
	},
}


export type Stage_Act = {
	--[string]: any,
	AutoGenerate: boolean?,
	AutoGenerationData: MapGenerationData?, 
	Description: string?,
	Requisites: {

	},

	Rewards: {
		Handler: (Objectives: {[string]: boolean}) -> (Rating),

		Items: {
			LootItem
		},
	},

    Markers: {
		[string]: Marker
    },

	Guide: {
		Begin: Stage_Key_Event,
		[string]: Stage_Key_Event,
	}
}

export type Stage = {
	Icon: number?,
	Name: string,
	Map: string,

	Acts: {
		[string]: Stage_Act,
	},

	Survival: {
		[string]: Stage_Survival,
	},
}

export type MissionClass = {
	Finished: Signal<{[string]: any}>,

	__Active: boolean,
	__Act: string,
	__Stage: string,
	__Is_Finished: boolean,
	__Current_Active_Triggers: {thread | RBXScriptConnection},
	__Current_Events: {[string]: EventClass},
	__Current_State: {[string]: any},
	__Hooks: {[string]: (...any) -> ()},

	--
	Begin: (self: MissionClass) -> (),

	--[[
		Begin the event associated to the current mission
		@param Event : `string` the event to be started, passing none will result in it loading the "Begin" event
		@param Players : `{StagePlayer}` The players in stage that enter the event
		@param Ignore_Replay : `boolean?` Used to determine if the event should be re-played if it wasn't
	]]
	BeginEvent: (self: MissionClass, Event: ("Begin" | string)?, Players: {StagePlayer}, Ignore_Replay: boolean?, Trigger: BasePart?) -> (),
	SummonEnemyWave: (self: MissionClass, Wave: number) -> (),
	Finish: (self: MissionClass) -> (),

	--[[
		Sync with all clients the current events and information
	]]
	Sync: (self: MissionClass, Players: {StagePlayer}, Type: number, ...any) -> (),

	--[[
		Sets up the area triggers for each event, only in the scenario where there are any area triggers
	]]
	DetectAreaTriggers: (self: MissionClass) -> (),
	CleanUpTriggers: (self: MissionClass) -> (),
	AddTrigger: (self: MissionClass, Area: BasePart) -> (),

	IsFinished: (self: MissionClass) -> (boolean),
}

export type EventClass = {
	Finished: Signal<string, {[string]: any}>,

	__Current_Barrier_State: boolean,
	__Players: {StagePlayer},
	__Current_Barriers: {BasePart},
	__Finish_Status: boolean,
	__Event: string,
	__Stage: string,
	__Act: string,
	__Current_Time: number,
	__Current_Wave_Thread: thread?,
	__Current_Wave_Connection: RBXScriptConnection?,
	__Current_Goals: Goal,
	__Current_State: {[Stage_Objective]: (number | boolean)?, Dead: boolean},

	AddPlayer: (self: EventClass, Player: StagePlayer) -> (),

	Start: (self: EventClass, Trigger: BasePart?) -> (),
	SummonEnemyWave: (self: EventClass, Wave: number) -> (),
	Destroy: (self: EventClass) -> (),

	HasGoal: (self: EventClass, Type: Stage_Objective) -> (boolean),
	IsFinished: (self: EventClass) -> (),
	GetPlayerObjects: (self: EventClass) -> ({Player}),
	CreateEventAreaModel: (self: EventClass, Trigger: BasePart) -> (),
	SetBarrierCollision: (self: EventClass, State: boolean) -> (),
	--[[
		Update the progress in teh current mission
		@param Type : `Goal` the goal type to be updated
		@param Value : `any` the value of the new goal, incremental in case of numbers.
	]]
	UpdateProgress: (self: EventClass, Type: Stage_Objective, Value: any) -> (),

	GetCorrectedState: (self: EventClass) -> (),
}

export type LootExtraData = {
	Slot: number?,

	Artifact_Name: string?,
	Drive_Name: string?,
}

export type LootType = "Item" | "Artifact" | "Drive" | "Gold" | "Gems"
export type LootObject = {
	Type: LootType,
	Amount: number,
	Extra: LootExtraData?,
}

export type StagePlayer = {
	__Player_Object: Player,
	__Designated_Id: number,
	__Team: {Agents.ServerAgentClass},
	__Loot_Obtained: {any},
	__Match_Inventory: {any},

	GetId: (self: StagePlayer) -> number,
	GetTeam: (self: StagePlayer) -> {Agents.ServerAgentClass},
	GetBase: (self: StagePlayer) -> Player,
	GetAgents: (self: StagePlayer) -> (),
	GetObtainedLoot: (self: StagePlayer) -> ({LootObject}),

	AddLoot: (self: StagePlayer, LootType: LootType, Data: {Amount: number, Extra: LootExtraData}) -> (),
	AddModifier: (self: StagePlayer) -> (),
	AddMatchItem: (self: StagePlayer) -> (),
}

export type MapGenerationData = {
	Infinite: boolean?,
	Seed: number, -- when set to 0 it'll be random
	Source: string, -- From the map base folder,
	Extent: number?, -- How far from the source to expand from the initial room
	Trail: number?,
}

return 0