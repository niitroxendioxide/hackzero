----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Components = ServerStorage.Modules.Components


local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Types = require(Shared.Types.Behaviors)

----
local Behaviors = {
    __Cached = {},
}

function Behaviors.Init(_)
    
    for _, BehaviorModule in Components.Behaviors:GetDescendants() do
        if not BehaviorModule:IsA('ModuleScript') then
            continue
        end

        local Success, BehaviorInitializator = pcall(require, BehaviorModule);
        if Success then
            local CleanedName = string.gsub(BehaviorModule.Name, "_Behavior", "")

            Behaviors.__Cached[CleanedName] = BehaviorInitializator;
        else
            Debugger:DebugLine("Behaviors", "Could not load behavior module: " .. BehaviorModule.Name, 50)
        end
    end

end

function Behaviors.GetBehavior(self, Name: string): (Behavior: Types.EntityBehavior, State: Types.EntityState) -> ()
    return Behaviors.__Cached[Name]
end

return Behaviors
