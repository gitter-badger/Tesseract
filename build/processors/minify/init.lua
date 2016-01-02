
local minify

local module = {
	name = "minify";
	processors = {};
}

function module:init()
	os.loadAPI "processors/minify/minify.lua"
	minify = _G["minify.lua"]
end

function module.processors:minify( text )
	return minify.Rebuild.MinifyString( text )
end

return module
