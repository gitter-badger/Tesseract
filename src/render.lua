
local min, max = math.min, math.max
local width, height = term.getSize()
local screen = canvas( width, height )
local target = screen
local render = {}

function render.setDimensions( w, h )
	width, height = floor( w + .5 ), floor( h + .5 )
end

function render.getDimensions()
	return width, height
end

function render.setTarget( t )
	target = t or screen
	width, height = t.width, t.height
end

function render.getTarget()
	return target
end

function render.clear( value )
	value = value or 0

	for i = 1, width * height do
		target[i] = value
	end
end

function render.blit( x, y, values )
	local p = y * width + x
	for i = max( 1 - x, 1 ), min( #values, width - x ) do
		target[p + i] = values[i]
	end
end

function render.mapPoints( points, value )
	for i = 1, #points do
		target[points[i]] = value
	end
end

return render
