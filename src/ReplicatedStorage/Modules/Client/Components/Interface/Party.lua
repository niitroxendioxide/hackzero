local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Interface

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)

local PartyComponent = ComponentClass.new("Party", "Lobby")


--
local function RequestPartyCreation()
    print("Fired to server")
    Network:Fire("Party", GameEnum.PartyManaging.Create)
end

local function AddPlayerToList(PlayerName: string)
    local Main = PartyComponent:GetFrame()
    local Object = Assets.Lobby.Party.PlayerListObject:Clone()
    Object.PlayerName.Text = PlayerName
    Object.Parent = Main.Players
end

--
function PartyComponent:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD") :: ScreenGui
	local Main = HUD:FindFirstChild("Party", true)

    return Main
end


function PartyComponent:Init(): ()
    Network:On("Party", function(Type: number, PartyData): ()
        if Type == GameEnum.PartyManaging.Create then
            AddPlayerToList(Player.DisplayName)
        end
    end)
end

function PartyComponent:CreateParty()
    return RequestPartyCreation()
end

return PartyComponent :: Types.UIComponent & {
    CreateParty: () -> ()
}