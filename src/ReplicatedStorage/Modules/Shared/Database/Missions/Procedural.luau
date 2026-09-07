--[[

    @important
    claude hallucination, do not bother.
    @readabove
    @tags: @important

    Procedural missions.

    These are shaped like any other mission entry, the difference is that they do not ship
    a hand-built map: `Procedural` sends the run through the dungeon generator, and
    `Generation` says how big the layout should be.

    Every room the generator places becomes a `Room_<n>` trigger, so `Triggers` keys line
    up with rooms by name. A room without an entry here is just a room to walk through,
    one with an entry runs that event when a player enters it.

    Entries in here are `Invisible` because the intent is for them to be produced at
    runtime (the lobby mission NPC rolling a mission) rather than picked off a list, this
    one exists as the walkable reference for that shape.
]]

return {
    ['Dungeon_Procedural_Test'] = {
        Invisible = true,

        Display_Name = "Unstable Rift",
        Description = 'The rift keeps rearranging itself. Clear it out before it settles.',
        Recommended_Level = 1,

        Stage_Act = 'DungeonEx/Intro',
        Difficulty = 'EASY',

        Procedural = true,
        --- Nil seed on purpose: each run rolls its own layout and reports it back.
        Generation = {
            Rooms = 8,
            Extent = 25,
            Source = 'Rooms',
        },

        Destructibles = {},

        Triggers = {
            Begin = {
                Objective = "Find your way through the rift",
                Goal = {},
                Enemies = {},
                Global = true,

                Finished = 'None',
            },

            --- Rooms are numbered from the spawn room outwards (Room_0 .. Room_<Rooms-1>).
            Room_1 = {
                Objective = "Clear the room {objective[KillEnemies]}",
                Goal = {
                    ['KillEnemies'] = 3,
                },
                Enemies = {
                    [1] = {
                        {Name = 'SandShinobi', Level = 1, Amount = 3},
                    },
                },

                Finished = 'None',
            },
        },

        Completion = {
            Experience = 500,
            Rewards = {
                ['A'] = {
                    {Type = 'Money', Amount = 2500},
                },
                ['B'] = {
                    {Type = 'Money', Amount = 1000},
                },
            },

            Handler = function(_State: {})
                return 'A'
            end,
        },
    },
}
