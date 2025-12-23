local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)

local Anims = ReplicatedStorage.Assets.Animations
local Movement = Anims.General.Movement

--
local InterfaceAnims = {}
function InterfaceAnims:PlayAnim(Rig: Model, Tab: string, AgentName: string)
    local AnimIdTrack = Anims.Menu:FindFirstChild(Tab)
    if Tab == 'Stats' then
        local MovementDirectory = Anims.Characters:FindFirstChild(AgentName) and Anims.Characters[AgentName]:FindFirstChild('Movement')
        if MovementDirectory and MovementDirectory:FindFirstChild('Idle') then
            AnimIdTrack = MovementDirectory.Idle;
        else
            AnimIdTrack = Movement.Idle;
        end
    end
    
    Animation:StopTracksWithTag(Rig, 'Interface')
    
    local PlayingTrack = Animation:Play(Rig, AnimIdTrack)
    PlayingTrack:AddTag('Interface')

    return PlayingTrack
end

return InterfaceAnims
