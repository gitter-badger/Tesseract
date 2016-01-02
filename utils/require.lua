
PATH = "/"

local loaded = {}
local result = {}

function _G.require( name )
	if loaded[name] then
		return result[name]
	end
	loaded[name] = true

	for path in PATH:gmatch "[^;]+" do
		local file = path .. "/" .. name:gsub( "%.", "/" )
		if fs.isDir( file ) then
			file = file .. "/init"
		end
		
		if fs.exists( file .. ".lua" ) and not fs.isDir( file .. ".lua" ) then
			local h = fs.open( file .. ".lua", "r" )
			local env = getfenv and getfenv() or _ENV
			local f, err = ( load or loadstring )( h.readAll(), name, nil, env )

			if setfenv then setfenv( f, env ) end

			h.close()

			result[name] = f( file .. ".lua" )
			return result[name]
		end
	end

	loaded[name] = false
	error( "Could not find file '" .. name .. "'", 2 )
end
