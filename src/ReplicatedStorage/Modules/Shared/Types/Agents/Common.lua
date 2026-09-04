--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local Types = require(script.Parent.Parent)
local Heap = require(script.Parent.Parent.Parent.Utility.Heap)

-- Base re-exports shared by every Agent-domain submodule (Core/Status/Movement).
export type Artifact = Types.PlayerArtifactData
export type Drive = Types.PlayerDriveData
export type Stat = Types.Stat
export type StatesClass = Types.StatesClass
export type StateEffect = Types.StateEffect
export type State = Types.State
export type AnimatorController = Types.AnimatorController
export type CharacterClass = Types.CharacterClass
export type CharacterStats = Types.CharacterStats
export type Heap = Heap.Heap
export type Element = Types.Element
export type AgentMovesetAbility = Types.AgentMovesetAbility
export type Rig = Types.Rig
export type Signal<T...> = Signal.ScriptSignal<T...>

export type Enemy = Types.ServerEnemyClass
export type ClientEnemy = Types.EnemyClass

return 0
