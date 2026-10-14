local STAR = Color3.fromRGB(255, 150, 30)
local AJISA = Color3.fromRGB(110, 255, 140)
local SEAL = Color3.fromRGB(120, 200, 255)
local AMPLIFIER = Color3.fromRGB(170, 60, 255)

local function Affected(Name: string, Level: number, Amount: number)
    return {Name = Name, Level = Level, Amount = Amount, Affected_Aura = true}
end

local function Event(Data: {[string]: any})
    Data.Goal = Data.Goal or {}
    Data.Enemies = Data.Enemies or {}
    Data.Global = true

    if #Data.Enemies > 0 then
        local Total = 0
        for _, Wave in Data.Enemies do
            for _, Entry in Wave do
                if typeof(Entry) == 'table' then
                    Total += Entry.Amount
                end
            end
        end

        Data.Goal.KillEnemies = Total
    end

    return Data
end

local function Say(Speaker: string, Text: string, Time: number?)
    return {Speaker = Speaker, Text = Text, NextDialogue = Time or 3}
end

local function GoTo(Objective: string, Area: string, Dialogue: {any}?)
    return Event({
        Objective = Objective,
        Goal = {ReachPlace = Area},
        Dialogue = Dialogue,
        Finished = 'None',
    })
end

local function Board(Objective: string, From: string, To: string, Next: string, Dialogue: {any}?)
    return Event({
        Objective = Objective,
        Goal = {Travel = true},
        Ship = {From = From, To = To},
        Dialogue = Dialogue,
        Finished = Next,
    })
end

local function Ending(Dialogue: {any})
    return Event({
        Objective = "",
        Dialogue = Dialogue,
        Finished = 'End',
    })
end

local function ProgressOn(Key: string, EventName: string, Goal: string, Value: any)
    return function(Mission, Change)
        if Change.Kind ~= 'Value' or Change.Key ~= Key or Change.Value ~= true then
            return nil
        end

        local Running = Mission.__Current_Events[EventName]
        if Running and not Running:IsFinished() then
            Running:UpdateProgress(Goal, Value)
        end

        return nil
    end
end

local function NoAgentsLost()
    return {
        Text = "Don't lose any agents",
        Check = function(State)
            return (State.Agents_Lost or 0) == 0
        end,
    }
end

local function NeverMaxCorruption()
    return {
        Text = "Never reach max corruption",
        Check = function(State)
            return State.Max_Corruption_Reached ~= true
        end,
    }
end

local function Within(Minutes: number, Text: string?)
    return {
        Text = Text or `Finish within {Minutes} minutes`,
        Check = function(State)
            return (State.Elapsed or math.huge) <= Minutes * 60
        end,
    }
end

local function Flag(Text: string, Key: string)
    return {
        Text = Text,
        Check = function(State)
            return State[Key] == true
        end,
    }
end

local function Rewards(Money: number, Gems: number, Capsule: boolean?)
    local S = {
        {Type = 'Money', Amount = Money},
        {Type = 'Gems', Amount = Gems},
    }

    if Capsule then
        table.insert(S, {Type = 'Artifact', Amount = 1, Extra = {Name = 'CorpCapsule'}})
    end

    return {
        ['S'] = S,
        ['A'] = {
            {Type = 'Money', Amount = math.floor(Money * 0.6)},
            {Type = 'Gems', Amount = math.floor(Gems * 0.4)},
        },
        ['B'] = {
            {Type = 'Money', Amount = math.floor(Money * 0.4)},
        },
    }
end

