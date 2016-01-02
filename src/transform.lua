
local transform = {}
local stack = {}

local sin, cos = math.sin, math.cos
local unpack = table.unpack or unpack

function transform.add( t )
	local a, b, c, d, e, f, g, h, i = unpack( t )
	local j, k, l, m, n, o, p, q, r = unpack( stack[#stack] )

	stack[#stack] = {
		a*j + b*m + c*p, a*k + b*n + c*q, a*l + b*o + c*r;
		d*j + e*m + f*p, d*k + e*n + f*q, d*l + e*o + f*r;
		g*j + h*m + i*p, g*k + h*n + i*q, g*l + h*o + i*r;
	}
end

function transform.push( t )
	stack[#stack + 1] = t or {
		1, 0, 0;
		0, 1, 0;
		0, 0, 1;
	}
end

function transform.pop()
	local v = stack[#stack]

	stack[#stack] = nil

	if #stack == 0 then
		transform.push()
	end

	return v
end

function transform.translate( x, y )
	return {
		1, 0, x;
		0, 1, y;
		0, 0, 1;
	}
end

function transform.scale( x, y )
	return {
		x, 0, 0;
		0, y, 0;
		0, 0, 1;
	}
end

function transform.rotate( a )
	local s, c = sin(a), cos(a)
	return {
		 c, -s, 0;
		 s,  c, 0;
		 0,  0, 1;
	}
end

function transform.shear( x, y )
	return {
		1, x, 0;
		y, 1, 0;
		0, 0, 1;
	}
end

function transform.transform( x, y )
	local t = { x, y, 1 }

	for i = 1, #stack do
		local a, b, c,
			  d, e, f,
			  g, h, i  = unpack( stack[i] )

		local x, y, z = t[1], t[2], t[3]
		
		t = {
			x*a + y*b + z*c;
			x*d + y*e + z*f;
			x*g + y*h + z*i;
		}
	end

	return t[1], t[2]
end

transform.push()

return setmetatable( transform, { __call = function( _, ... ) return transform.transform( ... ) end } )
