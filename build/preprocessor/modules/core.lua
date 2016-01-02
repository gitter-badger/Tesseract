
local logblanked = false

local module = {
	name = "core";
	instructions = {};
	processors = {};
}

function module:init()
	logblanked = false
end

function module.instructions:print()
	print( self:getidata() )
end

function module.instructions:log()
	local h = io.open( self:getPath():gsub( ";.*$", "" ) .. "/log.txt", logblanked and "a" or "w" )

	if h then
		h:write( self:getidata() .. "\n" )
		h:close()
	else
		self:getidata()
	end
end

function module.instructions:error()
	local err = tostring( self:getidata() )
	local h = io.open( self:getPath():gsub( ";.*$", "" ) .. "/log.txt", logblanked and "a" or "w" )
	if h then
		h:write( "ERROR: " .. err )
		h:close()
	end
	error( err, 0 )
end

function module.instructions:echo()
	self:push( self:getidata() )
end

function module.instructions:flag()
	local name = self:getidata()
	self:setFlag( name, self:getidata() )
end

function module.instructions:define()
	local name = tostring( self:getidata() )
	local data = tostring( self:getidata() )

	if self.environment[name] == nil then
		self.environment[name] = data
		self.macros["([^%w_%-%./])" .. name .. "([^%w_%-%./])"] = "%1" .. data .. "%2"
		self.macros["^" .. name .. "([^%w_%-%./])"] = data .. "%1"
		self.macros["([^%w_%-%./])" .. name .. "$"] = "%1" .. data
		self.macros["^" .. name .. "$"] = data
	end
end

function module.instructions:set()
	local index = self:getidata()
	self.environment[index] = self:getidata()
end

function module.instructions:undef()
	self.environment[self:getidata()] = nil
end

function module.instructions:using()
	local name = tostring( self:getidata() )

	if name == "nothing" then
		self:finalise_block()
		self.processor_stack = {}
	elseif self.module_processors[name] then
		self:pushProcessor( self.module_processors[name] )
	else
		error( "no such processor '" .. name .. "'", 0 )
	end
end

function module.instructions:done()
	self:popProcessor()
end

function module.instructions:load()
	local name = tostring( self:getidata() )

	if self.modules[name] then
		return
	end

	local path = self:resolvePath( name ) or self:resolvePath( name:gsub( "%.", "/" ) )

	if path then
		local h = io.open( path )
		local content = h:read "*a"

		h:close()

		local f, err = (loadstring or load)( content, name, nil, _ENV )
		if f and setfenv then
			setfenv( f, getfenv() )
		elseif not f then
			return error( err, 0 )
		end

		self:load( f() or { name = name } )
	else
		return error( "no such module '" .. name .. "'", 0 )
	end
end

function module.processors:text( s )
	return ("local %s = %q"):format( tostring( self.environment["text-varname"] or "__text" ), s )
end

function module.processors:comment( s )
	return " -- " .. s:gsub( "^%s+", "" ):gsub( "%s+$", "" ):gsub( "\n", "\n %-%- " )
end

return module
