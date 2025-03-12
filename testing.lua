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