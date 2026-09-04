--
local Common = require(script.Common)
local Status = require(script.Status)
local Movement = require(script.Movement)
local Core = require(script.Core)

export type Artifact = Common.Artifact
export type Drive = Common.Drive
export type Stat = Common.Stat
export type StatesClass = Common.StatesClass
export type StateEffect = Common.StateEffect
export type State = Common.State
export type AnimatorController = Common.AnimatorController
export type CharacterClass = Common.CharacterClass
export type CharacterStats = Common.CharacterStats
export type Heap = Common.Heap
export type Enemy = Common.Enemy
export type ClientEnemy = Common.ClientEnemy

export type AgentMeter = Status.AgentMeter
export type EffectParameters = Status.EffectParameters
export type EffectObject = Status.EffectObject
export type AgentStatusClass = Status.AgentStatusClass

export type ServerCharacterClass = Movement.ServerCharacterClass

export type ProcessEventData = Core.ProcessEventData
export type HitProcessState = Core.HitProcessState
export type AgentArtifactClass = Core.AgentArtifactClass
export type DriveObject = Core.DriveObject
export type MarkedEnemyStruct = Core.MarkedEnemyStruct
export type AssistStruct = Core.AssistStruct
export type AgentClass = Core.AgentClass
export type ServerAgentClass = Core.ServerAgentClass
export type AgentItemsClass = Core.AgentItemsClass
export type GearType = Core.GearType
export type GearObject = Core.GearObject
export type ServerGearManager = Core.ServerGearManager
export type ClientGearManager = Core.ClientGearManager

return 0
