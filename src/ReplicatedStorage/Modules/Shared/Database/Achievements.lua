

export type Achievement = {
    Description: string,
    Rewards: {
        Gems: number,
        Gold: number?,
    },

    Display_Name: string?,
    Tier: number,
}


return  {

    Tiers = {
        Bronze = 1,
        Silver = 2,
        Gold = 3,
        Platinum = 4,
    },

    List = {
        ["Tutorial_Complete"] = {
            Description = "You\'ve completed the tutorial!",
            Rewards = {
                Gems = 60,
            },

            Tier = 1,
        },

        ["Beginner_Agent"] = {
            Description = "You\'ve completed your first mission ever!",
            Rewards = {
                Gems = 60,
            },

            Tier = 1,
        },
    }

} :: {
    Tiers: {
        Silver: number,
        Bronze: number,
        Gold: number,
        Platinum: number,
    },

    List: {
        [string]: Achievement
    }
}