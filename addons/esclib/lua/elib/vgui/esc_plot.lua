local PANEL = {}

local accessor_fn = esclib.accessor
local masks = esclib.masks
local radial_grad_mat = esclib:GetMaterial("radial_gradient.png")

local esclib = esclib
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local surface_DrawRect = surface.DrawRect
local draw_SimpleText = draw.SimpleText
local table_IsEmpty = table.IsEmpty
local math_min = math.min
local math_max = math.max
local round = math.Round
local string_format = string.format
local string_sub = string.sub
local math_floor = math.floor
local math_log10 = math.log10
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad
local math_ceil = math.ceil
local math_deg = math.deg
local math_atan2 = math.atan2
local math_sqrt = math.sqrt
local math_huge = math.huge


AccessorFunc(PANEL, "xFormat", "XFormat")
AccessorFunc(PANEL, "yFormat", "YFormat")
AccessorFunc(PANEL, "margin", "Margin")
AccessorFunc(PANEL, "drawPoints", "DrawPoints", FORCE_BOOL)
AccessorFunc(PANEL, "drawGrid", "DrawGrid", FORCE_BOOL)
AccessorFunc(PANEL, "barPadding", "BarPadding")
AccessorFunc(PANEL, "xTicks", "XTicks")
AccessorFunc(PANEL, "yTicks", "YTicks")
AccessorFunc(PANEL, "innerRadius", "InnerRadius")
AccessorFunc(PANEL, "enableTooltip", "EnableTooltip", FORCE_BOOL)
AccessorFunc(PANEL, "showLegend", "ShowLegend", FORCE_BOOL)

local legendPositions = {
    ["topleft"] = true,
    ["topright"] = true,
    ["bottomleft"] = true,
    ["bottomright"] = true,
}   
accessor_fn(PANEL, "legendPosition", "LegendPosition", "topleft", function(val)
    return legendPositions[val]
end)

local displayModes = {
    ["plot"] = true,
    ["histogram"] = true,
    ["pie"] = true
}
accessor_fn(PANEL, "displayMode", "DisplayMode", "plot", function(val)
    return displayModes[val]
end)

-- Default colors for series
local defaultColors = {
    Color(50, 150, 250),   -- Blue
    Color(255, 100, 100),  -- Red
    Color(50, 200, 100),   -- Green
    Color(255, 200, 50),   -- Yellow
    Color(150, 100, 200),  -- Purple
    Color(255, 150, 50),   -- Orange
    Color(100, 200, 200),  -- Teal
    Color(200, 100, 150),  -- Pink
}

function PANEL:Init()
    self.series = {}
    self.margin = esclib:AdaptiveSize(5)
    self.maxMargin = esclib:AdaptiveSize(80)  -- Maximum margin for axis labels
    self.leftMargin = esclib:AdaptiveSize(40) -- Separate margin for the left side
    self.xTicks = 10
    self.yTicks = 10
    self.axisColor = Color(255, 255, 255)
    self.gridColor = Color(70, 70, 70, 100)
    self.pointColor = Color(255, 100, 100)
    self.barPadding = 2
    self.font = esclib:AdaptiveFont("esclib", 14, 500)
    self.legendFont = esclib:AdaptiveFont("esclib", 12, 500)
    self.labelPositions = {}
    
    self.legendPadding = 5
    self.legendItemHeight = draw.GetFontHeight(self.legendFont)+4
    self.legendBoxColor = Color(40, 40, 40, 200)
    self.legendTextColor = Color(255, 255, 255)
    self.legendItemSpacing = 5
    self.legendMarkerSize = 15

    self.minX = 0
    self.maxX = 0
    self.minY = 0
    self.maxY = 0
    self.xRange = 1
    self.yRange = 1

    self:SetXFormat("%.2f")
    self:SetYFormat("%.2f")
    self:SetDrawPoints(true)
    self:SetDisplayMode("plot")
    self:SetDrawGrid(true)
    self:SetEnableTooltip(true)
    self:SetShowLegend(false)
    self:SetLegendPosition("topright")
    self:SetInnerRadius(0.7)

    self.hoverPoint = nil
    self.hoverSeries = nil
    self.hoverX = 0
    self.hoverY = 0
    self.showTooltip = false
    self.tooltipPadding = 5
    self.tooltipColor = Color(40, 40, 40, 240)
    self.tooltipTextColor = Color(255, 255, 255)
    
    self.pieSegmentPoints = {}
    
    -- Кэшированные данные для отрисовки
    self.cachedGridData = {}
    self.cachedHistogramData = {}
    self.cachedLegendData = {}
    self.cachedPlotPoints = {}
