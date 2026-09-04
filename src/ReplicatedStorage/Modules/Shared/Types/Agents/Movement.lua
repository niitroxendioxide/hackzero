--
local Common = require(script.Parent.Common)

type StatesClass = Common.StatesClass
type State = Common.State

export type ServerCharacterClass = {
	__MovementVelocity: Vector3,
	__SurfaceVelocity: Vector3,
	__LastMovementVelocity: Vector3,
	__Velocity: Vector3,
	__ActiveThread: thread?,
	__PhysicsSpeed: number,
	__Moving: boolean,
	__Active: boolean,
	__MovementAcceleration: number,
	__Linear_Movements: {},
	__Enemy_Collisions_Enabled: boolean,
	__Forward_Velocities: {},
	__Height: number,
	__Normal: Vector3,
	__Position: Vector3,
	__Rotation: Vector3,
	__Added_Colliders: {[any]: boolean?},
	__Collider: BasePart?,

	Name: string,
	States: StatesClass,

	SetEnemyCollisionState: (self: ServerCharacterClass, State: boolean) -> (),
	Init: (self: ServerCharacterClass) -> (),

	Stop: (self: ServerCharacterClass) -> (),
	Move: (self: ServerCharacterClass) -> (),
	Rotate: (self: ServerCharacterClass, Angle: Vector3) -> (),

	GetPivot: (self: ServerCharacterClass) -> CFrame,
	PivotTo: (self: ServerCharacterClass, Pivot: CFrame) -> (),

	SetColliderGroupState: (self: ServerCharacterClass, Group: {}, State: boolean?) -> (),
	ApplyForwardImpulse: (self: ServerCharacterClass, Power: number, FadeOutTime: number) -> (),
	AddLinearMovement: (self: ServerCharacterClass, Direction: Vector3, Time: number) -> (),

	RemoveForwardImpulse: (self: ServerCharacterClass, Object: {}) -> (),

	--[[
		Deceleration to apply to the given velocity this frame, based on world air/surface friction.
		@param AirMod Multiplier applied to the air-friction component only
	]]
	CalculateVelocityDeceleration: (self: ServerCharacterClass, Velocity: Vector3, AirMod: number?) -> (Vector3),
	--[[
		Sum of every active linear-movement and forward-impulse velocity currently applied to the character.
	]]
	GetAdditionalVelocities: (self: ServerCharacterClass) -> (Vector3),
	GetTotalVelocity: (self: ServerCharacterClass) -> (Vector3),

	--[[
		(Re)creates the physical collider part used for enemy/world collision checks.
	]]
	CreateCollider: (self: ServerCharacterClass) -> (),
	IsMoving: (self: ServerCharacterClass) -> (boolean),
	GetState: (self: ServerCharacterClass) -> (State),
}

return 0
