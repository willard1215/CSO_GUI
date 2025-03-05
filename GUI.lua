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
        TEXT = 1
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
    local obj = GUI.Element.New(self)

    obj.type = GUI.TYPE.BOX
    obj.csObject = box

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

    if not text then error('_CreateObject: Exceeded max text entity') end
    text:Set(args)
    text:Show()
    table.insert(GUI.textObjects,obj)
    return obj
end

function GUI.Box:Set()
end
function GUI.Text:Set()

function GUI._RemoveObject(self)
    if not self.csObject then error('_RemoveObject: Not a GUI object') end
    local index = table.indexof(GUI.boxObjects, self)
    local obj = self.csObject
    setmetatable(obj,nil)
    table.remove(GUI.boxObjects, index)
    table.insert(GUI.boxBuffers, obj)
end

GUI.Container = GUI.Element:new()
function GUI.Container:new()
    local obj = GUI.Element.new(self)
    return obj
end

function GUI.Container:AddChild(child)
    table.insert(self.children, child)
end

