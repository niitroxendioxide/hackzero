--[[
    World handler for the 'Recover' mission kind.

    A component under `Components/Missions/<Kind>` runs missions that have no map and no
    database entry of their own. It is handed a `MissionBuilder` over the rooms the
    generator just placed, and authors the mission into them.

    Reference implementation for "Recover my suitcase!":
      - the item is a pickup in the room furthest from spawn, behind a fight
      - picking it up and beating that fight end the mission, in either order (see the watcher)
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
const Corners = {
    vector.create(1, 0, 1),
    vector.create(1, 0, -1),
    vector.create(-1, 0, 1),
    vector.create(-1, 0, -1),
}

const function AddCratesToRoom(Builder: MissionBuilder.MissionBuilder, Room: { read Id: number })
    const RoomRNG = Random.new(Builder:GetSeed() + Room.Id);
    const Amount = RoomRNG:NextInteger(0, 4)
    if Amount == 0 then
        return;
    end

    local Corner = Corners[ RoomRNG:NextInteger(1, #Corners) ]

    for i = -Amount // 2, Amount // 2 do
        local At = Corner * 30 + vector.create(i * 2.25, 2.5, -i * 2.25) ---vector.create(Corner.x * 30, 3.25, Corner.z * 30)


        Builder:AddDestructible(Room, 'Crate', {
            Drops = {
                {Type = 'Money', Amount = 375},
            },
        }, CFrame.new(At))
    end
end

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
    local Rooms = Builder:PickRooms(FillerRooms)

    for Index, Room in Rooms do
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
                    Amount = MinCount,
                })
            end
        end

        Builder:AddEvent(Room, {
            Objective = "Clear the way {objective[KillEnemies]}",
            Goal = {
                ['KillEnemies'] = BASE_ENEMY_COUNT + Index,
            },
            Enemies = EnemyList,
            Tags = {'Filler'},

            Finished = 'None',
        })

        AddCratesToRoom(Builder, Room);

        RoomActualIndex += 1;
    end

    if not TargetRoom then
        warn("There is no target room.")

        return
    end

    Builder:AddInteraction(TargetRoom, {
        Type = 'ItemPickup',
        Tag = TargetItem,
        Drops = {
            {Type = '_mission_object', Extra = {Name = TargetItem}, Amount = 1},
        },
        SetValues = {
            ['Recovered'] = true,
        },
    }, CFrame.new(0, 2, 8))

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
        Tags = {'FinalBoss'},

        -- The ending is the watcher's call, so the fight and the pickup can land in either order.
        Finished = 'None',
    })

    Builder:AddNamedEvent('Recovered', {
        Objective = "Get the " .. TargetItem .. " out",
        Goal = {},
        Enemies = {},
        -- Cutscene = 'Recover_Ending', -- the ending cutscene goes here
        Dialogue = {{
            Speaker = "Agency",
            Text = "Got it. Pulling you out now.",
            NextDialogue = 3,
        }},
        Global = true,
        Finished = 'End',
    })

    Builder:AddWatcher(function(Mission, _Change)
        print("Completed final boss?", Mission:HasCompletedTag('FinalBoss'))
        if Mission:GetProgressValue('Recovered') == true and Mission:HasCompletedTag('FinalBoss') then
            return 'Recovered'
        end

        return nil
    end)

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
