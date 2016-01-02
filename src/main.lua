
@if MINIFY
  @using minify
@endif

@ifn API
@if LUA51
local env = setmetatable( {}, { __index = getfenv() } )
env._G = env
local function __f()
@else
local env = setmetatable( {}, { __index = _ENV } )
env._G = env
local function __f()
	_ENV = env
@endif
@endif

@flag file-inline false
@include as transform transform
@include as render render

_G.transform = transform
_G.render = render

local screen = {}
local width, height = term.getSize()

render.setDimensions( width, height )

local function reset()
	for i = 1, width * height do
		screen[i] = 0
	end
end

local function shape( pixels )
	for i = 1, #pixels do
		screen[pixels[i]] = 1
	end
end

local function box()
	shape( render.box( 0, 0, 10, 10 ) )
end

local function tri()
	shape( render.triangle( 0, 0, 10, 0, 5, 10 ) )
end

local function lines()
	shape( render.line( 0, 0, 10, 0 ) )
	shape( render.line( 10, 0, 10, 10 ) )
	shape( render.line( 0, 10, 10, 10 ) )
	shape( render.line( 0, 0, 0, 10 ) )
end

local function draw()
	local p = 1
	local blank = (" "):rep( width )

	for y = 1, height do
		local t = {}

		for x = 1, width do
			t[x] = screen[p] == 1 and "b" or "0"
			p = p + 1
		end

		term.setCursorPos( 1, y )
		term.blit( blank, blank, table.concat( t ) )
	end
end

local n = 0

os.startTimer( .1 )

while true do
	reset()

	transform.push()
	transform.add( transform.rotate( n ) )
	transform.add( transform.translate( 50, 17 ) )
	box()
	-- lines()
	transform.pop()

	draw()
	local ev = os.pullEvent()
	if ev == "key" or ev == "char" then
		break
	elseif ev == "timer" then
		os.startTimer( .1 )
		n = n + math.pi / 16
	end
end

@ifn API
end
@if LUA51
setfenv(__f, env)
@endif
__f()
local l = {}
for k, v in pairs( env ) do
	l[k] = v
end
return l
@endif

@if MINIFY
  @done
@endif
