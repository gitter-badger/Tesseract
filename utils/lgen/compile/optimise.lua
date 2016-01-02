
local canHaveNewline = require "compile.common" .canHaveNewline

local function sorter( a, b )
	return #a.application > #b.application or ( #a.application == #b.application and a.value > b.value )
end

local function hasSpecialCharacters( str )
	return str:find "[%%%^%$%.%-%+%*%?%(%)]" or str:find "%[" or str:find "%]"
end

local function convertPlainPatterns( statements )
	for i = 1, #statements do
		if statements[i].type == "pattern" and not hasSpecialCharacters( statements[i].application ) then
			statements[i].type = "literal"
		end
	end
end

local function sortLiterals( statements )
	local n = 0
	local litn = {}
	local litnc = {}

	local function reg( n )
		if not litnc[n] then litn[#litn + 1] = n; litnc[n] = true end
	end

	while n < #statements do
		n = n + 1

		if statements[n].type == "literal" then

			local finish = #statements
			local copy = {}

			statements[n].hasLiteralApplication = true
			reg( #statements[n].application )

			for i = n + 1, #statements do
				if statements[i].type ~= "literal" then
					finish = i - 1
					break
				end
				
				statements[i].hasLiteralApplication = true

				-- table containing the lengths of all the literals
				reg( #statements[i].application )
			end

			for i = n, finish do
				copy[i - n + 1] = statements[i]
			end

			table.sort( copy, sorter )

			for i = 1, #copy do
				statements[i + n - 1] = copy[i]
			end

			n = finish

		elseif statements[n].type == "complex" and not hasSpecialCharacters( statements[n].application ) then

			reg( #statements[i].application )
			statements[n].hasLiteralApplication = true

		else
			statements[n].hasLiteralApplication = false

		end
	end

	return litn
end

local function optimise( statements )
	local stato = {}
	local litn = {}
	local i = 1
	local options = {
		needs_throw_header = false;
		needs_advcmplx_header = false;
	}

	convertPlainPatterns( statements )
	litn = sortLiterals( statements )

	local function literals()
		local c = 1
		local applications = { statements[i].application }

		while statements[i + c] and statements[i + c].hasLiteralApplication and statements[i].value == statements[i + c].value and #statements[i].application == #statements[i + c].application do
			applications[c + 1] = statements[i + c].application
			c = c + 1
		end

		stato[#stato + 1] = {
			type = statements[i].type;
			application = applications;
			value = statements[i].value;
			ignore = statements[i].ignore;
			hasLiteralApplication = true;
		}

		i = i + c
	end

	while i <= #statements do
		if statements[i].type == "complex" then
			options.needs_throw_header = true
		end

		if statements[i].hasLiteralApplication then
			literals()
		else
			if statements[i].type == "complex" or canHaveNewline( statements[i].application ) then
				options.needs_advcmplx_header = true
			end
			stato[#stato + 1] = statements[i]
			i = i + 1
		end
	end

	return stato, litn, options
end

return optimise