end

function PANEL:AddSeries(name, xPoints, yPoints, color)
    if self.displayMode == "pie" then
        local value = xPoints
        if type(value) ~= "number" then return false end
        
        color = color or defaultColors[(#self.series % #defaultColors) + 1]
        
        local seriesData = {
            name = name or string_format("Series %d", #self.series + 1),
            value = value,
            color = color,
            pieColor = color,
            polyPoints = {}
        }
        
        table.insert(self.series, seriesData)
    else
        if not xPoints or #xPoints < 2 or not yPoints or #yPoints < 2 then return false end
        
        color = color or defaultColors[(#self.series % #defaultColors) + 1]
        
        local seriesData = {
            name = name or string_format("Series %d", #self.series + 1),
            xPoints = xPoints,
            yPoints = yPoints,
            color = color,
            pointColor = color,
            barColor = color,
            calculatedPoints = {}
        }
        
        table.insert(self.series, seriesData)
    end
    
    self:RecalculateValues()
    self:InvalidateLayout()
    return true
end

function PANEL:ClearSeries()
    self.series = {}
    self:RecalculateValues()
    self:InvalidateLayout()
end

function PANEL:GetSeries()
    return self.series
end

function PANEL:GetSeriesCount()
    return #self.series
end

function PANEL:GeneratePieSegmentPoints(centerX, centerY, radius, startAngle, endAngle, segments)
    local points = {}
    
    table.insert(points, {x = centerX, y = centerY})
    
    local segmentCount = segments or math_max(4, math_ceil((endAngle - startAngle) / 3))
    
    local sweep = endAngle - startAngle
    if sweep <= 0 then sweep = sweep + 360 end
    
    for i = 0, segmentCount do
        local t = i / segmentCount
        local angle = startAngle + sweep * t
        
        local rad = math_rad(angle - 90)
        
        local x = centerX + math_cos(rad) * radius
        local y = centerY + math_sin(rad) * radius
        
        table.insert(points, {x = x, y = y})
    end
    
    return points
end

function PANEL:CalculateMargins()
    surface.SetFont(self.font)
    local maxWidth = 0
    for i = 0, self.yTicks do
        local valY = self.minY + self.yRange * (1 - i / self.yTicks)
        local text = string_format(self.yFormat, valY)
        local w = surface.GetTextSize(text)
        maxWidth = math_max(maxWidth, w)
    end
    
    self.leftMargin = math_min(self.maxMargin, maxWidth + 15)
    
    self.margin = 40
end

function PANEL:RecalculateValues()
    if #self.series == 0 then return end
    
    local w, h = self:GetSize()
    
    if self.displayMode == "pie" then
        self.pieTotal = 0
        for _, series in ipairs(self.series) do
            self.pieTotal = self.pieTotal + series.value
        end
        
        local startAngle = 0
        for _, series in ipairs(self.series) do
            series.startAngle = startAngle
            series.percentage = series.value / self.pieTotal
            series.sweepAngle = series.percentage * 360
            series.endAngle = startAngle + series.sweepAngle
            startAngle = series.endAngle
        end
        
        -- Calculate polygon points for each segment
        local centerX = w * 0.5
        local centerY = h * 0.5
        local radius = math_min(w, h) * 0.5 - self.margin
        
        for _, series in ipairs(self.series) do
            local segmentPoints = self:GeneratePieSegmentPoints(
                centerX, centerY, radius, 
                series.startAngle, series.endAngle
            )
            
            if #segmentPoints >= 3 then
                series.polyPoints = segmentPoints
            else
                series.polyPoints = {}
            end
        end
    else
        self.minX = math_huge
        self.maxX = -math_huge
        self.minY = math_huge
        self.maxY = -math_huge
        
        for _, series in ipairs(self.series) do
            local xMin = math_min(unpack(series.xPoints))
            local xMax = math_max(unpack(series.xPoints))
            local yMin = math_min(unpack(series.yPoints))
            local yMax = math_max(unpack(series.yPoints))
            
            self.minX = math_min(self.minX, xMin)
            self.maxX = math_max(self.maxX, xMax)
            self.minY = math_min(self.minY, yMin)
            self.maxY = math_max(self.maxY, yMax)
            
            series.calculatedPoints = {}
            for i = 1, math_min(#series.xPoints, #series.yPoints) do
                series.calculatedPoints[i] = {
                    x = series.xPoints[i],
                    y = series.yPoints[i]
                }
            end
        end
        
        self.xRange = self.maxX - self.minX
        self.yRange = self.maxY - self.minY
        self.xRange = self.xRange == 0 and 1 or self.xRange
        self.yRange = self.yRange == 0 and 1 or self.yRange
        
        -- Calculate margins based on text size
        self:CalculateMargins()
    end
    
    -- Calculate data for all modes
    self:CalculateGridData()
    self:CalculateHistogramData()
    self:CalculatePlotPoints()
    self:CalculateLegendData()
end

-- Calculate data for the grid
function PANEL:CalculateGridData()
    local w, h = self:GetSize()
    if w <= 0 or h <= 0 then return end
    
    local plotWidth = w - self.margin - self.leftMargin
    local plotHeight = h - 2 * self.margin
    
    local gridData = {
        xTicks = {},
        yTicks = {}
    }
    
    surface.SetFont(self.font)
    
    -- X axis ticks
    for i = 0, self.xTicks do
        local gx = self.leftMargin + plotWidth * (i / self.xTicks)
        local valX = self.minX + self.xRange * (i / self.xTicks)
        local text = string_format(self.xFormat, valX)
        
        -- Limit text length of X axis labels
        local textWidth = surface.GetTextSize(text)
        local maxWidth = plotWidth / self.xTicks * 0.9
        
        if textWidth > maxWidth and maxWidth > 10 then
            local ratio = maxWidth / textWidth
            local chars = #text
            text = string_sub(text, 1, math_floor(chars * ratio) - 2) .. ".."
        end
        
        table.insert(gridData.xTicks, {
            x = gx,
            y = h - self.margin,
            value = valX,
            text = text
        })
    end
    
    -- Y axis ticks
    for i = 0, self.yTicks do
        local gy = self.margin + plotHeight * (i / self.yTicks)
        local valY = self.minY + self.yRange * (1 - i / self.yTicks)
        local text = string_format(self.yFormat, valY)
        
        -- Limit text length of Y axis labels
        if self.leftMargin < self.maxMargin then
            local textWidth = surface.GetTextSize(text)
            if textWidth > self.leftMargin - 10 and self.leftMargin > 15 then
                local ratio = (self.leftMargin - 10) / textWidth
                local chars = #text
                text = string.sub(text, 1, math.floor(chars * ratio) - 2) .. ".."
            end
        end
        
        table.insert(gridData.yTicks, {
            x = self.leftMargin,
            y = gy,
            value = valY,
            text = text
        })
    end
    
    gridData.bounds = {
        left = self.leftMargin,
        right = w - self.margin,
        top = self.margin,
        bottom = h - self.margin
    }
    
    self.cachedGridData = gridData
end

function PANEL:CalculateHistogramData()
    if #self.series == 0 or self.displayMode ~= "histogram" then return end
    
    local w, h = self:GetSize()
    local plotWidth = w - self.margin - self.leftMargin
    local plotHeight = h - 2 * self.margin
    
    local uniqueX = {}
    local xToIndexMap = {}
    
    -- Collect unique X values
    for _, series in ipairs(self.series) do
        for _, point in ipairs(series.calculatedPoints) do
            local x = point.x
            if not xToIndexMap[x] then
                table.insert(uniqueX, x)
                xToIndexMap[x] = #uniqueX
            end
        end
    end
    
    table.sort(uniqueX)
    
    for i, x in ipairs(uniqueX) do
        xToIndexMap[x] = i
    end
    
    local numGroups = #uniqueX
    local numSeries = #self.series
    local groupWidth = plotWidth / numGroups
    local barWidth = (groupWidth * 0.8) / numSeries
    local groupSpacing = groupWidth * 0.1
    
    local barInfo = {}
    
    for s, series in ipairs(self.series) do
        local xToY = {}
        for _, point in ipairs(series.calculatedPoints) do
            xToY[point.x] = point.y
        end
        
        for i, x in ipairs(uniqueX) do
            local y = xToY[x] or 0
            
            local groupStartX = self.leftMargin + (i - 1) * groupWidth + groupSpacing
            local barX = groupStartX + (s - 1) * barWidth
            local barY = self.margin + plotHeight * (1 - (y - self.minY) / self.yRange)
            
            barY = math_max(barY, self.margin)
            local barHeight = h - self.margin - barY
            
            if barHeight > 0 then
                table.insert(barInfo, {
                    seriesIndex = s,
                    x1 = barX,
                    y1 = barY,
                    x2 = barX + barWidth,
                    y2 = barY + barHeight,
                    valueX = x,
                    valueY = y
                })
            end
        end
    end
    
    self.cachedHistogramData = {
        barInfo = barInfo,
        uniqueX = uniqueX,
        xToIndexMap = xToIndexMap
    }
    
    -- Save for use in the tooltip determination function
    self.barInfo = barInfo
end

-- Calculate points for the line plot
function PANEL:CalculatePlotPoints()
    if #self.series == 0 or self.displayMode ~= "plot" then return end
    
    local w, h = self:GetSize()
    local plotWidth = w - self.margin - self.leftMargin
    local plotHeight = h - 2 * self.margin
    
    local cachedPoints = {}
    
    for s, series in ipairs(self.series) do
        cachedPoints[s] = {}
        
        for i = 1, #series.calculatedPoints do
            local point = series.calculatedPoints[i]
            local px = self.leftMargin + plotWidth * ((point.x - self.minX) / self.xRange)
            local py = self.margin + plotHeight * (1 - (point.y - self.minY) / self.yRange)
            
            cachedPoints[s][i] = {
                x = px,
                y = py,
                originalX = point.x,
                originalY = point.y
            }
        end
    end
    
    self.cachedPlotPoints = cachedPoints
end

-- Calculate data for the legend
function PANEL:CalculateLegendData()
    if not self.showLegend or #self.series == 0 then return end
    
    local w, h = self:GetSize()
    local legendWidth = 0
    local legendHeight = (#self.series * self.legendItemHeight) + (2 * self.legendPadding)
    
    surface.SetFont(self.legendFont)
    for _, series in ipairs(self.series) do
        local displayName = series.name
        if series.percentage then
            displayName = string_format("%s (%.1f%%)", series.name, series.percentage * 100)
        end
        local textW = surface.GetTextSize(displayName)
        legendWidth = math_max(legendWidth, textW + self.legendMarkerSize + 15)
    end
    
    legendWidth = legendWidth + 2 * self.legendPadding
    
    local legendX, legendY
    if self.legendPosition == "topright" then
        legendX = w - self.margin - legendWidth - 5
        legendY = self.margin + 5
    elseif self.legendPosition == "topleft" then
        legendX = self.margin + 5
        legendY = self.margin + 5
    elseif self.legendPosition == "bottomright" then
        legendX = w - self.margin - legendWidth - 5
        legendY = h - self.margin - legendHeight - 5
    elseif self.legendPosition == "right" then
        legendX = w - self.margin - legendWidth - 5
        legendY = (h - legendHeight) * 0.5
    else -- bottomleft
        legendX = self.margin + 5
        legendY = h - self.margin - legendHeight - 5
    end
    
    local items = {}
    for i, series in ipairs(self.series) do
        local itemY = legendY + self.legendPadding + (i-1) * self.legendItemHeight
        local displayName = series.name
        
        if self.displayMode == "pie" and series.percentage then
            displayName = string_format("%s (%.1f%%)", series.name, series.percentage * 100)
        end
        
        items[i] = {
            series = i,
            x = legendX + self.legendPadding,
            y = itemY,
            text = displayName,
            centerY = itemY + self.legendItemHeight/2
        }
    end
    
    self.cachedLegendData = {
        x = legendX,
        y = legendY,
        width = legendWidth,
        height = legendHeight,
        items = items
    }
end

function PANEL:SetXPoints(tbl)
    self:ClearSeries()
    self:AddSeries("Default", tbl, self.yPoints or {}, self.lineColor)
end

function PANEL:SetYPoints(tbl)
    if #self.series == 0 then
        self:AddSeries("Default", self.xPoints or {}, tbl, self.lineColor)
    else
        self.series[1].yPoints = tbl
        self:RecalculateValues()
        self:InvalidateLayout()
    end
end

function PANEL:PaintGrid(w, h)
    if not self.cachedGridData or not self.cachedGridData.bounds then return end
    
    local gridData = self.cachedGridData
    
    -- Рисуем сетку
    for i, tick in ipairs(gridData.xTicks) do
        if i > 1 and i < #gridData.xTicks and self.drawGrid then
            surface_SetDrawColor(self.gridColor)
            surface_DrawLine(tick.x, gridData.bounds.top, tick.x, gridData.bounds.bottom)
        end
        
        draw_SimpleText(tick.text, self.font, tick.x, tick.y + 4, self.axisColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    for i, tick in ipairs(gridData.yTicks) do
        if i > 1 and i < #gridData.yTicks and self.drawGrid then
            surface_SetDrawColor(self.gridColor)
            surface_DrawLine(gridData.bounds.left, tick.y, gridData.bounds.right, tick.y)
        end
        
        draw_SimpleText(tick.text, self.font, tick.x - 6, tick.y, self.axisColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    
    -- Draw borders
    surface_SetDrawColor(self.gridColor)
    surface_DrawLine(gridData.bounds.left, gridData.bounds.top, gridData.bounds.left, gridData.bounds.bottom)
    surface_DrawLine(gridData.bounds.right, gridData.bounds.top, gridData.bounds.right, gridData.bounds.bottom)
    surface_DrawLine(gridData.bounds.left, gridData.bounds.bottom, gridData.bounds.right, gridData.bounds.bottom)
    surface_DrawLine(gridData.bounds.left, gridData.bounds.top, gridData.bounds.right, gridData.bounds.top)
end

function PANEL:PaintHistogram(w, h)
    if #self.series == 0 or not self.cachedHistogramData or #self.cachedHistogramData.barInfo == 0 then return end

    self:PaintGrid(w, h)
    
    for _, barInfo in ipairs(self.cachedHistogramData.barInfo) do
        local series = self.series[barInfo.seriesIndex]
        surface_SetDrawColor(series.barColor)
        
        draw.RoundedBox(4, barInfo.x1, barInfo.y1, barInfo.x2 - barInfo.x1, barInfo.y2 - barInfo.y1, series.barColor)
    end
end

function PANEL:PaintPlot(w, h)
    if #self.series == 0 or not self.cachedPlotPoints then return end

    self:PaintGrid(w, h)
    
    for s, series in ipairs(self.series) do
        local points = self.cachedPlotPoints[s]
        if not points or #points < 2 then continue end
    
        surface_SetDrawColor(series.color)
        
        for i = 2, #points do
            local prev = points[i-1]
            local curr = points[i]
            
            surface_DrawLine(prev.x, prev.y, curr.x, curr.y)

            if self.drawPoints then
                surface_DrawRect(prev.x - 1, prev.y - 1, 4, 4)
            end
        end
    end
end

function PANEL:PaintLegend(w, h)
    if not self.showLegend or #self.series == 0 or not self.cachedLegendData then return end
    
    local legendData = self.cachedLegendData
    
    draw.RoundedBox(4, legendData.x, legendData.y, legendData.width, legendData.height, self.legendBoxColor)
    
    for _, item in ipairs(legendData.items) do
        local series = self.series[item.series]
        
        if self.displayMode == "plot" then
            surface_SetDrawColor(series.color)
            surface_DrawLine(
                item.x, 
                item.centerY,
                item.x + self.legendMarkerSize, 
                item.centerY
            )
            
            if self.drawPoints then
                surface_SetDrawColor(series.pointColor)
                surface_DrawRect(
                    item.x + self.legendMarkerSize/2 - 1.5,
                    item.centerY - 1.5,
                    3, 3
                )
            end
        elseif self.displayMode == "pie" then
            draw.RoundedBox(2,
                item.x,
                item.centerY - (self.legendMarkerSize/3),
                self.legendMarkerSize,
                self.legendMarkerSize/1.5,
                series.pieColor
            )
        else
            draw.RoundedBox(2,
                item.x,
                item.centerY - (self.legendMarkerSize/3),
                self.legendMarkerSize,
                self.legendMarkerSize/1.5,
                series.barColor
            )
        end
        
        draw_SimpleText(
            item.text,
            self.legendFont,
            item.x + self.legendMarkerSize + 5,
            item.centerY,
            self.legendTextColor,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end
end

function PANEL:OnCursorMoved(x, y)
    if not self:IsHovered() then 
        self.showTooltip = false
        return 
    end
    
    local w, h = self:GetSize()
    local mouseX, mouseY = self:ScreenToLocal(gui.MousePos())
    
    self.hoverX = mouseX
    self.hoverY = mouseY
    self.showTooltip = false
    
    if #self.series == 0 then return end
    
    if self.displayMode == "pie" then
        local centerX = w * 0.5
        local centerY = h * 0.5
        local radius = math_min(w, h) * 0.5 - self.margin
        
        local dx = mouseX - centerX
        local dy = mouseY - centerY
        local distance = math_sqrt(dx * dx + dy * dy)
        
        if distance <= radius then
            local angle = math_deg(math_atan2(dy, dx)) + 90
            if angle < 0 then angle = angle + 360 end
            
            for i, series in ipairs(self.series) do
                local startA = series.startAngle
                local endA = series.endAngle
                
                if endA < startA then
                    if angle >= startA or angle <= endA then
                        self.hoverSeries = i
                        self.hoverPoint = {
                            x = mouseX,
                            y = mouseY,
                            valueX = series.value,
                            valueY = series.percentage * 100
                        }
                        self.showTooltip = true
                        break
                    end
                else
                    if angle >= startA and angle <= endA then
                        self.hoverSeries = i
                        self.hoverPoint = {
                            x = mouseX,
                            y = mouseY,
                            valueX = series.value,
                            valueY = series.percentage * 100
                        }
                        self.showTooltip = true
                        break
                    end
                end
            end
        end
    elseif self.displayMode == "histogram" then
        -- Используем предварительно рассчитанные данные о барах
        if self.barInfo then
            for _, barInfo in ipairs(self.barInfo) do
                if mouseX >= barInfo.x1 and mouseX <= barInfo.x2 and
                   mouseY >= barInfo.y1 and mouseY <= barInfo.y2 then
                    self.hoverSeries = barInfo.seriesIndex
                    self.hoverPoint = {
                        x = (barInfo.x1 + barInfo.x2) * 0.5,
                        y = barInfo.y1,
                        valueX = barInfo.valueX,
                        valueY = barInfo.valueY
                    }
                    self.showTooltip = true
                    break
                end
            end
        end
    else
        -- Используем предварительно рассчитанные точки для графика
        local closestDist = math_huge
        local closestPoint = nil
        local closestSeries = nil
        
        for s, points in ipairs(self.cachedPlotPoints) do
            for i, point in ipairs(points) do
                local dist = (mouseX - point.x)^2 + (mouseY - point.y)^2
                
                if dist < closestDist then
                    closestDist = dist
                    closestPoint = {
                        index = i,
                        x = point.x,
                        y = point.y,
                        valueX = point.originalX,
                        valueY = point.originalY
                    }
                    closestSeries = s
                end
            end
        end
        
        if closestDist < 200 then
            self.hoverPoint = closestPoint
            self.hoverSeries = closestSeries
            self.showTooltip = true
        else
            self.hoverPoint = nil
            self.hoverSeries = nil
        end
    end
    
    self:InvalidateLayout()
end

function PANEL:PaintTooltip(w, h)
    if not self.enableTooltip or not self.showTooltip or not self.hoverPoint or not self.hoverSeries then return end
    
    local point = self.hoverPoint
    local series = self.series[self.hoverSeries]
    local text
    
    if self.displayMode == "pie" then
        text = string_format("%s\n%s (%.1f%%)", 
            series.name,
            string_format(self.yFormat, series.value),
            series.percentage * 100)
    else
        text = string_format("%s\nX: %s\nY: %s", 
            series.name,
            string_format(self.xFormat, point.valueX),
            string_format(self.yFormat, point.valueY))
    end
    
    surface.SetFont(self.font)
    local tw, th = surface.GetTextSize(text)
    tw = tw + self.tooltipPadding * 2
    th = th + self.tooltipPadding * 2
    
    local tx = point.x + 10
    local ty = point.y - th/2
    
    if tx + tw > w - self.margin then
        tx = point.x - tw - 10
    end
    if ty + th > h - self.margin then
        ty = h - self.margin - th
    end
    
    local old = DisableClipping( true )
    draw.RoundedBox(4, tx, ty, tw, th, self.tooltipColor)
    
    draw.DrawText(text, self.font, 
        tx + self.tooltipPadding, 
        ty + self.tooltipPadding, 
        self.tooltipTextColor, 
        TEXT_ALIGN_LEFT)
    DisableClipping( old )
end

function PANEL:BeforePaint(w,h)
    --For override
end

function PANEL:Paint(w, h)
    if #self.series == 0 then return end
    self:BeforePaint(w,h)

    if self.displayMode == "pie" then
        self:PaintPie(w, h)
    elseif self.displayMode == "histogram" then
        self:PaintHistogram(w, h)
    else
        self:PaintPlot(w, h)
    end
    
    if self.showLegend then
        self:PaintLegend(w, h)
    end
    
    if self.enableTooltip then
        self:PaintTooltip(w, h)
    end
end

function PANEL:LinearInterpolate(x1, y1, x2, y2, x)
    return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
end

function PANEL:CubicInterpolate(x0, y0, x1, y1, x2, y2, x3, y3, x)
    local t = (x - x1) / (x2 - x1)
    local t2 = t * t
    local t3 = t2 * t
    
    local a = -0.5 * y0 + 1.5 * y1 - 1.5 * y2 + 0.5 * y3
    local b = y0 - 2.5 * y1 + 2 * y2 - 0.5 * y3
    local c = -0.5 * y0 + 0.5 * y2
    local d = y1
    
    return a * t3 + b * t2 + c * t + d
end

function PANEL:InterpolateSeriesPoints(seriesIndex, method, density)
    if not self.series[seriesIndex] then return end
    
    local series = self.series[seriesIndex]
    if #series.xPoints < 2 or #series.yPoints < 2 then return end
    
    local newX = {}
    local newY = {}
    local n = #series.xPoints
    
    for i = 1, n - 1 do
        local x1, y1 = series.xPoints[i], series.yPoints[i]
        local x2, y2 = series.xPoints[i + 1], series.yPoints[i + 1]
        
        table.insert(newX, x1)
        table.insert(newY, y1)
        
        for j = 1, density - 1 do
            local t = j / density
            local x = x1 + (x2 - x1) * t
            
            local y
            if method == "cubic" and i > 1 and i < n - 1 then
                y = self:CubicInterpolate(
                    series.xPoints[i-1], series.yPoints[i-1],
                    x1, y1,
                    x2, y2,
                    series.xPoints[i+2], series.yPoints[i+2],
                    x
                )
            else
                y = self:LinearInterpolate(x1, y1, x2, y2, x)
            end
            
            table.insert(newX, x)
            table.insert(newY, y)
        end
    end
    
    table.insert(newX, series.xPoints[n])
    table.insert(newY, series.yPoints[n])
    
    series.xPoints = newX
    series.yPoints = newY
    self:RecalculateValues()
end

function PANEL:InterpolatePoints(method, density)
    for i = 1, #self.series do
        self:InterpolateSeriesPoints(i, method, density)
    end
end

function PANEL:SetDisplayMode(mode)
    if self.displayMode ~= mode and displayModes[mode] then
        self.displayMode = mode
        self:RecalculateValues()
        self:InvalidateLayout()
    end
    return self
end

function PANEL:PerformLayout(w, h)
    if w <= 0 or h <= 0 then return end
    
    if self.displayMode == "pie" then
        self:RecalculateValues() -- Recalculate polygons when size changes
    else
        self:CalculateGridData()
        self:CalculateHistogramData()
        self:CalculatePlotPoints()
    end
    
    self:CalculateLegendData()
end

function PANEL:PaintPie(w, h)
    if table_IsEmpty(self.series) then return end
    
    local centerX = w * 0.5
    local centerY = h * 0.5
    local radius = math_min(w, h) * 0.5 - self.margin
    
    masks.Start()
    
        for i, series in ipairs(self.series) do
            if #series.polyPoints < 3 then continue end
            local pcolor = series.pieColor or series.color
            
            draw.NoTexture()
            surface.SetDrawColor(pcolor)
            surface.DrawPoly(series.polyPoints)

            if self.drawPoints and series.percentage > 0.05 then
                local text_offset = radius - (radius - (radius*self.innerRadius))*0.5
                local midAngle = math_rad((series.startAngle + series.endAngle) * 0.5 - 90)
                local textX = centerX + math_cos(midAngle) * text_offset
                local textY = centerY + math_sin(midAngle) * text_offset
                
                local percentText = string_format(self.yFormat, series.value)
                --shadow
                draw_SimpleText(
                    percentText, 
                    self.font, 
                    textX+1, 
                    textY+1, 
                    color_black, 
                    TEXT_ALIGN_CENTER, 
                    TEXT_ALIGN_CENTER
                )
                draw_SimpleText(
                    percentText, 
                    self.font, 
                    textX, 
                    textY, 
                    esclib.util:TextOnBG(pcolor, color_black, color_white), 
                    TEXT_ALIGN_CENTER, 
                    TEXT_ALIGN_CENTER
                )
            end
        end

    masks.Source()
        esclib.draw:Circle(w*0.5, h*0.5, radius-2, color_white)
    masks.And(masks.KIND_CUT)
        esclib.draw:Circle(w*0.5, h*0.5, radius*self.innerRadius, color_white)
    masks.End(masks.KIND_STAMP)

    -- esclib.draw:Circle(w*0.5, h*0.5, h*0.35, color_white, 10)
end

vgui.Register("esclib.plot", PANEL, "DPanel")


-- if IsValid(frame) then frame:Remove() end
-- frame = vgui.Create("DFrame")
-- frame:SetSize(400, 400)
-- frame:SetTitle("Pie Chart Example")
-- frame:Center()
-- frame:MakePopup()

-- local piePlot = vgui.Create("esclib.plot", frame)
-- piePlot:SetPos(20, 40)
-- piePlot:SetSize(360, 340)
-- piePlot:SetDisplayMode("pie")

-- piePlot:AddSeries("Segment 1", 155, nil, Color(50, 150, 250))
-- piePlot:AddSeries("Segment 2", 25, nil, Color(255, 100, 100))
-- piePlot:AddSeries("Segment 3", 10, nil, Color(50, 200, 100))
-- piePlot:AddSeries("Segment 4", 25, nil, Color(255, 200, 50))

-- piePlot:SetDrawPoints(true)
-- piePlot:SetShowLegend(true)
-- piePlot:SetLegendPosition("topright")




-- if IsValid(frame2) then frame2:Remove() end
-- frame2 = vgui.Create("DFrame")
-- frame2:SetSize(600, 400)
-- frame2:SetTitle("Normal Plot Example")
-- frame2:Center()
-- frame2:MakePopup()

-- local normPlot = vgui.Create("esclib.plot", frame2)
-- normPlot:SetPos(20, 40)
-- normPlot:SetSize(560, 340)
-- normPlot:SetDisplayMode("plot")

-- local x1, y1 = {}, {}
-- for i = 1, 10 do
--     x1[i] = i
--     y1[i] = i^2
-- end
-- local x2, y2 = {}, {}
-- for i = 1, 10 do
--     x2[i] = i
--     y2[i] = i^3
-- end

-- normPlot:AddSeries("Segment 1", x1, y1, Color(50, 150, 250))
-- normPlot:AddSeries("Segment 2", x2, y2, Color(255, 100, 100))

-- normPlot:SetDrawPoints(true)
-- normPlot:SetShowLegend(true)
-- normPlot:SetLegendPosition("topright")




-- if IsValid(frame3) then frame3:Remove() end
-- frame3 = vgui.Create("DFrame")
-- frame3:SetSize(600, 400)
-- frame3:SetTitle("Histogram Plot Example")
-- frame3:Center()
-- frame3:MakePopup()

-- local histPlot = vgui.Create("esclib.plot", frame3)
-- histPlot:SetPos(20, 40)
-- histPlot:SetSize(560, 340)
-- histPlot:SetDisplayMode("histogram")

-- local x1, y1 = {}, {}
-- for i = 1, 10 do
--     x1[i] = i
--     y1[i] = i^2
-- end
-- local x2, y2 = {}, {}
-- for i = 1, 10 do
--     x2[i] = i
--     y2[i] = i^3
-- end

-- histPlot:AddSeries("Segment 1", x1, y1, Color(50, 150, 250))
-- histPlot:AddSeries("Segment 2", x2, y2, Color(255, 100, 100))

-- histPlot:SetDrawPoints(true)
-- histPlot:SetShowLegend(true)
-- histPlot:SetLegendPosition("topright")

