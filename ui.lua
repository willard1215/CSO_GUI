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

function table.extend(a,b)
	for k,v in pairs(b) do
		a[k] = v
	end
end

function table.append(a,b)
	local last = #a
	for i,v in ipairs(b) do
		a[i+last] = v
	end
	return a
end

function table.indexof(t,q)
	for idx,v in ipairs(t) do
		if v == q then return idx end
	end
	return 0
end

--GUI모듈
GUI = {}
GUI.DEBUGMODE = false
GUI.TYPE = {
	BOX = 0,
	TEXT = 1
}
GUI._texts = {}
GUI._boxes = {}
GUI.Diagram = {}
    
--사각형 UI 객체를 생성합니다.
--동시에 최대 1024개까지 생성할 수 있습니다.
function GUI:_CreateObject(args,type)
	if not args or not type then return 0 end
	local lastindex = 0
	
	--todo > box or text nil값 반환 시  객체 1024개 초과 알럿
	if type == GUI.TYPE.BOX then
		local box = UI.Box.Create()
		if box == nil then
			error('Over Max Entity')
		else
			for i,_ in ipairs(self._boxes) do
				lastindex = i
			end
		end
		local wrapper = {__box = box}
		setmetatable(wrapper, {__index = GUI})
		if args then
			box:Set(args)
		end
		box = nil
		
		wrapper.index = lastindex + 1
		wrapper.type = GUI.TYPE.BOX
		table.insert(GUI._boxes,wrapper)
		return wrapper

	elseif type == GUI.TYPE.TEXT then
		text = UI.Text.Create()
		if text == nil then
			error('Over Max Entity')
		end
		local wrapper = {__text = text  }
		setmetatable(wrapper, {__index = GUI})
		if args then
			text:Set(args)
		end
		text = nil

		wrapper.index = #GUI._texts + 1
		wrapper.type = GUI.TYPE.TEXT
		table.insert(GUI._texts,wrapper)
		return wrapper
	
	else
		error('invalid values')
	end
end

