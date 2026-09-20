local Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Client = ReplicatedStorage.Modules.Client
const Shared = ReplicatedStorage.Modules.Shared

local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
const Agents = require(Client.Libraries.Characters)
const Animation = require(Client.Libraries.Animation)
-- local String = require(Shared.Utility.String)
const Debugger = require(Shared.Utility.Debugger)
const GameEnum = require(Shared.GameEnum)
const Prompts = require(Client.Libraries.Prompts)
const Network = require(Shared.Network)
const AgentTypes = require(Shared.Types.Agents)

const EVENT_NAME = "MatchInteraction"

--
type NetObj = {buffer | BasePart}
type InteractionType = keyof<typeof(GameEnum.MatchInteractionType)>

type ObjInterface = {
    Id: number,
    Type: InteractionType,
    TriggerCount: number,
    Triggered: boolean,
    Collider: BasePart
}
type StoredObject = { 
    Id: number, 
    Prompt: ProximityPrompt, 
    Collider: BasePart,
    Type: InteractionType,
    Effects: { Instance | ParticleEmitter | Beam },
}

--
const Controller = {
    __trigger_lock = false,

    Cache = {} :: { [number]: StoredObject },
}

const ReverseLookups = {
    ItemPickup = "Pick Up Item"
} :: { [InteractionType]: string }

-- // PRIVATE

const function DecodeObject(Object: NetObj | ObjInterface): ObjInterface
    if typeof(Object[1]) ~= 'buffer' then
        return Object :: ObjInterface
    end

    const Id = buffer.readu16(Object[1] :: buffer, 0)
    const TriggerCount = buffer.readu16(Object[1] :: buffer, 2)
    const Triggered = buffer.readu8(Object[1] :: buffer, 4) == 1
    const TypeId = buffer.readu8(Object[1] :: buffer, 5)
    const Type = GameEnum.KeyLookup(GameEnum.MatchInteractionType, TypeId) :: InteractionType

    return {
        Id = Id,
        TriggerCount = TriggerCount,
        Triggered = Triggered,
        Type = Type,
        Collider = Object[2] :: BasePart,
    } :: ObjInterface
end

const function PlayObjVFX(Object: StoredObject)
    if not Object or not Object.Effects then return end

    for _, EffectItem in Object.Effects do
        if typeof(EffectItem) == 'function' then
            task.spawn(EffectItem)
        elseif EffectItem:IsA('BasePart') then
            Effects:CleanUp(EffectItem, 5)
            Effects:Toggle(EffectItem, false)
        end
    end
end

const function ItemPickupAction(Object: StoredObject, RepId: number)
    if RepId == nil or (Object == nil or Object.Collider == nil) then
        print('RepId or Obj/Obj.Collider are nil')
        
        return;
    end

    const ActiveAgent: AgentTypes.AgentClass = Agents:GetCurrent(RepId)

    if ActiveAgent == nil then
        return;
    end
    
    const AnimObj = Animation:GetAnim("General.Interact.ItemPickup")
    const Track = Animation:Play(ActiveAgent:GetModel(), AnimObj, 0, 1, 1)
    const AgentPos = ActiveAgent:GetPivot().Position
    const Direction = CFrame.lookAt( AgentPos, Object.Collider.Position * vector.create(1, 0, 1) + AgentPos * vector.create(0, 1, 0) ).LookVector
    local CFLocation = (Object.Collider.Position * vector.create(1, 0, 1)) - (Direction * 2.5) + vector.create(0, AgentPos.Y)
    if (AgentPos - Object.Collider.Position).Magnitude < 4 then
        CFLocation = AgentPos;
    end

    const GoalCFrame = CFrame.lookAlong(CFLocation, Direction)

    Effects:Tween(ActiveAgent:GetHitbox(), { 0.3, 'Sine' }, { CFrame = GoalCFrame })
    
    task.delay(0.283, PlayObjVFX, Object)

    ActiveAgent:SetPhysicsEnabled(false)
    
    Track.Stopped:Wait()

    ActiveAgent:PivotTo(GoalCFrame)
    ActiveAgent:SetPhysicsEnabled(true)
end



-- // PUBLIC FUNCTIONS

function Controller.OnEvent(Type: number, ...)
    local Args = { ... };

    if Type == GameEnum.MatchInteraction.Create then
        const Object = Args[1];
    
        Controller:AddInteraction(Object)
    elseif Type == GameEnum.MatchInteraction.BatchCreate then
        const List = Args[1]

        for _, Object in List do
            print('Create instruction here:', Object)

            Controller:AddInteraction(Object)
        end

    end

end

function Controller:AddInteraction(paramObject: NetObj | ObjInterface)
    local Data = DecodeObject(paramObject);
    if Controller.Cache[Data.Id] then
        Controller:RemoveInteraction(Data.Id);

        Debugger:WarnLine(
            "MatchInteractionsController::AddInteraction", 
            `To replace id {Data.Id}, it was first removed.`,
            5
        )
    end

    const VFXFolder = ReplicatedStorage.Assets.Effects.General.Interactions;
    local Type = (GameEnum.MatchInteractionType :: any)[Data.Type]

    local Prompt = Prompts:CreatePromptOnPart(Data.Collider, Type, ReverseLookups[Data.Type], "Item" , 12, {
        "MatchInteraction",
    })

    const ItemVFX = {}
    if Data.Type == "ItemPickup" then
        const Glitter = Effects:Create(VFXFolder.FloatingItem);
        Glitter:PivotTo(Data.Collider.CFrame) -- * CFrame.new(0, -Data.Collider.Size.Y/2 + 0.5, 0)
    
        table.insert(ItemVFX, function()
            print('Emitting the glitter')
            Effects:Emit(Glitter, true)
            Effects:Toggle(Glitter, false)
            Effects:CleanUp(Glitter, 5)
        end);
    end

    Prompt:SetAttribute('InteractionId', Data.Id);

    Controller.Cache[Data.Id] = {
        Id = Data.Id,
        Prompt = Prompt,
        Type = Data.Type,
        Collider = Data.Collider,
        Effects = ItemVFX,
    }
end

function Controller:RemoveInteraction(id: NetObj | number)
    if typeof(id) ~= 'number' and typeof(id) ~= 'table' then
        Debugger:WarnLine(
            "MatchInteractionsController::RemoveInteraction", 
            `Cannot remove interaction, id is wrong type. {id}`, 
            5
        )
        
        return;
    end

    local ObjId = typeof(id) == 'number' and id or DecodeObject(id).Id;
    local Item = Controller.Cache[ObjId]
    if Item then
        Item.Prompt:Destroy();
        Controller.Cache[ObjId] = nil;
    end
end

function Controller:Trigger(Id: number, Bypass: boolean, TriggerData: {}?)
    if typeof(Id) ~= 'number' then
        warn('Cannot trigger object by passing non-number id.');
        
        return;
    end
    
    const Object = Controller.Cache[Id];
    if Object == nil or (Controller.__trigger_lock) then
        return
    end

    TriggerData = TriggerData or {};

    Controller.__trigger_lock = true

    const ReplicationIdTrigger =  TriggerData.ReplicationId or Players.LocalPlayer:GetAttribute('ReplicationId');

    if Object.Type == "ItemPickup" then
        Network:Fire(EVENT_NAME, GameEnum.MatchInteraction.Triggered, Object.Id);

        ItemPickupAction(Object, ReplicationIdTrigger)
    end
    
    Controller:RemoveInteraction(Object.Id);
    Controller.__trigger_lock = false
end

return Controller