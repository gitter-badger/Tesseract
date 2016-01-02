
return function( text, source )
	local tokens = {}
	local line, character, position, oldposition = 1, 1, 1, 1
	
	local function token( type, value )
		tokens[#tokens + 1] = { type = type, value = value, source = source, line = line, character = character	}
	end
	
	local function __advbasic( n )
		character = character + n
		position = position + n
	end
	
	local function __advcmplx()
		local str = text:sub( oldposition, position - 1 )
		character = character + #str:gsub( ".+\n", "" )
		line = line + select( 2, str:gsub( "\n", "a" ) )
	end
	
	local function throw( err )
		return error( source .. "[" .. line .. ", " .. character .. "]: " .. tostring( err or "undefined exception" ), 0 )
	end
	
	local escape_characters = {
		["n"] = "\n";
		["0"] = "\0";
		["r"] = "\r";
		["t"] = "\t";
	}
	
	while position <= #text do
		local lit6, lit4, lit3, lit7, lit1, lit2 = text:sub( position, position + 5 ), text:sub( position, position + 3 ), text:sub( position, position + 2 ), text:sub( position, position + 6 ), text:sub( position, position + 0 ), text:sub( position, position + 1 )
		oldposition = position
	
		if text:find( "^\9(.-)\n", position ) then -- tabbed_line ( "\9(.-)\n" )
			local rawmatch = text:match( "^\9.-\n", position )
			token( "tabbed_line", text:match( "^\9(.-)\n", position ) )
			position = position + #rawmatch
			__advcmplx()
	
		elseif text:find( "^\9(.-)$", position ) then -- tabbed_line ( "\9(.-)$" )
			local rawmatch = text:match( "^\9.-$", position )
			token( "tabbed_line", text:match( "^\9(.-)$", position ) )
			position = position + #rawmatch
			__advcmplx()
	
		elseif text:find( "^//.-\n", position ) then -- ignored pattern ( "//.-\n" )
			position = position + #text:match( "^//.-\n", position )
			__advcmplx()
	
		elseif text:find( "^//.-$", position ) then -- ignored pattern ( "//.-$" )
			position = position + #text:match( "^//.-$", position )
			__advcmplx()
	
		elseif lit7 == "pattern" or lit7 == "complex" or lit7 == "literal" then -- keyword ( "pattern", "complex", "literal" )
			token( "keyword", lit7 )
			__advbasic( 7 )
	
		elseif lit6 == "ignore" then -- keyword ( "ignore" )
			token( "keyword", lit6 )
			__advbasic( 6 )
	
		elseif lit4 == "meta" or lit4 == "once" then -- keyword ( "meta", "once" )
			token( "keyword", lit4 )
			__advbasic( 4 )
	
		elseif lit3 == "pat" or lit3 == "lit" then -- keyword ( "pat", "lit" )
			token( "keyword", lit3 )
			__advbasic( 3 )
	
		elseif lit2 == "->" then -- equals ( "->" )
			token( "equals", lit2 )
			__advbasic( 2 )
	
		elseif lit1 == "=" or lit1 == ":" then -- equals ( "=", ":" )
			token( "equals", lit1 )
			__advbasic( 1 )
	
		elseif lit1 == "," then -- comma ( "," )
			token( "comma", lit1 )
			__advbasic( 1 )
	
		elseif text:find( "^[%w_]+", position ) then -- identifier ( "[%w_]+" )
			local rawmatch = text:match( "^[%w_]+", position )
			token( "identifier", rawmatch )
			__advbasic( #rawmatch )
	
		elseif text:find( "^[\"']", position ) then -- complex ( "[\"']" )
			local initialiser = text:match( "^[\"']", position )
			position = position + #initialiser
	
			local escaped = false
			local done = false
			local s = {}
			for i = position, #text do
				local char = text:sub( i, i )
				if escaped then
					s[#s + 1] = escape_characters[char] or char
					escaped = false
				elseif char == "\\" then
					escaped = true
				elseif char == initialiser then
					token( "string", table.concat( s ) )
					position = i + 1
					done = true
					break
				else
					s[#s + 1] = char
				end
			end
			if not done then
				throw "end of string not found"
			end
	
			__advcmplx()
	
		else
			position = position + 1
			if ( lit1 or text:sub( position, position ) ) == "\n" then
				line, character = line + 1, 1
			else
				character = character + 1
			end
		end
	end
	
	return tokens
end
