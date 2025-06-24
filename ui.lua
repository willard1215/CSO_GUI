local table = table
local screen = UI.ScreenSize()
local center = {x=screen.width/2, y = screen.height/2}


local table = table
local eventHandler = {}
eventHandler.events = {}

function eventHandler:addEvent(handler)
	if type(handler) ~= 'function' then error('Not a function!') end
	table.insert(eventHandler.events,handler)
end

function eventHandler:removeEvent(handler)
	if type(handler) ~= 'function' then error('Not a function!') end
	table.remove(eventHandler.events,table.indexof(eventHandler.events,handler))
end


---------------


local MAX_OBJECT = 1024

local ObjectPool = {}
ObjectPool.__index = ObjectPool

--- 객체 매니저 생성
---@param objectFactory function
function ObjectPool:new(objectFactory)
	local pool = {
		pool = {},
		used = {},
		objectFactory = objectFactory
	}

	for i = 1, MAX_OBJECT do
		pool.pool[i] = objectFactory()
	end

	setmetatable(pool,self)
	return pool
end

function ObjectPool:acquire()
	for i, obj in ipairs(self.pool) do
		if not self.used[i] then
			self.used[i] = true
			return obj, i
		end
	end
	
	return nil
end

function ObjectPool:release(index)
	if self.used[index] then
		self.used[index] = false
	end
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

test = {}
--프레임마다 호출되는 이벤트 콜백입니다
function UI.Event:OnUpdate(time)
	--이벤트 핸들러.
	for _, handler in ipairs(eventHandler.events) do
		if type(handler) == 'function'then
			local res = handler()
			--핸들러 함수의 반환값이 0이되면 자동 종료
			if res == 0 then
				eventHandler:removeEvent(handler)
			end
			xpcall(function ()
			end,function ()
				print('error on eHandler')
			end)
		end
	end
	-- print(string.format('%d개의 객체 사용중',GUI.CheckUsage()))
	-- print(collectgarbage("count")..'kb Used')
	collectgarbage('collect')
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

---------------
---런타임---

local function createBox()
	return UI.Box.Create()
end

local BOX = ObjectPool:new(createBox)

obj, index = BOX:acquire()
if obj then
	obj:Set({x=0,y=0,width = 100,height= 100, r= 255,g=255,b=255,a=255})
end