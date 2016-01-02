
local fmt = require "compile.common" .fmt
local canHaveNewline = require "compile.common" .canHaveNewline
local stripBrackets = require "compile.common" .stripBrackets

local block = {}

function block.literal( ignore, value, application )
	local ret = "\t\t"

	if not ignore then
		ret = "\t\ttoken( " .. fmt( value ) .. ", lit" .. #application .. " )\n\t\t"
	end

	if application:find "\n" then
		ret = ret .. "position = position + " .. #application .. "\n\t\t"
				  .. "character = " .. #application:gsub( ".*\n", "" ) .. "\n\t\t"
				  .. "line = line + " .. select( 2, application:gsub( "\n", "a" ) )
	else
		ret = ret .. "__advbasic( " .. #application .. " )"
	end
	return ret
end

function block.pattern( ignore, value, application )
	if ignore then
		if canHaveNewline( application ) then
			return "\t\tposition = position + #text:match( " .. fmt( "^" .. stripBrackets( application ) ) .. ", position )\n\t\t__advcmplx()"
		else
			return "\t\t__advbasic( #text:match( " .. fmt( "^" .. stripBrackets( application ) ) .. ", position ) )"
		end
	else
		local ret = "\t\tlocal rawmatch = text:match( " .. fmt( "^" .. stripBrackets( application ) ) .. ", position )\n\t\t"

		if application:find "[%(%)]" then
			ret = ret .. "token( " .. fmt( value ) .. ", text:match( " .. fmt( "^" .. application ) .. ", position ) )\n\t\t"
		else
			ret = ret .. "token( " .. fmt( value ) .. ", rawmatch )\n\t\t"
		end

		if canHaveNewline( application ) then
			ret = ret .. "position = position + #rawmatch\n\t\t__advcmplx()"
		else
			ret = ret .. "__advbasic( #rawmatch )"
		end
		return ret
	end
end

function block.complex( isPattern, ignore, value, application )
	local ret = "\t\tlocal initialiser = " .. ( isPattern and "text:match( " .. fmt( "^" .. application ) .. ", position )" or "lit" .. #application )
			 .. "\n\t\tposition = position + "

	if isPattern then
		local stripped = stripBrackets( application )
		if stripped == application then
			ret = ret .. "#initialiser"
		else
			ret = ret .. "#text:match( " .. fmt( "^" .. stripped ) .. ", position )"
		end
	else
		ret = ret .. #application
	end

	return ret .. "\n\n\t\t" .. ( ignore and "" or table.concat( value, "\n\t\t" ) ) .. "\n\n\t\t__advcmplx()"
end

return block
