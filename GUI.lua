local table = table

function table.dump(v, ores)
	local res = ores or {}
	local t = type(v)
	if t == "function" then 
		table.insert(res, "<function>")
		return res
	elseif t ~= "table" then 
		table.insert(res, string.format("%q",v))
		return res
	end
	table.insert(res, "{")
	for tk,tv in pairs(v) do
		table.insert(res, "[")
		table.dump(tk, res)
		table.insert(res, "]=")
		table.dump(tv, res)
		table.insert(res, ",")
	end
	table.insert(res, "}")
	return res
end

function table.indexof(t,q)
	for idx,v in ipairs(t) do
		if v == q then return idx end
	end
	return 0
end

function table.compact(t)
    local newTable = {}
    for _, v in pairs(t) do
        if v ~= nil then
            table.insert(newTable, v)
        end
    end
    return newTable
end


local math = math

--이벤트 핸들러
local eventHandler = {
    events = {}
}

function eventHandler:addEvent(schedule)
    if not schedule or type(schedule) ~= "function" then error('EventHandler: Check Argument') end
    table.insert(eventHandler.events, schedule)
end

function eventHandler:removeEvent(schedule)
    if not schedule or type(schedule) ~= "function" then error('EventHandler: Check Argument') end
    table.remove(eventHandler.events, table.indexof(eventHandler.events,schedule))
end

GUI = {
    DEBUGMODE = false,
    TYPE = {
        BOX = 0,
        TEXT = 1,
        CONTAINER = 2
    },
    textObjects = {},
    textBuffers = {},
    boxObjects = {},
    boxBuffers = {},

    Element = {}
}

for i = 1, 1024 do
    table.insert(GUI.boxBuffers, UI.Box.Create())
    table.insert(GUI.textBuffers, UI.Text.Create())
end

function GUI.Element:new()
    local obj = { children = {} }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

--ui객체 생성
GUI.Box = GUI.Element:new()
function GUI.Box:Create(args)
    if not args then return 0 end

    local box = table.remove(GUI.boxBuffers)
    local obj = GUI.Element.new(self)

    obj.type = GUI.TYPE.BOX
    obj.csObject = box
	setmetatable(obj, { __index = GUI})
    if not box then error('_CreateObject: Exceeded max box entity') end
    box:Set(args)
    box:Show()
    table.insert(GUI.boxObjects,obj)
    return obj
end

GUI.Text = GUI.Element:new()
function GUI.Text:Create(args)
    if not args then return 0 end

    local text = table.remove(GUI.textBuffers)
    local obj = GUI.Element.New(self)

    obj.type = GUI.TYPE.TEXT
    obj.csObject = text
	setmetatable(obj, { __index = GUI})

    if not text then error('_CreateObject: Exceeded max text entity') end
    text:Set(args)
    text:Show()
    table.insert(GUI.textObjects,obj)
    return obj
end

function GUI:Set(args)
    if self.type == GUI.TYPE.CONTAINER then
        error('tried to apply args to Container')
    end
	self.csObject:Set(args)
end

function GUI:Get()
    if self.type == GUI.TYPE.CONTAINER then
        error('tried to get Conatiner\'s args')
    end
    self.csObject.Get()
end

function GUI:Hide()
    if self.type == GUI.TYPE.CONTAINER then
        for _,v in ipairs(self.children) do
            v:Hide()
        end
    else
	    self.csObject:Hide()
    end
end

function GUI:Show()
    if self.type == GUI.TYPE.CONTAINER then
        for _,v in ipairs(self.children) do
            v:Show()
        end
    else
        self.csObject:Show()
    end
end

function GUI:Refresh()
    if self.type == GUI.TYPE.CONTAINER then
        for _,v in ipairs(self.children) do
            local arg = v:Get()
            v:Hide()
            v:Set(arg)
            v:Show()
        end
    else
        local arg = self.csObject:Get()
        self.csObject:Hide()
        self.csObject:Set(arg)
        self.csObject:Show()
    end
end

function GUI.Remove(self)
    if not self.csObject then error('Remove: Not a GUI object') end
    local index = table.indexof(GUI.boxObjects, self)
    local obj = self.csObject
    setmetatable(obj,nil)
    table.remove(GUI.boxObjects, index)
    table.insert(GUI.boxBuffers, obj)
end

GUI.Container = GUI.Element:new()
function GUI.Container:new()
    local obj = GUI.Element.new(self)
    obj.type = GUI.TYPE.CONTAINER
    return obj
end

function GUI.Container:AddChild(child)
    table.insert(self.children, child)
end

--Container 객체의 child를 대상으로 최적화 진행.
function GUI.Container:Optimize()
    local _args = {}
    for _,v in ipairs(self.children) do
        table.insert(_args,v:Get())
    end
    table.sort(_args, function(a, b)
        if a.y == b.y then return a.x < b.x end
        return a.y < b.y
    end)
    
    local merged = {}
    local function canMergeVertical(a,b)
        return  a.x ==b.x and a.width == b.width and
                a.y <= b.y and (a.y + a.height) >= b.y and
                a.r == b.r and a.g == b.g and
                a.b == b.b and a.a == b.addEvent
    end
    
    local i = 1
    while i<= #_args do
        local box = _args[i]
        local j = i + 1
        while j <= #_args do
            if canMergeVertical(box,_args[j]) then
                local newY = math.max(box.y + box.height, _args[j].y + _args[j].height)
                box.height = newY - box.y
                table.remove(_args, j)
            else
            j = j+1
            end
        end
        table.insert(merged,box)
        i = i + 1
    end

    local _optimizedArgs = {}
    local function canMergeHorizontal(a,b)
        return  a.y == b.y and a.height == b.height and
                a.x <= b.x and (a.x + a.width) >= b.x and
                a.r == b.r and a.g == b.g and
                a.b == b.b and a.a == b.a
    end

    i = 1
    while i <= #merged do
        local box = merged[i]
        local j = i + 1
        while j <= #merged do
            if canMergeHorizontal(box, merged[j]) then
                local newX = math.max(box.x + box.width, merged[j].x + merged[j].width)
                box.width = newX - box.x
                table.remove(merged, j)
            else
                j = j + 1
            end
        end
        table.insert(_optimizedArgs, box)
        i = i + 1
    end
    
    for k,v in ipairs(self.children) do
        if v.type == GUI.TYPE.BOX then
            v:Remove()
            table.remove(self.children, k)
        end
    end
    for _,v in ipairs(_optimizedArgs) do
        self:AddChild(GUI.Box:Create(v))
    end
end

a = GUI.Box:Create({x=100,y=100,width=100,height=100,r=255,g=255,b=255,a=255})
a:Set({x=100,y=100,width=100,height=100,r=255,g=0,b=255,a=255})