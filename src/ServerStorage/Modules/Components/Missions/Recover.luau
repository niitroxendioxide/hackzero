--[[
    World handler for the 'Recover' mission kind.

    A component under `Components/Missions/<Kind>` runs missions that have no map and no
    database entry of their own. It is handed a `MissionBuilder` over the rooms the
    generator just placed, and authors the mission into them.

    Reference implementation for "Recover my suitcase!":
      - the item goes in the room furthest from spawn, behind a fight
      - a couple of rooms in between get filler fights
      - a handler NPC waits at spawn

    Every roll comes off the run seed, so the same seed gives the same layout *and* the
    same mission inside it.

    Reads from `Builder:GetData()`, all optional, all set by the lobby when it built the
    packet: `Target_Item`, `Display_Name`, `Enemy`, `Enemy_Level`, `Filler_Rooms`.
]]

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

const Shared = ReplicatedStorage.Modules.Shared
const Classes = ServerStorage.Modules.Classes

const GameEnum = require(Shared.GameEnum)
const StageClass = require(Classes.Game.Stage)
const MissionBuilder = require(Classes.Game.MissionBuilder)

const DEFAULT_ENEMY = 'Sorcerer'
const DEFAULT_LEVEL = 5
const BASE_ENEMY_COUNT = 5
const DEFAULT_FILLER_ROOMS = 2

const Recover = StageClass.new()
const NPC_CFRAME = CFrame.new(18, 3.67, -24) * CFrame.Angles(0, math.rad(135), 0)

Recover:OnBuild(function(Builder: MissionBuilder.MissionBuilder)
    const Data = Builder:GetData()

    const TargetItem = Data.Target_Item or 'Suitcase'
    const Enemy = Data.Enemy or DEFAULT_ENEMY
    const Level = (Data.Enemy_Level or DEFAULT_LEVEL) :: number
    const FillerRooms = (Data.Filler_Rooms or DEFAULT_FILLER_ROOMS) :: number

    Builder:SetBeginEvent({
        Objective = "Find the " .. TargetItem,
        Goal = {},
        Enemies = {},
        Dialogue = {{
            Speaker = "Agency",
            Text = "It's in here somewhere. Time to sweep the rooms.",
            NextDialogue = 3,
        }},
        Global = true,
        Finished = 'None',
    })

    Builder:AddNPC(Builder:GetSpawnRoom(), 'Handler', {
        Name = 'Handler',
        Dialogue = {{
            Speaker = "Handler",
            Text = "Bring me that " .. TargetItem .. " and we're square.",
            NextDialogue = 2.3,
        }},
    }, NPC_CFRAME)

    local TargetRoom = Builder:PickFurthestRoom() or Builder:PickRoom()

    local RoomActualIndex = 0;
    for Index, Room in Builder:PickRooms(FillerRooms) do
        const MIN_FIRST_WAVE = BASE_ENEMY_COUNT // 2;
        const MIN_SECOND_WAVE = BASE_ENEMY_COUNT - MIN_FIRST_WAVE;
        const WAVES_GENERATED = 2 + Builder.__Random:NextNumber(0.25 * RoomActualIndex, 0.5 * RoomActualIndex);

        const EnemyList = {};

        for i = 1, WAVES_GENERATED do
            local MinCount = i == 1 and MIN_FIRST_WAVE + Index or MIN_SECOND_WAVE + Index
            EnemyList[i] = {}

            const ENEMIES_COUNT = 1;
            for i = 1, ENEMIES_COUNT do
                table.insert(EnemyList[i], {
                    Name = DEFAULT_ENEMY,
                    Level = Level,
                    Amount = MinCount, -- WARNING: Must replace with actual code for better spread later
                })
            end
        end

        Builder:AddEvent(Room, {
            Objective = "Clear the way {objective[KillEnemies]}",
            Goal = {
                ['KillEnemies'] = BASE_ENEMY_COUNT + Index,
            },
            Enemies = EnemyList,

            Finished = 'None',
        })

        RoomActualIndex += 1;
    end

    if not TargetRoom then
        warn("There is no target room.")

        return
    end

    Builder:AddDestructible(TargetRoom, 'Crate', {
        Drops = {
            {Type = '_mission_object', Extra = {Name = "Suitcase"}, Amount = 1,},
            {Type = 'Money', Amount = 1500},
        },
        SetValues = {
            ['Recovered'] = true,
        },
    }, CFrame.new(0, 4, 0))

    const Final_Room_Enemy_Count = Builder.__Random:NextInteger(8, 16)
    const Third_Part = Final_Room_Enemy_Count // 3;
    const Boss_Amount = 1;

    Builder:AddEvent(TargetRoom, {
        Objective = "Recover the " .. TargetItem .. " {objective[KillEnemies]}",
        Goal = {
            ['KillEnemies'] = Third_Part * 3 + Boss_Amount,
        },
        Enemies = {
            [1] = {
                {Name = Enemy, Level = Level, Amount = Third_Part},
                {Name = Enemy, Level = Level + 2, Amount = Third_Part},
            },

            [2] = {
                {Name = Enemy, Level = Level + 5, Amount = Third_Part},
                {Name = 'Boss', Level = Level + 10, Amount = Boss_Amount},
            }
        },
        Dialogue = {{
            Speaker = "Agency",
            Text = "There. They were sitting on it the whole time.",
            NextDialogue = 3,
        }},

        Finished = function(State, Mission_State)
            if Mission_State.Recovered ~= true then
                warn('Do somethin when they haven\'t recovered the item yet.')

                return 'None'
            end

            return 'End'
        end
    })

    Builder:SetCompletion({
        Experience = 750,

        Rewards = {
            ['S'] = {
                {Type = 'Money', Amount = 5000},
                {Type = 'Gems', Amount = 20},
            },
            ['A'] = {
                {Type = 'Money', Amount = 3000},
            },
            ['B'] = {
                {Type = 'Money', Amount = 1200},
            },
        },

        Handler = function(State: {[string]: any})
            local NeededRecovered = State.Recovered == true and 5 or 0;
            local RecoveredScore = NeededRecovered + (State.Optional and 5 or 0)

            if RecoveredScore >= 10 then
                return 'S'
            elseif RecoveredScore >= 7 then
                return 'A'
            elseif RecoveredScore >= 5 then
                return 'B'
            end

            return
        end,
    })
end)

return Recover
