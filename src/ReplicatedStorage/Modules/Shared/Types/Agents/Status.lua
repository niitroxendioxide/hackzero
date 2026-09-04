--
local Common = require(script.Parent.Common)

type Stat = Common.Stat
type CharacterStats = Common.CharacterStats
type Heap = Common.Heap
type AgentMovesetAbility = Common.AgentMovesetAbility

export type AgentMeter = {
	Value: number,
	Max: number,

	Name: string,
	FillSpeed: number,
	EmptySpeed: number,
	LastUpdate: number,

	Fill: boolean,
	Empty: boolean,
}

-- [[Server data]]
export type EffectParameters = {
	Type: (Stat & AgentMovesetAbility)?,
	Value: (number | string)?,
	Time: number?,
	Tag: string,
	Unique: boolean?,
	Callback: ((Id: number) -> ())?,
	Hide: boolean,
	Base_Amount: number?,
	Limit: number?,
	RemovesAll: boolean,
}
export type EffectObject = {
	Remove: () -> (),
	Id: number,
	Value: number,
	Type: Stat & AgentMovesetAbility,
	Tag: string?,
	Time: number?,
	Created: number,
	Thread: thread,
	Amount: number,
	Limit: number,
}

export type AgentStatusClass = {
	__Ultimate: number,
	__Energy: number,
	__Health: number,
	__Max_Health: number,
	__Base_Stats: CharacterStats,
	__Alive: boolean,
	__Total_Effects: Heap,
	__Meters: {AgentMeter},

	__Artifact_Set: {},
	__Card_Set: nil,
	__Effects: {EffectObject},

	CreateMeter: (self: AgentStatusClass, Name: string, Data: {Max: number?, EmptySpeed: number?, FillSpeed: number?, Id: number}) -> (),
	UpdateMeter: (self: AgentStatusClass, Name: string, Amount: number) -> (),
	SetMeter: (self: AgentStatusClass, Name: string, Amount: number) -> (),
	GetAllMeters: (self: AgentStatusClass) -> ({AgentMeter}),
	HasMeter: (self: AgentStatusClass) -> (boolean),
	RemoveMeter: (self: AgentStatusClass, Name: string) -> (),
	SetMeterUpdateType: (self: AgentStatusClass, Meter: string, Type: number, State: boolean, Handler: (() -> ())?) -> (),

	GetStat: (self: AgentStatusClass, Name: Stat) -> (number),
	Update: (self: AgentStatusClass, delta: number) -> (),

	IsAlive: (self: AgentStatusClass) -> (boolean),
	Revive: (self: AgentStatusClass) -> (),
	Damage: (self: AgentStatusClass, Amount: number) -> (),
	Heal: (self: AgentStatusClass, Amount: number) -> (),
	GetHealth: (self: AgentStatusClass) -> (number, number),
	GetEnergy: (self: AgentStatusClass) -> (number),

	--[[
		Sets the maximum health of the status.
		@param Fill If true, also fills current health up to the new max.
	]]
	SetMaxHealth: (self: AgentStatusClass, Amount: number, Fill: boolean?) -> (),
	--[[
		Directly overwrites current health, clamped between 0 and the current max health.
	]]
	SetHealth: (self: AgentStatusClass, Amount: number) -> (),

	SetEnergy: (self: AgentStatusClass, Energy: number) -> (),
	UseEnergy: (self: AgentStatusClass, EnergyUsed: number) -> (),
	GiveEnergy: (self: AgentStatusClass, EnergyGiven: number) -> (),

	AddEffect: (self: AgentStatusClass, EffectParameters) -> (EffectObject),
	GetEffect: (self: AgentStatusClass, string) -> (EffectObject),
	ChangeEffect: (self: AgentStatusClass, Tag: string, Amount: number?, RestartThread: boolean?) -> (EffectObject),
	GetStatEffects: (self: AgentStatusClass, Stat) -> (number),
	RemoveEffect: (self: AgentStatusClass, Id: number) -> (),

	GetArtifactBonus: (self: AgentStatusClass, Type: string) -> (number),
	GetDriveBonus: (self: AgentStatusClass, Type: string) -> (),
	GetMultBonus: (self: AgentStatusClass, Name: string) -> (),

	GetUltimate: (self: AgentStatusClass) -> (number),
	SetUltimate: (self: AgentStatusClass, Value: number) -> (number),
	UseUltimate: (self: AgentStatusClass, Mods: {}?) -> (),
	GiveUltimate: (self: AgentStatusClass, Amount: number) -> (),
}

return 0
