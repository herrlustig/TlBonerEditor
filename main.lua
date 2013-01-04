-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end


-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(x2-x1, y2-y1) end

function love.load()
  require "TLboner"
  -- load pictures of dir given via argument
  -- TODO: userinput
  dir = 'testmaterial/'
  files = love.filesystem.enumerate( dir )
  images = {}
  image_locations = {}
  defaultimage = love.graphics.newImage('defaultimage.png')

  for k, file in ipairs(files) do
    filename = dir .. file
    print("Filename " .. filename)
    -- TODO: add expection handling here. if it fails then remove file from files table
    table.insert(images, love.graphics.newImage(filename))
    x, y = math.random(0, love.graphics.getWidth()-100), math.random(0, love.graphics.getHeight() - 100) -- TODO: replace with window resolution values
    print( "x,y" .. x .. "/" .. y )
    table.insert(image_locations, {x, y } )
  end

  hover_image = nil
  active_image = nil
  hover_marker = nil
  active_marker = nil
  move_mode = false
  rotate_mode = false
  resize_mode = false
  animation_test_mode = false

  bone_markers = nil
  bone_markers_simple = nil

  skeleton_position = {love.graphics.getWidth()/2, love.graphics.getHeight()/2}

  -- ----------------------- view options -------------------------------
  bmark_len = 8

  -- ----------------------- TLboner default skeleton -------------------
  anim = { 
    default = { 
		  r=1, loop=true, advanced=false,
		  -- { a=0, {a=math.pi},{a=-math.pi/2},{a=math.pi/2}  },
		  { a=0, {a=0},{a=0},{a=0}  },
		--  { a=-0.1, {a=math.pi-0.1},{a=-math.pi/2-0.1},{a=math.pi/2+0.1}  },
    }
  }

  -- TLboner scaffold
  body = { 
    -- set default anim
    anim = { d=anim.default, t=0, r=1, },

    -- add root bone with some start values
    i=nil, sx=1, sy=1,  ox=0,   oy=0,     l=50,
    { i=nil, sx=1, sy=1,  ox=0,   oy=0,     l=50,},
    { i=nil, sx=1, sy=1,  ox=0,   oy=0,     l=50,},
    { i=nil, sx=1, sy=1,  ox=0,   oy=0,     l=50,},
    -- TODO: add other basic bones
  }

  bone_markers, bone_markers_simple = createBoneMarkers(skeleton_position[1], skeleton_position[2], body, anim.default[1], anim.default[1].a, true)
  print(dumpTable(bone_markers))
  --[[
  print("\n\n")
  print(dumpTable(bone_markers_simple))
  --]]
end


