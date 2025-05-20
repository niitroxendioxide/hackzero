--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Places = require(Shared.Places)
local Network = require(Shared.Network)
local Statics = require(Shared.Database.Statics)
local GameEnum = require(Shared.GameEnum)

local Services = Modules.Services
local DataService = require(Services.Data.DataService)
local TeleportService = require(Services.Data.TeleportService)

--
local TIMES = Statics.AFK_Times
local REWARDS = Statics.AFK_Rewards

--
local Service = {

    __Player_Clock = {},
}

function Service:Init()
    Network.new('AFKEvent', 'Event')

    Network:On("AFKEvent", function(Player: Player, Type: number)
        if Type == 1 then
            local Success = TeleportService:TeleportPlayer(Player, 'Lobby')

            if Success then
                print("Teleported back!")
            end
        elseif Type == 2 then
            local Success = TeleportService:TeleportPlayer(Player, 'AFK')

            if Success then
                print("Teleported to AFK place!")
            end
        end
    end)

    -- Prevent it from loading AFK place functions !
    if not Places:IsInPlace("AFK") then
        return
    end

    --
    RunService.Heartbeat:Connect(function(Delta: number): ()
        for _, Player in Players:GetPlayers() do
            Service:UpdateCounters(Player)
        end
    end)
end

function Service:UpdateCounters(Player: Player)
    if not Service.__Player_Clock[Player] then
        Service.__Player_Clock[Player] = {
            Money = os.time(),
            Gems = os.time(),
        }
    end

    --
    local PlayerData = Service.__Player_Clock[Player]

    if os.time() - PlayerData.Gems >= TIMES.Gems then
        Service:GiveCurrency(Player, "Gems", REWARDS.Currency.Gems)
    end

    if os.time() - PlayerData.Money >= TIMES.Money then
        Service:GiveCurrency(Player, "Money", REWARDS.Currency.Money)
    end

    --
    for ClockName, Time in PlayerData do
        if os.time() - Time >= TIMES[ClockName] then
            PlayerData[ClockName] = os.time()
        end
    end
end

function Service:GiveCurrency(Player: Player, Type: 'Gems' | 'Money', Amount: number)
    local PlayerCurrencyVal = DataService:Get(Player, Type)
    if PlayerCurrencyVal == nil then
        return
    end

    DataService:Set(Player, PlayerCurrencyVal + Amount)

    --
    Network:Fire("AFKEvent", Player, GameEnum.AFKEvent.GiveCurrency, {Type, Amount})
end

return Service
