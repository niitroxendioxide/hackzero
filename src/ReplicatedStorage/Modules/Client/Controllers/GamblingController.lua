--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Places = require(Shared.Places)

local InterfaceController = require(script.Parent.InterfaceController)
local Cutscenes = require(Client.Libraries.Cutscenes)
local NavStates = require(Client.States.Navigation)

--
local Controller = {}

function Controller:Init()
    if not Places:IsInPlace("Lobby") then
        return
    end


    Network:On("Banner", Controller.__BannerUpdated)
    Network:On("Summon", function(Type: number, Result: {string})
        if Type == GameEnum.SummonRequests.SummonResult then
            local SummonMenu = InterfaceController:GetComponent("Summon")
            SummonMenu:SetVisibility(false)
            NavStates:Set('Movement_Locked', true)

            for _, Agent in Result do
                Cutscenes:Start("Summon", {Agent[1], Agent[2]})
                Cutscenes:WaitCurrent()
            end

            NavStates:Set('Movement_Locked', false)
            SummonMenu:SetVisibility(true)
        end
    end)
end

function Controller.__BannerUpdated(BannerId: number, BannerData: {})
    if typeof(BannerData) ~= "table" then
        return
    end

    print(BannerId, BannerData)

    local SummonMenu = InterfaceController:GetComponent("Summon")

    local SubCharacters = {}
    for i = 2, #BannerData do
        table.insert(SubCharacters, BannerData[i][1])
    end

    if not(BannerData) or not(BannerData[1]) or not(BannerData[1][1]) then
        return
    end

    SummonMenu:SetBanner({
        Main = BannerData[1][1],
        Sub = SubCharacters,
    })
end

return Controller