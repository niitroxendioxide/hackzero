--
local Types = require("../../Types/Stages")


--
return {
    Name = "Earth",
    Map = "Dragon Ball/Destroyed West City",

    Acts = {
        Intro = {
            Requisites = {},

            Rewards = {
                Items = {
                    ['Meat'] = 5,
                },

                Handler = function(CompletionState): Types.Rating
                    local Survivors = CompletionState.Rescued_All_Survivors == true and 1 or 0
                    local AllEnemies = CompletionState.Beat_All_Enemies == true and 1 or 0

                    if Survivors and AllEnemies then
                        return 'S'
                    elseif Survivors or AllEnemies then
                        return 'A'
                    end

                    return 'X'
                end,
            },

            Markers = {
                ['FightArea'] = {
                    Type = 'Trigger',
                    Name = 'Spawn_Area',
                },

                ['FightArea1'] = {
                    Type = 'Trigger',
                    Name = 'Harder_Area',
                },

                ['FightArea2'] = {
                    Type = 'Trigger',
                    Name = 'Inbetween_Area',
                },

                ['FightArea3'] = {
                    Type = 'Trigger',
                    Name = 'Last_Area',
                },

                ['CrystalDestructible'] = {
                    Type = "Destructible",
                    Destructible_Id = "Crystals",
                },

                ['DestructibleWall'] = {
                    Type = "Destructible",
                    Destructible_Id = "Reinforced_Wall",

                }
            },

            Guide = {
                Begin = {
                    Objective = "Rescue all the survivors",
                    Goal = {Rescued = true},
                    Enemies = {},
                    Global = true,

                    Finished = function(State)
                        return "End"
                    end
                },

                Spawn_Area = {
                    Objective = "Defeat {objective[KillEnemies]} enemies",
                    Goal = {
                        ['KillEnemies'] = 10,
                    },
                    Enemies = {
                        [1] = {'Saiyan', 3, 1, 'Saiyan', 2, 1},
                        [2] = {'Saiyan', 4, 2, 'Boss', 1, 2},
                    },

                    Finished = function()
                        return 'None'
                    end
                },

                Harder_Area = {
                    Objective = "Defeat the {objective[KillEnemies]} saiyans",
                    Goal = {
                        ['KillEnemies'] = 10,
                    },
                    Enemies = {
                        [1] = {'Saiyan', 3, 3},
                        [2] = {'Saiyan', 4, 3},
                        [3] = {'Saiyan', 3, 3},
                    },

                    Finished = function()
                        return 'None'
                    end
                },
            },
        },

        --[[ex = {
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
        }]]
    }
} :: Types.Stage