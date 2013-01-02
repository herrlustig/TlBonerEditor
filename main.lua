
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
  animation_test_mode = false

  bone_markers = nil
  bone_markers_simple = nil

  -- ----------------------- view options -------------------------------
  bmark_len = 8

  -- ----------------------- TLboner default skeleton -------------------
  anim = { 
    default = { 
		  r=1, loop=true, advanced=false,
		  { a=0, {a=math.pi},{a=-math.pi/2},{a=math.pi/2}  },
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

  bone_markers, bone_markers_simple = createBoneMarkers(love.graphics.getWidth()/2, love.graphics.getHeight()/2, body, anim.default[1], anim.default[1].a, true)
  print(dumpTable(bone_markers))
  print("\n\n")
  print(dumpTable(bone_markers_simple))
end


function love.keypressed(k)
	if k=="escape" then 
    love.event.push("q")
	elseif k=="t" then 
    animation_test_mode = not animation_test_mode
	elseif k=="r" then 
    rotate_mode = not rotate_mode
	else 
    animation_test_mode = false
    rotate_mode = false
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
        else
          -- print("there is a active image, set it to nil!")
          active_image = nil
          move_mode = false
          marker_move_mode_position = nil
        end
      elseif active_marker  then
        active_marker = false
        move_mode = false
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

    if move_mode and active_marker and marker_move_mode_position then
      -- remember mouse position
      loc = { love.mouse.getX(), love.mouse.getY() }
      x = marker_move_mode_position[1] - loc[1]
      y = marker_move_mode_position[2] - loc[2]
      -- TODO!!! adjust for no-brain-fuck-editing :D

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
      if v['image'] then
        -- print("print here: " .. loc[1] .. loc[2])
        love.graphics.draw(v['image'], v['bottom'][1], v['bottom'][2], v['angle'], v['body']['sx'],v['body']['sy'], v['body']['ox'],v['body']['oy'])
      end
    end
  else
    TLboner.draw(body, love.graphics.getWidth()/2 ,love.graphics.getHeight()/2, nil, dt)
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
  parent_angle = parent_angle or 0
  parent_angle = parent_angle + anim.a
  if root then 
    bone_markers_simple = {}
  end
  local bone_markers = {}

  -- body structure: {i=nil, sx=1, sy=1,  ox=0,   oy=0,     l=50, { ...<same here for subbone1>... }, { ...subbone2...}, etc }
  -- anim structure: { a = 0, {...<same here for subbone1>...}, {...etc... } }
  local new_x, new_y = x + (body.l*math.cos(parent_angle+math.pi*1.5)), y + (body.l*math.sin(parent_angle+math.pi*1.5))
  bottom = {x,y}
  top = {new_x,new_y}
  bone_markers.bottom = bottom--love.graphics.setColor(0, 0, 255, 255) -- set special color for root bone
  bone_markers.top = top
  -- also save references
  bone_markers.body = body
  bone_markers.anim = anim

  table.insert(bone_markers_simple, {bottom = bottom, top = top, body = body, anim = anim, angle = parent_angle})
  -- print ("recLvl " .. recLvl)
  for k, v in ipairs(body) do
    -- print(k .. " " .. new_x .. " " .. new_y)
    bone_markers[k] = createBoneMarkers(new_x, new_y, body[k], anim[k], parent_angle, false)
  end

  if root then
    return bone_markers, bone_markers_simple
  else
    return bone_markers
  end
end

function drawBones(bone_markers, root)
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