--input : UI구성요소, output : 최적화된 구성요소
function GUI.Optimize(args)

	table.sort(args, function(a, b)
		if a.y == b.y then return a.x < b.x end
		return a.y < b.y
	end)

	local merged = {}


	local function can_merge_v(box1, box2)
		return box1.x == box2.x and box1.width == box2.width and
			   box1.y <= box2.y and (box1.y + box1.height) >= box2.y and
			   box1.r == box2.r and box1.g == box2.g and
			   box1.b == box2.b and box1.a == box2.a
	end

	local i = 1
	while i <= #args do
		local box = args[i]
		local j = i + 1
		while j <= #args do
			if can_merge_v(box, args[j]) then
				local new_end_y = math.max(box.y + box.height, args[j].y + args[j].height)
				box.height = new_end_y - box.y
				table.remove(args, j)
			else
				j = j + 1
			end
		end
		table.insert(merged, box)
		i = i + 1
	end

	local final_boxes = {}

	local function can_merge_h(box1, box2)
		return box1.y == box2.y and box1.height == box2.height and
			   box1.x <= box2.x and (box1.x + box1.width) >= box2.x and
			   box1.r == box2.r and box1.g == box2.g and
			   box1.b == box2.b and box1.a == box2.a
	end

	i = 1
	while i <= #merged do
		local box = merged[i]
		local j = i + 1
		while j <= #merged do
			if can_merge_h(box, merged[j]) then
				local new_end_x = math.max(box.x + box.width, merged[j].x + merged[j].width)
				box.width = new_end_x - box.x
				table.remove(merged, j)
			else
				j = j + 1
			end
		end
		table.insert(final_boxes, box)
		i = i + 1
	end
	print(string.format('optimized: %d px',#final_boxes))
	-- error(table.concat(table.dump(final_boxes),""))
	return final_boxes
end

--객체 생성 현황을 반환합니다.
function GUI:GetResource()
	local countB = 0
	local countT = 0
	for k,v in ipairs(GUI._boxes) do
		if v:IsVisible() then
			countB = countB + 1
		end
	end
	for k,v in ipairs(GUI._texts) do
		if v:IsVisible() then
			countT = countT + 1
		end
	end
	return countB,countT
end

--객체의 인덱스번호를 가져옵니다.
function GUI:GetIndex()
	return self.index
end

--화면에 표시합니다.
function GUI:Show()
	if self.type == GUI.TYPE.BOX then
		self.__box:Show()
	elseif self.type == GUI.TYPE.TEXT then
		self.__text:Show()
	end
end

--화면에 표시되지 않도록 변경합니다.
function GUI:Hide()
	if self.type == GUI.TYPE.BOX then
		self.__box:Hide()
	elseif self.type == GUI.TYPE.TEXT then
		self.__text:Hide()
	end
	
end

--현재 화면에 표시중인지 여부를 가져옵니다.

function GUI:IsVisible()
	if self.type == GUI.TYPE.BOX then
		return self.__box:IsVisible()
	elseif self.type == GUI.TYPE.TEXT then
		return self.__text:IsVisible()
	end
end

--객체의 속성을 변경합니다.
function GUI:Set(args)
	if self.type == GUI.TYPE.BOX then
		return self.__box:Set(args)
	elseif self.type == GUI.TYPE.TEXT then
		return self.__text:Set(args)
	end
end

--객체의 속성이 담긴 테이블을 가져옵니다
function GUI:Get()
	if self.type == GUI.TYPE.BOX then
		return self.__box:Get()
	elseif self.type == GUI.TYPE.TEXT then
		return self.__text:Get()
	end

end

--객체 스스로를 지웁니다.
function GUI:Remove()
	if self.type == GUI.TYPE.BOX then
		self._boxes[self.index] = nil
		self.__box = nil
		self.type = nil
		self.index = nil
		self = nil
	elseif self.type == GUI.TYPE.TEXT then
		self._texts[self.index] = nil
		self.__text = nil
		self.type = nil
		self.index = nil
		self = nil
	end
end

--페이드 아웃 메서드
function GUI:FadeOut(duration)
	local a
	if self.__box or self.__text then
		a = self:Get().a
	else
		a = 0
	end
	eventHandler:addEvent(function()
		return self:decAlpha(a/duration)
	end)
end

--페이드 인 메서드
function GUI:FadeIn(duration)
	local a = -1
	if self.__box or self.__text then
		a = self:Get().a
	else
		a = 255
	end
	eventHandler:addEvent(function()
		return self:incAlpha((255-a)/duration)
	end)
end

--알파값 감소 메서드, 
function GUI:decAlpha(amount)
	local a
	if self.__box or self.__text then
		a = self:Get().a
	else
		return 0
	end
	if math.floor(a - amount) > 0 then
		a = math.floor(a-amount)
		self:Set({a=a})
	else
		self:Remove()
	end
	return a
end

--알파값 증가 메서드
function GUI:incAlpha(amount)
	local a
	if self.__box or self.__text then
		a = self:Get().a or 255
	else
		return 0
	end
	if math.ceil(a + amount) < 255 then
		a = math.ceil(a + amount)
		self:Set({a=a})
	else
		self:Remove()
	end
	return 255 - a
end

function GUI.CheckUsage()
	local count = 0
	local t = {}
	for i = 1,1024 do
		local obj = UI.Box.Create()
		if obj ~= nil then
			count = count + 1
			table.insert(t,obj)
		else -- 꽉찼을때
			for _,v in ipairs(t) do
				v:Hide()
				v = nil
			end
			return 1024-count
		end
	end
end


--------------사용자용 코드-------------

GUI.Group = {
	TYPE = {
		GODOWN = 1,
		GOUP = 2,
		INCREASE = 3,
		DECREASE = 4,
		ROTATE = 5
	}
}
--객체들을 묶어 하나의 그래픽그룹으로 작동하도록 만듭니다.
--offset은 그래픽그룹의 위치를 나타내는 테이블입니다. x,y로 구성됩니다.
---@param t table
---@param name string
---@param offset table
function GUI.Group:New(t,offset)
	if not offset then
		offset = {x=0,y=0}
	end

	local o = setmetatable({},self)
	self.__index = self

	o.data = {
		--처음 입력받은 args 정보를 담은 테이블
		original = t,
		--현재 사용중인 args 정보를 당믄테이블
		using = {},
		--현재 사용중인 픽셀 객체를 담은 테이블
		object = {},
		--애니메이션에서 사용하는 time축
		t = 0,
		--애니메이션이 작동중인지 여부
		isAnimationRun = false,
		--애니메이션 진행도
		integral = 0,
	}

    local optimized = GUI.Optimize(t)
    for _, arg in ipairs(optimized) do
		local arg = arg
		arg.x, arg.y = arg.x + offset.x, arg.y + offset.y
		table.insert(o.data.object,GUI:_CreateObject(arg,GUI.TYPE.BOX))
    end
	-- print(string.format('%d used on Group',#optimized))
	o.data.using = optimized

	return o
end



function GUI.Group.Delete(object)
	for _,v in pairs(object.data.object) do
		v:Remove()
	end
	object = nil
end

--그래픽그룹을 회전시킵니다. 이 작업은 많은 리소스를 소모합니다.
---@param group table
function GUI.Group.Rotate(group,amount,center)
	local o = group

	--픽셀화
	local range = {xmax = 0,xmin = 100000, ymax = 0, ymin = 100000}
	for _,v in ipairs(o.data.original) do
		-- range.xmax = math.max(range.xmax, v.x + v.width)
		-- range.ymax = math.max(range.ymax, v.y + v.height)
		range.xmin = math.min(range.xmin, v.x)
		range.ymin = math.min(range.ymin, v.y)
	end
	
	if not center then
		center = {x=range.xmin,y=range.ymin}
	else
		center = {x = center.x + range.xmin, y = center.y + range.ymin}
	end
	print(center.x)
	print(center.y)
	local pixels = {}
	for _, v in ipairs(o.data.original) do
		for i = 0, v.width - 1 do
			for j = 0, v.height - 1 do
				local px = v.x + i
				local py = v.y + j

				table.insert(pixels, {x = px, y= py, width = v.width, height = v.height, r = v.r, g = v.g, b = v.b, a = v.a})
			end
		end
	end

	local rad = math.rad(amount)
	local cosA, sinA = math.cos(rad), math.sin(rad)

	--회전된 이후의 픽셀데이터
	local rotated = {}

	--해시테이블
	local visited = {}

	for _,pixel in ipairs(pixels) do
		local x,y = pixel.x - center.x, pixel.y - center.y
		local newX = cosA * x - sinA * y + center.x
		local newY = sinA * x + cosA * y + center.y

		table.insert(rotated, {
			x = math.floor(newX),
			y = math.floor(newY),
			width = 1,
			height = 1,
			r = pixel.r,
			g = pixel.g,
			b = pixel.b,
			a = pixel.a
		})
	end

	--회전후 생기는 좆같은 빈공간 해결
	local function fillGaps()
		local filled = {}
		for _,p in ipairs(rotated) do
			table.insert(filled, p)

			for dx = -1, 1 do
				for dy = -1, 1 do
					local nx, ny = p.x + dx, p.y + dy
					local key = nx..','..ny
					if not visited[key] then
						visited[key] = true
						table.insert(filled, {
							x = nx,
							y = ny,
							width = 1,
							height = 1,
							r = p.r,
							g = p.g,
							b = p.b,
							a = p.a
						})
					end
				end
			end
		end
		return filled
	end

	rotated = fillGaps()



	o.data.using = GUI.Optimize(rotated)
	for _,v in ipairs(o.data.object) do
		v:Remove()
	end
	for _,v in ipairs(o.data.using) do
		table.insert(o.data.object,GUI:_CreateObject(v,GUI.TYPE.BOX))
	end
	print('done')
end

--그래픽 그룹의 객체를 업데이트합니다.
--t 새로 적용할 arg 들어있는 테이블
---@param t table
function GUI.Group.Update(o,t)
	if t and type(t) ~= "table" then error('Arguments Error') end
	if not t then
		for _,v in ipairs(o.data.object) do
			v:Remove()
		end
		for _,v in ipairs(o.data.using) do
			table.insert(o.data.object, GUI:_CreateObject(v,GUI.TYPE.BOX))
		end
	else
		for _,v in ipairs(o.data.object) do
			v:Remove()
		end
		o.data.object = {}
		for _,v in ipairs(t) do
			table.insert(o.data.object,GUI:_CreateObject(v,GUI.TYPE.BOX))
		end
	end
end


--그래픽그룹에 애니메이션을 적용시킵니다.
--method는 가중치를 적용할 방향성입니다.
--f는 가중치 적용 공식입니다.
function GUI.Group.ApplyAnimation(group,method,f)
	if type(f) ~= "function" or type(group) ~= "table" then error('arguments error') end
	if not group.isAnimationRun then --애니메이션 처음 가동 시
		local args = {}
		for k,v in ipairs(group.data.object) do
			args[k] = v:Get()
		end
		group.isAnimationRun = true
		eventHandler:addEvent(function()
			return group:_operateAnimation(method,f,args)
		end)
	else --이미 가동중일 시
		print('이미작동중')
	end
end

--애니메이션의 t축을 움직이는 함수
--args는 실행당시의 arguments
function GUI.Group._operateAnimation(group,method,f,args)
	-- print(table.concat(table.dump(args),''))
	local o = group
	--t값 변화량
	local amount = 0.01
	if o.data.t > 1 then o.isAnimationRun = false o.data.t = 0 return 0 end
	local weight = 1-f(group.data.t)
	
	--디버깅용
	table.insert(graphArgs,{x=o.data.t*100+100,y=weight*100+100,height=1,width=1,r=255,g=0,b=0,a=255})
	graph:Update(graphArgs)
	
	--todo > 최초위치 고정 방법
	group.data.t = group.data.t + amount
	local limit = 100
	for k,v in ipairs(group.data.object) do
		local _arg = v:Get()
		_arg.y = _arg.y + delta * limit
		print(args[k] == v)
		v:Set(_arg)
	end
end

function Bounce(t)
		if (t < 1.0 / 2.75) then
			return 7.5625 * t * t;
		elseif (t < 2 / 2.75) then
			t = t - 1.5 / 2.75;
			return 7.5625 * t * t + 0.75;
		elseif (t < 2.5 / 2.75) then
			t = t - 2.25 / 2.75;
			return 7.5625 * t * t + 0.9375;
		end
		t = t -2.625 / 2.75;
		return 7.5625 * t * t + 0.984375;
end

function EaseElasticIn(t, period)
    if t == 0 or t == 1 then return t end

    period = period or 0.4
    local s = period / 4.0

    for i = 1, 10 do
        t = t - 1.0
        return -(2.0 ^ (10.0 * t)) * math.sin((t - s) * (math.pi * 2.0) / period)
    end
end



--예제
local exampleBoxArgs1 = {
	{x=0,y=0,height=2,width=100,r=255,g=80,b=31,a=255},
	{x=100,y=0,height=40,width=2,r=255,g=80,b=31,a=255}
}
local exampleBoxArgs2 = {
	{x=0,y=0,height=20,width=50,r=255,g=80,b=31,a=255}
}
local exampleTextArgs1 = {text='Box1',font='verylarge',align='center',x=0,y=0,height=300,width=300,r=255,g=255,b=255,a=255}

graphArgs = {
	{x=-20,y=-130,height=150,width=300,r=255,g=255,b=255,a=255},
	{x=0,y=-120,height=130,width=2,r=0,g=0,b=0,a=255},
	{x=-10,y=0,height=2,width=280,r=0,g=0,b=0,a=255}
}

myrad = 0
graph = GUI.Group:New(graphArgs,{x=100,y=230})
abc = GUI.Group:New(exampleBoxArgs2,{x=1024/2,y=768/2})

-- abc:Rotate(30,{x=0,y=0})

-- td= {}
-- for k = 1,32 do
-- 	local args = {}
-- 	local offset = {x=400,y=400}
-- 	for j = 1,20 do
-- 		local i = (k-1)*32+j
-- 		table.insert(args,{x =offset.x + (i-1)%32 + ((i-1)%32-1)*4, y= offset.y + (i-1)//32 + ((i-1)//32-1)*4, height=4,width=4,r=255,g=0,b=0,a=255})
-- 	end
-- 	local pixel = GUI.Group:New(args,{x=0,y=0})
-- 	-- pixel:Set()
-- 	table.insert(td,pixel)
-- end


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