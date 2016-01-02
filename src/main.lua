
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
@include as primitive primitive
@include as canvas canvas

_G.transform = transform
_G.primitive = primitive
_G.canvas = canvas

@include as render render
_G.render = render

@include test

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
