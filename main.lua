
function love.load()
  -- load pictures of dir given via argument
  -- TODO: userinput
  dir = 'testmaterial/'
  files = love.filesystem.enumerate( dir )
  images = {}
  image_locations = {}

  for k, file in ipairs(files) do
    filename = dir .. file
    print("Filename " .. filename)
    -- TODO: add expection handling here. if it fails then remove file from files table
    table.insert(images, love.graphics.newImage(filename))
    x, y = math.random(0, 600), math.random(0, 300) -- TODO: replace with window resolution values
    print( "x,y" .. x .. "/" .. y )
    table.insert(image_locations, {x, y } )
  end

  hover_image = nil
  active_image = nil
  hover_bone = nil
  active_bone = nil
  move_mode = false
end


function love.keypressed(k)
  --[[
	if k=="escape" then love.event.push("q")
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
  if button == "l" then
    print("mouse klick left!")
    if active_image  then
      print("there is a active image, set it to nil!")
      active_image = nil
    else
      if hover_image then
        print("there is a hover image, set it to active!")
        active_image = hover_image
      end
    end
  end
  if button == "r" then move_mode = not move_mode end
end

function love.update()
  mousex, mousey = love.mouse.getX(), love.mouse.getY()
  -- hover checks
  found = false
  for k, image in ipairs(images) do
    loc = image_locations[k]
    loc2 = { loc[1] + image:getWidth(), loc[2] + image:getHeight() }
    if mousex >= loc[1] and mousex <= loc2[1] and mousey >= loc[2] and mousey <= loc2[2] then
      -- print("Hover Image!! => " .. k )
      hover_image = k
      found = true
    end
  end

  if found == false then hover_image = nil end

  if active_image and move_mode then
    image_locations[active_image] = {mousex, mousey}
  end
  --[[
  print ('hover_image => ' .. (hover_image or ''))
  print ('active_image => ' .. (active_image or ''))
  --]]
end

function love.draw()
  love.graphics.setBackgroundColor( 255, 255,255 )
  for k, v in ipairs(images) do
    loc = image_locations[k]
    -- print("print here: " .. loc[1] .. loc[2])
    love.graphics.draw(v, loc[1], loc[2])
  end

  -- ----------------------      markers      ---------------------------
  love.graphics.setColor(255, 0, 0, 255)
  -- mark active_image
  if active_image then
    loc = image_locations[active_image]
    width = images[active_image]:getWidth()
    love.graphics.line(loc[1],loc[2], loc[1] + width, loc[2])
  end

  love.graphics.setColor(0, 0, 0, 255)
end
