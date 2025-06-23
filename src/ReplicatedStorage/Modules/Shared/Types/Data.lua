local Types = require(script.Parent)

export type GearData = {
    Name: string,
    Stack_Limit: number?,
    Mods: {
        [string]: number,
    },
}


export type ItemTypes = "Upgrade" | "Feeding"
export type ItemData = {
    DisplayName: string,
    Description: string,

    Type: ItemTypes,
    Tier: Types.Tier,
    Icon: number,
    Max: number,

    Other: {
        FeedExp: number,
    }?,
}

export type PlayerItemData = {
    Name: string,
    Amount: number,
}

export type PlayerItemDataClass = {
    __Name: string,
    __Amount: number,

    SetAmount: (self: PlayerItemDataClass, number) -> (),

    Compress: (self: PlayerItemDataClass) -> (buffer, string?),
    ToData: (self: PlayerItemDataClass) -> (),
}

export type QuestData = {
    Rewards: {
        [string]: number,
    },

    Goals: {
        [string]: number | {
            [string]: number
        }
    },

    Progress: {
        [string]: {[string]: number} | number,
    },

    Id: string,
    Description: string,
    Type: string,
    Name: string,
}


return {}