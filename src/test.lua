
local width, height = term.getSize()

render.clear( "f" )

local n = 1
local c = { "0", "1", "2", "3", "4", "5", "6", "7" }

for i = 1, #c do
	transform.add( transform.translate( 51, 18 ) )
	render.mapPoints( primitive.rectangle( 0, 0, 5, 5 ), c[i] )
	transform.pop()
	transform.add( transform.rotate( i * math.pi / 4 - math.pi ) )
	transform.add( transform.scale( 1 + i / 2, 1 + i / 3 ) )
end

local function draw()

	local target = render.getTarget()
	local n = 1

	for y = 1, target.height do

		local blank = (" "):rep( target.width )
		local t = {}

		for x = 1, target.width do
			t[x] = target[n]
			n = n + 1
		end

		term.setCursorPos( 1, y )
		term.blit( blank, blank, table.concat( t ) )
	end
end

draw()