return {
    ['Namek_P01'] = {
        Display_Name = "Static Over Namek",
        Description = "Namek's Anima is spiking like a trending feed. Land on the first island, push through whatever the static dragged in, and find out where it's coming from.",
        Recommended_Level = 8,
        Stage_Act = 'Namek/Story',
        Difficulty = 'EASY',

        Corruption = {Rate = 0.8, Decay = 6},

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {
                    Say("Agency", "Namek's Anima is screaming. Somebody back home is very loud about something."),
                    Say("Agency", "Keep an eye on your corruption. Stay out in this static too long and it starts eating your agents."),
                },
                Finished = 'GoTo_Plateau',
            }),

            GoTo_Plateau = GoTo("Head to the plateau ruins", 'I1_Plateau'),

            I1_Plateau = Event({
                After = 'GoTo_Plateau',
                Objective = "Clear the static-touched invaders {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 6, 3)},
                    [2] = {Affected('Sorcerer', 7, 3)},
                },
                Dialogue = {Say("Agency", "Those aren't Namekians. The static is pulling fighters in from other worlds.")},
                Finished = 'GoTo_Village',
            }),

            GoTo_Village = GoTo("Find the village below the plateau", 'I1_Village'),

            I1_Village = Event({
                After = 'GoTo_Village',
                Objective = "Drive the static out of the village {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('Sorcerer', 7, 4)},
                    [2] = {Affected('SandShinobi', 8, 4), Affected('SandShinobi', 10, 1)},
                },
                Finished = 'Village_Calm',
            }),

            Village_Calm = Ending({
                Say("Agency", "The static is thickest around the craters. Something in them is fighting back."),
                Say("Agency", "The Namekians say the Dragon Balls rest there. We'll need a way to clear the air."),
            }),
        },

        Completion = {
            Experience = 1500,
            Rewards = Rewards(6000, 30),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(8)},
        },
    },

    ['Namek_P02'] = {
        Requires = {'Namek_P01'},
        Display_Name = "The First Cleanser",
        Description = "The Agency shipped an Anima Cleanser to the village crater. Switch it on, hold its zone, and see what the static has been hiding.",
        Recommended_Level = 11,
        Stage_Act = 'Namek/Story',
        Difficulty = 'EASY',

        Corruption = {Rate = 1, Decay = 6},
        Cleansers = {
            Cleanser_Star3 = {Radius = 16, Expanded = 45, Duration = 35, Core = '3-Star Dragon Ball', Color = STAR},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {
                    Say("Agency", "The cleanser is already in the ground by the village crater. Get close and switch it on."),
                    Say("Agency", "Stay inside its zone. You won't corrupt in there, but the static will come for it."),
                },
                Finished = 'GoTo_Village',
            }),

            GoTo_Village = GoTo("Reach the village crater", 'I1_Village'),

            I1_Village = Event({
                After = 'GoTo_Village',
                Objective = "Hold the cleanser zone {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star3',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 10, 3)},
                    [2] = {Affected('SandShinobi', 10, 3)},
                    [3] = {Affected('Sorcerer', 11, 3), Affected('SandShinobi', 12, 1)},
                },
                Finished = 'Core_Found',
            }),

            Core_Found = Ending({
                Say("Agency", "There it is. The 3-Star Dragon Ball. It was holding the static back the whole time."),
                Say("Agency", "If the cores are what keep this world steady, we need to check every crater."),
            }),
        },

        Completion = {
            Experience = 1800,
            Rewards = Rewards(7000, 35),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(9)},
        },
    },

    ['Namek_P03'] = {
        Requires = {'Namek_P02'},
        Display_Name = "Twin Signals",
        Description = "Two craters on the lower island are flaring at once. Clean both, in whatever order you like, before the static settles in.",
        Recommended_Level = 14,
        Stage_Act = 'Namek/Story',
        Difficulty = 'MEDIUM',

        Corruption = {Rate = 1.1, Decay = 6},
        Cleansers = {
            Cleanser_Star6 = {Radius = 16, Expanded = 45, Duration = 35, Core = '6-Star Dragon Ball', Color = STAR},
            Cleanser_Star2 = {Radius = 16, Expanded = 45, Duration = 35, Core = '2-Star Dragon Ball', Color = STAR},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {
                    Say("Agency", "Two readings: the east village and the crater south of the main village."),
                    Say("Agency", "There's also a static nest by the far crater. Optional, but it'd help the locals."),
                },
                Finished = 'Twin_Signals',
            }),

            Twin_Signals = Event({
                Objective = "Restore the east and south craters {objective[Cores]}",
                Goal = {Cores = 2},
                Finished = 'Both_Restored',
            }),

            I1_EastVillage = Event({
                Objective = "Hold the east cleanser {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star6',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('SandShinobi', 13, 4)},
                    [2] = {Affected('Sorcerer', 14, 4), Affected('SandShinobi', 15, 1)},
                },
                Finished = 'None',
            }),

            I1_SouthCrater = Event({
                Objective = "Hold the south cleanser {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star2',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 13, 4)},
                    [2] = {Affected('Sorcerer', 14, 3), Affected('SandShinobi', 15, 1)},
                },
                Finished = 'None',
            }),

            I1_FarCrater = Event({
                Objective = "Clear the static nest {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 14, 3), Affected('Sorcerer', 14, 3)},
                },
                Complete = {Nest_Cleared = true},
                Finished = 'None',
            }),

            Both_Restored = Ending({
                Say("Agency", "6-Star and 2-Star, both back in the light. The island is breathing easier."),
            }),
        },

        Watchers = {
            ProgressOn('Cleansed_Cleanser_Star6', 'Twin_Signals', 'Cores', 1),
            ProgressOn('Cleansed_Cleanser_Star2', 'Twin_Signals', 'Cores', 1),
        },

        Completion = {
            Experience = 2100,
            Rewards = Rewards(8000, 40),
            Objectives = {NoAgentsLost(), Flag("Clear the static nest by the far crater", 'Nest_Cleared'), Within(12)},
        },
    },

    ['Namek_P04'] = {
        Requires = {'Namek_P03'},
        Display_Name = "Trending Downward",
        Description = "The static is surging on the plateau, faster than anything we've seen. Get to the plateau crater and clean it before the surge peaks.",
        Recommended_Level = 17,
        Stage_Act = 'Namek/Story',
        Difficulty = 'MEDIUM',

        Corruption = {Rate = 2.2, Decay = 8},
        Cleansers = {
            Cleanser_Star5 = {Radius = 16, Expanded = 50, Duration = 40, Core = '5-Star Dragon Ball', Color = STAR},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {
                    Say("Agency", "Corruption is building twice as fast up here. Don't stay outside a zone longer than you have to."),
                },
                Finished = 'GoTo_PlateauCenter',
            }),

            GoTo_PlateauCenter = GoTo("Climb to the heart of the plateau", 'I1_PlateauCenter'),

            I1_PlateauCenter = Event({
                After = 'GoTo_PlateauCenter',
                Objective = "Hold the plateau cleanser {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star5',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 16, 4)},
                    [2] = {Affected('SandShinobi', 17, 4)},
                    [3] = {Affected('SandShinobi', 22, 1), Affected('Sorcerer', 17, 2)},
                },
                Finished = 'Empty_Craters',
            }),

            I1_PlateauEast = Event({
                Objective = "Take down the static elite {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('Sorcerer', 18, 2)},
                    [2] = {Affected('Sorcerer', 23, 1)},
                },
                Complete = {Elite_Down = true},
                Finished = 'None',
            }),

            Empty_Craters = Ending({
                Say("Agency", "The 5-Star is safe. But I'm reading three craters on this island with nothing in them."),
                Say("Agency", "The 1-Star, 4-Star and 7-Star are gone. Someone took them."),
            }),
        },

        Completion = {
            Experience = 2400,
            Rewards = Rewards(9000, 45),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Flag("Defeat the elite on the east plateau", 'Elite_Down')},
        },
    },

    ['Namek_P05'] = {
        Requires = {'Namek_P04'},
        Display_Name = "Crossing the Water",
        Description = "The static has a trail and it leads off-island. Take the ZarosShip to the second island and clean whatever is feeding it.",
        Recommended_Level = 20,
        Stage_Act = 'Namek/Story',
        Difficulty = 'MEDIUM',

        Corruption = {Rate = 1.2, Decay = 6},
        Cleansers = {
            Cleanser_I2_Lower = {Radius = 18, Expanded = 50, Duration = 40, Core = 'Ajisa Sapling', Color = AJISA},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {
                    Say("Agency", "The trail leads across the water. The ZarosShip is fuelled and waiting."),
                },
                Finished = 'Board_Ship',
            }),

            Board_Ship = Board("Board the ZarosShip", 'Ship_Island1', 'Landing_Island2', 'Secure_Landing'),

            Secure_Landing = Event({
                Objective = "Secure the landing {objective[KillEnemies]}",
                Area = 'I2_Landing',
                Enemies = {
                    [1] = {Affected('SandShinobi', 19, 4)},
                    [2] = {Affected('Sorcerer', 20, 4)},
                },
                Dialogue = {Say("Agency", "Welcome party. Clear them out.")},
                Finished = 'GoTo_Lower',
            }),

            GoTo_Lower = GoTo("Follow the static to the lower village", 'I2_LowerVillage'),

            I2_LowerVillage = Event({
                After = 'GoTo_Lower',
                Objective = "Hold the village cleanser {objective[Cleanse]}",
                Cleanser = 'Cleanser_I2_Lower',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 20, 4)},
                    [2] = {Affected('SandShinobi', 21, 4)},
                    [3] = {Affected('SandShinobi', 24, 1), Affected('Sorcerer', 21, 3)},
                },
                Finished = 'Sapling',
            }),

            Sapling = Ending({
                Say("Agency", "An Ajisa sapling. This island's core. With it clean, the trail goes cold here."),
            }),
        },

        Completion = {
            Experience = 2800,
            Rewards = Rewards(10000, 50, true),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(12)},
        },
    },

    ['Namek_P06'] = {
        Requires = {'Namek_P05'},
        Display_Name = "The Elder's Watch",
        Description = "The elder of the second island wants to rebuild its seal. Hold the upper village while the cleanser works, and listen to what the elder has to say.",
        Recommended_Level = 23,
        Stage_Act = 'Namek/Story',
        Difficulty = 'MEDIUM',
        Spawn = 'Spawn_Island2',

        Corruption = {Rate = 1.2, Decay = 6},
        Cleansers = {
            Cleanser_I2_Upper = {Radius = 18, Expanded = 55, Duration = 45, Core = "Elder's Seal", Color = SEAL},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {
                    Say("Namekian Elder", "You cleaned our sapling. Now help me raise the seal over the upper village."),
                },
                Finished = 'GoTo_Upper',
            }),

            GoTo_Upper = GoTo("Climb to the upper village", 'I2_UpperVillage'),

            I2_UpperVillage = Event({
                After = 'GoTo_Upper',
                Objective = "Defend the seal while it charges {objective[Cleanse]}",
                Cleanser = 'Cleanser_I2_Upper',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 22, 5)},
                    [2] = {Affected('SandShinobi', 23, 5)},
                    [3] = {Affected('Sorcerer', 24, 4), Affected('SandShinobi', 27, 1)},
                },
                Finished = 'Elder_Speaks',
            }),

            I2_UpperEast = Event({
                Objective = "Secure the east terrace {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 23, 3), Affected('Sorcerer', 23, 3)},
                },
                Complete = {East_Secured = true},
                Finished = 'None',
            }),

            Elder_Speaks = Ending({
                Say("Namekian Elder", "The missing stars were not lost. They were carried to the third island."),
                Say("Namekian Elder", "Frieza's soldiers took them. The static only hid what they did."),
            }),
        },

        Completion = {
            Experience = 3100,
            Rewards = Rewards(11000, 55),
            Objectives = {NoAgentsLost(), Flag("Secure the east terrace", 'East_Secured'), NeverMaxCorruption()},
        },
    },

    ['Namek_P07'] = {
        Requires = {'Namek_P06'},
        Display_Name = "Static Trail",
        Description = "Fly to the third island, scout the outskirts and find the stolen 7-Star Dragon Ball.",
        Recommended_Level = 26,
        Stage_Act = 'Namek/Story',
        Difficulty = 'MEDIUM',
        Spawn = 'Spawn_Island2',

        Corruption = {Rate = 1.3, Decay = 6},
        Cleansers = {
            Cleanser_I3_Camp = {Radius = 16, Expanded = 45, Duration = 35, Core = '7-Star Dragon Ball', Color = STAR, Pickup = true},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Agency", "Third island. That's where Frieza parked his ship. Keep your head down.")},
                Finished = 'Board_Ship',
            }),

            Board_Ship = Board("Board the ZarosShip", 'Ship_Island2', 'Landing_Island3', 'Recon'),

            Recon = GoTo("Scout the outskirts", 'I3_Outskirts'),

            I3_Outskirts = Event({
                After = 'Recon',
                Objective = "Take out the scouts {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('Sorcerer', 25, 5)},
                    [2] = {Affected('SandShinobi', 26, 5)},
                },
                Finished = 'GoTo_Camp',
            }),

            GoTo_Camp = GoTo("Find the camp", 'I3_Camp'),

            I3_Camp = Event({
                After = 'GoTo_Camp',
                Objective = "Cleanse the camp {objective[Cleanse]}",
                Cleanser = 'Cleanser_I3_Camp',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('SandShinobi', 26, 5)},
                    [2] = {Affected('Sorcerer', 27, 5), Affected('SandShinobi', 30, 1)},
                },
                Finished = 'Grab_Star',
            }),

            Grab_Star = Event({
                Objective = "Pick up the 7-Star Dragon Ball",
                Goal = {Picked = true},
                Dialogue = {Say("Agency", "They buried it under the static. Grab it.")},
                Finished = 'Got_Seven',
            }),

            Got_Seven = Ending({
                Say("Agency", "One down, two to go. Let's get it home before they notice."),
            }),
        },

        Watchers = {
            ProgressOn('Recovered_Cleanser_I3_Camp', 'Grab_Star', 'Picked', true),
        },

        Completion = {
            Experience = 3400,
            Rewards = Rewards(12000, 60),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(14)},
        },
    },

    ['Namek_P08'] = {
        Requires = {'Namek_P07'},
        Display_Name = "Homecoming: Seven",
        Description = "Carry the 7-Star Dragon Ball back to its crater on the first island. Returning it means cleaning its crater first.",
        Recommended_Level = 29,
        Stage_Act = 'Namek/Story',
        Difficulty = 'HARD',
        Spawn = 'Spawn_Island3',

        Corruption = {Rate = 1, Decay = 6},
        Cleansers = {
            Cleanser_Star7 = {Radius = 16, Expanded = 50, Duration = 35, Core = '7-Star Dragon Ball', Color = STAR},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Agency", "The 7-Star belongs in the far crater. Fly it home.")},
                Finished = 'Board_Ship',
            }),

            Board_Ship = Board("Board the ZarosShip", 'Ship_Island3', 'Landing_Island1', 'GoTo_FarCrater'),

            GoTo_FarCrater = GoTo("Carry the 7-Star to the far crater", 'I1_FarCrater'),

            I1_FarCrater = Event({
                After = 'GoTo_FarCrater',
                Objective = "Return the 7-Star {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star7',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 28, 5)},
                    [2] = {Affected('SandShinobi', 29, 5)},
                    [3] = {Affected('SandShinobi', 32, 1), Affected('Sorcerer', 29, 3)},
                },
                Dialogue = {Say("Agency", "They followed us. Hold the crater until the ball settles.")},
                Finished = 'Seven_Home',
            }),

            I1_EastVillage = Event({
                Objective = "Clear the static from the east village {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 29, 4), Affected('Sorcerer', 29, 3)},
                },
                Complete = {Village_Safe = true},
                Finished = 'None',
            }),

            Seven_Home = Ending({
                Say("Agency", "The 7-Star is home. Five of seven in place."),
            }),
        },

        Completion = {
            Experience = 3700,
            Rewards = Rewards(13000, 65),
            Objectives = {NoAgentsLost(), Flag("Clear the east village", 'Village_Safe'), Within(12)},
        },
    },

    ['Namek_P09'] = {
        Requires = {'Namek_P08'},
        Display_Name = "Raid on the Elder",
        Description = "Frieza's soldiers hit the second island carrying the 1-Star and 4-Star. Get there, find both and take them back.",
        Recommended_Level = 32,
        Stage_Act = 'Namek/Story',
        Difficulty = 'HARD',

        Corruption = {Rate = 1.3, Decay = 6},
        Cleansers = {
            Cleanser_I2_Upper = {Radius = 16, Expanded = 45, Duration = 35, Core = '1-Star Dragon Ball', Color = STAR, Pickup = true},
            Cleanser_I2_East = {Radius = 16, Expanded = 45, Duration = 35, Core = '4-Star Dragon Ball', Color = STAR, Pickup = true},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Namekian Elder", "They are here! They have two of the stars with them!", 3.5)},
                Finished = 'Board_Ship',
            }),

            Board_Ship = Board("Board the ZarosShip", 'Ship_Island1', 'Landing_Island2', 'Two_Stars'),

            Two_Stars = Event({
                Objective = "Recover the 1-Star and 4-Star {objective[Stars]}",
                Goal = {Stars = 2},
                Finished = 'Stars_Secured',
            }),

            I2_UpperVillage = Event({
                Objective = "Cleanse the upper village {objective[Cleanse]}",
                Cleanser = 'Cleanser_I2_Upper',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 31, 5)},
                    [2] = {Affected('SandShinobi', 32, 5), Affected('SandShinobi', 35, 1)},
                },
                Finished = 'None',
            }),

            I2_UpperEast = Event({
                Objective = "Cleanse the east terrace {objective[Cleanse]}",
                Cleanser = 'Cleanser_I2_East',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('SandShinobi', 31, 5)},
                    [2] = {Affected('Sorcerer', 32, 5), Affected('Sorcerer', 35, 1)},
                },
                Finished = 'None',
            }),

            I2_LowerVillage = Event({
                Objective = "Rout the raiders in the lower village {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 32, 4), Affected('Sorcerer', 32, 4)},
                },
                Complete = {Raiders_Routed = true},
                Finished = 'None',
            }),

            Stars_Secured = Ending({
                Say("Agency", "Both stars recovered. Next stop, their craters."),
            }),
        },

        Watchers = {
            ProgressOn('Recovered_Cleanser_I2_Upper', 'Two_Stars', 'Stars', 1),
            ProgressOn('Recovered_Cleanser_I2_East', 'Two_Stars', 'Stars', 1),
        },

        Completion = {
            Experience = 4000,
            Rewards = Rewards(14000, 70),
            Objectives = {NoAgentsLost(), Flag("Rout the raiders in the lower village", 'Raiders_Routed'), NeverMaxCorruption()},
        },
    },

    ['Namek_P10'] = {
        Requires = {'Namek_P09'},
        Display_Name = "Homecoming: One and Four",
        Description = "Fly the 1-Star and 4-Star home and return them to their craters on the plateau. That makes all seven.",
        Recommended_Level = 35,
        Stage_Act = 'Namek/Story',
        Difficulty = 'HARD',
        Spawn = 'Spawn_Island2',

        Corruption = {Rate = 1, Decay = 6},
        Cleansers = {
            Cleanser_Star4 = {Radius = 16, Expanded = 50, Duration = 35, Core = '4-Star Dragon Ball', Color = STAR},
            Cleanser_Star1 = {Radius = 16, Expanded = 50, Duration = 35, Core = '1-Star Dragon Ball', Color = STAR},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Agency", "The 4-Star goes on the west plateau, the 1-Star on the east one. Any order.")},
                Finished = 'Board_Ship',
            }),

            Board_Ship = Board("Board the ZarosShip", 'Ship_Island2', 'Landing_Island1', 'Return_Stars'),

            Return_Stars = Event({
                Objective = "Return the 1-Star and 4-Star {objective[Stars]}",
                Goal = {Stars = 2},
                Finished = 'All_Seven',
            }),

            I1_Plateau = Event({
                Objective = "Return the 4-Star {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star4',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 34, 5)},
                    [2] = {Affected('SandShinobi', 35, 5), Affected('SandShinobi', 38, 1)},
                },
                Finished = 'None',
            }),

            I1_PlateauEast = Event({
                Objective = "Return the 1-Star {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star1',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('SandShinobi', 34, 5)},
                    [2] = {Affected('Sorcerer', 35, 5), Affected('Sorcerer', 38, 1)},
                },
                Finished = 'None',
            }),

            All_Seven = Ending({
                Say("Agency", "All seven Dragon Balls are home. Namek's Anima is flat. Quiet."),
                Say("Agency", "Too quiet."),
            }),
        },

        Watchers = {
            ProgressOn('Cleansed_Cleanser_Star4', 'Return_Stars', 'Stars', 1),
            ProgressOn('Cleansed_Cleanser_Star1', 'Return_Stars', 'Stars', 1),
        },

        Completion = {
            Experience = 4400,
            Rewards = Rewards(16000, 80, true),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(15)},
        },
    },

    ['Namek_P11'] = {
        Requires = {'Namek_P10'},
        Display_Name = "Hold the Stars",
        Description = "Frieza's raiders are hitting the craters one after another. Defend them in order and don't let them take another star.",
        Recommended_Level = 38,
        Stage_Act = 'Namek/Story',
        Difficulty = 'HARD',

        Corruption = {Rate = 1.4, Decay = 6},
        Cleansers = {
            Cleanser_Star3 = {Radius = 16, Expanded = 45, Duration = 30, Core = '3-Star Dragon Ball', Color = STAR},
            Cleanser_Star2 = {Radius = 16, Expanded = 45, Duration = 30, Core = '2-Star Dragon Ball', Color = STAR},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Agency", "Raiders on the lower island, heading for the craters. Village first.")},
                Finished = 'GoTo_Village',
            }),

            GoTo_Village = GoTo("Get to the village crater", 'I1_Village'),

            I1_Village = Event({
                After = 'GoTo_Village',
                Objective = "Re-seal the 3-Star {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star3',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 37, 5)},
                    [2] = {Affected('SandShinobi', 38, 6)},
                },
                Finished = 'GoTo_South',
            }),

            GoTo_South = GoTo("Run to the south crater", 'I1_SouthCrater'),

            I1_SouthCrater = Event({
                After = 'GoTo_South',
                Objective = "Re-seal the 2-Star {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star2',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('SandShinobi', 38, 6)},
                    [2] = {Affected('Sorcerer', 39, 5), Affected('Sorcerer', 42, 1)},
                },
                Finished = 'GoTo_East',
            }),

            GoTo_East = GoTo("Reach the east village", 'I1_EastVillage'),

            I1_EastVillage = Event({
                After = 'GoTo_East',
                Objective = "Stop the raiders at the east crater {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 39, 6)},
                    [2] = {Affected('Sorcerer', 40, 6)},
                    [3] = {Affected('SandShinobi', 43, 1), Affected('Sorcerer', 40, 4)},
                },
                Finished = 'Six_Taken',
            }),

            Six_Taken = Ending({
                Say("Agency", "That fight was a distraction. They've taken the 6-Star and they're running for the water!"),
            }),
        },

        Completion = {
            Experience = 4800,
            Rewards = Rewards(17000, 85),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(16)},
        },
    },

    ['Namek_P12'] = {
        Requires = {'Namek_P11'},
        Display_Name = "Chase the Six",
        Description = "Chase the 6-Star thieves to the second island, take the ball back and fly it straight home to its crater.",
        Recommended_Level = 41,
        Stage_Act = 'Namek/Story',
        Difficulty = 'HARD',

        Corruption = {Rate = 1.3, Decay = 6},
        Cleansers = {
            Cleanser_I2_Lower = {Radius = 16, Expanded = 45, Duration = 30, Core = '6-Star Dragon Ball', Color = STAR, Pickup = true},
            Cleanser_Star6 = {Radius = 16, Expanded = 50, Duration = 30, Core = '6-Star Dragon Ball', Color = STAR},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Agency", "They took a ship to the second island. Go after them.")},
                Finished = 'Board_Ship',
            }),

            Board_Ship = Board("Chase them in the ZarosShip", 'Ship_Island1', 'Landing_Island2', 'Corner_Thieves'),

            Corner_Thieves = Event({
                Objective = "Corner the thieves {objective[KillEnemies]}",
                Area = 'I2_Landing',
                Enemies = {
                    [1] = {Affected('SandShinobi', 40, 6)},
                    [2] = {Affected('Sorcerer', 41, 6)},
                },
                Finished = 'GoTo_Lower',
            }),

            GoTo_Lower = GoTo("Track the 6-Star to the lower village", 'I2_LowerVillage'),

            I2_LowerVillage = Event({
                After = 'GoTo_Lower',
                Objective = "Cleanse their hideout {objective[Cleanse]}",
                Cleanser = 'Cleanser_I2_Lower',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('Sorcerer', 41, 6)},
                    [2] = {Affected('SandShinobi', 42, 5), Affected('SandShinobi', 45, 1)},
                },
                Finished = 'Grab_Six',
            }),

            Grab_Six = Event({
                Objective = "Pick up the 6-Star Dragon Ball",
                Goal = {Picked = true},
                Finished = 'Board_Back',
            }),

            Board_Back = Board("Fly the 6-Star home", 'Ship_Island2', 'Landing_Island1', 'GoTo_East'),

            GoTo_East = GoTo("Carry the 6-Star to the east crater", 'I1_EastVillage'),

            I1_EastVillage = Event({
                After = 'GoTo_East',
                Objective = "Return the 6-Star {objective[Cleanse]}",
                Cleanser = 'Cleanser_Star6',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('SandShinobi', 42, 6)},
                    [2] = {Affected('Sorcerer', 43, 6)},
                },
                Finished = 'Six_Home',
            }),

            Six_Home = Ending({
                Say("Agency", "Seven for seven again. But the static isn't coming from the craters anymore."),
                Say("Agency", "It's coming from Frieza's ship."),
            }),
        },

        Watchers = {
            ProgressOn('Recovered_Cleanser_I2_Lower', 'Grab_Six', 'Picked', true),
        },

        Completion = {
            Experience = 5200,
            Rewards = Rewards(18000, 90),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(20)},
        },
    },

    ['Namek_P13'] = {
        Requires = {'Namek_P12'},
        Display_Name = "The Amplifier",
        Description = "Frieza has something next to his ship that is feeding the static. Push through the outskirts and cleanse it.",
        Recommended_Level = 44,
        Stage_Act = 'Namek/Story',
        Difficulty = 'EXTREME',

        Corruption = {Rate = 1.6, Decay = 6},
        Cleansers = {
            Cleanser_I3_Ship = {Radius = 18, Expanded = 60, Duration = 45, Core = 'Anima Amplifier', Color = AMPLIFIER},
        },

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Agency", "Whatever is by that ship is amplifying the static. We shut it down today.")},
                Finished = 'Board_Ship',
            }),

            Board_Ship = Board("Board the ZarosShip", 'Ship_Island1', 'Landing_Island3', 'Push_Outskirts'),

            Push_Outskirts = GoTo("Push into the outskirts", 'I3_Outskirts'),

            I3_Outskirts = Event({
                After = 'Push_Outskirts',
                Objective = "Break the outer line {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('Sorcerer', 43, 6)},
                    [2] = {Affected('SandShinobi', 44, 6)},
                    [3] = {Affected('SandShinobi', 47, 1), Affected('Sorcerer', 44, 3)},
                },
                Finished = 'GoTo_Ship',
            }),

            GoTo_Ship = GoTo("Reach the front of the ship", 'I3_ShipFront'),

            I3_ShipFront = Event({
                After = 'GoTo_Ship',
                Objective = "Cleanse the amplifier {objective[Cleanse]}",
                Cleanser = 'Cleanser_I3_Ship',
                Goal = {Cleanse = 100},
                Enemies = {
                    [1] = {Affected('SandShinobi', 44, 6)},
                    [2] = {Affected('Sorcerer', 45, 6)},
                    [3] = {Affected('SandShinobi', 48, 1), Affected('Sorcerer', 48, 1), Affected('Sorcerer', 45, 4)},
                },
                Finished = 'Amplifier_Down',
            }),

            I3_Camp = Event({
                Objective = "Burn down the camp {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 44, 5), Affected('Sorcerer', 44, 5)},
                },
                Complete = {Camp_Burned = true},
                Finished = 'None',
            }),

            Amplifier_Down = Ending({
                Say("Agency", "It was an Anima amplifier. He's been farming the static and feeding it back into Namek."),
                Say("Agency", "And now he knows we're here."),
            }),
        },

        Completion = {
            Experience = 5600,
            Rewards = Rewards(20000, 100),
            Objectives = {NoAgentsLost(), Flag("Burn down the camp", 'Camp_Burned'), NeverMaxCorruption()},
        },
    },

    ['Namek_P14'] = {
        Requires = {'Namek_P13'},
        Display_Name = "Elite Guard",
        Description = "Frieza's elite guard is holding the ground around his ship. Take them out one by one.",
        Recommended_Level = 47,
        Stage_Act = 'Namek/Story',
        Difficulty = 'EXTREME',
        Spawn = 'Spawn_Island3',

        Corruption = {Rate = 1.4, Decay = 6},

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {Say("Agency", "Three guard posts: the camp, the outskirts, then the front of the ship.")},
                Finished = 'GoTo_Camp',
            }),

            GoTo_Camp = GoTo("Hit the camp post", 'I3_Camp'),

            I3_Camp = Event({
                After = 'GoTo_Camp',
                Objective = "Defeat the camp guard {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 46, 6)},
                    [2] = {Affected('SandShinobi', 52, 1)},
                },
                Finished = 'GoTo_Outskirts',
            }),

            GoTo_Outskirts = GoTo("Hit the outskirts post", 'I3_Outskirts'),

            I3_Outskirts = Event({
                After = 'GoTo_Outskirts',
                Objective = "Defeat the outskirts guard {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('Sorcerer', 46, 6)},
                    [2] = {Affected('Sorcerer', 52, 1)},
                },
                Finished = 'GoTo_Front',
            }),

            GoTo_Front = GoTo("Head to the front of the ship", 'I3_ShipFront'),

            I3_ShipFront = Event({
                After = 'GoTo_Front',
                Objective = "Defeat the elite pair {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('SandShinobi', 47, 4), Affected('Sorcerer', 47, 4)},
                    [2] = {Affected('SandShinobi', 54, 1), Affected('Sorcerer', 54, 1)},
                },
                Finished = 'Guard_Down',
            }),

            Guard_Down = Ending({
                Say("Agency", "The guard is down. The hatch is opening..."),
            }),
        },

        Completion = {
            Experience = 6000,
            Rewards = Rewards(22000, 110),
            Objectives = {NoAgentsLost(), NeverMaxCorruption(), Within(14)},
        },
    },

    ['Namek_P15'] = {
        Requires = {'Namek_P14'},
        Display_Name = "Emperor of Static",
        Description = "Frieza steps out of his ship. Clear his last soldiers, then end this.",
        Recommended_Level = 50,
        Stage_Act = 'Namek/Story',
        Difficulty = 'EXTREME',
        Spawn = 'Spawn_Island3',

        Corruption = {Rate = 1.2, Decay = 6},

        Triggers = {
            Begin = Event({
                Objective = "",
                Dialogue = {
                    Say("Frieza", "So you're the ones who've been cleaning up my little experiment.", 3.5),
                    Say("Agency", "Clear his soldiers before he comes down. Then it's just him."),
                },
                Finished = 'GoTo_Front',
            }),

            GoTo_Front = GoTo("Face Frieza's ship", 'I3_ShipFront'),

            I3_ShipFront = Event({
                After = 'GoTo_Front',
                Objective = "Defeat Frieza's soldiers {objective[KillEnemies]}",
                Enemies = {
                    [1] = {Affected('Sorcerer', 48, 8)},
                    [2] = {Affected('SandShinobi', 49, 8)},
                    [3] = {Affected('Sorcerer', 50, 6), Affected('SandShinobi', 50, 2)},
                },
                Complete = {Cleared_Before_Frieza = true},
                Finished = 'Frieza',
            }),

            Frieza = Event({
                Objective = "Defeat Frieza {objective[KillEnemies]}",
                Area = 'I3_ShipFront',
                Enemies = {
                    [1] = {{Name = 'Boss', Level = 55, Amount = 1}},
                },
                Dialogue = {Say("Frieza", "Enough. I'll handle this personally.")},
                Finished = 'Victory',
            }),

            Victory = Ending({
                Say("Agency", "Frieza's down, and the static is clearing. Namek is back to itself."),
            }),
        },

        Completion = {
            Experience = 7500,
            Rewards = Rewards(30000, 150, true),
            Objectives = {
                Flag("Defeat every sub-rank enemy before Frieza appears", 'Cleared_Before_Frieza'),
                NoAgentsLost(),
                Within(10, "Defeat Frieza within 10 minutes"),
                NeverMaxCorruption(),
            },
        },
    },
}
