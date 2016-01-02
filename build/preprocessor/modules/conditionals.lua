
--[[
@if/ifn/ifdef/ifndef
	...
[@elif/elifn/elifdef/elifndef]*
	...
[@else]
	...
@endif
]]

local lookup = { "endif", "else", "elif", "elifdef", "elifn", "elifndef" }
for i = 1, #lookup do
	lookup[lookup[i]] = i
end

local function condition( self, instruction )
	local d = tostring( self:getidata() )

	if instruction == 1 then
		return self.environment[d]
	elseif instruction == 2 then
		return self.environment[d] ~= nil
	elseif instruction == 3 then
		return not self.environment[d]
	elseif instruction == 4 then
		return self.environment[d] == nil
	end
end

local function block( self, write )
	local m, d = self:fetch()
	local c = 1

	while true do
		if m == "instruction" and lookup[d] then
			if c == 1 then
				return lookup[d]
			elseif d == "endif" then
				c = c - 1
			end
		else
			if write then
				if m == "instruction" then
					self:call( d )
				else
					self:push( d )
				end
			elseif d == "if" or d == "ifn" or d == "ifdef" or d == "ifndef" then
				c = c + 1
			end
		end

		if self.istream:eof() then
			break
		end

		m, d = self:fetch()
	end
end

local function begin( self, instruction )
	local c = condition( self, instruction )
	local i = block( self, c )

	while i ~= 1 do
		if not i then
			error( "expected 'endif'" .. start, 0 )
		end

		if i == 2 then
			if block( self, not c ) ~= 1 then
				error( "expected 'endif' after 'else'", 0 )
			end
			return
		end

		if c then
			i = block( self, false )
		else
			c = condition( self, i - 2 )
			i = block( self, c )
		end
	end
end

local module = {
	name = "conditionals";
	instructions = {};
}

module.instructions["if"] = function( self )
	begin( self, 1 )
end

module.instructions["ifdef"] = function( self )
	begin( self, 2 )
end

module.instructions["ifn"] = function( self )
	begin( self, 3 )
end

module.instructions["ifndef"] = function( self )
	begin( self, 4 )
end

return module
