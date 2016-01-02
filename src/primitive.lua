
local floor, abs = math.floor, math.abs
local min, max = math.min, math.max
local PI, PI2 = math.pi, math.pi * 2
local sin, cos = math.sin, math.cos

local function linfo( x1, y1, x2, y2 )
	local dy = y2 - y1

	if dy == 0 then return end

	local dx = x2 - x1
	local m = dx / dy
	local c = x1 - m * y1

	return {
		dx >= 0 and x1 or x2;
		dx >= 0 and x2 or x1;
		m;
		c;
		dx;
	}
end

local function scanline( lines, y )
	local points = {}
	local n = 1

	for i = 1, #lines do
		local l = lines[i]
		local p = l[5] == 0 and l[1] or l[3] * y + l[4]

		if p >= l[1] and p <= l[2] then
			points[n] = p
			n = n + 1
		end
	end

	if points[1] then
		return floor( points[1] + .5 ), floor( ( points[2] or points[1] ) + .5 )
	end
end

local function shapeFromLines( lines, minY, maxY )
	local pixels = {}
	local n = 1
	local width, height = render.getDimensions()

	for i = max( floor( minY + .5 ), 0 ), min( floor( maxY + .5 ), height - 1 ) do
		local a, b = scanline( lines, i )

		if a then
			a, b = min( a, b ), max( a, b )
			if a < 0 then a = 0 end
			if b >= width then b = width - 1 end

			local o = i * width + a + 1

			for p = 0, b - a do
				pixels[n] = p + o
				n = n + 1
			end
		end
	end

	return pixels
end

local primitive = {}

function primitive.line( x1, y1, x2, y2 )
	x1, y1 = transform( x1, y1 )
	x2, y2 = transform( x2, y2 )

	local width, height = render.getDimensions()
	local dx, dy = x2 - x1, y2 - y1
	local points = {}
	local n = 0

	if abs(dx) <= 0.001 then
		if abs(dy) <= 0.001 then
			return { floor( y1 + .5 ) * width + floor( x1 + .5 ) + 1 }
		end

		if x1 < 0 or x1 >= width then return {} end
		if y1 > y2 then y1, y2 = y2, y1 end

		y1, y2 = floor( max( y1, 0 ) + .5 ), floor( min( y2, height - 1 ) + .5 )
		
		local o = y1 * width + floor( x1 + .5 ) + 1

		for i = y1, y2 do
			points[n] = o
			o = o + width
			n = n + 1
		end

	elseif abs(dy) <= 0.001 then

		if y1 < 0 or y1 >= height then return {} end
		if x1 > x2 then x1, x2 = x2, x1 end

		x1, x2 = floor( max( x1, 0 ) + .5 ), floor( min( x2, width - 1 ) )
		
		local o = floor( y1 + .5 ) * width + x1 + 1

		for i = 0, x2 - x1 do
			points[n] = o + i
			n = n + 1
		end

	else

		points[1] = floor( y1 + .5 ) * width + floor( x1 + 1.5 )
		points[2] = floor( y2 + .5 ) * width + floor( x2 + 1.5 )
		n = 3

		local m = dy / dx
		local c = y1 - m * x1 + .5

		if x2 < x1 then
			x1, x2 = x2, x1
		end

		for x = max( x1, 0 ), min( x2, width - 1 ), min( 1, 1 / abs(m) ) do
			local y = floor( m * x + c )
			if y >= 0 and y <= height - 1 then
				points[n] = y * width + floor( x + .5 ) + 1
				n = n + 1
			end
		end

	end

	return points
end

function primitive.triangle( x1, y1, x2, y2, x3, y3 )
	x1, y1 = transform( x1, y1 )
	x2, y2 = transform( x2, y2 )
	x3, y3 = transform( x3, y3 )

	local lines = {}
	local pixels = {}
	local n = 1

	lines[#lines + 1] = linfo( x1, y1, x2, y2 )
	lines[#lines + 1] = linfo( x2, y2, x3, y3 )
	lines[#lines + 1] = linfo( x3, y3, x1, y1 )

	return shapeFromLines( lines, min( y1, y2, y3 ), max( y1, y2, y3 ) )
end

function primitive.rectangle( x, y, w, h )
	local x1, y1 = transform( x, y )
	local x2, y2 = transform( x + w, y )
	local x3, y3 = transform( x + w, y + h )
	local x4, y4 = transform( x, y + h )
	local lines = {}
	local pixels = {}
	local n = 1

	lines[#lines + 1] = linfo( x1, y1, x2, y2 )
	lines[#lines + 1] = linfo( x2, y2, x3, y3 )
	lines[#lines + 1] = linfo( x3, y3, x4, y4 )
	lines[#lines + 1] = linfo( x4, y4, x1, y1 )

	return shapeFromLines( lines, min( y1, y2, y3, y4 ), max( y1, y2, y3, y4 ) )
end

function primitive.circle( rx, ry, r, s )
	s = s or floor( PI2 * r + .5 )

	rx, ry = transform( rx, ry )

	local x = {}
	local y = {}
	local lines = {}

	for i = 1, s do
		local angle = i/s * PI2
		x[i], y[i] = transform( rx + cos( angle ) * r, ry + sin( angle ) * r )
	end

	for i = 1, s do
		lines[i] = linfo( x[i], y[i], x[i + 1] or x[1], y[i + 1] or y[1] )
	end

	return shapeFromLines( lines, min( unpack( y ) ), max( unpack( y ) ) )
end

return primitive
