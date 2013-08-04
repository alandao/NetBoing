local socket = require "socket"

-- the address and port of the server
local address, port = "72.207.38.240", 27105

local entity -- entity is what we'll be controlling
local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update

local world = {} -- the empty world-state
local ball = {}
local t

function love.load()
	
	udp = socket.udp()
	--settimeout(0) makes it so game doesn't hang up until we receive data
	udp:settimeout(0)
	udp:setpeername(address, port)
	
	math.randomseed(os.time())
	entity = tostring(math.random(99999))
	
	local dg = string.format("%s %s %d %d", entity, 'rightpaddle_at', 800, 0)
	udp:send(dg) -- the magic line in question. sends 'dg' to server.
	
	ball.x, ball.y = 400,300
	
	--t is just a variable we use to help us with the update rate in love.update
	t = 0

end


function love.update(dt)
	t = t + dt -- increase t by the deltatime
	
	if t > updaterate then
		local x, y = 0, 0
		
		x, y = love.mouse.getPosition( )
		
		local dg = string.format("%s %s %f %f", entity, 'rightpaddle_at', 780, y)
		udp:send(dg)
		
		local dg = string.format("%s %s $", entity, 'update')
		udp:send(dg)
		
		t = t - updaterate -- set t for the next round
	end
	--repeat
	
	data, msg = udp:receive()
	
	if data then
		ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
		if cmd == 'rightpaddle_at' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y)
			x, y = tonumber(x), tonumber(y)
			world[ent] = {x=x, y=y}
		elseif cmd == 'leftpaddle_at' then
		
		elseif cmd == 'ball_at' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y)
			x, y = tonumber(x), tonumber(y)
			ball.x, ball.y = x, y
		
		else
			print("unrecognized command:", cmd)
		end
	elseif msg ~= 'timeout' then
		error("Network error: "..tostring(msg))
	end
	
	--until not data
	
end

function love.draw()
	for k, v in pairs(world) do
		love.graphics.print(k, v.x - 50, v.y - 20)
		love.graphics.rectangle("fill", v.x, v.y - 50, 20, 100)
	end
	
	love.graphics.rectangle("fill", ball.x, ball.y, 10, 10)
end

