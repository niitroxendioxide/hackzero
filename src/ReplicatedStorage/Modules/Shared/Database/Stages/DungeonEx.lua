local Types = require("../../Types/Stages")

return {
    Name = "Example Dungeon",
    Map = "General/Dungeon",
    Icon = 111390689929706,

    Acts = {
        --[[
            Procedural act. `AutoGenerate` is what makes MatchService build the map with
            the dungeon generator instead of unpacking a static asset, and
            `AutoGenerationData` are this act's defaults.

            A mission can override any of these per run (see `settings.MISSION.GENERATION`
            or the `Generation` block on a mission entry), which is how one dungeon stage
            serves missions of different sizes.

            Rooms placed by the generator become `Room_<n>` triggers automatically, so
            hooking one only takes an entry in `Markers` (for event data) or a
            `ForTrigger("Room_3", ...)` in the stage's server component.
        ]]
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
