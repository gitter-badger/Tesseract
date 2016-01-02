
local function fmt( str )
	if not str then error( "here", 2 ) end
	return ("%q"):format( str ):gsub( "\\\n", "\\n" )
end

local function canHaveNewline( str )
	return str:find "[\n%.]" or str:find "%%[s%u]" or str:find "%[%^"
end

local function stripBrackets( str )
	local s, f = str:find "[%(%)]"
	while s do
		local escapes = str:sub( 1, s - 1 ):match "%%+$"
		if not escapes or #escapes % 2 == 0 then
			str = str:sub( 1, s - 1 ) .. str:sub( f + 1 )
			s, f = str:find( "[%(%)]", f )
		else
			s, f = str:find( "[%(%)]", f + 1 )
		end
	end
	return str
end

return {
	fmt = fmt;
	canHaveNewline = canHaveNewline;
	stripBrackets = stripBrackets;
}
