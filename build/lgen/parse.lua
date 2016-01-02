
local function parse( tokens )
	local statements = {}
	local meta = {}
	local ignore = false
	local token = 1
	local EOF = {
		type = "EOF";
		value = "EOF";
		line = ( tokens[#tokens] or { line = 1 } ) .line;
		character = ( tokens[#tokens] or { character = 1 } ) .character;
		source = source;
	}
	local patterns = {}

	local function peek( n )
		return tokens[token + ( n or 0 )] or EOF
	end

	local function throw( err )
		error( peek().source .. " [" .. peek().line .. ", " .. peek().character .. "]: " .. tostring( err ), 0 )
	end

	local function next()
		local t = peek()
		token = token + 1
		return t
	end

	local function test( t, v, n )
		local token = peek( n )
		return token.type == t and ( v == nil or token.value == v ) and token
	end

	local function skip( t, v )
		if test( t, v ) then
			return next()
		end
	end

	local function push( type, applications, value )
		for i = 1, #applications do
			statements[#statements + 1] = {
				type = type;
				application = applications[i];
				value = value;
				ignore = ignore;
			}
		end
	end

	local function gettypename()
		if test "identifier" then
			return next().value
		else
			throw( "expected (identifier) typename, got " .. peek().type )
		end
	end

	local function getstr()
		if test "string" or test "identifier" then
			return next().value
		else
			throw( "expected string or identifier, got " .. peek().type )
		end
	end

	local function getstrlist()
		local list = { getstr() }
		while skip "comma" do
			list[#list + 1] = getstr()
		end
		return list
	end

	local function getcodelist()
		skip( "equals", ":" )
		local code = {}
		while test "tabbed_line" do
			code[#code + 1] = next().value
		end
		return code
	end

	local function parseLiteral()
		local applications = getstrlist()
		if ignore then
			if skip "equals" then
				return push( "literal", applications, gettypename() )
			end
			push( "literal", applications, "literal" )
		else
			if not skip "equals" then
				throw( "expected equals ('->', ':', '='), got " .. peek().type )
			end
			push( "literal", applications, gettypename() )
		end
	end

	local function parsePattern()
		local applications = getstrlist()
		if ignore then
			if skip "equals" then
				return push( "pattern", applications, gettypename() )
			end
			push( "pattern", applications, "pattern" )
		else
			if not skip "equals" then
				throw( "expected equals ('->', ':', '='), got " .. peek().type )
			end
			push( "pattern", applications, gettypename() )
		end
	end

	local function parseComplex()
		local applications = getstrlist()
		push( "complex", applications, getcodelist() )
	end

	local function parseMeta()
		local once = skip( "keyword", "once" )
		meta[#meta + 1] = {
			once = once;
			code = getcodelist();
		}
	end

	while not test "EOF" do
		ignore = false
		if skip( "keyword", "ignore" ) then
			ignore = true
		end

		if skip( "keyword", "lit" ) or skip( "keyword", "literal" ) then
			parseLiteral()
		elseif skip( "keyword", "pat" ) or skip( "keyword", "pattern" ) then
			parsePattern()
		elseif skip( "keyword", "complex" ) then
			parseComplex()
		elseif skip( "keyword", "meta" ) then
			parseMeta()
		else
			throw( "unexpected " .. peek().type .. " (" .. peek().value .. ")" )
		end
	end

	return statements, meta
end

return parse
