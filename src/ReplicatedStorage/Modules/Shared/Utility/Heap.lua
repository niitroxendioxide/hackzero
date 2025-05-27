local HeapClassObj = {}
HeapClassObj.__index = HeapClassObj;

export type Heap = typeof(setmetatable({}, HeapClassObj))

function HeapClassObj.new(intItemCount: number): Heap
    local self = setmetatable({}, HeapClassObj)
    self.__items = {}

    for k = 1, intItemCount do
        table.insert(self.__items, k)
    end

    return self
end

function HeapClassObj:siftUp(index)
    local current = index

    while current > 1 do
        local parent = math.floor(current / 2)

        if self.__items[current] < self.__items[parent] then
            self.__items[current], self.__items[parent] = self.__items[parent], self.__items[current]
            current = parent
        else
            break
        end
    end
end

function HeapClassObj:siftDown(index)
    local current = index
    local size = self:size()

    while true do
        local leftIndex = 2 * current
        local rightIndex = 2 * current + 1
        local target = current

        if leftIndex <= size and (self.__items[leftIndex] < self.__items[target]) then
            target = leftIndex
        end

        if rightIndex <= size and (self.__items[rightIndex] < self.__items[target]) then
            target = rightIndex
        end

        if target ~= current then
            self.__items[current], self.__items[target] = self.__items[target], self.__items[current]
            current = target
        else
            break
        end
    end
end

function HeapClassObj:insert(obj: number)
    table.insert(self.__items, obj)
end

function HeapClassObj:extract()
    if self:isEmpty() then
        return;
    end

    local value = self.__items[1];
    self.__items[1] = self.__items[#self.__items]

    table.remove(self.__items)

    if not self:isEmpty() then
        self:siftDown(1)
    end

    return value;
end

function HeapClassObj:peek()
    return self.__items[1]
end

function HeapClassObj:size()
    return #self.__items
end

function HeapClassObj:isEmpty()
    return #self.__items == 0;
end

return HeapClassObj
