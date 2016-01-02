
local floor = math.floor

local canvas = {}

function canvas:new( width, height )
	if type( width ) ~= "number" then return error( "expected number width, got " .. type( width ) ) end
	if type( height ) ~= "number" then return error( "expected number height, got " .. type( height ) ) end
	width, height = floor( width + .5 ), floor( height + .5 )

	local c = setmetatable( { width = width, height = height }, { __index = self } )

	for i = 1, width * height do
		c[i] = 0
	end

	return c
end

function canvas:resize( width, height )
	if type( width ) ~= "number" then return error( "expected number width, got " .. type( width ) ) end
	if type( height ) ~= "number" then return error( "expected number height, got " .. type( height ) ) end
	width, height = floor( width + .5 ), floor( height + .5 )

	local backup = {}

	for i = 1, self.width * self.height do
		backup[i] = self[i]
	end

	local n = 1
	for y = 1, height do
		local pos = ( y - 1 ) * width
		for x = 1, width do
			if x <= self.width and y <= self.height then
				self[pos + x] = backup[n]
			end
			n = n + 1
		end
	end

	for i = width * height + 1, self.width * self.height do
		self[i] = nil
	end

	self.width = width
	self.height = height
end

return setmetatable( canvas, { __call = canvas.new } )
