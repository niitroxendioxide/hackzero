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

--
local Controller = {}

function Controller:Init()
    if Places:CanFight() then
        return
    end


    Network:On("Banner", Controller.__BannerUpdated)
    Network:On("Summon", function(Type: number, Result: {string})
        if Type == GameEnum.SummonRequests.SummonResult then
            local SummonMenu = InterfaceController:GetComponent("Summon")
            SummonMenu:Set(false)

            for _, Agent in Result do
                Cutscenes:Start("Summon", {Agent[1]})
                Cutscenes:WaitCurrent()
            end

            SummonMenu:Set(true)
        end
    end)
end

function Controller.__BannerUpdated(BannerId: number, BannerData: {})
    if typeof(BannerData) ~= "table" then
        return
    end

    local SummonMenu = InterfaceController:GetComponent("Summon")

    local SubCharacters = {}
    for i = 2, #BannerData do
        table.insert(SubCharacters, BannerData[i][1])
    end

    SummonMenu:SetBanner({
        Main = BannerData[1][1],
        Sub = SubCharacters,
    })
end

return Controller