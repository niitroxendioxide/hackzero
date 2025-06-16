local Types = require(script.Parent)

export type GearData = {
    Name: string,
    Stack_Limit: number?,
    Mods: {
        [string]: number,
    },
}

export type ItemData = {
    DisplayName: string,
    Description: string,

    Tier: Types.Tier,
    Icon: number,
    Max: number,
}

export type PlayerItemData = {
    Name: string,
    Amount: number,
}

export type PlayerItemDataClass = {
    __Name: string,
    __Amount: number,

    SetAmount: (self: PlayerItemDataClass, number) -> (),

    Compress: (self: PlayerItemDataClass) -> (buffer),
    ToData: (self: PlayerItemDataClass) -> (),
}


return {}