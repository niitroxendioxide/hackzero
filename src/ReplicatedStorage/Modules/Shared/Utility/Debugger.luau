local RunService = game:GetService("RunService")
local Debugger = {}
local Cache = {}

function Debugger:DebugLine(Id: string, Text: string, TimesPerSecond: number, Side: string?)
    if Cache[Id] and (os.clock() - Cache[Id] < (1 / TimesPerSecond)) then
        return
    end

    Cache[Id] = os.clock()

    if RunService:IsServer() and not(Side == 'Client') then
        print(`[SERVER] ({Id}): {Text}`)
    elseif RunService:IsClient() and not(Side == 'Server') then
        print(`[CLIENT] ({Id}): {Text}`)
    end
end

function Debugger:WarnLine(Id: string, Text: string, TimesPerSecond: number, Side: string?)
    if Cache[Id] and (os.clock() - Cache[Id] < (1 / TimesPerSecond)) then
        return
    end

    Cache[Id] = os.clock()

    if RunService:IsServer() and not(Side == 'Client') then
        warn(`[SERVER] ({Id}): {Text}`)
    elseif RunService:IsClient() and not(Side == 'Server') then
        warn(`[CLIENT] ({Id}): {Text}`)
    end
end


return Debugger