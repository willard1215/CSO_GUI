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
    boxBuffsers = {}
}

for i = 1, 1024 do
    table.insert(GUI.boxBuffsers, UI.Box.Create())
    table.insert(GUI.textBuffers, UI.Text.Create())
end

--ui객체 생성
function GUI._CreateObject(self, args, uiType)
    if not args or not uiType then return 0 end
    
    if type == GUI.TYPE.BOX then
        local box = table.remove(GUI.boxBuffsers)
        if not box then error('_CreateObject: Exceeded max box entity') end
        local wrapper = {csObject = box}
        setmetatable(wrapper, {__index = GUI})
        box:Set(args)
        wrapper.type = GUI.TYPE.BOX
        table.insert(GUI.boxObjects,wrapper)
        return wrapper
    elseif type == GUI.TYPE.TEXT then
        local text = table.remove(GUI.boxBuffsers)
        if not text then error('_CreateObject: Exceeded max text entity') end
        local wrapper = {csObject = box}
        setmetatable(wrapper, {__index = GUI})
        text:Set(args)
        wrapper.type = GUI.TYPE.TEXT
        table.insert(GUI.boxObjects,wrapper)
        wrapper.csObject:Show()
        return wrapper
    else
        error('_CreateObject: invalid uiType')
    end
end

function GUI._RemoveObject(self)
    if not self.csObject then error('_RemoveObject: Not a GUI object') end
    local index = table.indexof(GUI.boxObjects, self)
    local obj = self.csObject
    setmetatable(obj,nil)
    table.remove(GUI.boxObjects, index)
    table.insert(GUI.boxBuffsers, obj)
end