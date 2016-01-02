
local lgen = require "lgen"

local function isTrue( v )
	return v == true or v == "yes"
end

local module = {
	name = "lgen";
	processors = {};
	flags = {};
	instructions = {};
}

function module:init()
	self:call "lgen_prep"
end

function module.instructions:lgen_prep()
	self.environment["lgen-as-function"] = true
	self.environment["lgen-global-function"] = false
	self.environment["lgen-function-name"] = "lex"
end

module.flags["as-function"] = {
	"yes", "no", true, false
}

module.flags["global-function"] = {
	"yes", "no", true, false
}

function module.processors:lgen( text )
	local asf = isTrue( self.environment["lgen-as-function"] )
	local isg = isTrue( self.environment["lgen-global-function"] )
	local fname = tostring( self.environment["lgen-function-name"] or "lex" ):gsub( "[^%w_]", "" )

	text = lgen.compile( text, "lexer-" .. fname )

	if asf then
		return (isg and "" or "local ") .. "function " .. fname .. "( text, source )\n\t" .. text:gsub( "\n", "\n\t" ) .. "\nend"
	else
		return text
	end
end

return module
