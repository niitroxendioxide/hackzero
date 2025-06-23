--
local Types = require("../../Types")


--
return {
    Name = "Earth",
    Map = "Dragon Ball/West City",

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
                    Objective = "Go check out what\'s going on at that one street",
                    Goal = {ReachPlace = "FirstFightZone"},
                    Enemies = {},
                    Global = true,

                    Finished = function(State: Types.EventHandlerState): string
                        if State.ReachPlace == true then
                            return "FirstFightZone"
                        end

                        return "Second"
                    end
                },

                FirstFightZone = {
                    Objective = "Beat {objective[KillEnemies]} enemies!",
                    Goal = {KillEnemies = 10},
                    Enemies = {
                        -- Enemy Name, Enemy Amount, Enemy Level
                        [1] = {"Saiyan", 3, 5, "Template", 1, 10},
                        [2] = {"Template", 4, 25, "Saiyan", 1, 20},
                        [3] = {"Boss", 1, 30},
                    },
                    Global = true,

                    Finished = function(State: Types.EventHandlerState)
                        return "End"
                    end
                },

                Second = {
                    Objective = "Do something idk",
                    Goal = {ReachPlace = ""},
                    Enemies = {},

                    Finished = function(State: Types.EventHandlerState): (string)
                        return "End"
                    end
                },

                Death = {
                    Actions = {
                        ["KickPlayer"] = "all",
                    }
                }
            }
        }
    }
} :: Types.Stage