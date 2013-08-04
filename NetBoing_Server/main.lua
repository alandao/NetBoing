local socket = require "socket"
local HC = require 'lib.hardoncollider'
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 27105)

local world = {} -- the empty world-state
local ball
local data, msg_or_ip, port_or_nil
local entity, cmd, parms



function love.load()
	--initialize library
    Collider = HC(100, on_collide)

    ball        = Collider:addCircle(400,300, 10)
	ball.name = "ball"

    leftPaddle  = Collider:addRectangle(10,250, 20,100)
	leftPaddle.name = "leftPaddle"
	leftPaddle.touched = false
	
    rightPaddle = Collider:addRectangle(770,250, 20,100)
	rightPaddle.name = "rightPaddle"
	rightPaddle.touched = false

    ball.velocity = {x = -300, y = 0}

    borderTop    = Collider:addRectangle(0,-100, 800,100)
	borderTop.name = "borderTop"
	
    borderBottom = Collider:addRectangle(0,600, 800,100)
	borderBottom.name = "borderBottom"
	
    goalLeft     = Collider:addRectangle(-100,0, 100,600)
	goalLeft.name = "goalLeft"
	
    goalRight    = Collider:addRectangle(800,0, 100,600)
	goalRight.name = "goalRight"
	
	print "beginning server loop."
end

function love.update(dt)

	data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		-- more of these funky match patterns!
		entity, cmd, parms = data:match("^(%S*) (%S*) (.*)")
		
		if cmd == 'move' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y) -- validation is better, but asserts will serve.
			--don't forget, even if you matched a "number", the result is still a string!
			x, y = tonumber(x), tonumber(y)
			-- and finally we stash it away
			local ent = world[entity] or {x=0, y=0}
			world[entity] = {x= ent.x+x, y=ent.y + y}
		elseif cmd == 'leftpaddle_at' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y) -- vallidation is better, but asserts will serve.
			x, y = tonumber(x), tonumber(y)
			world[entity] = {x = x, y = y}
			leftPaddle:moveTo( x, y)
		elseif cmd == 'rightpaddle_at' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y) -- vallidation is better, but asserts will serve.
			x, y = tonumber(x), tonumber(y)
			world[entity] = {x = x, y = y}
			rightPaddle:moveTo( x, y)
			
		elseif cmd == 'update' then
			for k, v in pairs(world) do
				udp:sendto(string.format("%s %s %d %d", k, 'leftpaddle_at', v.x, v.y), msg_or_ip, port_or_nil)
				udp:sendto(string.format("%s %s %d %d", k, 'rightpaddle_at', v.x, v.y), msg_or_ip, port_or_nil)
			end
			local x, y = ball:center()
			udp:sendto(string.format("%s %s %d %d", "PLACEHOLDER", 'ball_at', x, y), msg_or_ip, port_or_nil)
			
		elseif cmd == 'quit' then
			running = false;
		else
			print("unrecognized command:", cmd)
		end
	elseif msg_or_ip ~= 'timeout' then
		error("unknown network error: "..tostring(msg))
	end
	
	socket.sleep(0.01)
	ball:move(ball.velocity.x * dt, ball.velocity.y * dt)
	Collider:update(dt)

end

function love.draw(dt)

end


function on_collide(dt, shape_a, shape_b)
    -- determine which shape is the ball and which is not
    local other
    if shape_a == ball then
        other = shape_b
    elseif shape_b == ball then
        other = shape_a
    else -- no shape is the ball. exit
        return
    end

    -- reset on goal
    if other == goalLeft then
        ball.velocity = {x = 300, y = 0}
        ball:moveTo(400,300)
		leftPaddle.touched = false
		rightPaddle.touched = false
    elseif other == goalRight then
        ball.velocity = {x = -300, y = 0}
        ball:moveTo(400,300)
		leftPaddle.touched = false
		rightPaddle.touched = false
    elseif other == borderTop or other == borderBottom then
    -- bounce off top and bottom
        ball.velocity.y = -ball.velocity.y
    elseif other == leftPaddle and leftPaddle.touched == false then
	 -- reflect the ball off the paddle
		local px,py = other:center()
		local bx,by = ball:center()
		ball.velocity.x = -ball.velocity.x
		ball.velocity.y = by - py
		
		-- keep the ball at the same speed as before
		local len = math.sqrt(ball.velocity.x^2 + ball.velocity.y^2)
		ball.velocity.x = (ball.velocity.x  / len * 300)
		ball.velocity.y = (ball.velocity.y  / len * 300)
		ball.velocity.x = ball.velocity.x * 1.5
		ball.velocity.y = ball.velocity.y * 1.5
		
		leftPaddle.touched = true
		rightPaddle.touched = false
	elseif other == rightPaddle and rightPaddle.touched == false then

	 -- reflect the ball off the paddle
		local px,py = other:center()
		local bx,by = ball:center()
		ball.velocity.x = -ball.velocity.x
		ball.velocity.y = by - py
		
		-- keep the ball at the same speed as before
		local len = math.sqrt(ball.velocity.x^2 + ball.velocity.y^2)
		ball.velocity.x = (ball.velocity.x  / len * 300)
		ball.velocity.y = (ball.velocity.y  / len * 300)
		ball.velocity.x = ball.velocity.x * 1.5
		ball.velocity.y = ball.velocity.y * 1.5
		
		leftPaddle.touched = false
		rightPaddle.touched = true
		
	else
		return
		
    end
    --[[text[#text+1] = string.format("%s hit %s", 
                                    shape_a.name, shape_b.name)]]
end



print "Thank you."