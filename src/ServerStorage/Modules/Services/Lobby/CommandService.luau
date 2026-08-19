local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ServerStorage = game:GetService("ServerStorage")

--
local Packages = ServerStorage.Modules.Packages
local Commands = Packages.Commands

--
local Service = {
    __Modules = {},
    __Verified = {},
}

function Service:Init()
    for _, CommandModule in Commands:GetChildren() do
        local Success, ModuleFunction = pcall(require, CommandModule);
        if Success then
            Service.__Modules[CommandModule.Name] = ModuleFunction
        else
            warn('Error loading command:', ModuleFunction)
        end
    end

    --

    --
    local CommandFolder = TextChatService:FindFirstChild("Commands") :: Folder
    if not CommandFolder then
        return
    end

    for _, CommandInstance: TextChatCommand in CommandFolder:GetChildren() :: {TextChatCommand} do
        CommandInstance.Triggered:Connect(function(Caster: TextSource, Message: string)
            local Player = Players:GetPlayerByUserId(Caster.UserId)
            if not Service.__Verified[Player] then
                local Result = GroupService:GetRolesInGroupAsync(Caster.UserId, 33084145);
                if Result.IsMember then

                    for _, Role in Result.Roles do
                        if Role.Rank >= 100 then
                            Service.__Verified[Player] = true
                        end
                    end

                else
                    return
                end
            end

            local CleanedString = string.gsub(Message, CommandInstance.PrimaryAlias, '')
            CleanedString = string.gsub(CleanedString, "^%s+", "")

            Service:ExecuteCommand(CommandInstance.Name, Caster, string.split(CleanedString, ' '))
        end)
    end
end

function Service:ExecuteCommand(Name: string, ...)
    local Id = string.gsub(Name, 'Command', '')
    local Command = Service.__Modules[Id]

    if not Command then
        return
    end

    task.spawn(Command, ...)
end

return Service