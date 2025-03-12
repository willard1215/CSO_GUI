local vector = {}
vector.__index = vector
function vector.Create(x,y)
    local o = {}
    if not x or not y then return end
    o.x, o.y = x,y
    return o
end

local table = table
local screen = UI.ScreenSize()
local center = {x=screen.width/2, y = screen.height/2}

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
    TYPE = {
        BOX = 0,
        TEXT = 1,
        CONTAINER = 2
    },
    activeTexts = {},
    textBuffers = {},
    activeBoxes = {},
    boxBuffers = {},

    Element = {}
}

for i = 1, 1024 do
    table.insert(GUI.boxBuffers, UI.Box.Create())
    table.insert(GUI.textBuffers, UI.Text.Create())
end

function GUI.CheckUsage()
    local availableBox = #GUI.boxBuffers
    local availableText = #GUI.textBuffers
    local activeBox = 1024-availableBox
    local activeText = 1024-availableText
    print(string.format("box: %d / text: %d / Max: 1024", activeBox, activeText))

    return activeBox, activeText
end

function GUI.Element:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

--ui객체 생성
GUI.Box = GUI.Element:new()
function GUI.Box:Create(args)
    if not args then return 0 end

    local box = table.remove(GUI.boxBuffers)
    if not box then error('_CreateObject: Exceeded max box entity') end

    local obj = GUI.Element.new(self)
    obj.type = GUI.TYPE.BOX
    obj.csObject = box
	setmetatable(obj, { __index = GUI})

    box:Set(args)
    box:Show()

    GUI.activeBoxes[obj] = true
    return obj
end

GUI.Text = GUI.Element:new()
function GUI.Text:Create(args)
    if not args then return 0 end

    local text = table.remove(GUI.textBuffers)
    if not text then error('_CreateObject: Exceeded max text entity') end

    local obj = GUI.Element.New(self)

    obj.type = GUI.TYPE.TEXT
    obj.csObject = text
	setmetatable(obj, { __index = GUI})

    text:Set(args)
    text:Show()

    GUI.activeTexts[obj] = true
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
    
    if self.type == GUI.TYPE.BOX then
        if GUI.activeBoxes[self] then
            GUI.activeBoxes[self] = nil
            self.csObject:Hide()
            table.insert(GUI.boxBuffers, self.csObject)
            setmetatable(self, nil)
        end
    elseif self.type == GUI.TYPE.TEXT then
        if GUI.activeTexts[self] then
            GUI.activeTexts[self] = nil
            self.csObject:Hide()
            table.insert(GUI.textBuffers, self.csObject)
            setmetatable(self, nil)
        end
    end
end

GUI.Container = GUI.Element:new()

function GUI.Container:Create(args)
    local container = GUI.Element.new(self)
    container.type = GUI.TYPE.CONTAINER
    container.children = {}
    if args then
        container.x = args.x or 0
        container.y = args.y or 0
        container.width = args.width or 0
        container.height = args.height or 0
        container.rotation = args.rotation or 0
        container.alpha = args.alpha or 255
        container.zIndex = args.zIndex or 0
    else
        container.x = 0
        container.y = 0
        container.width = 0
        container.height = 0
        container.rotation = 0
        container.alpha = 255
        container.zIndex = 0
    end
    return container
end

function GUI.Container:AddChild(child,zIndex)
    if child then
        child.zIndex = zIndex or child.zIndex or 0
        table.insert(self.children, child)
        child.parent = self
        -- self:UpdateChildTransform(child)
        self:Reorder()
    end
end

function GUI.Container:RemoveChild(child)
    for i, v in ipairs(self.children) do
        if v == child then
            table.remove(self.children, i)
            child.parent = nil
            break
        end
    end
end

