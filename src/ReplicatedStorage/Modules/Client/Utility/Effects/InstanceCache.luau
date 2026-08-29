---


---
local InstanceCache = {}
local DeleteThreads = {};
local PoolCache = {} :: { [string]: {
    Ready: number,
    Base: Instance,
    Alive: number,
    Items: { Instance },
    Ids: { string },
    Parent: Instance,
} }

function InstanceCache:CreatePoolFor(PoolId: string, Object: Instance, Minimum: number, IncludeReferenceAsFirstElement: boolean?): boolean
    assert(typeof(Object) == 'Instance', "Must provide an instance to cache and create")
    assert(typeof(Minimum) == 'number' and Minimum >= 1, "Must provide a valid minimum amount of instances created.")

    if PoolCache[PoolId] then
        warn(`Pool {PoolId} already exists`)

        return false
    end

    local WorkspaceEffects = workspace.World.Effects
    local Parent = WorkspaceEffects:FindFirstChild(PoolId) or Instance.new("Folder")
    Parent.Name = PoolId;
    Parent.Parent = WorkspaceEffects

    local PoolObjectData = {
        Ready = Minimum,
        Base = Object,
        Alive = 0, 
        Items = {},
        Ids = {},
        Parent = Parent,
    }

    for i = 1, Minimum do
        local Clone = if (IncludeReferenceAsFirstElement and i == 1) then Object else Object:Clone();
        Clone.Parent = Parent;
        if not (i == 1 and IncludeReferenceAsFirstElement) then
            Clone:PivotTo(CFrame.new(0, 2500, 0))
        end

        PoolObjectData.Alive += 1;
        table.insert(PoolObjectData.Ids, Clone)
        table.insert(PoolObjectData.Items, Clone);
    end

    PoolCache[PoolId] = PoolObjectData;

    return true
end

function InstanceCache:DoesPoolExist(PoolId: string): boolean?
    return PoolCache[PoolId] ~= nil;
end

function InstanceCache:RetrieveFromPool(PoolId: string, ForceNoNewInstances: boolean?): Instance?
    if not PoolCache[PoolId] then
        warn("Pool does not exist");
        return;
    end

    local Pool = PoolCache[PoolId]
    if Pool.Alive <= 0 then
        if ForceNoNewInstances then
            return;
        end

        local Borrowed = Pool.Base:Clone();
        Borrowed.Parent = Pool.Parent;
        Borrowed:SetAttribute('PoolBorrowed', true)

        Pool.Ready += 1;

        table.insert(Pool.Ids, Borrowed)

        return Borrowed;
    end

    local FirstElement = table.remove(Pool.Items, 1)

    if typeof(DeleteThreads[FirstElement]) == 'thread' and (DeleteThreads[FirstElement] ~= coroutine.running()) then
        task.cancel(DeleteThreads[FirstElement])
    end

    Pool.Alive -= 1;

    return FirstElement;
end

function InstanceCache:StoreInPool(PoolId: string, Object: Instance)
    if not PoolCache[PoolId] then
        return;
    end
   
    local Pool = PoolCache[PoolId];
    if not table.find(Pool.Ids, Object) then
        warn('Tried to store an object whose id is not recognized by the pool')

        return
    end

    Pool.Alive += 1;

    Object:PivotTo(CFrame.new(0, 2500, 0))
    table.insert(Pool.Items, Object);

    ---
    if Object:GetAttribute('PoolBorrowed') ~= true then
        return;
    end

    DeleteThreads[Object] = task.delay(30, function()
        Pool.Ready -= 1;
        Pool.Alive -= 1;

        local IdIndex = table.find(Pool.Ids, Object)
        if IdIndex then
            table.remove(Pool.Ids, IdIndex)
        end
        
        local ObjectIndex = table.find(Pool.Items, Object)
        if ObjectIndex then
            table.remove(Pool.Items, ObjectIndex)
        end
    end)
end

return InstanceCache

