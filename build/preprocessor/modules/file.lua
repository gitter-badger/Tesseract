
local function isTrue( value )
	return value == true or value == "yes"
end

local module = {
	name = "file";
	instructions = {};
	processors = {};
	flags = {};
}

function module:init()
	self.environment["file-inline"] = true
	self.environment["file-compact"] = false
end

function module.instructions:include()
	local name = self:getidata "as" and self:getidata()
	local file = tostring( self:getidata() )
	local once = self:getidata "once"
	local path = self:resolvePath( file ) or self:resolvePath( file:gsub( "%.", "/" ) .. ".lua" )
	local inline = isTrue( self.environment["file-inline"] )
	local compact = isTrue( self.environment["file-compact"] )

	if once and self.environment["__INCLUDE_" .. file] then
		return
	end

	self.environment["__INCLUDE_" .. file] = true

	if path then

		local h = io.open( path )
		local content = h:read "*a"

		if inline and compact then
			content = content:gsub( "\n", " " )
		elseif inline and not compact then
			-- content = content
		elseif not inline and compact then
			content = "local __f, __err = (loadstring or load)(@using 'file_wrap_compact'" .. content .. "@done ," .. ("%q"):format( name or file ) .. ",nil,_ENV or getfenv())if not __f then error(__err,0)end if setfenv then setfenv(__f, getfenv())end " .. ( name and "local " .. name .. "=__f()" or "__f()" )
		elseif not inline and not compact then
			content = "local __f, __err = (loadstring or load)(@using 'file_wrap'" .. content .. "@done ," .. ("%q"):format( name or file ) .. ",nil,_ENV or getfenv())\nif not __f then error(__err,0)end if setfenv then setfenv(__f, getfenv())end " .. ( name and "local " .. name .. "=__f()" or "__f()" )
		end

		h:close()
		self.istream:write( content )
	else
		error( "cannot find file '" .. file .. "'", 0 )
	end
end

function module.instructions:findfile()
	local file = tostring( self:getidata() )
	local path = self:resolvePath( file ) or self:resolvePath( file:gsub( "%.", "/" ) .. ".lua" )

	self.environment["file-found"] = path
end

function module.processors:file_wrap( s )
	return ("%q"):format( s )
end

function module.processors:file_wrap_compact( s )
	return ("%q"):format( s ):gsub( "\\\n", "\\n" )
end

module.flags["inline"] = {
	"yes", "no", true, false
}

module.flags["compact"] = {
	"yes", "no", true, false
}

module.flags["include-once"] = {
	"yes", "no", true, false
}

return module
