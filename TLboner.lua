-- TLboner v1.0b2, a powerful skeleton-based object and tweening animation system
-- by Taehl (SelfMadeSpirit@gmail.com)

TLboner = {}		-- namespace


local function lerp(a,b,t) return a+(b-a)*t end
local draw,color,cos,sin,min,max = love.graphics.draw, love.graphics.setColor, math.cos, math.sin, math.min, math.max


-- Draw an animated boner
function TLboner.draw(o, x,y, a, dt, ...)
	assert(o, "You must specify a boner to draw.")
	x,y,a,dt = x or 0, y or 0, a or 0, dt or love.timer.getDelta()
	local emptyFrame = {a=0}
	local cR,cG,cB,cA = love.graphics.getColor()
	
	-- drawing function uses recursion for fastest speed and lowest memory usage
	local function drawBoner(o, tx,ty, ta, anim, frameA,frameB, t, frameChange, ...)
		if o.anim then	-- determine animation state, frame pairs, and tween timing (rather laboriously, to be honest)
			anim = o.anim
			anim.t = anim.t + dt * anim.d.r * anim.r
			local nFrames = #anim.d
			f,t = math.modf( anim.t + 1 )
			if t<0 then f,t = f-1,1+t end		-- fixes looping and tweening if time is going backwards
			
			if type(anim.d.loop)=="table" and f >= nFrames then	-- if an animation flows into another animation
				if f == nFrames then		-- if transitioning
					frameA, frameB = anim.d[f], anim.d.loop[(f-nFrames)%nFrames+1]
				else						-- if the old animation is completely done
					f = f - nFrames
					o.anim.t, o.anim.d = t, anim.d.loop
					frameA, frameB = anim.d[f], anim.d[f%nFrames+1]
				end
			else						-- regular animation
				if not anim.d.loop then		-- non-looping animation
					f = min(f, nFrames)
					frameA, frameB = anim.d[f], anim.d[min(f+1, nFrames)]
				else						-- looping animation
					f = (f-1) % nFrames + 1
					frameA, frameB = anim.d[f], anim.d[f%nFrames+1]
				end
			end
			frameChange, anim.f = anim.f ~= f, f	-- detect when changing frames (so pose functions get called only once)
		else frameA, frameB = frameA or emptyFrame, frameB or emptyFrame	-- in case an animation is missing parts, don't crash
		end
		
		o.a = lerp(frameA.a or o.a or 0, frameB.a or o.a or 0, t)			-- bone angle (always tweened)
		ta,tx,ty = ta+o.a, tx+(o.x or 0), ty+(o.y or 0)		-- add bone's angle and offsets to the running total
		if anim.d.advanced then		-- advanced mode enables animation for all numeric properties, but is a little slower
			o.l = lerp(frameA.l or o.l or 0, frameB.l or o.l or 0, t)		-- bone length
			o.x = lerp(frameA.x or o.x or 0, frameB.x or o.x or 0, t)		-- bone relative x position
			o.y = lerp(frameA.y or o.y or 0, frameB.y or o.y or 0, t)		-- bone relative y position
			o.oa = lerp(frameA.oa or o.oa or 0, frameB.oa or o.oa or 0, t)	-- graphic angle offset
			o.ox = lerp(frameA.ox or o.ox or 0, frameB.ox or o.ox or 0, t)	-- graphic x offset
			o.oy = lerp(frameA.oy or o.oy or 0, frameB.oy or o.oy or 0, t)	-- graphic y offset
			o.sx = lerp(frameA.sx or o.sx or 1, frameB.sx or o.sx or 1, t)	-- graphic x scale
			o.sy = lerp(frameA.sy or o.sy or 1, frameB.sy or o.sy or 1, t)	-- graphic y scale	--]]
			--for k,v in pairs(frameA) do if type(v)=="number" then o[k] = lerp(v or o[k] or 0, frameB[k] or o[k] or 0) end end		-- this line is an alternate implementation of the above 8 lines, but is a little slower. On the other hand, it'll tween custom numeric data in addition to TLboner's hardcoded data.
			
			local fadeIn,fadeOut = min(2-t*2,1), min(t*2,1)
			if o.i then
				color(cR,cG,cB, 255 * (frameA.i and 1-fadeIn or 1) * (frameB.i and 1-fadeOut or 1) )
				draw(o.i, tx,ty, ta+(o.oa or 0), o.sx,o.sy, o.ox,o.oy)
			end
			if frameA.i then color(cR,cG,cB, 255*fadeIn) draw(frameA.i, tx,ty, ta+(o.oa or 0), o.sx,o.sy, o.ox,o.oy) end
			if frameB.i then color(cR,cG,cB, 255*fadeOut) draw(frameB.i, tx,ty, ta+(o.oa or 0), o.sx,o.sy, o.ox,o.oy) end
		else
			if o.i then draw(o.i, tx,ty, ta+(o.oa or 0), o.sx,o.sy, o.ox,o.oy) end		-- draw the bone if it's drawable
		end
		
		if o.f then o.f( tx,ty,ta, ... ) end	-- if the bone has a function, call it
		if frameChange and frameA.f then frameA.f( tx,ty,ta,anim, ... ) end	-- if the pose has a function, call it once
		
		if o[1] then	-- traverse child bones
			tx,ty = tx+(o.l or 0)*sin(ta), ty-(o.l or 0)*cos(ta)	-- the new total coordinates are the current bone's endpoint
			for i=1,#o do drawBoner( o[i], tx,ty, ta, anim, frameA[i],frameB[i], t, frameChange, ... ) end
		end
	end
	
	drawBoner(o, x,y, a)
	--color(cR,cG,cB, cA)		-- restore the original color/alpha, in case it was changed
end


-- Change the animation of a boner
function TLboner.doanim(o, newAnim, tweenTime, rate, noOverride)
	assert(o, "You must specify a boner to change the animation of.")
	assert(newAnim, "You must specify a boner animation to use.")
	local tweenTime, rate = tweenTime or .5, rate or 1
	local tweenAnim = { r=1/tweenTime, loop=newAnim, advanced=newAnim.advanced }
	
	local function makeFrame(o, newAnim)
		local newFrame		-- tweenAnim's frame is the skeleton's current pose
		if not newAnim.advanced then newFrame = { a=o.a }
		else newFrame = { l=o.l, x=o.x, y=o.y, a=o.a, oa=o.oa, ox=o.ox, oy=o.oy, sx=o.sx, sy=o.sy, }
		end
		if not noOverride then o.anim = nil end		-- override animations on the new animation's child bones, if desired
		for i=1,#newAnim do newFrame[i] = makeFrame(o[i], newAnim[i]) end
		return newFrame
	end
	
	tweenAnim[1] = makeFrame(o, newAnim[1])		-- make a temporary frame from the current angles of each bone
	o.anim = { d=tweenAnim, t=0, r=rate  }
	if newAnim.f then newAnim.f() end
end