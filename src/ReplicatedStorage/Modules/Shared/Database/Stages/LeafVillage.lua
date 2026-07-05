--
local Types = require("../../Types/Stages")


--
return {
    Name = "Leaf Village",
    Map = "Naruto/Leaf Village",
    Icon = 87617824603134,

    Acts = {
        Intro = {
            Markers = {
                ['PreEntrance'] = {
                    Type = 'Trigger',
                    Name = 'GrassArea',
                },

                ['Entrance'] = {
                    Type = 'Trigger',
                    Name = 'Entrance',
                },
            },
        },
    }
} :: Types.Stage