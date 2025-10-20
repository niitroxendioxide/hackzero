local Types = require(script.Parent.Parent.Parent.Types.Stages)

return {
    Name = "Las Noches",
    Map = "General/Dungeon",

    Acts = {
        Intro = {
            AutoGenerate = true,
            AutoGenerationData = {
                Seed = 0x1524, 
                Source = 'Rooms',
                Extent = 15,
            },
            Description = "Investigate the place",
        },

        SecondMission = {
            AutoGenerate = true,
            AutoGenerationData = {
                Seed = 0x1525, 
                Source = 'Rooms',
                Extent = 15,
            },
            Description = "Investigate the place",
        },

        ThirdMission = {
            AutoGenerate = true,
            AutoGenerationData = {
                Seed = 0x1525, 
                Source = 'Rooms',
                Extent = 15,
            },
            Description = "Investigate the place",
        },
    },
} :: Types.Stage