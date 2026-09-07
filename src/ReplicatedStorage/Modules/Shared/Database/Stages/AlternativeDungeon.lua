local Types = require("../../Types/Stages")

return {
    Name = "Alternative_Dungeon_Test",
    Map = "General/AlternativeDungeon",

    Acts = {
        Intro = {
            AutoGenerate = true,
            AutoGenerationData = {
                Infinite = false,
                Seed = 0, -- 0 means the run rolls one
                Rooms = 8, -- how many rooms, halls excluded
                Extent = 25, -- hard cap on total tiles
                Trail = 15,
                Source = 'Rooms', -- folder of room models under the map asset
            },

            Description = "Infinite Scrolling Test",
            Requisites = {},

            Markers = {},

            Completion = {
                Experience = 500,

                Handler = function(State)
                    return "A"
                end,

                Rewards = {
                    ['A'] = {
                        {Type = "Gold", Amount = 1000},
                    },
                    ['B'] = {
                        {Type = "Gold", Amount = 250},
                    },
                },
            },

            Guide = {},
        }
    }
} :: Types.Stage
