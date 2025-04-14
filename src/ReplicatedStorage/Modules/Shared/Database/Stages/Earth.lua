--
local Types = require("../../Types")


--
return {
    Name = "Earth",

    Acts = {
        Act1 = {
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
                    Objective = "Beat {objective[KillEnemies]} enemies!",
                    Goal = {KillEnemies = 10},
                    Enemies = {
                        [1] = {"Saiyan", 3, "Template", 1},
                        [2] = {"Template", 4, "Saiyan", 1},
                        [3] = {"Boss", 1},
                    },

                    Finished = function(State: Types.EventHandlerState): string
                        if State.KillEnemies == true then
                            return "Second"
                        end

                        return "Bye"
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

                Bye = {
                    Actions = {
                        ["KickPlayer"] = "all",
                    }
                }
            }
        }
    }
} :: Types.Stage