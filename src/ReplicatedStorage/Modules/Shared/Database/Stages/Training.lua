--
local Types = require("../../Types")


--
return {
    Name = "Training",
    Map = "General/Training",

    Acts = {
        Act1 = {
            Requisites = {
                
            },

            Rewards = {
                Handler = function(Objectives): Types.Rating
                    if Objectives.Main == true then
                        return "SSS"
                    end

                    return "X"
                end
            },
            Guide = {
                Begin = {
                    Objective = "Test out new skills",
                    Goal = {LeaveTestingPlace = true},
                    Enemies = {},
                    Global = true,

                    Finished = function(State: Types.EventHandlerState): string
                        return "End"
                    end
                },
            }
        }
    }
} :: Types.Stage