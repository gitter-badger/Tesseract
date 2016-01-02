
local stream = {
	text = "";
	position = 1;
}

function stream:new( ... )
	local s = setmetatable( {}, { __index = self } )
	s:init( ... )
	return s
end

function stream:init( text )
	self.text = tostring( text or "" )
end

function stream:write( text )
	self.text = self.text:sub( 1, self.position - 1 ) .. text .. self.text:sub( self.position )
	return text
end

function stream:read()
	return self.text:sub( self.position )
end

function stream:advance( n )
	self.position = self.position + (n or 1)
end

function stream:eof()
	return self.position > #self.text
end

setmetatable( stream, { __call = stream.new } )

local identifier = "[%w_%-%./]+"

local escape_characters = {
	["n"] = "\n";
	["r"] = "\r";
	["0"] = "\0";
	["t"] = "\t";
}

local function isFile( path )
	local h = io.open( path )
	if h then
		h:close()
		return true
	end
end

local function str( text, environment )
	local length, close, str = #( text:match( "^[^\n%S]+" ) or "" )

	close = text:sub( length + 1, length + 1 )
	str = ""

	if close == "'" or close == "\"" then

		local escaped, char = false, ""

		for i = length + 2, #text do
			char = text:sub( i, i )

			if escaped then
				str = str .. ( escape_characters[char] or char )
				escaped = false
			elseif char == "\\" then
				escaped = true
			elseif char == close then
				length = i
				break
			else
				str = str .. char
			end
		end

	else

		str = text:match( "^%$?" .. identifier, length + 1 ) or ""
		length = length + #str

	end

	local function varname( v )
		return tostring( environment[v] )
	end

	str = str:gsub( "$(" .. identifier .. ")", varname )
			 :gsub( "$%((" .. identifier .. ")%)", varname )

	if str == "true" or str == "false" then
		return str == "true", length
	elseif tonumber( str ) then
		return tonumber( str ), length
	end

	return str, length
end

local preprocessor = {}

function preprocessor:new( ... )
	local p = setmetatable( {}, { __index = self } )
	p:init( ... )
	return p
end

function preprocessor:init( path )
	self.istream = stream ""
	self.ostream = stream ""
	self.block = {}

	self.environment = { _PATH = tostring( path or "" ) .. ";preprocessor/modules", ["true"] = true, ["false"] = false }
	self.macros = {}
	self.processor_stack = {}

	self.modules = {}
	self.module_processors = {}
	self.module_flags = {}
	self.module_instructions = {}

	local h = io.open "preprocessor/modules/core.lua"
	if h then
		local f, err = (loadstring or load)(h:read "*a", "core", nil, _ENV)
		if f and setfenv then setfenv(f, getfenv()) end
		if f then self:load( f() or {} ) end
	end
end

function preprocessor:getPath()
	return tostring( self.environment._PATH )
end

function preprocessor:setPath( path )
	self.environment._PATH = path
end

function preprocessor:resolvePath( file )
	for path in self:getPath():gmatch "[^;]+" do

		if isFile( path .. "/" .. file ) then
			return path .. "/" .. file
		elseif isFile( path .. "/" .. file .. ".lua" ) then
			return path .. "/" .. file .. ".lua"
		elseif isFile( path .. "/" .. file .. "/init.lua" ) then
			return path .. "/" .. file .. "/init.lua"
		end

	end
end

function preprocessor:push( text ) -- pushes text onto the stack (not yet processed)
	self.block[#self.block + 1] = text
end

function preprocessor:pushProcessor( p ) -- pushes a processor to the stack
	self.processor_stack[#self.processor_stack + 1] = { processor = p, index = #self.block }
end

function preprocessor:popProcessor() -- pops a processor from the stack
	if not self.processor_stack[1] then return end

	local processor = self.processor_stack[#self.processor_stack].processor
	local index = self.processor_stack[#self.processor_stack].index
	local text = {}

	for i = 1, #self.block - index do
		text[i] = self.block[index + i]
		self.block[index + i] = nil
	end

	self.block[index + 1] = tostring( processor( self, table.concat( text ) ) )
	self.processor_stack[#self.processor_stack] = nil
end

function preprocessor:fetch() -- fetches an instruction or text
	local stream = self.istream:read()
	if stream:find "^@%s*[%w_]+" then
		local prefix, instruction = stream:match "^(@[^%S\n]*)([%w_]+)"

		self.istream:advance( #instruction + #prefix )

		if stream:find "^[^%S\n]" then
			self.istream:advance( #stream:match "^[^%S\n]+" )
		end

		return "instruction", instruction

	else
		local s = stream:match( "^[^%s@]+", self.position ) or stream:sub( 1, 1 )
		self.istream:advance( #s )
		return "text", s
	end
end

function preprocessor:getidata( label ) -- gets data following an instruction
	local stream = self.istream:read()

	if label then
		local match = stream:match( "^[^%S\n]*" .. label )

		if match then
			self.istream:advance( #match )
			return label
		else
			return nil
		end
	else
		local text, length = str( stream, self.environment )
		self.istream:advance( length )
		return text

	end
end

function preprocessor:call( i ) -- calls an instruction named 'i'
	if self.module_instructions[i] then
		return self.module_instructions[i]( self )
	else
		error( "no such instruction '" .. i .. "'", 0 )
	end
end

function preprocessor:build()
	while not self.istream:eof() do
		local m, d = self:fetch()
		if m == "instruction" then
			self:call( d )
		else
			self:push( d )
		end
	end
	self:finalise_block()
	return self.ostream.text
end

function preprocessor:finalise_block()
	while self.processor_stack[1] do
		self:popProcessor()
	end

	local text = table.concat( self.block )

	local k, v = next( self.macros )
	while k do
		text = text:gsub( k, v )
		k, v = next( self.macros, k )
	end

	self.block = {}
	self.ostream:write( text )
	self.ostream:advance( #text )
end

function preprocessor:setFlag( flag, value )
	if self.module_flags[flag] then
		if self.module_flags[flag][value] then
			self.environment[flag] = value
		else
			return error( "flag '" .. flag .. "' cannot take value '" .. tostring(value) .. "'", 0 )
		end
	else
		return error( "no such flag '" .. flag .. "'", 0 )
	end
end

function preprocessor:load( module )

	local name = module.name or "module"
	local processors = module.processors or {}
	local flags = module.flags or {}
	local instructions = module.instructions or {}

	if self.modules[name] then
		return
	else
		self.modules[name] = true
	end

	for k, v in pairs( processors ) do
		self.module_processors[k] = v
	end

	for k, v in pairs( instructions ) do
		self.module_instructions[k] = v
	end

	for k, v in pairs( flags ) do
		local t = {}

		for i = 1, #v do
			t[v[i]] = true
		end

		self.module_flags[name .. "-" .. k] = t
	end

	if module.init then
		module.init( self )
	end

end

return setmetatable( preprocessor, { __call = preprocessor.new } )
