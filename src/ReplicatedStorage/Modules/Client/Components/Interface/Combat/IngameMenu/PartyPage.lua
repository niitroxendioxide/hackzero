local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local PartyAssets = Assets.Interface.Menu.Party
local RandomNameGen = require(ReplicatedStorage.Modules.Client.Utility.RandomNameGen)
local Agents = require(Client.Libraries.Characters)
local Companions = require(Client.Libraries.Companions)

local AgentDatabase = require(Shared.Database.Characters)
local CompanionDatabase = require(Shared.Database.Companions)

type BaseInterface = Frame & {
    List: ScrollingFrame,
    Background: ImageLabel,
    Label: TextLabel,
}

--
local PageController = {
    Frame = nil :: BaseInterface?,
}

function PageController:Init(Frame: BaseInterface)
    PageController.Frame = Frame
end

function PageController:Refresh()
    local Frame = PageController.Frame
    local List = Agents:GetCharacters()

    for _, Obj in Frame.List:GetChildren() do
        if Obj:IsA("Frame") then
            Obj:Destroy()
        end
    end

    for _, Agent in List do
        local Data = AgentDatabase:GetCharacterData(Agent.Name)

        local Cur, Max = Agent:GetHealth()
        local NewObject = PartyAssets.Agent:Clone()
        local ObjData = NewObject.Data
        ObjData.CharName.Text = Data.Display_Name
        ObjData.Health.Fill.Size = UDim2.fromScale(Cur/Max, 1)
        NewObject.Type.Text = 'AGENT'
        NewObject.Parent = Frame.List
    end

    --
    local CompanionList = Companions:GetCompanionsForPlayer(Players.LocalPlayer)
    for _, ClientCompanion in CompanionList do
        local Data = CompanionDatabase:GetCompanionData(ClientCompanion.Name)
        if not(Data) then
            return
        end

        local NewObject = PartyAssets.Agent:Clone()
        local ObjData = NewObject.Data
        ObjData.CharName.Text = ClientCompanion:GetName() --RandomNameGen(ClientCompanion:GetId())
        ObjData.Health:Destroy()
        NewObject.Type.Text = 'COMPANION'
        NewObject.Parent = Frame.List
    end
end

return PageController;