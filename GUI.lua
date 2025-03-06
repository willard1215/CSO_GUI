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

function GUI.CheckUsage()
    return #GUI.boxBuffers, #GUI.textBuffers
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
    return self.csObject:Get()
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
    obj:Hide()
    setmetatable(self,nil)
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
function GUI.Optimize(_args)
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
    return _optimizedArgs
end

function GUI.Container:Rotate(amount, center)
    -- 최초 호출 시 원본 children 데이터를 저장
    if not self._originalChildren then
        self._originalChildren = {}
        for i, child in ipairs(self.children) do
            if child.type == GUI.TYPE.BOX then
                local data = child:Get()
                self._originalChildren[i] = {
                    x = data.x,
                    y = data.y,
                    width = data.width,
                    height = data.height,
                    r = data.r,
                    g = data.g,
                    b = data.b,
                    a = data.a
                }
            end
        end
    end

    -- 원본 데이터를 기반으로 외곽 바운딩 박스 계산
    local union = {xmin = math.huge, ymin = math.huge, xmax = -math.huge, ymax = -math.huge}
    local firstBoxData = nil
    for _, data in ipairs(self._originalChildren) do
        if not firstBoxData then firstBoxData = data end
        union.xmin = math.min(union.xmin, data.x)
        union.ymin = math.min(union.ymin, data.y)
        union.xmax = math.max(union.xmax, data.x + data.width)
        union.ymax = math.max(union.ymax, data.y + data.height)
    end
    if union.xmin == math.huge then return end  -- 처리할 BOX가 없으면 종료

    -- 회전 중심 결정 (center가 주어지면 offset 적용, 없으면 좌측 상단 사용)
    if not center then
        center = {x = union.xmin, y = union.ymin}
    else
        center = {x = center.x + union.xmin, y = center.y + union.ymin}
    end

    local rad = math.rad(amount)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)

    -- 바운딩 박스의 네 모서리 좌표
    local corners = {
        {x = union.xmin, y = union.ymin},
        {x = union.xmax, y = union.ymin},
        {x = union.xmin, y = union.ymax},
        {x = union.xmax, y = union.ymax}
    }

    -- 모서리들을 회전 (회전 후 다각형)
    local rotatedCorners = {}
    for _, corner in ipairs(corners) do
        local dx = corner.x - center.x
        local dy = corner.y - center.y
        local rx = cosA * dx - sinA * dy + center.x
        local ry = sinA * dx + cosA * dy + center.y
        table.insert(rotatedCorners, {x = rx, y = ry})
    end

    -- 회전된 다각형의 올바른 순서 정렬 (중심 기준)
    local polyCenter = {x = 0, y = 0}
    for _, pt in ipairs(rotatedCorners) do
        polyCenter.x = polyCenter.x + pt.x
        polyCenter.y = polyCenter.y + pt.y
    end
    polyCenter.x = polyCenter.x / #rotatedCorners
    polyCenter.y = polyCenter.y / #rotatedCorners
    table.sort(rotatedCorners, function(a, b)
        return math.atan(a.y - polyCenter.y, a.x - polyCenter.x) < math.atan(b.y - polyCenter.y, b.x - polyCenter.x)
    end)
    
    -- 회전된 다각형의 bounding box 계산 (행 스캔 범위 결정)
    local polyXmin, polyYmin = math.huge, math.huge
    local polyXmax, polyYmax = -math.huge, -math.huge
    for _, pt in ipairs(rotatedCorners) do
        polyXmin = math.min(polyXmin, pt.x)
        polyYmin = math.min(polyYmin, pt.y)
        polyXmax = math.max(polyXmax, pt.x)
        polyYmax = math.max(polyYmax, pt.y)
    end

    -- 다각형 내부를 채우기 위해, 각 정수 행에 대해 내부 x 구간 계산
    local rows = {}
    local yStart = math.floor(polyYmin)
    local yEnd = math.ceil(polyYmax)
    
    local function edgeIntersection(p1, p2, y)
        if (p1.y - y) * (p2.y - y) > 0 then return nil end
        if p1.y == p2.y then return nil end
        local t = (y - p1.y) / (p2.y - p1.y)
        return p1.x + t * (p2.x - p1.x)
    end

    for y = yStart, yEnd - 1 do
        local scanY = y + 0.5
        local intersections = {}
        for i = 1, #rotatedCorners do
            local p1 = rotatedCorners[i]
            local p2 = rotatedCorners[(i % #rotatedCorners) + 1]
            local ix = edgeIntersection(p1, p2, scanY)
            if ix then table.insert(intersections, ix) end
        end
        if #intersections >= 2 then
            table.sort(intersections)
            local x_left = intersections[1]
            local x_right = intersections[#intersections]
            local colStart = math.ceil(x_left)
            local colEnd = math.floor(x_right)
            if colStart <= colEnd then
                rows[y] = {x_start = colStart, x_end = colEnd}
            end
        end
    end

    -- 연속된 행들 중 x 구간이 동일한 행들을 하나의 박스로 병합
    local boxes = {}
    local current_box = nil
    for y = yStart, yEnd - 1 do
        local seg = rows[y]
        if seg then
            local seg_width = seg.x_end - seg.x_start + 1
            if current_box and current_box.x == seg.x_start and current_box.width == seg_width then
                current_box.height = current_box.height + 1
            else
                if current_box then table.insert(boxes, current_box) end
                current_box = {x = seg.x_start, y = y, width = seg_width, height = 1}
            end
        else
            if current_box then
                table.insert(boxes, current_box)
                current_box = nil
            end
        end
    end
    if current_box then table.insert(boxes, current_box) end

    -- 각 박스에 색상 정보 추가 (첫번째 BOX의 색상을 사용)
    for _, box in ipairs(boxes) do
        if firstBoxData then
            box.r = firstBoxData.r
            box.g = firstBoxData.g
            box.b = firstBoxData.b
            box.a = firstBoxData.a
        else
            box.r, box.g, box.b, box.a = 255, 255, 255, 255
        end
    end

    -- 기존 children을 제거 (직접 self.children에서 삭제)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        child:Remove()
        table.remove(self.children, i)
    end

    -- 최적화된 박스들을 새로 추가
    for _, box in ipairs(boxes) do
        self:AddChild(GUI.Box:Create(box))
    end
end

screen = UI.ScreenSize()
center = {x=screen.width/2, y = screen.height/2}



child_a = GUI.Box:Create({x=center.x,y=center.y,width=200,height=100,r=255,g=255,b=255,a=255})
child_b = GUI.Box:Create({x=center.x,y=center.y,width=10,height=10,r=255,g=255,b=255,a=255})
container_a = GUI.Container:new()
print(GUI.CheckUsage())
container_a:AddChild(child_a)
container_a:AddChild(child_b)
print(GUI.CheckUsage())
container_a:Rotate(50,{x=0,y=0})
i=1
function UI.Event:OnUpdate(time)
    container_a:Rotate(i,{x=0,y=0})
    i = i+1
end