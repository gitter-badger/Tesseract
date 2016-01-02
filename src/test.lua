
local width, height = term.getSize()
local r = 0

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

while os.pullEvent() ~= "mouse_click" do
	render.clear "0"
	r = r + math.pi / 64
	transform.pop()
	transform.add( transform.rotate( r ) )
	transform.add( transform.scale( 2, 2 ) )
	transform.add( transform.translate( 51, 10 ) )
	render.mapPoints( primitive.rectangle( 0, 0, 10, 10, 10, 0 ), "b" )
	transform.add( transform.translate( -51, -10 ) )
	transform.add( transform.scale( .5, .5 ) )
	transform.add( transform.translate( 51, 10 ) )
	render.mapPoints( primitive.rectangle( 0, 0, 10, 10, 10, 0 ), "e" )
	transform.pop()
	transform.add( transform.translate( 5, 0 ) )
	transform.add( transform.rotate( r ) )
	transform.add( transform.scale( 1.4, 1 ) )
	transform.add( transform.translate( 20, 20 ) )
	render.mapPoints( primitive.circle( 0, 0, 10 ), "9" )
	draw()
end