function GUI.Container:Set(args)
    if args.x then self.x = args.x end
    if args.y then self.y = args.y end
    if args.rotation then self.rotation = args.rotation end
    if args.alpha then self.alpha = args.alpha end
    if args.zIndex then self.zIndex = args.zIndex end

    -- 자식 객체들의 위치와 효과 업데이트 (예: 회전, 레이어 정렬)
    -- for _, child in ipairs(self.children) do
    --     self:UpdateChildTransform(child)
    -- end
end

function GUI.Container:UpdateChildTransform(child)
    -- 예시: 컨테이너의 회전 적용
    -- 자식은 컨테이너 내 상대 좌표(child.relativeX, child.relativeY)를 갖는다고 가정
    if child.relativeX and child.relativeY then
        local rad = math.rad(self.rotation)
        local cosA = math.cos(rad)
        local sinA = math.sin(rad)
        local rotatedX = child.relativeX * cosA - child.relativeY * sinA
        local rotatedY = child.relativeX * sinA + child.relativeY * cosA
        -- 자식의 최종 좌표는 컨테이너의 좌표 + 회전 후 좌표
        -- child:Set({ x = self.x + rotatedX, y = self.y + rotatedY, alpha = self.alpha })
    else
        -- 자식 객체가 절대 좌표를 사용한다면 별도 처리
        -- child:Set({ x = self.x, y = self.y, alpha = self.alpha })
    end
end

-- 컨테이너 내 자식 객체들의 레이어 재정렬 (zIndex 기반)
function GUI.Container:Reorder()
    table.sort(self.children, function(a, b)
        return (a.zIndex or 0) < (b.zIndex or 0)
    end)
    for _, child in ipairs(self.children) do
        child:Refresh()  -- 각 자식 객체에 새 순서를 적용 (기본 UI 모듈의 특성에 맞게)
    end
end

-- 애니메이션 (범용 함수)
function GUI.Container:Animate(property, targetValue, duration, easingFunction)
    -- 애니메이션 로직: 예를 들어, Tweening 엔진과 연동하여 속성을 일정 시간 동안 변화
    -- 이 부분은 프레임 업데이트 루프나 타이머와 연계해서 구현해야 합니다.
end

-- 페이드아웃 효과 구현
function GUI.Container:FadeOut(duration)
    self:Animate("alpha", 0, duration, function(t) return t end)  -- 간단한 선형 이징 예제
end

-- 회전 애니메이션 구현
function GUI.Container:AnimateRotation(targetAngle, duration, easingFunction)
    self:Animate("rotation", targetAngle, duration, easingFunction)
end

-- 컨테이너의 표시/숨김 처리 (자식 모두에 적용)
function GUI.Container:Show()
    for _, child in ipairs(self.children) do
        child:Show()
    end
end

function GUI.Container:Hide()
    for _, child in ipairs(self.children) do
        child:Hide()
    end
end

-- 전체 갱신: 컨테이너 및 자식들의 최신 상태 반영
function GUI.Container:Refresh()
    self:Reorder()
    for _, child in ipairs(self.children) do
        child:Refresh()
    end
end

function GUI.Container:Rotate(angle, pivot)
    local vertex = {}
    local allArguments = {}

    local afterArgs = {}
    for k,v in ipairs(self.children) do
        local args = v:Get()
        local vertexes = {}
        table.insert(vertexes, vector.Create(args.x,args.y))
        table.insert(vertexes, vector.Create(args.x+args.width,args.y))
        table.insert(vertexes, vector.Create(args.x+args.width,args.y+args.height))
        table.insert(vertexes, vector.Create(args.x,args.y+args.height))
    end
end

function GUI.Container:Collision(obj1,obj2)
    
end


myContainer = GUI.Container:Create()
box1 = GUI.Box:Create({x=center.x+1,y=center.y,width= 39,height=50,r=255,g=255,b=0,a=255})
box2 = GUI.Box:Create({x=center.x+10,y=center.y,width= 30,height=60,r=255,g=255,b=0,a=255})
myContainer:AddChild(box1)
myContainer:AddChild(box2)
-- myContainer:Rotate(30,{x=center.x,y=center.y})
GUI:CheckUsage()