
local path = (... or "lgen"):gsub( "/init%.lua$", "", 1 )
local l, d = {}, {}

local env = setmetatable( {}, { __index = _ENV or getfenv() } )

local function require( file )
	if l[file] then return d[file] end
	l[file] = true

	local h = io.open( path .. "/" .. file:gsub( "%.", "/" ) .. ".lua" ) or io.open( path .. "/" .. file:gsub( "%.", "/" ) .. "/init.lua" )
	if h then
		local content = h:read "*a"
		local f, err = (loadstring or load)( content, file, nil, env )

		h:close()

		if f and setfenv then setfenv( f, env ) end
		if not f then error( err, 0 ) end

		d[file] = f()
		return d[file]
	else
		return error( "cannot find file '" .. file .. "'" )
	end
end

env.require = require

local lex = require "lex"
local parse = require "parse"
local compile = require "compile"
local errmsg = [[
This shouldn't happen: a syntax error has been found in the generated lexer:

%s

Please submit this as an issue on the GitHub repo.]]

local lgen = {}

function lgen.compile( str, src )
	local statements, meta = parse( lex( str, src or "string" ) )

	if #statements == 0 then
		return "return {}"
	end

	local s = compile( statements, meta )
	local f, err = loadstring( s, src )

	if not f then error( errmsg:format( err ), 0 ) end

	return s
end

function lgen.compileAsFunction( str, src )
	return "local function lex( text, source )\n\t" .. lgen.compile( str, src ):gsub( "\n", "\n\t" ) .. "\nend"
end

function lgen.generate( str, src )
	return loadstring( lgen.compileAsFunction( str, src ) .. "\nreturn lex" )()
end

return lgen
