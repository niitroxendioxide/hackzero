--
local Types = require("../../Types/Stages")

local function Area(Name: string)
    return {
        Type = 'Trigger',
        Name = Name,
    }
end

--
return {
    Name = "Namek",
    Map = "Dragon Ball/Namek",

    Acts = {
        Story = {
            Markers = {
                ['I1_Landing'] = Area('I1_Landing'),
                ['I1_Plateau'] = Area('I1_Plateau'),
                ['I1_PlateauCenter'] = Area('I1_PlateauCenter'),
                ['I1_PlateauEast'] = Area('I1_PlateauEast'),
                ['I1_Village'] = Area('I1_Village'),
                ['I1_SouthCrater'] = Area('I1_SouthCrater'),
                ['I1_EastVillage'] = Area('I1_EastVillage'),
                ['I1_FarCrater'] = Area('I1_FarCrater'),
                ['I1_Shore'] = Area('I1_Shore'),

                ['I2_Landing'] = Area('I2_Landing'),
                ['I2_LowerVillage'] = Area('I2_LowerVillage'),
                ['I2_UpperVillage'] = Area('I2_UpperVillage'),
                ['I2_UpperEast'] = Area('I2_UpperEast'),

                ['I3_Landing'] = Area('I3_Landing'),
                ['I3_Outskirts'] = Area('I3_Outskirts'),
                ['I3_Camp'] = Area('I3_Camp'),
                ['I3_ShipFront'] = Area('I3_ShipFront'),
            },
        },
    },
} :: Types.Stage
