local Types = require("../../Types/Stages")

return {
    Name = "Dungeon_Test",
    Map = "General/TestDungeon",

    Acts = {
        -- Infinite scrolling example/test
        Intro = {
            AutoGenerate = true,
            AutoGenerationData = {
                Infinite = true,
                Seed = 0, -- can be a number,
                Source = 'Rooms',-- by default it'l lsearch for this folder, but as example
            },

            Description = "Infinite Scrolling Test",
            Requisites = {},

            Rewards = {
                Handler = function(State)
                    return "A"
                end,

                Items = {
                    {
                        Type = "Item",
                        Amount = 1,
                        Extra = {
                            Slot = 1,
                        }
                    },
                }
            },

            Guide = {},
        }
    }
} :: Types.Stage