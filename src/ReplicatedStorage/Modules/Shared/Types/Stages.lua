local Agents = require('./Agents')

export type Signal<T...> = RBXScriptSignal & {Fire: (self: RBXScriptSignal, T...) -> ()}
export type Stage_Objective = "KillEnemies" | "TimeSurvive" | "PushLoad" | "ReachPlace" | "TalkTo" | "AllReachPlace"
export type Reward_Type = "Artifact" | "Gold" | "Gems" | "Agent"
export type Goal = {
	[Stage_Objective]: number,
}
export type EventHandlerState = {Dead: boolean, [string | Stage_Objective]: any}
export type Action = "KickPlayer"
export type MissionKind = "Recover" | "Escort" | "Revenge";

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

export type LootExtraData = {
	Slot: number?,
	Tier: ('Epic' | 'Legendary' | 'Mythical')?,
	Extra: number,

	Name: string?,
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
		[number]: {
			[number]: EnemySpawnData,
		}
	},
}


export type Stage_Act = {
	--[string]: any,
	AutoGenerate: boolean?,
	AutoGenerationData: MapGenerationData?, 
	Description: string?,
	Requisites: {

	},

	Completion: {
		Experience: number,
		Handler: (Objectives: {[string]: boolean}) -> (Rating),

		Rewards: {
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

--[[
	Everything `MissionClass.new` needs to build a mission. Passed as a single table so
	adding a field doesn't shuffle a positional argument list.
]]
export type MissionConfig = {
	Type: MissionType,
	Stage: string,
	Act: string,

	--[[
		The world data the mission runs on: `Markers` / `Guide` / `Destructibles` /
		`Completion`. For an Expedition this is the stage act itself.
	]]
	Data: {[string]: any},

	-- Seed the map was generated with, 0 when the map is static.
	Seed: number?,
	Procedural: boolean?,
	Generated_Rooms: {GeneratedRoom}?,

	--[[
		Component running this mission, already resolved by MatchService. Passing it means a
		runtime-authored mission hooks into its kind's handler rather than a stage act it
		does not have.
	]]
	Hooks: any?,
}

export type MissionType = "Mission" | "Expedition" | "ChaosControl"

export type MissionClass = {
	--- Fired with (Won, FinalState) once the mission closes out.
	Finished: Signal<boolean, {[string]: any}>,

	__Is_Chaos_Control: boolean,
	__Custom_Data: {
		[string]: any,
	},
	__Active: boolean,
	__Act: string,
	__Stage: string,
	__Seed: number,
	__Procedural: boolean,
	__Generated_Rooms: {GeneratedRoom},
	__Mission_Type: MissionType,
	__Is_Finished: boolean,
	__Current_Active_Triggers: {thread | RBXScriptConnection},
	__Current_Events: {[string]: EventClass},
	__Current_State: {[string]: any},
	__Hooks: {[string]: (...any) -> ()},


	--[[
		Seed the map for this mission was generated with, 0 for a static map.
	]]
	GetSeed: (self: MissionClass) -> (number),

	--[[
		Rooms the generator placed for this mission, empty for a static map.
	]]
	GetGeneratedRooms: (self: MissionClass) -> ({GeneratedRoom}),
	IsProcedural: (self: MissionClass) -> (boolean),

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
	Finish: (self: MissionClass, Won: boolean?) -> (),
	ObtainMissionRank: (self: MissionClass, Won: boolean) -> (Rating),
	GetHookPayload: (self: MissionClass, Extra: {[string]: any}?) -> ({[string]: any}),
	GetProgressValue: (self: MissionClass, Key: string) -> (),
	SetProgressValue: (self: MissionClass, Key: string, Value: any) -> (),

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

	__Current_Mission_State_Link: {}?,
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
	__Is_Custom_Event: boolean,
	__Custom_Event_Data: {[string]: any},

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

export type LootType = "Item" | "Artifact" | "Drive" | "Money" | "Gems"
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
	Extent: number?, -- Hard cap on how many tiles (rooms + halls) may be placed
	Trail: number?,

	--[[
		How many *rooms* (halls excluded) the layout should end up with.
		This is the number a procedural mission "comes up with", `Extent` stays the
		safety cap for the tile budget.
	]]
	Rooms: number?,
}

--[[
	One placed piece of a generated layout. Halls are included so a hook can walk the
	whole layout, but only rooms get a marker/trigger part.
]]
export type GeneratedRoom = {
	Id: number,
	Name: string,
	Model: Model,
	Marker: BasePart?,
	IsHall: boolean,

	--[[
		A plug plastered over a doorway that led nowhere, rather than part of the layout
		proper. Carries no marker, so it is never a place a mission can put anything.
	]]
	IsSeal: boolean?,
}

--[[
	What the map generator hands back, so the caller knows what it actually built and
	with which seed (relevant when the seed was rolled at runtime).
]]
export type MapGenerationResult = {
	Seed: number,
	Rooms: {GeneratedRoom},
	RoomCount: number,
	HallCount: number,

	--- Plugs placed over doorways that led nowhere. Outside the room and tile budgets.
	SealCount: number,
}

--[[
	Parameters a mission carries when it wants its map built procedurally instead of
	unpacked from a static asset.
]]
export type ProceduralMissionData = {
	Rooms: number?,
	Source: string?,
	Infinite: boolean?,
	Extent: number?,
	Trail: number?,
}

return 0