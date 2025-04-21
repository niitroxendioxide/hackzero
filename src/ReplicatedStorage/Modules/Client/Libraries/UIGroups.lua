--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local InterfaceStates = {
    __Groups = {}
}

function InterfaceStates:Bind(Group: string)
    if not InterfaceStates.__Groups[Group] then
        InterfaceStates.__Groups[Group] = {
            Active = nil,
            Items = {},
        }
    end

    return InterfaceStates.__Groups[Group]
end

function InterfaceStates:Add(Group: string, Item: Types.UIComponent): ()
    if not InterfaceStates.__Groups[Group] then
        InterfaceStates:Bind(Group)
    end

    InterfaceStates.__Groups[Group].Items[Item.__Name] = Item
end

function InterfaceStates:GetActiveElement(Group: string)
    if not InterfaceStates.__Groups[Group] then
        return
    end

    return InterfaceStates:GetElementClass(Group, InterfaceStates.__Groups[Group].Active)
end

function InterfaceStates:GetActiveElementName(Group: string): (string?)
    if not InterfaceStates.__Groups[Group] then
        return nil
    end
    return InterfaceStates.__Groups[Group].Active
end

function InterfaceStates:SetActiveElement(Group: string, Item: string?)
    if not InterfaceStates.__Groups[Group] then return end

    if InterfaceStates.__Groups[Group].Active == Item then return end

    if InterfaceStates:GetActiveElement(Group) then
        local Element = InterfaceStates:GetActiveElement(Group)
        InterfaceStates.__Groups[Group].Active = nil
        Element:Set(false)
    end

    InterfaceStates.__Groups[Group].Active = Item
end

export type Element = Types.UIComponent & {[string]: () -> ()}
function InterfaceStates:GetElementClass(Group: string, Name: string): (Element)
    if not InterfaceStates.__Groups[Group] then return {} :: Element end

    return InterfaceStates.__Groups[Group].Items[Name]
end

function InterfaceStates:IsActive(Group: string, ElementName: string)
    return InterfaceStates.__Groups[Group].Active == ElementName
end

return InterfaceStates