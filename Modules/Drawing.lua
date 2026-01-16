local DrawingAPI = {}
DrawingAPI.__index = DrawingAPI

local NewDrawing = Drawing and Drawing.new
local TableClear = table.clear

type DrawingObject = { [string]: any, Remove: (any) -> () }

function DrawingAPI.new()
	return setmetatable({
		Cache = {}
	}, DrawingAPI)
end

function DrawingAPI:_Create(className: string, properties: {[string]: any}?)
	if not NewDrawing then return nil end
	
	local obj = NewDrawing(className)
	if not obj then return nil end

	if properties then
		for prop, val in properties do
			obj[prop] = val
		end
	end
	
	local cache = self.Cache
	cache[#cache + 1] = obj
	return obj
end

function DrawingAPI:Line(p) return self:_Create("Line", p) end
function DrawingAPI:Circle(p) return self:_Create("Circle", p) end
function DrawingAPI:Square(p) return self:_Create("Square", p) end
function DrawingAPI:Text(p) return self:_Create("Text", p) end
function DrawingAPI:Triangle(p) return self:_Create("Triangle", p) end
function DrawingAPI:Quad(p) return self:_Create("Quad", p) end

function DrawingAPI:RemoveAll()
	local cache = self.Cache
	for i = 1, #cache do
		local obj = cache[i]
		if obj then
			obj:Remove()
		end
	end
	TableClear(cache)
end

return DrawingAPI