function love.keypressed(k)
	if k=="escape" then 
    love.event.push("q")
	elseif k=="t" then 
    print("toggle animation mode")
    animation_test_mode = not animation_test_mode
  end
  if active_marker then 
    animation_test_mode = false
    if k=="r" then 
      print("enter rotate mode")
      rotate_mode = not rotate_mode
      orig_angle = bone_markers_simple[active_marker]['body']['oa'] or 0
      marker_move_mode_position = { love.mouse.getX(), love.mouse.getY() } -- TODO: rename
    elseif k=="s" then 
      print("enter resize mode")
      resize_mode = not resize_mode
      orig_scale = {bone_markers_simple[active_marker]['body']['sx'] or 1, bone_markers_simple[active_marker]['body']['sy'] or 1}
      marker_move_mode_position = { love.mouse.getX(), love.mouse.getY() } -- TODO: rename
    elseif k=="a" then 
      print("add bone")
      table.insert(bone_markers_simple[active_marker]['body'], { i=nil, sx=1, sy=1,  ox=0,   oy=0,     l=50,})
      table.insert(bone_markers_simple[active_marker]['anim'], {a=0})
      -- recreate bone_markers 
      -- TODO: minor bug of createBoneMarkers! parent_angle must be set to nil here
      bone_markers, bone_markers_simple = createBoneMarkers(skeleton_position[1], skeleton_position[2], body, anim.default[1], nil, true)
    elseif k=="m" then 
      modify_mode = not modify_mode
      local bottom = bone_markers_simple[active_marker]['bottom'] 
      if modify_mode == false and new_angle then
        print("modified bone: set new bone position")
        bone_markers_simple[active_marker]['body']['l'] = math.dist(bottom[1], bottom[2], love.mouse.getX(), love.mouse.getY())
        bone_markers_simple[active_marker]['anim']['a'] = new_angle
        print ( "new angle")
        print (new_angle)
        print ( anim.default[1].a )
        -- recreate bone_markers -- TODO: update subbones's 'bottom' and 'top' and 'angle' attributes (used for drawing)
        -- TODO: minor 'bug' in createBoneMarkers, for root the parent angle has to be set to 0
        bone_markers, bone_markers_simple = createBoneMarkers(skeleton_position[1], skeleton_position[2], body, anim.default[1], 0, true)
        new_angle = nil
      elseif modify_mode then
        print("modify bone")
      end
      orig_angle = math.angle(bottom[1],bottom[2], love.mouse.getX(), love.mouse.getY() )

    end
	else 
    rotate_mode = false
    resize_mode = false
    orig_angle = nil
  end

  if k=="b" then 
      print("recreate bone_markers " )
      bone_markers, bone_markers_simple = createBoneMarkers(skeleton_position[1], skeleton_position[2], body, anim.default[1], anim.default[1].a, true)
  end
  --[[
	elseif k=="r" then love.filesystem.load("main.lua")() love.load()
	-- switch animations if buttons are pressed
	elseif k=="w" then TLboner.doanim(body, anim.up)
	elseif k=="a" then TLboner.doanim(body, anim.left, 1)
	elseif k=="s" then TLboner.doanim(body, anim.default)
	elseif k=="d" then TLboner.doanim(body, anim.right)
	elseif k=="q" then TLboner.doanim(body[2], anim.partial)
	elseif k=="z" then body.anim.r = body.anim.r<1 and 1 or 1/3
	elseif k=="up" then y = y - 10
	elseif k=="down" then y = y + 10
	elseif k=="right" then x = x + 10
	elseif k=="left" then x = x - 10
	end
  --]]
end

function love.mousepressed(x, y, button)
  if not animation_test_mode then
    if button == "l" then
      if active_image  then
        if hover_marker then
          -- attach image to bone
          print("attach image " .. active_image .. " to bone " .. hover_marker )
          bone_markers_simple[hover_marker]['image'] = images[active_image]
          bone_markers_simple[hover_marker]['body']['image'] = images[active_image]
        else
          -- print("there is a active image, set it to nil!")
          active_image = nil
          move_mode = false
          marker_move_mode_position = nil
        end
      elseif active_marker  then
        active_marker = false
        move_mode = false
        rotate_mode = false
        marker_move_mode_position = nil
      else -- no active image or marker
        if hover_marker then
          -- print("there is a hover image, set it to active!")
          active_marker = hover_marker
        elseif hover_image then
          -- print("there is a hover image, set it to active!")
          active_image = hover_image
        end
      end
    end


    -- ------------ right mouse button -------------
    if button == "r" then 
      move_mode = not move_mode
      if move_mode and active_marker then
        -- remember mouse position
        original_pos = { bone_markers_simple[active_marker]['body']['ox'], bone_markers_simple[active_marker]['body']['oy'] }
        marker_move_mode_position = { love.mouse.getX(), love.mouse.getY() }
      end
    end
  end
end

function love.update()
  mousex, mousey = love.mouse.getX(), love.mouse.getY()
  if not animation_test_mode then
    -- ---------------------- hover checks ------------------------
    -- image check
    found_img = false
    for k, image in ipairs(images) do
      loc = image_locations[k]
      loc2 = { loc[1] + image:getWidth(), loc[2] + image:getHeight() }
      if mousex >= loc[1] and mousex <= loc2[1] and mousey >= loc[2] and mousey <= loc2[2] then
        -- print("Hover Image!! => " .. k )
        hover_image = k
        found_img = true
      end
    end
    -- bone marker check
    found_marker = false
    for k, marker in ipairs(bone_markers_simple) do
      x, y = marker['top'][1], marker['top'][2]
      loc = {x - (bmark_len/2), y - (bmark_len/2) }
      loc2 = {x + (bmark_len/2), y + (bmark_len/2) }
      if mousex >= loc[1] and mousex <= loc2[1] and mousey >= loc[2] and mousey <= loc2[2] then
        -- print("Hover Marker!! => " .. k )
        hover_marker = k
        found_marker = true
      end
    end

    -----------------------
    if found_img == false then hover_image = nil end
    if found_marker == false then hover_marker = nil end

    if active_image and move_mode then
      image_locations[active_image] = {mousex, mousey}
    end

    if active_marker and modify_mode and orig_angle then
      local bottom = bone_markers_simple[active_marker]['bottom']
      local rel_angle = math.angle(bottom[1],bottom[2], love.mouse.getX(), love.mouse.getY() )
      local diff_angle = (orig_angle - rel_angle)%(2*math.pi)
      new_angle = (bone_markers_simple[active_marker]['anim']['a'] + diff_angle)%(2*math.pi)
      -- print ("orig / new angle:" .. bone_markers_simple[active_marker]['anim']['a'] .. " / " .. new_angle ) 
    elseif active_marker and rotate_mode and orig_angle and marker_move_mode_position then
      loc = { love.mouse.getX(), love.mouse.getY() }
      x = marker_move_mode_position[1] - loc[1]
      new_angle = (orig_angle + (x/100) )%(2*math.pi)
