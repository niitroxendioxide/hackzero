local Agents = require(script.Parent.Agents)


export type CompanionClass = {
    __Connection: RBXScriptConnection,
    __Movement: CompanionMovementClass,
    __Owner: Agents.AgentClass | Agents.ServerAgentClass,
    __Level: number,
    __Gear: CompanionStatsClass,
    __Key: number,

    --[[
        Set the player to follow by default. When no area is set, the robot follows this character
        @param Box **BasePart** The area that the companion will be limited to
    ]]
    Follow: (self: CompanionClass, AgentToFollow: Agents.AgentClass | Agents.ServerAgentClass) -> (),
    AddGear: (self: CompanionClass, Gear: Agents.GearObject) -> (),
    GetOwner: (self: CompanionClass) -> (Agents.AgentClass | Agents.ServerAgentClass),
    RemoveGear: (self: CompanionClass, Gear: Agents.GearObject) -> (),

    --[[
        Set the area for the companion to wander around
        @param Box **BasePart** The area that the companion will be limited to
    ]]
    SetAreaDelimiter: (self: CompanionClass, Box: BasePart) -> (),
    Init: (self: CompanionClass, Id: number) -> (),

    --Update: (self: CompanionClass, Delta: number) -> (),
}

export type CompanionStatsClass = {
    __Items: {Agents.GearObject},
    __Stats: {
        Attack: number,
        Defense: number,
        Speed: number,
    },
}

export type CompanionMovementClass = {
    __Area: BasePart?,
    __Clock: number,
    __Speed: number,
    __Moving: boolean,
    __Collider: BasePart,
    __Can_Move: boolean,
    __Follow_Object: (Agents.AgentClass | Agents.ServerAgentClass)?,
    __Movement_Length: number,

    __Goal: vector | Vector3,
    __Position: vector | Vector3,
    __Direction: vector | Vector3,

    Update: (self: CompanionMovementClass, Delta: number) -> (),

    SetArea: (self: CompanionMovementClass, Box: BasePart?) -> (),
    Follow: (self: CompanionMovementClass, Agent: Agents.AgentClass | Agents.ServerAgentClass) -> (),

    CreateCollider: (self: CompanionMovementClass) -> (BasePart),
    GetCollider: (self: CompanionMovementClass) -> (BasePart),
    GetPivot: (self: CompanionMovementClass) -> (CFrame),
}

return 0