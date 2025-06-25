-- UI = {}
local table = table
local screen = UI.ScreenSize()
local center = {x=screen.width/2, y = screen.height/2}

---핸를러 등록 클래스
---@class frameEvent
local frameEvent = {}
frameEvent.__index = frameEvent

frameEvent.callType = {
	MOVE = 1,
	FADEOUT = 2,
}

---@param logic function
---@param duration number 
function frameEvent:new(logic, duration, caller, ...)
	---@class frameEvent
    local o = setmetatable({}, self)
    o.logic = logic
    o.duration = duration
	o.args = {...}
	if caller == self.callType.MOVE then
		o.initPosition = o.args[2]
	end

    return o
end

function frameEvent:run()
	if self.duration == 0 then 
		return -1
	end
	self.duration = self.duration - 1
	self:logic()
	return 1
end

local eventHandler = {
	events = {}
}


---@param frameEvent frameEvent
function eventHandler:addEvent(frameEvent)
	if frameEvent == nil then error("No frameEvent format") end
	eventHandler.events[frameEvent] = frameEvent
end

---@param frameEvent frameEvent 
function eventHandler:removeEvent(frameEvent)
	eventHandler.events[frameEvent] = nil
end


---------------


local MAX_OBJECT = 1024

local ObjectPool = {}
ObjectPool.__index = ObjectPool

--- 객체 매니저 생성
---@param factory function
function ObjectPool:new(factory)
    local o = {
        pool = {},
        used = {},
        factory = factory
    }

    for i = 1, MAX_OBJECT do
        local obj = factory()
        o.pool[i] = obj
        o.used[obj] = false
    end

    setmetatable(o, self)
    return o
end

function ObjectPool:acquire()
    for _, obj in ipairs(self.pool) do
        if not self.used[obj] then
            self.used[obj] = true
            return obj
        end
    end
    return nil
end

function ObjectPool:release(obj)
    if obj and self.used[obj] then
        self.used[obj] = false
    end
end

------------------------

Container = {}
Container.__index = Container

function Container:new()
	local c = {
		children = {},
		x = 0, y = 0,
		scale = 1,
		rotation = 0,
	}
	setmetatable(c,self)
	return c
end

function Container:addChild(child)
	table.insert(self.children, child)
end

function Container:setPosition(x,y)
	local differ = {x = x-self.x, y = y-self.y}
	self.x = x
	self.y = y

	for _,child in ipairs(self.children) do
		local args = child:Get()
		local newX = args.x + differ.x
		local newY = args.y + differ.y
		child:Set({x = newX, y = newY})
	end
end

---@param to table 
---@param duration number
---@param animation function
function Container:Move(to, duration, animation)
	---Move 메서드 발생 시 [목적지 - 현위치]
    local differ = {x = to.x - self.x, y = to.y - self.y}
	print(self.x..", "..self.y)

	---반복진행될 함수
    --- @param instance frameEvent
    local function moveLogic(instance)
        local originalDuration = duration
        local Container = self
		-- Move 메서드 발생 시 [목적지 - 현위치]
        local differ = instance.args[1]
        local progress = (originalDuration - instance.duration) / originalDuration

        -- 애니메이션 적용
        local easingValue = progress
        if animation then
            easingValue = animation(progress)
        end
		-- delta값. 절대좌표가 아님.
        local step = {
            x = math.floor(differ.x * easingValue),
            y = math.floor(differ.y * easingValue)
        }
	
        Container:setPosition(instance.initPosition.x + step.x, instance.initPosition.y +step.y)
    end

    local o = frameEvent:new(
		moveLogic, duration, frameEvent.callType.MOVE,
		differ, {x=self.x, y=self.y}
	)
    eventHandler:addEvent(o)
end

---페이드아웃 함수
---@param duration number
function Container:Fadeout(duration)
	---인자 frameEvent
	local function fadeOutLogic (instance)
		---호출자
		local Container = self
		for _,child in ipairs(Container.children) do
			local arg = child:Get().a
			local a = arg - (arg / duration)
			if a < 0 then
				a = 0
			end
			print(a)
			child:Set({a = arg - (arg / duration)})
		end
	end
	local o = frameEvent:new(fadeOutLogic,100,frameEvent.callType.FADEOUT)
	eventHandler:addEvent(o)
end



---------API------------

--라운드가 시작할 때 호출되는 이벤트 콜백입니다.
function UI.Event:OnRoundStart()
end

--플레이어가 스폰 될 때 호출되는 이벤트 콜백입니다.
function UI.Event:OnSpawn()
end

--플레이어가 사망 할 때 호출되는 이벤트 콜백입니다.
function UI.Event:OnKilled()
end

--플레이어가 키를 누르고 있으면 지속적으로 호출되는 이벤트 콜백입니다.
function UI.Event:OnInput(inputs)
end

--플레이어가 채팅을 입력하면 호출되는 이벤트 콜백입니다.
function UI.Event:OnChat(text)
end

--서버로부터 signal을 받았을 때 호출되는 이벤트 콜백입니다.
function UI.Event:OnSignal(chat)
end

--플레이어가 키를 누를때 호출되는 이벤트 콜백입니다.
function UI.Event:OnKeyDown(inputs)
end

--플레이어가 키를 떼면 호출되는 이벤트 콜백입니다.
function UI.Event:OnKeyUp(inputs)
	if inputs[UI.KEY.E] then
		abc:ApplyAnimation(GUI.Group.TYPE.GODOWN,Bounce)
	elseif inputs[UI.KEY.R] then
	end
end

--프레임마다 호출되는 이벤트 콜백입니다
function UI.Event:OnUpdate(time)
	--이벤트 핸들러.
	for _, frameEvent in pairs(eventHandler.events) do
		if type(frameEvent.run) == 'function'then
			local res = frameEvent:run()
			--핸들러 함수의 반환값이 0이되면 자동 종료
			if res == -1 then
				eventHandler:removeEvent(frameEvent)
			end
			xpcall(function ()
			end,function ()
				print('error on eHandler')
			end)
		end
	end
	-- print(collectgarbage("count")..'kb Used')
	-- collectgarbage('collect')
end
---------------
---런타임---

local function createBox()
	return UI.Box.Create()
end

local function createText()
	return UI.Text.Create()
end

local BOX = ObjectPool:new(createBox)
local TEXT = ObjectPool:new(createText)

Obj, Index = BOX:acquire()
if Obj then
	Obj:Set({x=0,y=0,width = 100,height= 100, r= 255,g=255,b=255,a=255})
end

MyContainer = Container:new()
MyContainer:addChild(Obj)
MyContainer:setPosition(center.x*0.25,center.y)

print("-----------")
MyContainer:Fadeout(200)
MyContainer:Move({x=center.x,y=center.y},50)