--      print ( "new angle is: " .. new_angle )
      bone_markers_simple[active_marker]['body']['oa'] = new_angle
    elseif resize_mode and active_marker and marker_move_mode_position and orig_scale then
      loc = { love.mouse.getX(), love.mouse.getY() }
      x = ( marker_move_mode_position[1] - loc[1] ) / 100
      y = ( marker_move_mode_position[2] - loc[2] ) / 100

      -- translate values into bones orientation
      trans_x = 1*(x*math.cos(bone_markers_simple[active_marker]['angle'])) + 1*(y*math.sin(bone_markers_simple[active_marker]['angle']+0*math.pi/2))
      trans_y = 1*(y*math.cos(bone_markers_simple[active_marker]['angle'])) + 1*(x*math.sin(bone_markers_simple[active_marker]['angle']+2*math.pi/2))
      -- print ( x .. " " .. y .. " => " .. trans_x .. " " .. trans_y)

      bone_markers_simple[active_marker]['body']['sx'] = orig_scale[1] - trans_x
      bone_markers_simple[active_marker]['body']['sy'] = orig_scale[2] - trans_y
    elseif move_mode and active_marker and marker_move_mode_position then
      loc = { love.mouse.getX(), love.mouse.getY() }
      x = marker_move_mode_position[1] - loc[1]
      y = marker_move_mode_position[2] - loc[2]

      -- translate values into bones orientation
      trans_x = 1*(x*math.cos(bone_markers_simple[active_marker]['angle'])) + 1*(y*math.sin(bone_markers_simple[active_marker]['angle']+0*math.pi/2))
      trans_y = 1*(y*math.cos(bone_markers_simple[active_marker]['angle'])) + 1*(x*math.sin(bone_markers_simple[active_marker]['angle']+2*math.pi/2))
      -- print ( x .. " " .. y .. " => " .. trans_x .. " " .. trans_y)

      bone_markers_simple[active_marker]['body']['ox'] = original_pos[1] + trans_x
      bone_markers_simple[active_marker]['body']['oy'] = original_pos[2] + trans_y
    end

    --[[
    print ('hover_image => ' .. (hover_image or ''))
    print ('active_image => ' .. (active_image or ''))
    --]]
  else -- if in animation_test_mode
  -------------------------------------- animation test mode ------------------------------
    if last_dt_animation_test_mode == false and animation_test_mode == true then
      print("going to animation test mode")
      -- 
      for k, bone in ipairs(bone_markers_simple) do
        if bone['image'] then
          bone['body']['i'] = bone['image']
        else -- use default pic if no image provided
          bone['body']['i'] = defaultimage -- TODO: remove this when going back to non-animation-test-mode
        end
      end
      -- print(dumpTable(body))
    end
  end


  last_dt_animation_test_mode = animation_test_mode
end

