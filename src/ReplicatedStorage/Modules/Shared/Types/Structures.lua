local Types = require(script.Parent)
export type DestructibleData = {

    Health: number,
    Size: Vector3,

    Element_Damage_Multipliers: {
        [Types.Element]: number?,
    },

    Default_Structure_Data: {
        Effect: {
            {
                Type: string,
                Value: number | string,
                Time: number,
            }
        }?,

        Other: {
            Energy: number?,
        }?
    }

}

export type DestructibleServerEntity = {
    Destroyed: Types.Signal<Types.GenericClass>,

    __Type: string,
    __Position: Vector3,
    __Collider: BasePart,
    __Rotation: number,
    __Health: number,
    __Id: number,

    Destroy: (self: DestructibleServerEntity) -> (),
    Compress: (self: DestructibleServerEntity, OnlyId: boolean?) -> (buffer),

    GetCollider: (self: DestructibleServerEntity) -> (BasePart),
    GetPosition: (self: DestructibleServerEntity) -> (Vector3),

    --[[
        Sets up the destructible and it's stats
    ]]
    Spawn: (self: DestructibleServerEntity, Id: number) -> (),
    TakeDamage: (self: DestructibleServerEntity, Amount: number) -> (),
}

return 0