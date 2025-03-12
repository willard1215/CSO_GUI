function getUnionOutline(rects)
    local edges = {}

    -- 모든 사각형의 네 개 변을 수집
    for _, rect in ipairs(rects) do
        table.insert(edges, {x1 = rect.xmin, y1 = rect.ymin, x2 = rect.xmax, y2 = rect.ymin}) -- 아래변
        table.insert(edges, {x1 = rect.xmax, y1 = rect.ymin, x2 = rect.xmax, y2 = rect.ymax}) -- 오른쪽 변
        table.insert(edges, {x1 = rect.xmin, y1 = rect.ymax, x2 = rect.xmax, y2 = rect.ymax}) -- 위쪽 변
        table.insert(edges, {x1 = rect.xmin, y1 = rect.ymin, x2 = rect.xmin, y2 = rect.ymax}) -- 왼쪽 변
    end

    -- 겹치는 변 제거
    local function isSameEdge(edge1, edge2)
        return (edge1.x1 == edge2.x1 and edge1.y1 == edge2.y1 and edge1.x2 == edge2.x2 and edge1.y2 == edge2.y2) or
               (edge1.x1 == edge2.x2 and edge1.y1 == edge2.y2 and edge1.x2 == edge2.x1 and edge1.y2 == edge2.y1)
    end

    local finalEdges = {}
    for i, edge in ipairs(edges) do
        local unique = true
        for j, otherEdge in ipairs(edges) do
            if i ~= j and isSameEdge(edge, otherEdge) then
                unique = false
                break
            end
        end
        if unique then
            table.insert(finalEdges, edge)
        end
    end

    -- 정렬된 외곽선의 정점 추출
    local vertices = {}
    local currentEdge = table.remove(finalEdges, 1)
    table.insert(vertices, {x = currentEdge.x1, y = currentEdge.y1})
    table.insert(vertices, {x = currentEdge.x2, y = currentEdge.y2})

    while #finalEdges > 0 do
        for i, edge in ipairs(finalEdges) do
            if edge.x1 == vertices[#vertices].x and edge.y1 == vertices[#vertices].y then
                table.insert(vertices, {x = edge.x2, y = edge.y2})
                table.remove(finalEdges, i)
                break
            elseif edge.x2 == vertices[#vertices].x and edge.y2 == vertices[#vertices].y then
                table.insert(vertices, {x = edge.x1, y = edge.y1})
                table.remove(finalEdges, i)
                break
            end
        end
    end

    return vertices
end

-- 테스트 데이터
allArguments = {
    {xmin = 1, xmax = 40, ymin = 0, ymax = 50},
    {xmin = 10, xmax = 40, ymin = 0, ymax = 60},
}

-- 최외곽선 좌표 출력
outline = getUnionOutline(allArguments)
for _, vertex in ipairs(outline) do
    print("Vertex: x=" .. vertex.x .. ", y=" .. vertex.y)
end
