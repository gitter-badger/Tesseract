
local fmt = require "compile.common" .fmt

local condition = {}

function condition.literal( literal )
	return "lit" .. #literal .. " == " .. fmt( literal )
end

function condition.pattern( pattern )
	return "text:find( " .. fmt( "^" .. pattern ) .. ", position )"
end

return condition