function love.draw()
  love.graphics.setBackgroundColor( 255, 255,255 )
  if not animation_test_mode then
    for k, v in ipairs(images) do
      loc = image_locations[k]
      love.graphics.draw(v, loc[1], loc[2])
    end
    for k, v in ipairs(bone_markers_simple) do
      local image = v['image'] or defaultimage
      love.graphics.draw(image, v['bottom'][1], v['bottom'][2], v['angle'] + (v['body']['oa'] or 0 ), v['body']['sx'],v['body']['sy'], v['body']['ox'],v['body']['oy'])
    end
    if active_marker then
      if modify_mode then
        local bottom = bone_markers_simple[active_marker]['bottom']
        love.graphics.line(bottom[1], bottom[2], love.mouse.getX(), love.mouse.getY())
      end
    end
  else
    TLboner.draw(body, skeleton_position[1], skeleton_position[2], nil, dt)
  end

  -- ----------------------      bones      ---------------------------
  love.graphics.setColor(0, 0, 0, 255)
  -- TODO: enable other anims, other frames
  drawBones(bone_markers, true) 
  if active_marker then
    act_b = bone_markers_simple[active_marker]
    love.graphics.setColor(255, 170, 0, 255)
    local bmark_len = bmark_len + 2
    love.graphics.rectangle('fill', act_b.top[1]-(bmark_len/2), act_b.top[2]-(bmark_len/2), bmark_len, bmark_len)
  end

  -- ----------------------      markers      ---------------------------
  -- mark inactive & active_image
  if not animation_test_mode then
    for k, loc in ipairs(image_locations) do
      if k == active_image then
        love.graphics.setColor(255, 0, 0, 255)
        width = images[k]:getWidth()
        love.graphics.line(loc[1],loc[2], loc[1] + width, loc[2])
      else
        love.graphics.setColor(0, 0, 255, 255)
        width = images[k]:getWidth()
        love.graphics.line(loc[1],loc[2], loc[1] + width, loc[2])
      end
    end
  end

  love.graphics.setColor(0, 0, 0, 255)
end

function createBoneMarkers(x, y, body, anim, parent_angle, root)
  root = root or false
  -- TODO: minor bug of createBoneMarkers! parent_angle must be set to nil here when creating from root
  -- TODO: following lines do not work properly , don't know why
  --[[
  if root then
    local parent_angle = 0 -- for root parent_angle should be zero, because there is no parent
  else
    local parent_angle = parent_angle or 0
  end
  --]]

  local angle = parent_angle + anim.a
  if root then 
    bone_markers_simple = {}
    print("new root angle")
    print(parent_angle)
    print(angle)
  end
  local bone_markers = {}

  -- body structure: {i=nil, sx=1, sy=1,  ox=0,   oy=0,     l=50, { ...<same here for subbone1>... }, { ...subbone2...}, etc }
  -- anim structure: { a = 0, {...<same here for subbone1>...}, {...etc... } }
  local new_x, new_y = x + (body.l*math.cos(angle+math.pi*1.5)), y + (body.l*math.sin(angle+math.pi*1.5))
  bottom = {x,y}
  top = {new_x,new_y}
  bone_markers.bottom = bottom
  bone_markers.top = top
  -- also save references
  bone_markers.body = body
  bone_markers.anim = anim
  bone_markers.angle = angle
  bone_markers.parent_angle = parent_angle
  bone_markers.image = bone_markers.body.image

  table.insert(bone_markers_simple, {bottom = bottom, top = top, body = body, anim = anim, angle = angle, parent_angle = parent_angle, image = bone_markers.body.image})
  -- print ("recLvl " .. recLvl)
  for k, v in ipairs(body) do
    -- print(k .. " " .. new_x .. " " .. new_y)
    bone_markers[k] = createBoneMarkers(new_x, new_y, body[k], anim[k], angle, false)
  end

  if root then
    return bone_markers, bone_markers_simple
  else
    return bone_markers
  end
end

function drawBones(bone_markers, root)
  local bone_markers = bone_markers
  root = root or false

  if root then 
    love.graphics.setColor(0, 0, 255, 255) -- set special color for root bone
  else 
    love.graphics.setColor(0, 0, 0, 255) 
  end

  love.graphics.line(bone_markers.bottom[1], bone_markers.bottom[2], bone_markers.top[1], bone_markers.top[2])
  -- mark top with rectangle
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.rectangle('fill', bone_markers.top[1]-(bmark_len/2), bone_markers.top[2]-(bmark_len/2), bmark_len, bmark_len)
  love.graphics.setColor(0, 0, 0, 255) 

  for k, v in ipairs(bone_markers) do
    drawBones(bone_markers[k])
  end
end

-- snippet from http://snippets.luacode.org/?p=snippets/Simple_Table_Dump_7 , downloaded at 31.12.2012
function dumpTable(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dumpTable(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end
