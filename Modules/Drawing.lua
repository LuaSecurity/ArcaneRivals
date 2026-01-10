local DrawingAPI = {}
DrawingAPI.__index = DrawingAPI

local NewDrawing = Drawing and Drawing.new or function() return nil end
local Insert = table.insert

function DrawingAPI.new()
    local self = setmetatable({}, DrawingAPI)
    self.Cache = {}
    return self
end

function DrawingAPI:_Create(type, properties)
    local obj = NewDrawing(type)
    
    if not obj then return nil end

    if properties then
        for prop, val in pairs(properties) do
            pcall(function()
                obj[prop] = val
            end)
        end
    end
    
    Insert(self.Cache, obj)
    return obj
end

function DrawingAPI:Line(p) return self:_Create("Line", p) end
function DrawingAPI:Circle(p) return self:_Create("Circle", p) end
function DrawingAPI:Square(p) return self:_Create("Square", p) end
function DrawingAPI:Text(p) return self:_Create("Text", p) end
function DrawingAPI:Triangle(p) return self:_Create("Triangle", p) end
function DrawingAPI:Quad(p) return self:_Create("Quad", p) end

function DrawingAPI:RemoveAll()
    for i = #self.Cache, 1, -1 do
        local obj = self.Cache[i]
        if obj then
            pcall(function() obj:Remove() end)
        end
        self.Cache[i] = nil
    end
end

return DrawingAPI
