
local literalblock = require "compile.block" .literal
local patternblock = require "compile.block" .pattern
local complexblock = require "compile.block" .complex
local literalcondition = require "compile.condition" .literal
local patterncondition = require "compile.condition" .pattern
local optimise = require "compile.optimise"
local fmt = require "compile.common" .fmt

local LIT_LOOKUP_COUNT = 4

local footer = [[

	else
		position = position + 1
		if ( lit1 or text:sub( position, position ) ) == "\n" then
			line, character = line + 1, 1
		else
			character = character + 1
		end
	end
end

return tokens]]

local header = [[
source = source or "string"

local tokens = {}
local line, character, position, oldposition = 1, 1, 1, 1

local function token( type, value )
	tokens[#tokens + 1] = { type = type, value = value, source = source, line = line, character = character	}
end

local function __advbasic( n )
	character = character + n
	position = position + n
end
]]

local advcmplx_header = [[

local function __advcmplx()
	local str = text:sub( oldposition, position - 1 )
	character = character + #str:gsub( ".+\n", "" )
	line = line + select( 2, str:gsub( "\n", "a" ) )
end
]]

local throw_header = [[

local function throw( err )
	return error( source .. " [" .. line .. ", " .. character .. "]: " .. tostring( err or "undefined exception" ), 0 )
end
]]

local function sortMeta( meta )
	local meta_once, meta_loop = {}, {}

	for i = 1, #meta do
		if meta[i].once then
			meta_once[#meta_once + 1] = meta[i].code
		else
			meta_loop[#meta_loop + 1] = "\t" .. meta[i].code
		end
	end

	return meta_once, meta_loop
end

local function compileStatements( stato, meta_once )
	local statc = {}
	local litlookuptn = 0
	local comment, condition

	for i = 1, #stato do

		local ignore, value, application = stato[i].ignore, stato[i].value, stato[i].application

		if stato[i].hasLiteralApplication then

			comment = ( ignore and "ignored " or "" )
				   .. ( stato[i].type == "complex" and "complex" or value )
				   .. " ( " .. fmt( ( application[1] ) )

			for n = 2, #application do
				comment = comment .. ", " .. fmt( application[n] )
			end

			comment = comment .. " )"

			if #application >= LIT_LOOKUP_COUNT then

				local t = "{ [" .. fmt( application[1] ) .. "] = true"

				for n = 2, #stato[i].application do
					t = t .. ", [" .. fmt( application[n] ) .. "] = true"
				end

				litlookuptn = litlookuptn + 1
				meta_once[#meta_once + 1] = { "local __litlookupt" .. litlookuptn .. " = " .. t .. " }" }

				condition = "__litlookupt[lit" .. #application[1] .. "]"

			else

				local t = {}

				for n = 1, #application do
					t[n] = literalcondition( application[n] )
				end

				condition = table.concat( t, " or " )

			end

			statc[#statc + 1] = {
				condition = condition;
				block = stato[i].type == "complex" and complexblock( false, ignore, value, application[1] ) or literalblock( ignore, value, application[1] );
				comment = comment;
			}

		else

			comment = ( stato[i].ignore and "ignored " or "" )
				   .. ( stato[i].type == "complex" and "complex" or stato[i].value )
				   .. " ( " .. fmt( stato[i].application ) .. " )"

			statc[#statc + 1] = {
				condition = patterncondition( stato[i].application );
				block = stato[i].type == "complex" and complexblock( true, ignore, value, application ) or patternblock( ignore, value, application );
				comment = comment;
			}

		end
	end

	return statc
end

local function compileMeta( meta_once, meta_loop )
	if #meta_once == 0 then return "", meta_loop and compileMeta( meta_loop ) end

	local spacing = meta_loop and "\n" or "\n\t"
	for i = 1, #meta_once do
		meta_once[i] = spacing .. table.concat( meta_once[i], spacing )
	end

	return table.concat( meta_once, spacing ), meta_loop and compileMeta( meta_loop )
end

local function compile( statements, meta )
	local stato, litn, options = optimise( statements )
	local comp, meta_once, meta_loop = "", sortMeta( meta )
	local statc = compileStatements( stato, meta_once )

	if #litn > 0 then
		local s = "local lit" .. litn[1]

		for i = 2, #litn do
			s = s .. ", lit" .. litn[i]
		end

		s = s .. " = text:sub( position, position + " .. litn[1] - 1 .. " )"

		for i = 2, #litn do
			s = s .. ", text:sub( position, position + " .. litn[i] - 1 .. " )"
		end

		meta_loop[#meta_loop + 1] = { s }
	end

	local metac_once, metac_loop = compileMeta( meta_once, meta_loop )

	comp = comp .. header .. ( options.needs_advcmplx_header and advcmplx_header or "" ) .. ( options.needs_throw_header and throw_header or "" )
	comp = comp .. metac_once .. "\n\nwhile position <= #text do" .. metac_loop
		.. "\n\toldposition = position\n\n\tif " .. statc[1].condition .. " then -- " .. statc[1].comment .. "\n" .. statc[1].block .. "\n"

	for i = 2, #statc do
		comp = comp .. "\n\telseif " .. statc[i].condition .. " then -- " .. statc[i].comment .. "\n" .. statc[i].block .. "\n"
	end

	return comp .. footer
end

return compile
