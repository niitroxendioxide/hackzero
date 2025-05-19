local TextChatService = game:GetService("TextChatService")


--
local Service = {
    __Channels = {} :: {[string]: TextChannel},
}

function Service:Init()
    local Channels = TextChatService:FindFirstChild("Channels")
    if not Channels then
        return
    end

    for _, Channel in TextChatService.Channels:GetChildren() do
        Service.__Channels[Channel.Name] = Channel
    end
end

function Service:GetChannel(ChannelName: string): TextChannel
    return Service.__Channels[ChannelName]
end

function Service:SetupChannels(Player: Player)
    if Player:GetRankInGroup(33084145) >= 250 then
        local DevChannel = Service:GetChannel("Developing")
        if not DevChannel then return end

        DevChannel:AddUserAsync(Player.UserId)
    end
end

return Service